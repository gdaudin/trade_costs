
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




use "$dir/data/base_hs10_newyears.dta", clear
drop if mode =="cnt"
drop if sitc2==""
drop if duty_rate ==.

rename hs hs10
drop if hs10==""

sort mode year sitc2 hs10 iso_o
order year mode hs* sitc2 iso_o dist* val duty qy1 qy2 prix*


************************************************
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





***********************************************************************
**a bit of investigation on the different dimensions of heterogeneity**
***********************************************************************


/*
. duplicates tag  iso_o mode year hs10 dist_entry dist_unlad, g(tag)

Duplicates in terms of iso_o mode year hs10 dist_entry dist_unlad

. tab tag

        tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 | 13,098,092       94.40       94.40
          1 |    712,362        5.13       99.54
          2 |     55,317        0.40       99.93
          3 |      7,412        0.05       99.99
          4 |      1,270        0.01      100.00
          5 |        312        0.00      100.00
          6 |         98        0.00      100.00
          7 |         24        0.00      100.00
          8 |         27        0.00      100.00
          9 |         10        0.00      100.00
------------+-----------------------------------
      Total | 13,874,924      100.00

*/


/*

. duplicates tag  iso_o mode year hs10 dist_entry, g(tag)

Duplicates in terms of iso_o mode year hs10 dist_entry


        tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |  7,767,780       55.98       55.98
          1 |  3,189,978       22.99       78.98
          2 |  1,424,286       10.27       89.24
          3 |    675,288        4.87       94.11
          4 |    345,465        2.49       96.60
          5 |    188,376        1.36       97.95
          6 |    108,955        0.79       98.74
          7 |     67,328        0.49       99.23
          8 |     39,717        0.29       99.51
          9 |     24,700        0.18       99.69
         10 |     15,807        0.11       99.80
         11 |      9,672        0.07       99.87
         12 |      6,383        0.05       99.92
         13 |      4,368        0.03       99.95
         14 |      2,610        0.02       99.97
         15 |      1,712        0.01       99.98
         16 |      1,037        0.01       99.99
         17 |        576        0.00       99.99
         18 |        266        0.00      100.00
         19 |        220        0.00      100.00
         20 |        105        0.00      100.00
         21 |        154        0.00      100.00
         22 |         69        0.00      100.00
         23 |         72        0.00      100.00
------------+-----------------------------------
      Total | 13,874,924      100.00


*/
/*
duplicates tag  iso_o mode year hs10 dist_entry dist_unlad rate_prov, g(tag)
 tab tag



        tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 | 13,824,509       99.64       99.64
          1 |     48,412        0.35       99.99
          2 |      1,983        0.01      100.00
          3 |         20        0.00      100.00
------------+-----------------------------------
      Total | 13,874,924      100.00


	  
*les duplicates sont dans des dimensions secondaires. Pour l'instant, on supprime, pas de collapse
drop if tag>0
drop tag




*/

********************************************************************
***plusieurs lignes pour un même ensemble iso_o/year/mode/hS10******
***collapse en gardant les districts of entry ***********************
********************************************************************

***1./weighted average pour duty_rate avant par district of entry, car on a besoin d'une moyenne pondérée*** 

sort iso_o year mode hs10 dist_entry
bysort iso_o year mode hs10: egen wm_duty_rate = wtmean(duty_rate), weight(val)
 
*bysort iso_o year mode hs10 sitc2: asgen wm_duty_rate = duty_rate, weights(val)
*bysort iso_o year mode hs10 sitc2: egen wm_duty_rate_bis = wtmean(duty_rate), weight(val)
*les 2 commandes ci-dessus donnent exactement le même résultat*

*bysort iso_o year mode hs10 sitc2 dist_entry : asgen wm_duty_rate = duty_rate, weights(val)

order year mode hs10 sitc2 iso_o wm_* duty_rate

bys iso_o year mode hs10: egen sum_val=sum(val)
bys iso_o year mode hs10: egen sum_wgt=sum(wgt)


collapse (mean) sum* *duty_rate prix_fob_wgt, by(iso_o year mode hs10 sitc2)
rename prix_fob_wgt prix_fob_unweighted
*3,023,539 obs

