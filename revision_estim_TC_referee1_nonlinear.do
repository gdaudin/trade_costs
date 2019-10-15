

*version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost/JEGeo
}


/* Fixe Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\lpatureau\Dropbox\trade_cost\data
	global dir_temp \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results_revision /* pour stocker les bases temporaires */
	*global dir_results C:\Users\lpatureau\Dropbox\trade_cost\JEGeo\results
	global dir_results \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results_revision\non_linear
}

/* Vieux portable Lise */
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost\JEGeo
}

/* Nouveau portable Lise */
if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\lpatureau\Dropbox\trade_cost\data /* pour aller chercher la base de données au départ */ 
	global dir_temp \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results_revision /* pour stocker les base temporaires */
}





*cd $dir


capture log using "`c(current_time)' `c(current_date)'"

set more off


*----------------------------------------------------------
*** START FROM NEW YEARS 2005-2013
*----------------------------------------------------------

*****************************************************************
*** STEP 1: BUILD THE DATASET ***********************************
*****************************************************************



capture program drop build_database
program build_database

cd $dir_db\New_years


** STEP 1: CONSTITUER BASE ADDITIONAL YEARS: 2005, 2006, 2008, 2010 à 2013
********************************************************************************

** Step 1.1. Partir des nouvelles années en HS 10 **
** Garder le port d'entrée
 
local base IMDBR0512 IMDBR0612 IMDBR0712 IMDBR0812 IMDBR0912 IMDBR1012 IMDBR1112 IMDBR1212 IMDBR1312 
 
foreach x in `base' {
clear
infix str10	commodity 1-10 str6	cty_code 11-14 str2	cty_subco 15-16 str2	dist_entry 	17-18 str2	dist_unlad 	19-20 str2	rate_prov	21-22 int	year 23-26 int	month 	27-28 /*
*/ str15 cards_mo 29-43 double	con_qy1_mo 	44-58 double con_qy2_mo 59-73 double con_val_mo 74-88 double	dut_val_mo 	89-103 double	cal_dut_mo 	104-118 double	con_cha_mo 	119-133 /*
*/double con_cif_mo 134-148 double	gen_qy1_mo 	149-163 double	gen_qy2_mo 164-178 double gen_val_mo 179-193 double	gen_cha_mo 	194-208 double	gen_cif_mo 	209-223 double	air_val_mo 	224-238 /*
*/double air_wgt_mo 239-253 double	air_cha_mo 	254-268 double	ves_val_mo 	269-283 double	ves_wgt_mo 	284-298 double	ves_cha_mo 	299-313 double	cnt_val_mo 	314-328 double	cnt_wgt_mo 	329-343 /*
*/ double cnt_cha_mo 344-358 double	cards_yr 359-373 double	con_qy1_yr 	374-388 double	con_qy2_yr 	389-403 double	con_val_yr 	404-418 double	dut_val_yr 	419-433 double	cal_dut_yr 	434-448 /*
*/ double con_cha_yr 449-463 double con_cif_yr 464-478 double	gen_qy1_yr 	479-493 double	gen_qy2_yr 	494-508 double	gen_val_yr 	509-523 double	gen_cha_yr 	524-538 double	gen_cif_yr 	539-553 /*
*/ double	air_val_yr 	554-568 double	air_wgt_yr 	569-583 double	air_cha_yr 	584-598 double	ves_val_yr 	599-613 double	ves_wgt_yr 	614-628 double	ves_cha_yr 	629-643 double	cnt_val_yr 	644-658 /*
*/ double	cnt_wgt_yr 	659-673 double	cnt_cha_yr 	674-688  using `x'.txt

compress
save new_`x', replace

** Nettoyer a minima

use new_`x', clear

* renommer les variables
drop  cards_mo con_qy1_mo con_qy2_mo con_val_mo dut_val_mo cal_dut_mo con_cha_mo con_cif_mo gen_* 
drop air_val_mo air_wgt_mo air_cha_mo ves_val_mo ves_wgt_mo ves_cha_mo cnt_val_mo cnt_wgt_mo cnt_cha_mo
drop cnt_* cty_subco dist_unlad rate_prov month cal_dut_yr cards_yr

