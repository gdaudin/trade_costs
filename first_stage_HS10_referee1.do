
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




use "$dir/data/base_hs10_newyears.dta", clear
rename hs hs10
sort mode year sitc2 hs10 iso_o
order year mode hs* sitc2 iso_o dist con_val ves_val air_val con_qy1 con_qy2


************************************************
*****test de recalcul du prix_fob***************
************************************************

bys iso_o year mode hs10 dist_entry : gen prix_fob_recalc= air_val/air_wgt if mode=="air"
bys iso_o year mode hs10 dist_entry : replace prix_fob_recalc= ves_val/ves_wgt if mode=="ves"
bys iso_o year mode hs10 dist_entry : replace prix_fob_recalc= cnt_val/cnt_wgt if mode=="cnt"

count if prix_fob == prix_fob_recalc
pwcorr prix_fob*

/*
==> c'est bien la même variable
*/


cd "$dir/data"

drop if hs10==""

*keep mode hs* dist* sitc2 prix* duty iso_o year con_val ves_val air_val con_qy1 con_qy2 con_cha con_cif

/********************************************************************
***plusieurs lignes pour un même ensemble iso_o/year/mode/hS10******
***collapse si on veut rester cohérents ****************************
********************************************************************



collapse (sum) con_val duty air_val ves_val cnt_val *_wgt, by(iso_o year mode hs10)
save "$dir/hummels_FS_HS10.dta", replace

use "$dir/hummels_FS_HS10.dta", clear

duplicates tag mode year hs10 iso_o, g(tag)
sort mode year hs10 iso_o
tab tag
*no duplicates, all good
drop if tag==1
drop tag

sort year mode iso_o

*/
********************************************************************
***plusieurs lignes pour un même ensemble iso_o/year/mode/hS10******
***collapse en gardant les districts of entry ***********************
********************************************************************



collapse (sum) con_val duty air_val ves_val cnt_val *_wgt, by(iso_o year mode dist_entry hs10)
save "$dir/hummels_FS_HS10.dta", replace

use "$dir/hummels_FS_HS10.dta", clear

duplicates tag mode year hs10 dist_entry iso_o, g(tag)
sort mode year hs10 iso_o
tab tag
*no duplicates, all good
drop if tag==1
drop tag

sort year mode iso_o
*keep mode hs* dist* sitc2 prix* duty iso_o year con_val duty air_val ves_val cnt_val *_wgt

sort year mode dist_entry iso_o

replace ves_val = ves_val+cnt_val if cnt_val~=.
replace ves_wgt = ves_wgt+cnt_wgt if cnt_wgt~=.

drop cnt_val cnt_wgt

drop if mode =="cnt"

bys iso_o year mode dist_entry hs10 : gen prix_fob= air_val/air_wgt if mode=="air"
bys iso_o year mode dist_entry hs10 : replace prix_fob= ves_val/ves_wgt if mode=="ves"
*bys iso_o year mode hs10 : replace prix_fob= cnt_val/cnt_wgt if mode=="cnt"



***** tariff AVE

bys hs10 year iso_o dist_entry: gen s_tariff = duty/con_val
label var s_tariff "tariff as share of value imported, all modes"

bys hs10 year iso_o dist_entry: gen ls_tariff = ln(0.01+s_tariff)
label var ls_tariff "ln(0.01+tariff as share of value imported, all modes)"


**** ln-linéarisation prix_fob, mais cela impliquera d'appliquer la fonction exponentielle aux prédictions***
gen lprix_fob= ln(prix_fob)


****on crée les niveaux sectoriel 5 digit***

gen hs3= substr(hs10, 1, 3)
gen hs5= substr(hs10, 1, 5)



****On crée tous les groupes utiles pourles FE

egen sector_3d=group(hs3)
egen sector_5d=group(hs5)

egen dist=group(dist_entry)

egen cntry=group(iso_o)