/*pwcorr wm* duty_rate

             | wm_dut~e duty_r~e
-------------+------------------
wm_duty_rate |   1.0000 
   duty_rate |   0.9936   1.0000 
   */


bys iso_o year mode hs10 sitc2: gen prix_fob_wgt = sum_val/sum_wgt

/*

 pwcorr prix_fob*

             | prix_f~d prix_f~t
-------------+------------------
prix_fob_u~d |   1.0000 
prix_fob_wgt |   0.8786   1.0000 


*/

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

gen s_tariff = d.s_tariff

gen growth_tariff = s_tariff/l.s_tariff

gen s_tariff_lise = s_tariff/(1+l.s_tariff)

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
**((1,073,692 observations deleted)


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
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	keep if mode=="air"
	
reghdfe lprix_fob_wgt llprix_fob_wgt s_tariff if mode=="air", a(FEc= cntry FEs= sector_3d)  vce (ro) resid

mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variances_tariff)
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
gen t_student_tariff= betas_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test s_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betas_tariff~=.

keep year mode betallprix_fob_wgt sd_lag_prix_fob_wgt t_student_lag_pfob betas_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
*keep year mode betas_tariff sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betas_tariff beta_FS_tariff
rename betallprix_fob_wgt beta_lag_price
	
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_parameters_2006_air.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=2007(1)2013{

	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", clear
	sort year mode
	append using "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"
	save "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta", replace
}



forvalues x=2006(1)2013 {

	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta"
}



*********************
*****Vessel**********
*********************

capture drop FEcs

set more off

forvalues x=2006(1)2013{
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	keep if mode=="ves"
	

	
reghdfe lprix_fob_wgt llprix_fob_wgt s_tariff if mode=="ves", a(FEc= cntry FEs= sector_3d)  vce (ro) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variances_tariff)
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
gen t_student_tariff= betas_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test s_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betas_tariff~=.
keep year mode betallprix_fob_wgt sd_lag_prix_fob_wgt t_student_lag_pfob betas_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
*keep year mode betas_tariff sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betas_tariff beta_FS_tariff
rename betallprix_fob_wgt beta_lag_price

save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_parameters_2006_ves.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", replace


sort year 


forvalues x=2007(1)2013{

	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta", clear
	sort year mode
	append using "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta"
	save "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", replace
}



forvalues x=2006(1)2013 {

	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_ves.dta"
}


use "$dir/results/IV_referee1_yearly/FS_parameters_ves_yearly.dta", clear
append using "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"
sort mode year
order year mode beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
save "$dir/results/IV_referee1_yearly/FS_parameters_yearly_HS10.dta",replace

****a few useful descriptive statistics*****
tabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="air", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)
tabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="ves", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****a few useful descriptive statistics in LaTex Tables*****
latabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="air", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)
latabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if mode =="ves", s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)



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


**********************************
**********Both modes**************
**********************************

forvalues x=2006(1)2013{
	use "$dir/hummels_FS_HS10.dta", clear
	keep if year==`x'
	
reghdfe lprix_fob_wgt llprix_fob_wgt s_tariff, a(FEc= cntry FEs= sector_3d)  vce (ro) resid

mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variances_tariff)
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
gen t_student_tariff= betas_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test s_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betas_tariff~=.

keep year mode betallprix_fob_wgt sd_lag_prix_fob_wgt t_student_lag_pfob betas_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
*keep year mode betas_tariff sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betas_tariff beta_FS_tariff
rename betallprix_fob_wgt beta_lag_price
	
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_parameters_2006_both.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=2007(1)2013{

	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta", clear
	sort year mode
	append using "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta"
	save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta", replace
}




****a few useful descriptive statistics*****
tabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****a few useful descriptive statistics in LaTex Tables*****
latabstat beta_lag_price sd_lag_prix_fob_wgt t_student_lag_pfob beta_FS_tariff sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)



scatter beta_lag_price year
graph save graph_lag_yearly_both, replace

scatter beta_FS_tariff sd_tariff year
graph save graph_tariff_yearly_both, replace




sort year 

*OK jusque là


forvalues x=2006(1)2013 {

	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta"
}



capture log close
stop 

erase "$dir/hummels_FS_HS10.dta"



