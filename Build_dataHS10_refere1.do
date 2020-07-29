
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


** Juillet 2020: Lise, je mets tout sur mon OneDrive


/* Fixe Lise A FAIRE */
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\Ipatureau\Dropbox\trade_cost\JEGeo
	global dir_data \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\data
	global dir_temp \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\temp /* A créer */ 
}

/* Dell portable Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir "C:\Users\Ipatureau\Dropbox\trade_cost\JEGeo"
	global dir_data "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data"
	global dir_base "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data" /* pour l'instant je ne vois pas de difference avec le dossier data ? voir avec Guillaume */
	global dir_temp "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
}



cd "$dir_data"


** STEP 1: CONSTITUER BASE ADDITIONAL YEARS: 2005-2013 (Finalement, c’est fait ailleurs)
********************************************************************************


** base_new_years.zip est générée par build_new_years.do, à faire tourner avant **

unzipfile base_new_years.zip
use base_new_years.dta, replace
erase base_new_years.dta

***** Vérifications diverses
assert ves_wgt>=cnt_wgt /*suggère que cnt est bien un sous-ensemble de ves*/
assert con_val==gen_val, rc0 /*en 2010, c’est 3,8% des observations) ; 4,1% sur 2005-2013*/
assert gen_val==ves_val+air_val, rc0 /*en 2010 : 12,3%* 12,3% sur 2005-2013*/
assert ves_val==0 | air_val==0, rc0 /*7% des flux sur 2005-2013*/
assert (ves_val==0 | air_val==0) & (ves_val==gen_val | air_val==gen_val), rc0 /*19% sur 2005-2013*/

****Quelques variables d’intérêt
gen duty_rate = duty/con_val
label var duty_rate "cal_dut_yr/con_val -- estimate"



****Des variables en moins
drop con*
drop cnt*
drop duty
drop dut_val

assert gen_qy1 !=0, rc0 /*24% de qy1 manquant*/

gen ves_qy1 = ves_val*gen_qy1/gen_val
label var ves_qy1 "ves_val*gen_qy1/gen_val --- Assume that quantites to dollars are the same for all transportation modes"
gen ves_qy2 = ves_val*gen_qy2/gen_val
label var ves_qy2 "ves_val*gen_qy2/gen_val --- Assume that quantites to dollars are the same for all transportation modes"

gen air_qy1 = air_val*gen_qy1/gen_val
label var air_qy1 "air_val*gen_qy1/gen_val --- Assume that quantites to dollars are the same for all transportation modes"
gen air_qy2 = air_val*gen_qy2/gen_val
label var air_qy2 "air_val*gen_qy2/gen_val --- Assume that quantites to dollars are the same for all transportation modes"
drop gen_*


*** STEP 1.3: Construire l'écart prix cif/fob
******************************************************************************

** On le fait au niveau HS 10

**Il faut séparer les air et les vessels
** Attention, ce n'est pas "l'un ou l'autre"
** Il peut y avoir des observations qui utilisent à la fois air et ves
** On calcule un écart cif/fob pour chaque mode de transport


preserve
generate mode="ves"
drop air_*
rename ves_* *
drop if val==. | val==0 | wgt==0
save "$dir_temp/temp.dta", replace

restore
generate mode="air"
drop ves_*
rename air_* * 
drop if val==. | val==0 | wgt==0
append using "$dir_temp/temp.dta"
save "$dir_temp/temp.dta", replace

/*
replace mode="cnt"
append using "$dir_temp/temp.dta"
*/


generate prix_fob_wgt = val/wgt
generate prix_caf_wgt = (val+cha)/wgt
generate prix_fob_qy1 = val/qy1
generate prix_caf_qy1 = (val+cha)/qy1
generate prix_fob_qy2 = val/qy2
generate prix_caf_qy2 = (val+cha)/qy2
generate prix_trsp=(prix_caf_wgt-prix_fob_wgt)/prix_fob_wgt if mode=="`i'"
generate prix_trsp2=prix_caf_wgt/prix_fob_wgt
label variable prix_trsp "(prix_caf_wgt-prix_fob_wgt)/prix_fob_wgt"
label variable prix_trsp2 "prix_caf_wgt/prix_fob_wgt"

destring year, replace

*save base_hs10_newyears, replace
save "$dir_data/base_hs10_newyears.dta", replace

*erase "$dir/base_hs10_newyears.dta"
erase "$dir_temp/temp.dta"
