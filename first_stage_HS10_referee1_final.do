
/*ssc install reghdfe, replace
ssc install estout, replace
ssc install ftools, replace
ssc install latab, replace
ssc install asgen, replace
ssc install _gwtmean, replace
*/

clear all
set more off

if "`c(username)'" =="jerome" {
	global dir "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
	set maxvar 32000
}


if "`c(username)'" =="coadministrateur" {

	global dir "C:\Users\coadministrateur\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
	set maxvar 32000
}


if "`c(username)'" =="hericourt" {
	global dir "C:\Users\hericourt\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
	set maxvar 32000
}



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_pgms $dir/trade_costs_git
	set maxvar 120000
}

clear

set more off

/******************************************
*****construction nouvelle base HS10******
******************************************

use "$dir/data/base_hs10_2002.dta", replace
save "$dir/data/base_hs10_newyears.dta", replace

forvalues x=2003(1)2019{

	use "$dir/data/base_hs10_`x'.dta", clear
	append using "$dir/data/base_hs10_newyears.dta"
	save "$dir/data/base_hs10_newyears.dta", replace

}

forvalues x=2002(1)2019 {

	erase "$dir/data/base_hs10_`x'.dta"
}


set more off 
*/

******************************************
*******program first stage****************
******************************************

use "$dir/data/base_hs10_newyears.dta", clear
drop if mode =="cnt"
drop if sitc2==""
drop if duty_rate ==.

rename hs hs10
drop if hs10==""


sort mode year sitc2 hs10 iso_o
order year mode hs* sitc2 iso_o dist* val duty qy1 qy2 prix*


/************************************************
*****test de recalcul du prix_fob***************
************************************************

bys iso_o year mode hs10 dist_entry : gen prix_fob_recalc= val/wgt

count if prix_fob_wgt == prix_fob_recalc
pwcorr prix_fob*

/*
==> c'est bien la même variable
*/

drop prix_fob_recalc


cd "$dir/data"


*/

********************************************************************
***plusieurs lignes pour un même ensemble iso_o/year/mode/hS10******
***collapse en gardant les districts of entry ***********************
********************************************************************

***1./weighted average pour duty_rate avant par district of entry, car on a besoin d'une moyenne pondérée*** 

sort iso_o year mode hs10 dist_entry
bysort iso_o year mode hs10: egen wm_duty_rate = wtmean(duty_rate), weight(val)

order year mode hs10 sitc2 iso_o wm_* duty_rate

bys iso_o year mode hs10: egen sum_val=sum(val)
bys iso_o year mode hs10: egen sum_wgt=sum(wgt)


collapse (mean) sum* *duty_rate prix_fob_wgt, by(iso_o year mode hs10 sitc2)
rename prix_fob_wgt prix_fob_unweighted

bys iso_o year mode hs10 sitc2: gen prix_fob_wgt = sum_val/sum_wgt


drop duty_rate

rename wm_duty_rate duty_rate





save "$dir/hummels_FS_HS10.dta", replace

use "$dir/hummels_FS_HS10.dta", clear



***** tariff AVE

bys iso_o mode year hs10 sitc2: gen ls_tariff = ln(0.01+duty_rate)
label var ls_tariff "ln(0.01+tariff as share of value imported)"




**** ln-linéarisation prix_fob, mais cela impliquera d'appliquer la fonction exponentielle aux prédictions***
gen lprix_fob_wgt= ln(prix_fob_wgt)

*****on crée le niveau sectoriel 3 digit***

gen sitc2_3d= substr(sitc2, 1, 3)

*****on crée le niveau sectoriel 5 digit***

gen sitc2_5d= substr(sitc2, 1, 5)

****On crée tous les groupes utiles pourles FE

egen sector_3d=group(sitc2_3d)

egen sector_5d=group(sitc2_5d)

egen cntry=group(iso_o)

*egen cntry_sect3d=group(iso_o sitc2_3d)

*egen dist=group(dist_entry)

egen panel=group(iso_o mode hs10 sitc2)

drop if panel==.
drop if sector_3d==.


