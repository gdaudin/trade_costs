
*ssc install reghdfe, replace
*ssc install estout, replace
*ssc install ftools, replace
*ssc install latab, replace

clear all
set more off

if "`c(username)'" =="jerome" {
	global dir "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
	set maxvar 32000
}




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_pgms $dir/trade_costs_git
	set maxvar 120000
}

clear


*cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
cd "$dir/results/IV_referee1_panel"

use "$dir/data/hummels_tra.dta", clear
*use hummels_tra.dta, clear
set matsize 10000




*keep if year >2003
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

bys sitc2 year iso_o: gen ls_tariff = ln(0.01+s_tariff)
label var ls_tariff "ln(0.01+tariff as share of value imported, all modes)"
bys sitc2 year iso_o mode: gen ls_tariff_air = ln(0.01+s_tariff_air)
label var ls_tariff "ln(0.01+tariff as share of value imported, air)"
bys sitc2 year iso_o mode: gen ls_tariff_ves = ln(0.01+s_tariff_ves)
label var ls_tariff "ln(0.01+tariff as share of value imported, all modes)"

**** ln-linéarisation prix_fob, mais cela impliquera d'appliquer la fonction exponentielle aux prédictions***
gen lprix_fob= ln(prix_fob)


****on crée le niveau sectoriel 3 digit***

gen sitc2_3d= substr(sitc2, 1, 3)


****On crée tous les groupes utiles pourles FE

egen sector_3d=group(sitc2_3d)

egen cntry=group(iso_o)


egen cntry_sect5d=group(iso_o sitc2)
egen cntry_sect5d_mode=group(iso_o sitc2 mode)

egen cntry_sect3d=group(iso_o sitc2_3d)

egen cntry_sect3d_mode=group(iso_o sitc2_3d mode)


**** First_dif****
tsset cntry_sect5d_mode year

gen dlprix_fob = d.lprix_fob

gen dls_tariff = d.ls_tariff

gen dprix_fob = d.prix_fob

gen ds_tariff = d.s_tariff

gen growth_tariff = ds_tariff/l.s_tariff

gen ds_tariff_lise = ds_tariff/(1+l.s_tariff)

gen llprix_fob =  l.lprix_fob




order year iso_o sitc2_3d sitc2 mode lprix_fob dlprix_fob ls_tariff dls_tariff

*drop if year ==2004

*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", replace
save "$dir/hummels_FS.dta", replace



/***************************************************
***********First-stage regressions, PANEL**********
***************************************************



************************
**********panel*********
************************

*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
use "$dir/hummels_FS.dta", clear

****** Fixed effects************************

******on crée les FE utiles
set more off

egen cntry_year=group(iso_o year)
tab cntry_year, gen(cntry_yeard) 


egen cntry_sect3d=group(iso_o sitc2_3d)
egen sect3d_year=group(sitc2_3d year)

egen cntry_sect5d=group(iso_o sitc2)
egen cntry_sect5d_mode=group(iso_o sitc2 mode)

egen cntry_sect3d_mode=group(iso_o sitc2_3d mode)
egen cntry_mode_year=group(iso_o mode year)
egen sect3d_mode_year=group(sitc2_3d mode year)

*cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
cd "$dir/results/IV_referee1_panel"

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

scatter lprix_fob lprix_panel_hat_air_allFE
graph save graph_lprix_fob1, replace
scatter lprix_fob lprix_panel_hat_air_allFE2
graph save graph_lprix_fob2, replace

scatter dlprix_fob dlprix_panel_hat_air_allFE
graph save graph_dlprix_fob1, replace
scatter dlprix_fob dlprix_panel_hat_air_allFE2
graph save graph_dlprix_fob2, replace

scatter dprix_fob dlprix_panel_hat_air_allFE
graph save graph_dprix_fob1, replace
scatter dprix_fob dlprix_panel_hat_air_allFE2
graph save graph_dprix_fob2, replace


save predictions_FS_panel.dta, replace

*/

***************************************************
***********First-stage regressions, YEARLY*********
***************************************************


*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
use "$dir/hummels_FS.dta", clear

*cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
cd "$dir/results/IV_referee1_yearly"


capture log close
capture eststo clear

log using first_stage_yearly.log, replace

