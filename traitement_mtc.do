*** Pgm pour extraire la variable Vk de la Maritime Trnasport Costs database


**  traitement_mtc.do

*** GD LP Dec 23/12/2106


version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

import delimited using "C:\Users\lise\Dropbox\trade_cost\data\MTC_data.csv", delimiters(",") stringcols(11)



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

save "C:\Users\lise\Dropbox\trade_cost\data\data_mtc", replace

***  Convertir en SITC2  *************************************************

*** On double conversion: hs1988 en sitc Rev3, puis sitc Rev3 en sitc Rev 2

**** 23/12/2015 : Pb to be solved, pb d'encodage on perd les 0 du coup à la fin trop de variables unmatched

cd "C:\Users\lise\Dropbox\trade_cost\data"

import excel "CN 1988 - HS 1988 - CPA 1996 - SITC Rev 3 (eurostat_ramon)", firstrow allstring clear
replace SITCRev3 = substr(SITCRev3,2,.)

duplicates drop


save hs1988_sitc3, replace

import excel "SITC3- SITC2 Conversion (UNSTATS)", firstrow clear allstring
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