**** First_dif****
tsset panel year

gen dlprix_fob_wgt = d.lprix_fob_wgt

gen dls_tariff = d.ls_tariff

gen s_tariff= duty_rate

gen ds_tariff = d.s_tariff

gen growth_tariff = ds_tariff/l.s_tariff

gen ds_tariff_lise = ds_tariff/(1+l.s_tariff)

gen llprix_fob_wgt =  l.lprix_fob_wgt
*(1,073,692 missing values generated)) 


*order year iso_o hs3 hs5 hs10 mode dist_entry lprix_fob dlprix_fob ls_tariff dls_tariff

save "$dir/hummels_FS_HS10.dta", replace




***************************************************
***********First-stage regressions, YEARLY*********
***************************************************

**************************************************
*****this part of the program stores main*********
*****features of FS regressions in a separate DB**
**************************************************

use "$dir/hummels_FS_HS10.dta", clear

cd "$dir/results/IV_referee1_yearly"

keep if llprix_fob_wgt~=.


capture log close
capture eststo clear

log using first_stage_yearly_HS10.log, replace

set more off

capture drop FEcs FEc FEs
capture drop FEd



**********************************************************
**********First stage regressions: ESTIMATES**************
**********************************************************

forvalues x=2003(1)2019{
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	
reghdfe lprix_fob_wgt llprix_fob_wgt ds_tariff_lise, a(FEc= cntry FEs= sector_3d)  vce (ro) resid

mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(varianceds_tariff_lise)
gen sd_lag_prix_fob_wgt =  sqrt(variancellprix_fob_wgt)
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

gen t_student_lag_pfob = betallprix_fob_wgt/sd_lag_prix_fob_wgt
gen t_student_tariff= betads_tariff_lise/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test ds_tariff_lise=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betads_tariff_lise~=.

keep year mode betallprix_fob_wgt sd_lag_prix_fob_wgt t_student_lag_pfob betads_tariff_lise sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
*keep year mode betads_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betads_tariff_lise beta_Fds_tariff_lise
rename betallprix_fob_wgt beta_lag_price
	
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_parameters_2003_both.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=2004(1)2019{

	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta", clear
	sort year mode
	append using "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta"
	save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta", replace
}


save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly_prod10_sect3.dta", replace

****a few useful descriptive statistics*****
tabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_Fds_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****a few useful descriptive statistics in LaTex Tables*****
latabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_Fds_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)



scatter beta_lag_price year
graph save graph_lag_yearly_both, replace

scatter beta_Fds_tariff_lise year
graph save graph_tariff_yearly_both, replace




sort year 

*OK jusque là


forvalues x=2003(1)2019 {

	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta"
}



erase "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta"




**********************************************************
**********First stage regressions: PREDICTIONS***********
**********************************************************
set more off 

forvalues x=2003(1)2019{
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	
reghdfe lprix_fob_wgt llprix_fob_wgt ds_tariff_lise, a(FEc= cntry FEs= sector_3d)  vce (ro) resid

predict lprix_yearly_air_hat_allFE,xbd 
	drop FEc FEs
	
save "$dir/results/IV_referee1_yearly/FS_predictions_`x'_both.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_predictions_2003_both.dta", replace
save "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=2004(1)2019{

	use "$dir/results/IV_referee1_yearly/FS_predictions_`x'_both.dta", clear
	append using "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta"
	sort iso_o year mode hs10 
	order iso_o year mode hs10 sitc2 sitc2_3d
	keep sitc2 sitc2_3d hs10 iso_o year mode lprix_fob *prix_yearly*
	save "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta", replace
}




forvalues x=2003(1)2019 {

	erase "$dir/results/IV_referee1_yearly/FS_predictions_`x'_both.dta"
}


count if lprix_yearly_air_hat_allFE==.
  *719,543, 26% of the sample 2006-2013
drop if lprix_yearly_air_hat_allFE==.


save "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly_prod10_sect3.dta", replace

capture log close
*stop 

erase "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta"
erase "$dir/hummels_FS_HS10.dta"