set more off

capture drop FEcs




forvalues x=1974(1)2013{
	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
	use "$dir/hummels_FS.dta", clear
	keep if year==`x'
	
	*****just air
	eststo: reghdfe lprix_fob ls_tariff if mode=="air", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
	*predict lprix_yearly_air_hat,xb 
	predict lprix_yearly_air_hat_allFE,xbd 
	drop FEcs
	
	/*eststo: reghdfe dlprix_fob dls_tariff if mode=="air", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
	*predict dlprix_yearly_air_hat,xb 
	predict dlprix_yearly_air_hat_allFE,xbd 
	drop FEcs
	
	eststo: reghdfe dprix_fob ds_tariff if mode=="air", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
	*predict dprix_yearly_air_hat,xb 
	predict dprix_yearly_air_hat_allFE,xbd 
	drop FEcs*/
	
	*****just vessel
	eststo: reghdfe lprix_fob ls_tariff if mode=="ves", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
	*predict lprix_yearly_ves_hat,xb 
	predict lprix_yearly_ves_hat_allFE,xbd 
	drop FEcs
	
	/*eststo: reghdfe dlprix_fob dls_tariff if mode=="ves", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
	*predict dlprix_yearly_ves_hat,xb 
	predict dlprix_yearly_ves_hat_allFE,xbd 
	drop FEcs
	
	eststo: reghdfe dprix_fob ds_tariff if mode=="ves", a(FEcs= cntry_sect3d) vce (cluster cntry) resid
	*predict dprix_yearly_ves_hat,xb 
	predict dprix_yearly_ves_hat_allFE,xbd 
	drop FEcs
	*/
	set linesize 250
	esttab, mtitles b(%5.3f) se(%5.3f) compress r2 starlevels(c 0.1 b 0.05 a 0.01)  se 
	*esttab, mtitles b(%5.3f) se(%5.3f) r2 starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) keep(ls_tariff dls_tariff ds_tariff) se tex label  title(First_stage_`x'_estimates)
	esttab, mtitles b(%5.3f) se(%5.3f) r2 starlevels({$^c$} 0.1 {$^b$} 0.05 {$^a$} 0.01) keep(ls_tariff) se tex label  title(First_stage_`x'_estimates)

	eststo clear
	
	*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", replace
	save "$dir/FS_`x'.dta", replace

}



*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_2005.dta", clear

use "$dir/FS_1974.dta", replace
*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
save "$dir/results/IV_referee1_yearly/predictions_FS_yearly.dta", replace


sort iso_o year mode


forvalues x=1975(1)2013{

	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", clear
	use "$dir/FS_`x'.dta", clear
	sort iso_o year mode
	*append using "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta"
	append using "$dir/results/IV_referee1_yearly/predictions_FS_yearly.dta"
	order iso_o year mode sitc2 sitc2_3d
	keep sitc2 sitc2_3d iso_o year mode lprix_fob *prix_yearly*
	*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta", replace
	save "$dir/results/IV_referee1_yearly/predictions_FS_yearly.dta", replace
}



forvalues x=1974(1)2013 {

	*erase "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'.dta"
	erase "$dir/FS_`x'.dta"
}



erase "$dir/hummels_FS.dta"

scatter lprix_fob lprix_yearly_air_hat_allFE
graph save graph_lprix_fob_yearly_air, replace

scatter lprix_fob lprix_yearly_ves_hat_allFE
graph save graph_lprix_fob_yearly_ves, replace

capture log close



***************************************************
***********First-stage regressions, YEARLY*********
***************************************************

**************************************************
*****this part of the program stores main*********
*****features of FS regressions in a separate DB**
**************************************************

*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
use "$dir/hummels_FS.dta", clear

*cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
cd "$dir/results/IV_referee1_yearly"

keep if llprix_fob~=.



capture log close
capture eststo clear

log using first_stage_parameters_yearly.log, replace

set more off

capture drop FEcs FEc FEs



***************************
**********Air**************
***************************

forvalues x=1975(1)2013{
	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
	use "$dir/hummels_FS.dta", clear
	keep if year==`x'
	keep if mode=="air"
	
reghdfe lprix_fob llprix_fob ls_tariff if mode=="air", a(FEc= cntry FEs= sector_3d)  vce (cluster cntry) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variancels_tariff)
gen sd_lag_prix_fob =  sqrt(variancellprix_fob)
drop *cons 

mat r_square= e(r2)
svmat double r_square, names(matcol)
rename r_squarec1 r_square

mat adj_r_square= e(r2_a)
svmat double adj_r_square, names(matcol)
rename adj_r_squarec1 adj_r_square

mat r_square_within= e(r2_within)
svmat double r_square_within, names(matcol)
rename r_square_withinc1 r_square_within

gen t_student_lag_pfob = betallprix_fob/sd_lag_prix_fob
gen t_student_tariff= betals_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test ls_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betals_tariff~=.
keep year mode betallprix_fob sd_lag_prix_fob t_student_lag_pfob betals_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betals_tariff beta_FS_tariff
rename betallprix_fob beta_lag_price
	
*save "C:\Users\jerome\Dropbox\Papier_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", replace

}



*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_2005.dta", clear

use "$dir/results/IV_referee1_yearly/FS_parameters_1975_air.dta", replace
*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=1976(1)2013{

	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", clear
	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", clear
	sort year mode
	*append using "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta"
	append using "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"
	*order iso_o year mode sitc2 sitc2_3d
	*keep sitc2 sitc2_3d iso_o year mode lprix_fob *prix_yearly*
	*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta", replace
	save "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta", replace
}



forvalues x=1975(1)2013 {

	*erase "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'.dta"
	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta"
}



*********************
*****Vessel**********
*********************

capture drop FEcs

set more off

forvalues x=1975(1)2013{
	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
	use "$dir/hummels_FS.dta", clear
	keep if year==`x'
	keep if mode=="ves"
	

	
reghdfe lprix_fob llprix_fob ls_tariff if mode=="ves", a(FEc= cntry FEs= sector_3d)  vce (cluster cntry) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variancels_tariff)
gen sd_lag_prix_fob =  sqrt(variancellprix_fob)
drop *cons 

mat r_square= e(r2)
svmat double r_square, names(matcol)
rename r_squarec1 r_square

mat adj_r_square= e(r2_a)
svmat double adj_r_square, names(matcol)
rename adj_r_squarec1 adj_r_square

mat r_square_within= e(r2_within)
svmat double r_square_within, names(matcol)
rename r_square_withinc1 r_square_within

gen t_student_lag_pfob = betallprix_fob/sd_lag_prix_fob
gen t_student_tariff= betals_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test ls_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betals_tariff~=.
keep year mode betallprix_fob sd_lag_prix_fob t_student_lag_pfob betals_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betals_tariff beta_FS_tariff
rename betallprix_fob beta_lag_price

*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta", replace

}