rename cty_code country 
rename commodity hs
rename con_qy1_yr con_qy1
rename con_qy2_yr con_qy2 
rename con_val_yr con_val 
rename ves_val_yr ves_val
rename air_val_yr air_val
rename con_cha_yr con_cha
rename ves_cha_yr ves_cha
rename air_cha_yr air_cha
rename air_wgt_yr air_wgt
rename ves_wgt_yr ves_wgt
rename dut_val_yr duty 



save new_`x', replace
}

** Compiler les années à partir de 2005 en une même base
** Start in 2005
use new_IMDBR0512, clear

save $dir_db\base_hs10_newyears, replace



foreach x in new_IMDBR0612 new_IMDBR0712 new_IMDBR0812 new_IMDBR0912 new_IMDBR1012 new_IMDBR1112 new_IMDBR1212 new_IMDBR1312 { 
 

use $dir_db\base_hs10_newyears, clear

append using `x'

save $dir_db\base_hs10_newyears, replace

}

foreach x in `base' {
erase new_`x'.dta 
}


** Step 1.2 Ajout variables pays origine
******************************************************

** convertir le code pays en iso2 -iso3
** Les données du US Census sont au départ en code à 4 chiffres
** Conversion en iso2 via Schedule C (see US census foreign trade website)

cd $dir_db
 
clear 
insheet using countrycodes_use.txt, delimiter(";") 

rename isocode iso2
rename code country
tostring country, replace
sort country
save temp, replace


use base_hs10_newyears, clear
sort country
merge m:1 country using temp
drop if _merge==2
drop _merge


save base_hs10_newyears, replace
erase temp.dta

** Ajouter code iso3

use base_hs10_newyears, clear

* Ajouter la variable iso_d pour merge ensuite sur les variables de gravité
capture drop iso_d
generate iso_d="USA"


*merge m:1 iso2 using "E:\Lise\BQR_Lille\data\USdata_raw\country_codes_v2.dta"
merge m:1 iso2 using country_codes_v2
drop if _merge==2

drop _merge

** on enlève si code pays origine pas renseigné
drop if iso2==""

*rename yr year
tostring year, replace

rename iso3 iso_o


replace iso_o="SVN" if name=="Slovenia"
replace iso_o="MMR" if name=="Burma (Myanmar)"
replace iso_o="ZAR" if name =="Congo, Democratic Republic of th"

drop if iso_o==""
*On enlève les territoires français d'Antarctique.
drop if iso_o=="ATF"

label var iso2 "ISO 2 country code (origin)"
label var iso_d "Importing country (iso3)"
label var iso_o "Exporting country (iso3)"

save base_hs10_newyears, replace

******************************************************************************
*** STEP 2.3: Introduire éuqlivalence HS10 - SITC2 (la clé de classification dans hummels_tra)
******************************************************************************

** Les nouvelles années sont codées en HTS (Harmonized Tariff System): variable hs
** Les 6 premiers chiffres de "hs" sont en fait les mêmes que la classification HS6

** On garde les 6 premiers chiffres, on convertit ensuite en sitc Rev2

use base_hs10_newyears, clear

gen hs6=substr(hs,1,6)


save base_hs10_newyears, replace

clear

** Table de conversion HS6 - SITC2 (HS6 version 2002)
infix str6 hs2002 1-6 str sitc2 9-13 using HS2002_SITC2.txt
drop if _n==1
save hs_sitc2, replace

use hs_sitc2, clear
gen t0 = "0"
gen tt0 = "00"
gen tt = length(sitc2)
tab tt


egen sitc2_1 = concat(sitc2 t0) if length(sitc2)==4
egen sitc2_2 = concat(sitc2 tt0) if length(sitc2)==3

replace sitc2=sitc2_1 if length(sitc2)==4
replace sitc2=sitc2_2 if length(sitc2)==3

drop tt
gen tt= length(sitc2)
tab tt

drop tt0 t0 sitc2_1 sitc2_2 tt
rename hs2002 hs6
duplicates report hs6

save hs_sitc2, replace

** Merge avec base

use base_hs10_newyears, clear
merge m:1 hs6 using hs_sitc2

count if _merge==1
egen _=group(hs6) if _merge==1
sum _
drop _


drop if _merge==2
drop _merge

