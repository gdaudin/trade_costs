
***** Programme Préparation Base HS 10
***** Réponse au référé 1



*version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
	global dir_data ~/Documents/Recherche/2013 -- Trade Costs -- local/data
	global dir_temp ~/Downloads/temp_stata
}


/* Fixe Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost_nonpartage\database
	global dir_db \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\database
}


cd "$dir_data"


** STEP 1: CONSTITUER BASE ADDITIONAL YEARS: 2005-2013 (Finalement, c’est fait ailleurs)
********************************************************************************


unzipfile base_new_years.zip
use base_new_years.dta, replace
erase base_new_years.dta


*** STEP 1.3: Construire l'écart prix cif/fob
******************************************************************************

** On le fait au niveau HS 10

**Il faut séparer les air et les vessels
** Attention, ce n'est pas "l'un ou l'autre"
** Il peut y avoir des observations qui utilisent à la fois air et ves
** On calcule un écart cif/fob pour chaque mode de transport


generate mode="ves"
save "$dir_temp/temp.dta", replace

replace mode="air"
preserve
append using "$dir_temp/temp.dta"
save "$dir_temp/temp.dta", replace
restore

replace mode="cnt"
append using "$dir_temp/temp.dta"


generate prix_fob=.
generate prix_caf=.
generate prix_trsp=.
generate prix_trsp2=.

foreach i in air ves cnt {
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


destring year, replace

*save base_hs10_newyears, replace
save "$dir_base/base_hs10_newyears.dta", replace

*erase "$dir/base_hs10_newyears.dta"
erase "$dir_temp/temp.dta"
