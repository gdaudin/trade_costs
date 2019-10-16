*** Pgm pour extraire la variable Vk de la Maritime Trnasport Costs database


**  traitement_mtc.do

*** GD LP Dec 23/12/2106


version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/2013 -- trade_cost -- dropbox



if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost


if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost

if ("`c(os)'"=="Windows") import delimited using "$dir\data\MTC_data.csv", delimiters(",") stringcols(11)

if ("`c(os)'"=="MacOSX") import delimited using "$dir/data/MTC_data.csv", delimiters(",") stringcols(11)


drop time flags flagcodes transportcostmeasures

reshape wide value, i(commodity exp transportmode tog year) j(meas) string 

sort exp comh0

* chaque ligne : pays d'origine / transport mode (container/bulk)/ commodity via comh0 (hs6) / type of good via tog/ année (ici la même 2005)
* soit : imp/ transportmode/ comh0/ tog/year

* les valeurs pour hs 2 digits sont la somme par pays/tog etc., des valeurs en hs6
* On drop les variables hs2


drop if strlen(comh0)==2

gen tt = strlen(comh0)
sum tt

drop tt
* On n'a plus que du hs6

if ("`c(os)'"=="Windows") save "$dir\data\data_mtc", replace
if ("`c(os)'"=="MacOSX") save "$dir/data/data_mtc", replace

***  Convertir en SITC2  *************************************************

*** On double conversion: hs1988 en sitc Rev3, puis sitc Rev3 en sitc Rev 2

**** 23/12/2015 : Pb to be solved, pb d'encodage on perd les 0 du coup à la fin trop de variables unmatched

if ("`c(os)'"=="Windows") cd "$dir\data"
if ("`c(os)'"=="MacOSX") cd "$dir/data"

import excel "CN 1988 - HS 1988 - CPA 1996 - SITC Rev 3 (eurostat_ramon)", firstrow allstring clear

replace SITCRev3 = substr(SITCRev3,2,.)

replace HS1988="0" + HS1988  if strlen(HS1988) == 5

replace SITCRev3= SITCRev3 + "0" if strlen(SITCRev3) == 4
replace SITCRev3= SITCRev3 + "00" if strlen(SITCRev3) == 3

duplicates drop


save hs1988_sitc3, replace

import excel "SITC3- SITC2 Conversion (UNSTATS)", firstrow clear allstring


replace SITCRev3= SITCRev3 + "0" if strlen(SITCRev3) == 4
replace SITCRev3= SITCRev3 + "00" if strlen(SITCRev3) == 3


save sitc3_sitc2, replace

** merger les deux bases en une seule

use hs1988_sitc3, clear

sort SITCRev3

merge m:1 SITCRev3 using sitc3_sitc2

drop if _merge==2
* on drop les sitc3 vers lesquels aucun hs1988 ne pointe
rename _merge merge1

save temp, replace

use data_mtc, clear

rename comh0 HS1988

merge m:1 HS1988 using temp


drop if _merge==2
* On drop les observations avec codes stic2 mais sans données de MTC

drop _merge merge1

generate SITCRev2_3d = substr(SITCRev2,1,3)

drop if SITCRev2_3d==""

save data_mtc_avec_conversion, replace

*** Step suivant
*** On a le MTC par produit/pays d'origine (année = 2005)
*** On veut extraire une proxy du poids volumétrique = dimension produit seulement

*** Donc, régresser sur effets fixes pays et EF produit

use data_mtc_avec_conversion, clear


** On veut vérifier que les pays ne sont pas des exportateurs mono-secteurs
codebook SITCRev2_3d
* 235 secteurs (SITC rev 2, 3d)

codebook exp
* 186 pays



** Nous donne le nb de secteurs par pays exportateur
gen unit=1
collapse (sum) unit, by(exp SITCRev2_3d)
drop unit
tab exp
bys exp:gen nbr_sect_exp=_N
bys exp:keep if _n==1
drop SITCRev2_3d
save temp, replace

use data_mtc_avec_conversion, clear
if ("`c(os)'"=="Windows") merge m:1 exp using "$dir\data\temp.dta"
if ("`c(os)'"=="MacOSX") merge m:1 exp using "$dir/data/temp.dta"
drop _merge

save data_mtc_avec_conversion, replace
erase temp.dta

* ------------------------------------------------------------------------------------------------------------------
*** Avant de faire la régression, on vérifie que par SITC 3d, toutes les valeurs de valueTR_UNIT ne sont pas missing
* ------------------------------------------------------------------------------------------------------------------

use data_mtc_avec_conversion, clear

bys SITCRev2_3d: egen nbfilled_bySITC_3d = count(valueTR_UNIT)

tab SITCRev2_3d if nbfilled_bySITC_3d == 0 

/*

SITCRev2_3d |      Freq.     Percent        Cum.
------------+-----------------------------------
        282 |         51        7.61        7.61
        289 |         34        5.07       12.69
        665 |        350       52.24       64.93
        667 |         57        8.51       73.43
        671 |        145       21.64       95.07
        681 |         14        2.09       97.16
        961 |          8        1.19       98.36
        971 |         11        1.64      100.00
*/
drop if nbfilled_bySITC_3d == 0 


** la variable dépendante est VALUETR_UNIT =  transport cost per kilogramme, or in other words, the cost in USD required to transport one kilogramme of merchandise
** mais on veut régresser en pondérant par le nb de kg impliqué dans chaque importation

** UNIT = COST/quanty
** ADvalorem = COST/(price*qty)

** Donc
** pour avoir la quantité

** qty = valueTR_COST/valueTR_UNIT
** value = price*qty =valueTR_COST/valueTR_ADVA

gen qty = valueTR_COST/valueTR_UNIT

label var qty "quantity by maritime flow"

gen value = valueTR_COST/valueTR_ADVA
label var value "value by maritime"

* On prend le log du cout de transport
gen ln_TRunit = log(valueTR_UNIT)

drop if nbr_sect_exp < 50

encode SITCRev2_3d , generate(SITCRev2_3d_num)

su SITCRev2_3d_num, meanonly	
local nbr_sitc=r(max)
quietly levelsof SITCRev2_3d, local (liste_sitc) clean

encode exp, generate(exp_num) label()


**********************************************************
** Faire la régression pour extraire la composante secteur
**********************************************************


reg ln_TRunit i.SITCRev2_3d_num i.exp_num  [iweight = qty], robust 


capture	matrix X= e(b)

codebook exp if e(sample)==1
** 69 pays exportent dans 50 secteurs ou plus
** une manière de s'assurer que nos effets fixes produits sont bons

** Last step : enregistrer nos effets fixe produit

generate effet_fixe=.
 
keep SITCRev2_3d_num SITCRev2_3d effet_fixe
bys SITCRev2_3d_num : keep if _n==1

insobs `nbr_sitc'
local n 1
foreach i in `liste_sitc' {
	*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
	replace effet_fixe= X[1,`n'] in `n'
	local n=`n'+1
}

br

drop if effet_fixe == .

rename effet_fixe Vk
replace Vk=exp(Vk)
label var Vk "Indice de poids volumetrique par secteur (SITC Rev 2, 3 d)"

keep SITCRev2_3d Vk

save database_Vk, replace

erase data_mtc_avec_conversion.dta
erase hs1988_sitc3.dta
erase sitc3_sitc2.dta