label var hs6 "HS6 classification (2002 version)"
label var sitc2 "SITC, Rev.2, 5 digit"

save base_hs10_newyears, replace



*** STEP 1.3: Construire l'écart prix cif/fob
******************************************************************************

** On le fait au niveau HS 10

**Il faut séparer les air et les vessels
** Attention, ce n'est pas "l'un ou l'autre"
** Il peut y avoir des observations qui utilisent à la fois air et ves
** On calcule un écart cif/fob pour chaque mode de transport

use base_hs10_newyears, clear

generate mode="ves"
save temp, replace

replace mode="air"
append using temp


generate prix_fob=.
generate prix_caf=.
generate prix_trsp=.
generate prix_trsp2=.

foreach i in air ves {
	replace prix_fob = `i'_val/`i'_wgt if mode=="`i'"
	replace prix_caf = (`i'_val+`i'_cha)/`i'_wgt if mode=="`i'"
	replace prix_trsp=(prix_caf-prix_fob)/prix_fob if mode=="`i'"
	replace prix_trsp2=prix_caf/prix_fob
	label variable prix_trsp "(prix_caf-prix_fob)/prix_fob"
	label variable prix_trsp2 "prix_caf/prix_fob"
}


** De cette façon là, prix_fob est missing pour l'observation par mode "air" si tout le transport se fait par "ves"
** Et réciproquement


drop if prix_fob==.

erase temp.dta
destring year, replace

save base_hs10_newyears, replace
save $dir/database/base_hs10_newyears, replace

end


******************************************************
*** STEP 2: PREPARER LA BASE  pour la régression *****
******************************************************

capture program drop prep_reg
program prep_reg
args year class preci mode


use "$dir/database/base_hs10_newyears.dta"

keep if year==`year'
keep if mode=="`mode'"
rename `class' sector
replace sector = substr(sector,1,`preci')

drop if sector==""

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"
 
label var hs "HS 10 classification"

* Nettoyer la base de données

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************

display "Nombre avant bas et haut " _N

bys sector: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys sector: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 


display "Nombre après bas et haut " _N

*egen prix_min = min(prix_trsp2), by(sector)
*egen prix_max = max(prix_trsp2), by(sector)

**********Sur le produits

*codebook sector
egen group_sector=group(sector)
su group_sector, meanonly	
drop group_sector
local nbr_sector_exante=r(max)
display "Nombre de produits (`preci' digits) : `nbr_sector_exante'" 

bysort sector: drop if _N<=5


save $dir/database/tempHS10_`year'_`class'_`preci'_`mode', replace


end

******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE DU BETA ****
******************************************************************

capture program drop nlestim_beta
program nlestim_beta
	version 14
	su group_iso_o, meanonly	
	local nbr_iso_o=r(max)
	
	su group_prod, meanonly	
	local nbr_prod=r(max)
	
	su group_dentry, meanonly	
	local nbr_dentry=r(max)
	local nbr_var = `nbr_iso_o'+`nbr_prod'+`nbr_dentry' -1 +2 /*+11*/
		
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)
	local n 1
	
	
	foreach var in lprix_trsp2  lprix_fob  {
		local `var' : word `n' of `varlist'
		local n = `n'+1
	}

	local n 1
		
	capture drop blif
	generate double blif =0

		