egen cntry_sect5d=group(iso_o hs5)

egen cntry_sect10d=group(iso_o hs10)
egen cntry_sect10d_mode=group(iso_o hs10 mode)
egen cntry_sect10d_dist=group(iso_o hs10 dist_entry)
egen cntry_sect10d_mode_dist=group(iso_o hs10 mode dist_entry)

egen cntry_sect3d=group(iso_o hs3)
egen cntry_sect3d_dist=group(iso_o hs3 dist_entry)


**** First_dif****
tsset cntry_sect10d_mode_dist year

gen dlprix_fob = d.lprix_fob

gen dls_tariff = d.ls_tariff

gen dprix_fob = d.prix_fob

gen ds_tariff = d.s_tariff

gen growth_tariff = ds_tariff/l.s_tariff

gen ds_tariff_lise = ds_tariff/(1+l.s_tariff)

gen llprix_fob =  l.lprix_fob




order year iso_o hs3 hs5 hs10 mode dist_entry lprix_fob dlprix_fob ls_tariff dls_tariff


*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", replace
save "$dir/hummels_FS_HS10.dta", replace

stop


***************************************************
***********First-stage regressions, YEARLY*********
***************************************************

**************************************************
*****this part of the program stores main*********
*****features of FS regressions in a separate DB**
**************************************************

*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
use "$dir/hummels_FS_HS10.dta", clear

*cd "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev"
cd "$dir/results/IV_referee1_yearly"

keep if llprix_fob~=.



capture log close
capture eststo clear

log using first_stage_parameters_yearly_HS10.log, replace

set more off

capture drop FEcs FEc FEs
capture drop FEd



***************************
**********Air**************
***************************

forvalues x=2006(1)2013{
	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	keep if mode=="air"
	
reghdfe lprix_fob llprix_fob ds_tariff_lise if mode=="air", a(FEc= cntry FEs= sector_3d FEd=dist)  vce (cluster cntry) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(varianceds_tariff_lise)
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
gen t_student_tariff= betads_tariff_lise/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test ds_tariff_lise=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betads_tariff_lise~=.
keep year mode betallprix_fob sd_lag_prix_fob t_student_lag_pfob betads_tariff_lise sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betads_tariff_lise beta_FS_tariff
rename betallprix_fob beta_lag_price
	
*save "C:\Users\jerome\Dropbox\Papier_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", replace

}



*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_2005.dta", clear

use "$dir/results/IV_referee1_yearly/FS_parameters_2006_air.dta", replace
*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=2007(1)2013{

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



forvalues x=2006(1)2013 {

	*erase "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'.dta"
	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta"
}



*********************
*****Vessel**********
*********************

capture drop FEcs

set more off

forvalues x=2006(1)2013{
	*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", clear
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	keep if mode=="ves"
	

	
reghdfe lprix_fob llprix_fob ds_tariff_lise if mode=="ves", a(FEc= cntry FEs= sector_3d FEd = dist)  vce (cluster cntry) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(varianceds_tariff_lise)
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
gen t_student_tariff= betads_tariff_lise/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test ds_tariff_lise=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betads_tariff_lise~=.
keep year mode betallprix_fob sd_lag_prix_fob t_student_lag_pfob betads_tariff_lise sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betads_tariff_lise beta_FS_tariff
rename betallprix_fob beta_lag_price

*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta", replace

}



*use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_2005.dta", clear

use "$dir/results/IV_referee1_yearly/FS_parameters_2006_ves.dta", replace
*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", replace


sort year 


forvalues x=2007(1)2013{

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



forvalues x=2006(1)2013 {

	*erase "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\FS_`x'.dta"
	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta"
}


use "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", clear
append using "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"
sort mode year
order year mode beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
save "$dir/results/IV_referee1_yearly/FS_parameters_yearly_HS10.dta",replace

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

erase "$dir/hummels_FS_HS10.dta"

capture log close