*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_2005.dta", clear

use "$dir/results/IV_referee1_yearly/FS_parameters_1975_ves.dta", replace
*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", replace


sort year 


forvalues x=1976(1)2013{

	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", clear
	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta", clear
	sort year mode
	*append using "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta"
	append using "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta"
	*order iso_o year mode sitc2 sitc2_3d
	*keep sitc2 sitc2_3d iso_o year mode lprix_fob *prix_yearly*
	*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\predictions_FS_yearly.dta", replace
	save "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", replace
}



forvalues x=1975(1)2013 {

	*erase "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'.dta"
	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta"
}


use "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", clear
append using "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"
sort mode year
order year mode beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
save "$dir/results/IV_referee1_yearly/FS_parameters_yearly.dta",replace

****a few useful descriptive statistics*****
tabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="air", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)
tabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="ves", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****a few useful descriptive statistics in LaTex Tables*****
latabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="air", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)
latabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="ves", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)


scatter beta_lag_price year if mode=="air"
graph save graph_lag_yearly_air, replace

scatter beta_lag_price year if mode=="ves"
graph save graph_lag_yearly_ves, replace

scatter beta_FS_tariff sd_tariff year if mode=="air"
graph save graph_tariff_yearly_air, replace

scatter beta_FS_tariff sd_tariff year if mode=="ves"
graph save graph_tariff_yearly_ves, replace


erase "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta"
erase "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"

stop 

erase "$dir/hummels_FS.dta"

capture log close

