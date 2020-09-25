***********************************
** TRADE COSTS: ICEBERG, ADDITIVE, or BOTH?

** Avril 2015



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
	global dir_data ~/Documents/Recherche/2013 -- Trade Costs -- local/data
	global dir_external_data ~/Documents/Recherche/2013 -- Trade Costs -- local/external_data
	global dir_temp ~/Downloads/temp_stata
}


/* Fixe Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost_nonpartage\database
	global dir_data \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\database
	global dir_external_data ????
	global dir_temp ????
}



capture program drop Build_data_synthese
program Build_data_synthese
args year

cd "$dir_data"
************************************************************************
** PGM 1 : construction de la base de données - COMPLETE, de 1974 à 2013
************************************************************************

*** Attention, on part de la base de données fournies par Hummels sur son site
*** http://www.krannert.purdue.edu/faculty/hummelsd/research/jep/data.html ***

** Partant des importations US en hs10, hummels.dta = agrégé au niveau 5 digits (sitc2)

version 12

* sur le serveur
*cd "C:\Echange\trade_costs\database\hummels_db"
*sur mon ordi old
*cd "E:\Lise\BQR_Lille\data\USdata_use"

*sur mon nouvel ordi
if "`c(hostname)'" =="LAB0271A" cd "C:\Echange\trade_costs\database\hummels_db"

* sur le fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database"

clear all
set more off

*----------------------------------------------------------
**** STEP 1 - START FROM HUMMELS.dta, 1974-2004 
*----------------------------------------------------------


if "`c(hostname)'" =="LAB0271A"  use "C:\Lise\trade_costs\Hummels\database\raw_data\hummels.dta", clear
use "$dir_external_data/hummels.dta", replace

/*
* A faire une fois pour toutes
drop _merge
save "C:\Lise\trade_costs\Hummels\database\raw_data\hummels.dta", replace
*/

********Special Hummels******
capture drop iso_d
generate iso_d="USA"

capture drop _merge

merge m:1 iso2 using "$dir_external_data/Hummels_JEP_data/country_codes_v2.dta"
drop if _merge==2
drop _merge

rename yr year
tostring year, replace

rename iso3 iso_o

replace iso_o="SVN" if name=="Slovenia"
replace iso_o="MMR" if name=="Burma (Myanmar)"
replace iso_o="ZAR" if name =="Congo, Democratic Republic of th"

* On enlève si non renseigné pour le pays d'origine
drop if iso_o==""

*On enlève les territoires français d'Antarctique
drop if iso_o=="ATF"


merge m:1 iso_o iso_d using  "$dir_external_data/dist_cepii.dta"
drop if _merge==2
drop _merge


**Il faut séparer les air et les vessels
generate mode="ves"

save $dir_temp/temp, replace

replace mode="air"
append using $dir_temp/temp


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
}

drop if prix_fob==.

erase "$dir_temp/temp.dta"
destring year, replace
save hummels_tra.dta, replace 

*----------------------------------------------------------
*** STEP 2 - ADD NEW YEARS - ALL 2005-2013
*----------------------------------------------------------
**********
** Step 2.1 on va chercher les données
***************


*cd "E:\Jerome\Papier_Lise_Guillaume\2014"
*cd "E:\Lise\BQR_Lille\data\USdata_raw"
*cd "C:\Echange\trade_costs\database\hummels_db"

*cd "C:\Lise\trade_costs\Hummels\database\raw_data"

*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\database\rawdata" 

cd "$dir_data"

unzipfile base_`year'.zip
use base_`year'.dta, replace
erase base_`year'.dta

**********
** Step 2.2 On fait un collapse par sitc rev2/year/pays d'origine
***************


** Faire un collapse par year/country o/sitc2 (est-ce vraiment une bonne idée ?)


collapse(sum) con_qy1-ves_cha, by (iso_o year sitc2)
**Remarque : on se débarasse de cnt_ du coup.
count if sitc2==""
*422 obs sans code sitc2, on drop

drop if sitc2==""
count
* pour 2005 et 2006, 130,311 obs supplémentaires

egen _ =group(iso_o)
sum _
drop _
* 213 pays origine
egen _ = group(sitc2)
sum _
drop _
* 1735 sitc2 (5 digits)

save hummels_addyears, replace

******************************************************************************
*** STEP 2.3: Construire l'écart prix cif/fob
******************************************************************************

** Attention, comme pour la base hummels, on le fait au niveau agrégé (5 digits)

**Il faut séparer les air et les vessels
** Attention, ce n'est pas "l'un ou l'autre"
** Il peut y avoir des observations qui utilisent à la fois air et ves
** On calcule un écart cif/fob pour chaque mode de transport

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
}


** De cette façon là, prix_fob est missing pour l'observation par mode "air" si tout le transport se fait par "ves"
** Et réciproquement


drop if prix_fob==.

erase temp.dta
destring year, replace

save hummels_addyears, replace

***************************************************
*** STEP 2.6: ADD to the whole database
***************************************************

use hummels_tra, clear

append using hummels_addyears

save hummels_tra, replace

** Attention aux anciennes versions de stata si sous Stata13
*saveold hummels_tra, replace

 
erase hummels_addyears.dta


************************************************************************
*** 29 mai 2015 - To be confirmed 

*** Rétablir bug dans années récentes il n'y a pas les variables de gravité
*************************************************************************

* sur le fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database"

* sur le serveur
*cd "C:\Echange\trade_costs\database"

clear all
set more off



use hummels_tra, clear

* On enlève les variables de gravité et on recommence le merge
capture drop iso_d
generate iso_d="USA"

tab year

drop contig-distwces


*merge m:1 iso_o iso_d using "E:\Lise\BQR_Lille\data\USdata_raw\dist_cepii.dta"
merge m:1 iso_o iso_d using "$dir_external_data/dist_cepii.dta"
drop if _merge==2
drop _merge

label var iso2 "ISO 2 country code (origin)"
label var iso_d "Importing country (iso3)"
label var iso_o "Exporting country (iso3)"

capture rename con_cif_yr con_cif 
**Je ne sais pas pourquoi, mais c’était comme cela avant :)

save hummels_tra, replace

end


foreach year of numlist 2005(1)2019 {
	 Build_data_synthese `year'	
} 

