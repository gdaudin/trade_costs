
*ssc install reghdfe, replace
*ssc install estout, replace
*ssc install ftools, replace


set more off


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_pgms $dir/trade_costs_git
}


cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
*cd "$dir/results/IV_referee1"

*use "$dir/data/hummels_tra.dta", clear
use hummels_tra.dta, clear
set matsize 10000




keep if year >2003
keep mode sitc2 prix_fob prix_caf prix_trsp prix_trsp2 duty iso_o year con_val ves_val air_val

duplicates tag mode year sitc2 iso_o, g(tag)
sort mode year sitc2 iso_o
tab tag
*no duplicates, all good
drop if tag==1
drop tag

drop if sitc2==""

sort year mode iso_o

***** tariff AVE
/*

con_val 	double    %10.0g 	Imports for Consumption, Customs Value
ves_val 	double    %10.0g 	Shipments by Ocean Vessel, Customs Value
air_val 	double    %10.0g 	Shipments by Air, Customs Value

==> Utiliser con_val au dénominateur semble la chose à faire pour le calcul du tariff AVE 
(on ne voit pas pourquoi on devrait avoir deux AVE différents pour air et vessel)
==> On calcule néanmoins des tariff AVE par mode, pour plus tard.

*/

bys sitc2 year iso_o: gen s_tariff = duty/con_val
label var s_tariff "tariff as share of value imported, all modes"
bys sitc2 year iso_o mode: gen s_tariff_air = duty/air_val
label var s_tariff "tariff as share of value imported, air"
bys sitc2 year iso_o mode: gen s_tariff_ves = duty/ves_val
label var s_tariff "tariff as share of value imported, ves"

bys sitc2 year iso_o: gen ls_tariff = ln(1+s_tariff)
label var ls_tariff "ln(1+tariff as share of value imported, all modes)"
bys sitc2 year iso_o mode: gen ls_tariff_air = ln(1+s_tariff_air)
label var ls_tariff "ln(1+tariff as share of value imported, air)"
bys sitc2 year iso_o mode: gen ls_tariff_ves = ln(1+s_tariff_ves)
label var ls_tariff "ln(1+tariff as share of value imported, all modes)"

**** ln-linéarisation prix_fob, mais cela impliquera d'appliquer la fonction exponentielle aux prédictions***
gen lprix_fob= ln(prix_fob)

****** Fixed effects************************
****on crée le niveau sectoriel 3 digit***

gen sitc2_3d= substr(sitc2, 1, 3)

****On crée tous les FE utiles

egen sector_3d=group(sitc2_3d)

egen cntry=group(iso_o)
egen cntry_year=group(iso_o year)

******on crée des dummies country X year
set more off
tab cntry_year, gen(cntry_yeard) 


egen cntry_sect3d=group(iso_o sitc2_3d)
egen sect3d_year=group(sitc2_3d year)

egen cntry_sect5d=group(iso_o sitc2)
egen cntry_sect5d_mode=group(iso_o sitc2 mode)

egen cntry_sect3d_mode=group(iso_o sitc2_3d mode)
egen cntry_mode_year=group(iso_o mode year)
egen sect3d_mode_year=group(sitc2_3d mode year)


**** First_dif****
tsset cntry_sect5d_mode year

gen dlprix_fob = d.lprix_fob

gen dls_tariff = d.ls_tariff

gen dprix_fob = d.prix_fob

gen ds_tariff = d.s_tariff



order year iso_o sitc2_3d sitc2 mode lprix_fob dlprix_fob ls_tariff dls_tariff

*drop if year ==2004

save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", replace
*save "$dir/results/IV_referee1/hummels_FS.dta", replace



***************************************************
***********First-stage regressions, PANEL**********
***************************************************



************************
**********panel*********
************************

use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
*use "$dir/results/IV_referee1/hummels_FS.dta", clear

cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
*cd "$dir/results/IV_referee1"

capture log close
capture eststo clear
capture drop FEcs
capture drop FEsy