**Ici, on fait les effets fixes (produit-pays-point d'entrée)
	
		foreach p in iso_o prod dist_entry {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="iso_o" | `j'!=1 {
					tempname fe_`p'_`j'
					scalar `fe_`p'_`j'' =`at'[1,`n']
************************

					replace blif = blif + `fe_`p'_`j'' * `p'_`j'
					local n = `n'+1
				}
			}
		}
	
	tempname x
	scalar `x' =`at'[1,`n']


	replace blif =blif+ `lprix_fob'*(1/(1+exp(`x'))

* v10 on modifie la forme fonctionnelle
* de cette façon les erreurs sont bien centrées sur 0
	replace `lprix_trsp2' = blif
	
*Si je mets des "*" dans le terme_I, il me faut une constante
*Mais dans la forme fonctionnelle, il n'y a pas de constante, donc pas besoin ?
	
	
end
**********************************************************************
************** FIN FONCTION
**********************************************************************	

*** PROGRAMME DE REGRESSION **********


capture program drop do_reg
program do_reg
args year class preci mode

*** Pour stocker les résultats
clear
gen sector = ""
gen iso_o = ""
gen beta=.

save  $dir_results\results_beta_`year'_`class'_`preci'_`mode', replace

*** Faire les régressions

cd $dir_temp

use $dir/database/tempHS10_`year'_`class'_`preci'_`mode', clear

g lprix_trsp2 = ln(prix_trsp2)
label variable lprix_trsp2 "log(prix_caf/prix_fob)"
label variable prix_trsp2 "prix_caf/prix_fob"

g lprix_fob = ln(prix_fob)
label variable lprix_fob "log(prix_fob)"

* stocker les résultats
gen beta=.

count

* on fait la régression par secteur-pays: On ne garde que les observations pertinentes

quietly levelsof iso_o, local(liste_iso_o) clean
quietly levelsof sector, local(liste_sector) clean

save temp, replace

foreach i in `liste_iso_o' {

	use temp, clear
	
	keep if iso_o=="`i'"
	
	save temp_`i', replace
	
	foreach k in `liste_sector' {
	
	use temp_`i', clear
	keep if sector =="`k'"
	save temp_`i'_`k', replace
	
	}
	erase temp_`i'.dta
	}

foreach i in `liste_iso_o' {
foreach k in `liste_sector' {

use temp_`i'_`k', clear

local nb = _N

 * il faut que la base soit non vide
if `nb' !=0 {

egen group_dentry=group(dist_entry)
su group_dentry, meanonly	
local nbr_dentry=r(max)
*local nbr_dentry_min=r(min)
display "For sector `k', country `i': Nombre de district of entry = `nbr_dentry'" 


egen group_prod=group(hs)
su group_prod, meanonly	
local nbr_prod=r(max)
local nbr_prod_min=r(min)

egen group_iso_o=group(iso_o)
su group_iso_o, meanonly	
local nbr_iso_o =r(max)
local nbr_iso_o_min=r(min)

display "For sector `k', country `i': Nombre de products (HS 10) = `nbr_product'" 

local nbr_var = `nbr_product' + `nbr_dentry' + `nbr_iso_o' +1

disp "nb of explicatives"
disp "`nbr_var'"

* il faut plus d'observations que de nombre de variables explicatives pour faire la régression
	

	if `nb' > `nbr_var' {

*** Génerer les effets fixes produit / district of entry
* On fait la régression par couple pays/secteur donc pas la peine de mettre des EF secteur / pays

tab(hs),gen(product)
tab(dist_entry),gen(dist_entry)

nl estim_beta  @ lprix_trsp2 lprix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')

capture matrix X= e(b)

replace beta=X[1,1] if iso_o=="`i'" & sector=="`k'"



}
}

keep iso_o sector beta 
keep if _n==1

save temp_`i'_`k', replace

}
}

*** Stocker les résultats

foreach i in `liste_iso_o'  {
foreach k in `liste_sector' {


use $dir_results\results_beta_`year'_`class'_`preci'_`mode', clear
append using $dir_temp\temp_`i'_`k'
save $dir_results\results_beta_`year'_`class'_`preci'_`mode', replace

erase $dir_temp/temp_`i'_`k'.dta
}

}
erase $dir_temp/temp.dta

histogram beta, title("Distribution of beta, `year', `mode', `preci' digits") 
graph export $dir_results/histogram_beta_`year'_`class'_`preci'_`mode'.pdf, replace


end

*******************************************************************************************
******* FIN DES PROGRAMMES ****************************************************************
*******************************************************************************************

**** lancer les programmes **************

* A FAIRE UNE FOIS POUR TOUTES
*program build_database


* PREPARER ET LANCER LES REGRESSIONS- Uniquement sur les années 2005 à 2013

cd $dir


set more off
local mode air ves
*local year 2005 


foreach x in `mode' {

forvalues z = 2006(1)2013 {
*foreach z in 2005 {

capture log close
log using results_estim_TC_referee1_`z'_`x', replace

prep_reg `z' sitc2 3 `x'
do_reg `z' sitc2 3 `x'


log close

}
}



