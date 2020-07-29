
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
order year mode hs* sitc2 iso_o dist* val qy1 qy2 prix*


************************************************
*****test de recalcul du prix_fob***************
************************************************

bys iso_o year mode hs10 dist_entry : gen prix_fob_recalc= val/wgt

count if prix_fob_wgt == prix_fob_recalc
pwcorr prix_fob*

/*
==> c'est bien la même variable
*/


cd "$dir/data"



********************************************************************
***plusieurs lignes pour un même ensemble iso_o/year/mode/hS10******
***collapse en gardant les districts of entry ***********************
********************************************************************



/* collapse (sum) val duty air_val ves_val cnt_val *_wgt, by(iso_o year mode dist_entry dist_unlad hs10 sitc2)
save "$dir/hummels_FS_HS10.dta", replace

use "$dir/hummels_FS_HS10.dta", clear




*/
/*
. duplicates tag  iso_o mode year hs10 dist_entry dist_unlad, g(tag)

Duplicates in terms of iso_o mode year hs10 dist_entry dist_unlad

. tab tag

        tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 | 13,108,426       94.82       94.82
          1 |    688,656        4.98       99.80
          2 |     25,467        0.18       99.99
          3 |      1,748        0.01      100.00
          4 |        200        0.00      100.00
          5 |         12        0.00      100.00
------------+-----------------------------------
      Total | 13,824,509      100.00

*/


/*

. duplicates tag  iso_o mode year hs10 dist_entry, g(tag)

Duplicates in terms of iso_o mode year hs10 dist_entry

. tab tag

        tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |  7,776,310       56.25       56.25
          1 |  3,172,764       22.95       79.20
          2 |  1,402,548       10.15       89.35
          3 |    668,188        4.83       94.18
          4 |    341,845        2.47       96.65
          5 |    185,844        1.34       98.00
          6 |    107,002        0.77       98.77
          7 |     66,080        0.48       99.25
          8 |     38,817        0.28       99.53
          9 |     24,060        0.17       99.70
         10 |     15,367        0.11       99.81
         11 |      9,276        0.07       99.88
         12 |      6,162        0.04       99.93
         13 |      4,144        0.03       99.96
         14 |      2,475        0.02       99.97
         15 |      1,616        0.01       99.99
         16 |        901        0.01       99.99
         17 |        504        0.00      100.00
         18 |        266        0.00      100.00
         19 |        120        0.00      100.00
         20 |         63        0.00      100.00
         21 |        110        0.00      100.00
         22 |         23        0.00      100.00
         23 |         24        0.00      100.00
------------+-----------------------------------
      Total | 13,824,509      100.00
*/

duplicates tag  iso_o mode year hs10 dist_entry dist_unlad rate_prov, g(tag)
/* tab tag


tag	Freq.	Percent	Cum.
			
0	14,818,887	99.64	99.64
1	51,214	0.34	99.99
2	2,100	0.01	100.00
3	20	0.00	100.00
			
Total	14,872,221	100.00

*les duplicates sont dans des dimensions secondaires. Pour l'instant, on supprime, pas de collapse

*/

drop if tag>0
drop tag





***** tariff AVE

bys iso_o mode year hs10 dist_entry dist_unlad rate_prov: gen ls_tariff = ln(0.01+duty_rate)
label var ls_tariff "ln(0.01+tariff as share of value imported)"




**** ln-linéarisation prix_fob, mais cela impliquera d'appliquer la fonction exponentielle aux prédictions***
gen lprix_fob_wgt= ln(prix_fob_wgt)
gen lprix_fob_qy1= ln(prix_fob_qy1)
gen lprix_fob_qy2= ln(prix_fob_qy2)

*****on crée le niveau sectoriel 3 digit***

gen sitc2_3d= substr(sitc2, 1, 3)

****On crée tous les groupes utiles pourles FE

egen sector_3d=group(sitc2_3d)

egen cntry=group(iso_o)

egen cntry_sect3d=group(iso_o sitc2_3d)

egen dist=group(dist_entry)

egen panel=group(iso_o mode hs10 dist_entry dist_unlad rate_prov)

*egen panel2=group(iso_o mode year hs10 dist_entry)

drop if panel==.
drop if sector_3d==.


**** First_dif****
tsset panel year

gen dlprix_fob_wgt = d.lprix_fob_wgt
gen dlprix_fob_qy1 = d.lprix_fob_qy1
gen dlprix_fob_qy2 = d.lprix_fob_qy2

gen dls_tariff = d.ls_tariff

gen s_tariff= duty_rate

gen ds_tariff = d.s_tariff

gen growth_tariff = ds_tariff/l.s_tariff

gen ds_tariff_lise = ds_tariff/(1+l.s_tariff)

gen llprix_fob_wgt =  l.lprix_fob_wgt
gen llprix_fob_qy1 =  l.lprix_fob_qy1
gen llprix_fob_qy2 =  l.lprix_fob_qy2



*order year iso_o hs3 hs5 hs10 mode dist_entry lprix_fob dlprix_fob ls_tariff dls_tariff


*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\hummels_FS.dta", replace
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
**(7,347,318 observations deleted) !!!!



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
	
reghdfe lprix_fob_wgt llprix_fob_wgt growth_tariff if mode=="air", a(FEc= cntry FEs= sector_3d)  vce (cluster cntry) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variancegrowth_tariff)
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
gen t_student_tariff= betagrowth_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test growth_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betagrowth_tariff~=.
keep year mode betallprix_fob_wgt sd_lag_prix_fob_wgt t_student_lag_pfob betagrowth_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betagrowth_tariff beta_FS_tariff
rename betallprix_fob_wgt beta_lag_price
	
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_parameters_2006_air.dta", replace
*save "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\private\revision_JOEG\IV_rev\prediction_FS_yearly.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=2007(1)2013{

	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_air.dta", clear
	sort year mode
	append using "$dir/results/IV_referee1_yearly/FS_parameters_air_yearly.dta"
	*keep sitc2 sitc2_3d iso_o year mode lprix_fob_wgt *prix_yearly*
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
	

	
reghdfe lprix_fob_wgt llprix_fob_wgt growth_tariff if mode=="ves", a(FEc= cntry FEs= sector_3d)  vce (cluster cntry) resid
mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
gen sd_tariff = sqrt(variancegrowth_tariff)
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
gen t_student_tariff= betagrowth_tariff/sd_tariff 



mat F_stat=e(F) 
svmat double F_stat, names(matcol)
rename F_statc1 F_stat

test growth_tariff=0 

mat F_stat_tariff=r(F) 

svmat double F_stat_tariff, names(matcol)
rename F_stat_tariffc1 F_stat_tariff


keep if betagrowth_tariff~=.
keep year mode betallprix_fob_wgt sd_lag_prix_fob_wgt t_student_lag_pfob betagrowth_tariff sd_tariff t_student_lag_pfob  t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betagrowth_tariff beta_FS_tariff
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

	*keep sitc2 sitc2_3d iso_o year mode lprix_fob_wgt *prix_yearly*
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
capture log close
stop 

erase "$dir/hummels_FS_HS10.dta"