log using first_stage_panel.log, replace


set more off

***************pour info : air et vessel ensemble*********

/*reghdfe lprix_fob ls_tariff, a(cntry_sect3d sect3d_year) vce (cluster cntry_year) 

reghdfe dlprix_fob dls_tariff, a(cntry_sect3d sect3d_year) vce (cluster cntry_year) 

reghdfe dprix_fob ds_tariff, a(cntry_sect3d sect3d_year) vce (cluster cntry_year) 



reghdfe lprix_fob ls_tariff, a(cntry_sect3d_mode sect3d_mode_year) vce (cluster cntry_mode_year) 

reghdfe dlprix_fob dls_tariff, a(cntry_sect3d sect3d_year) vce (cluster cntry_mode_year) 

reghdfe dprix_fob ds_tariff, a(cntry_sect3d sect3d_year) vce (cluster cntry_year) 
*/

*****just air
eststo: reghdfe lprix_fob ls_tariff if mode=="air", a(FEcs=cntry_sect3d FEsy=sect3d_year) vce (cluster cntry_year) resid
predict lprix_panel_hat_air_allFE,xbd
drop FEcs FEsy
eststo: reghdfe lprix_fob ls_tariff cntry_yeard* if mode=="air", a(FEcs=cntry_sect3d FEsy=sect3d_year) resid 
predict lprix_panel_hat_air_allFE2,xbd
drop FEcs FEsy

eststo: reghdfe dlprix_fob dls_tariff if mode=="air", a(FEcs=cntry_sect3d FEsy=sect3d_year) vce (cluster cntry_year) resid
predict dlprix_panel_hat_air_allFE,xbd 
drop FEcs FEsy
eststo: reghdfe dlprix_fob dls_tariff cntry_yeard* if mode=="air", a(FEcs=cntry_sect3d FEsy=sect3d_year) resid
predict dlprix_panel_hat_air_allFE2,xbd 
drop FEcs FEsy

eststo: reghdfe dprix_fob ds_tariff if mode=="air", a(FEcs=cntry_sect3d FEsy=sect3d_year) vce (cluster cntry_year)  resid
predict dprix_panel_air_hat_allFE,xbd
drop FEcs FEsy
eststo: reghdfe dprix_fob ds_tariff cntry_yeard* if mode=="air", a(FEcs=cntry_sect3d FEsy=sect3d_year) resid
predict dprix_panel_hat_air_allFE2,xbd 
drop FEcs FEsy

*****just vessel

set more off

eststo: reghdfe lprix_fob ls_tariff if mode=="ves", a(FEcs=cntry_sect3d FEsy=sect3d_year) vce (cluster cntry_year)  resid
predict lprix_panel_hat_ves_allFE,xbd
drop FEcs FEsy
eststo: reghdfe lprix_fob ls_tariff cntry_yeard* if mode=="ves", a(FEcs=cntry_sect3d FEsy=sect3d_year) resid
predict lprix_panel_hat_ves_allFE2,xbd
drop FEcs FEsy

eststo: reghdfe dlprix_fob dls_tariff if mode=="ves", a(FEcs=cntry_sect3d FEsy=sect3d_year) vce (cluster cntry_year)  resid
predict dlprix_panel_hat_ves_allFE,xbd 
drop FEcs FEsy
eststo: reghdfe dlprix_fob dls_tariff cntry_yeard* if mode=="ves", a(FEcs=cntry_sect3d FEsy=sect3d_year) resid
predict dlprix_panel_hat_ves_allFE2,xbd 
drop FEcs FEsy

eststo: reghdfe dprix_fob ds_tariff if mode=="ves", a(FEcs=cntry_sect3d FEsy=sect3d_year) vce (cluster cntry_year) resid
predict dprix_panel_ves_hat_allFE,xbd
drop FEcs FEsy
eststo: reghdfe dprix_fob ds_tariff cntry_yeard* if mode=="ves", a(FEcs=cntry_sect3d FEsy=sect3d_year)  resid
predict dprix_panel_hat_ves_allFE2,xbd 
drop FEcs FEsy



set linesize 250
esttab, mtitles b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles b(%5.3f) se(%5.3f) r2 starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) keep(ls_tariff dls_tariff ds_tariff) se tex label  title(First_stage_panel_estimates)
eststo clear


log close 


keep sitc2 sitc2_3d iso_o year mode lprix_fob dlprix_fob dprix_fob *prix_panel*
order sitc2 sitc2_3d iso_o year mode lprix_fob  lprix_panel_hat_air_allFE lprix_panel_hat_air_allFE2 /*
*/dlprix_fob dlprix_panel_hat_air_allFE dlprix_panel_hat_air_allFE2 dprix_fob dprix_panel_air_hat_allFE dprix_panel_hat_air_allFE2
save predictions_FS_panel.dta, replace



***************************************************
***********First-stage regressions, YEARLY*********
***************************************************

use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
*use "$dir/results/IV_referee1/hummels_FS.dta", clear

cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
*cd "$dir/results/IV_referee1"


capture log close
capture eststo clear

log using first_stage_yearly.log, replace

set more off

***************pour info : air et vessel ensemble*********



set more off

forvalues x=2005(1)2013{
use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
*use "$dir/results/IV_referee1/hummels_FS.dta", clear
keep if year==`x'

*****just air
eststo: reghdfe lprix_fob ls_tariff if mode=="air", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
predict lprix_yearly_air_hat,xb 
predict lprix_yearly_air_hat_allFE,xbd 
drop FEcs

eststo: reghdfe dlprix_fob dls_tariff if mode=="air", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
predict dlprix_yearly_air_hat,xb 
predict dlprix_yearly_air_hat_allFE,xbd 
drop FEcs

eststo: reghdfe dprix_fob ds_tariff if mode=="air", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
predict dprix_yearly_air_hat,xb 
predict dprix_yearly_air_hat_allFE,xbd 
drop FEcs

*****just vessel
eststo: reghdfe lprix_fob ls_tariff if mode=="ves", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
predict lprix_yearly_ves_hat,xb 
predict lprix_yearly_ves_hat_allFE,xbd 
drop FEcs

eststo: reghdfe dlprix_fob dls_tariff if mode=="ves", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
predict dlprix_yearly_ves_hat,xb 
predict dlprix_yearly_ves_hat_allFE,xbd 
drop FEcs

eststo: reghdfe dprix_fob ds_tariff if mode=="ves", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
predict dprix_yearly_ves_hat,xb 
predict dprix_yearly_ves_hat_allFE,xbd 
drop FEcs

set linesize 250
esttab, mtitles b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
esttab, mtitles b(%5.3f) se(%5.3f) r2 starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) keep(ls_tariff dls_tariff ds_tariff) se tex label  title(First_stage_`x'_estimates)
eststo clear

save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", replace
*save "$dir/results/IV_referee1/FS_`x'.dta", replace

}



use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_2005.dta", clear
*use "$dir/results/IV_referee1/FS_2005.dta", replace
save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
*save "$dir/results/IV_referee1/prediction_FS_yearly.dta", replace


sort iso_o year mode



forvalues x=2006(1)2013{
use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", clear
*use "$dir/results/IV_referee1/FS_`x'.dta", clear
sort iso_o year mode
append using "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta"
*append using "$dir/results/IV_referee1/prediction_FS_yearly.dta"
order iso_o year mode sitc2 sitc2_3d
keep sitc2 sitc2_3d iso_o year mode lprix_fob dlprix_fob dprix_fob *prix_yearly*
save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta", replace
*save "$dir/results/IV_referee1/prediction_FS_yearly.dta", replace
}


forvalues x=2005(1)2013{
erase "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'.dta"
*erase "$dir/results/IV_referee1/FS_`x'.dta"

}


capture log close
