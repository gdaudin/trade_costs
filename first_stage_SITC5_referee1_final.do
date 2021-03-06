
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


use "$dir/data/hummels_tra.dta", clear
set matsize 10000

******************************************
*******program first stage****************
******************************************
drop if sitc2==""


sort mode year sitc2 iso_o

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
bys sitc2 year iso_o: gen s_tariff = duty/con_val
label var s_tariff "tariff as share of value imported, all modes"

bys sitc2 year iso_o: gen ls_tariff = ln(0.01+s_tariff)
label var ls_tariff "ln(0.01+tariff as share of value imported, all modes)"

**** ln-linéarisation prix_fob, mais cela impliquera d'appliquer la fonction exponentielle aux prédictions***
gen lprix_fob= ln(prix_fob)


*****on crée le niveau sectoriel 3 digit***

gen sitc2_3d= substr(sitc2, 1, 3)

*****on crée le niveau sectoriel 5 digit***

gen sitc2_5d= substr(sitc2, 1, 5)

****On crée tous les groupes utiles pourles FE

egen sector_3d=group(sitc2_3d)

egen sector_5d=group(sitc2_5d)

egen cntry=group(iso_o)

egen cntry_sect3d=group(iso_o sitc2_3d)


egen panel=group(iso_o mode sitc2)

drop if panel==.
drop if sector_3d==.


**** First_dif****
tsset panel year

gen dlprix_fob = d.lprix_fob

gen llprix_fob = l.lprix_fob

gen dls_tariff = d.ls_tariff

gen dprix_fob = d.prix_fob

gen ds_tariff = d.s_tariff

gen ds_tariff_lise = ds_tariff/(1+l.s_tariff)


order year iso_o sitc2_3d sitc2 mode lprix_fob dlprix_fob ls_tariff dls_tariff

save "$dir/hummels_FS_SITC5.dta", replace


***************************************************
***********First-stage regressions, YEARLY*********
***************************************************

**************************************************
*****this part of the program stores main*********
*****features of FS regressions in a separate DB**
**************************************************

use "$dir/hummels_FS_SITC5.dta", clear

cd "$dir/results/IV_referee1_yearly"

keep if llprix_fob~=.


capture log close
capture eststo clear

log using first_stage_yearly_SITC5.log, replace

set more off

capture drop FEcs FEc FEs
capture drop FEd



**********************************************************
**********First stage regressions: ESTIMATES**************
**********************************************************
/*qui statsby "reghdfe ldgf lpop iroise switch_all lnb_partis unemp_rate alignement_catd*  catd* alignement incumbent, a(codgeo dep_y) vce(robust)" _b _se e(N), clear

keep b_alignement_catd* se_alignement_catd*
*/



forvalues x=1975(1)2019{
	use "$dir/hummels_FS_SITC5.dta", clear
	keep if year==`x'
	
reghdfe lprix_fob llprix_fob ds_tariff_lise, a(FEc= cntry FEs= sector_3d)  vce (ro) resid

mat beta=e(b)
svmat double beta, names(matcol)
mat variance=e(V)

svmat double variance, names(matcol)
replace varianceds_tariff_lise=abs(varianceds_tariff_lise)
gen sd_tariff = sqrt(varianceds_tariff_lise)
gen sd_lag_prix_fob =  sqrt(variancellprix_fob)
drop *cons 
replace sd_tariff = sd_tariff[_n+1] if sd_tariff~=.

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
*keep year mode betads_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff r_square adj_r_square r_square_within
rename betads_tariff_lise beta_Fds_tariff_lise
rename betallprix_fob beta_lag_price
	
save "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_parameters_1975_both.dta", replace
save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=1976(1)2019{

	use "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta", clear
	sort year mode
	append using "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta"
	save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta", replace
}


save "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly_prod5_sect3.dta", replace




****a few useful descriptive statistics*****
tabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_Fds_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****a few useful descriptive statistics in LaTex Tables*****
latabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_Fds_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)


****a few useful descriptive statistics AFTER 2001 (to ease comparisons with current HS10 data)*****
tabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_Fds_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if year>2001, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****a few useful descriptive statistics in LaTex Tables AFTER 2001 (to ease comparisons with current HS10 data)*****
latabstat beta_lag_price sd_lag_prix_fob t_student_lag_pfob beta_Fds_tariff_lise sd_tariff t_student_tariff F_stat F_stat_tariff adj_r_square r_square_within if year>2001, s(mean p25 med p75 sd min max) columns(statistics) format(%9.4fc)

****Graphs with IC****

g beta_price_min = beta_lag_price-1.65*sd_lag_prix_fob
g beta_price_max = beta_lag_price+1.65*sd_lag_prix_fob

g beta_tariff_min = beta_Fds_tariff_lise-1.65*sd_tariff
g beta_tariff_max = beta_Fds_tariff_lise+1.65*sd_tariff



global bandwidth = 0.66
twoway rarea beta_price_min beta_price_max year, bsty(ci) sort ///
|| scatter beta_lag_price year, xlab(1975(4)2019) scheme(s1mono) c(l) xtitle("Year") ytitle("{&beta}") legend(off) msymbol(i) title("Distribution of {&beta} parameter on lagged fas price across years", pos(11) ring(0) size(medium))   ///
|| line beta_lag_price year
graph export "$dir/results/IV_referee1_yearly/beta_lag_SITC5.pdf", as(pdf) replace


global bandwidth = 0.66
twoway rarea beta_tariff_min beta_tariff_max year, bsty(ci) sort ///
|| scatter beta_Fds_tariff_lise year, xlab(1975(4)2019) scheme(s1mono) c(l) xtitle("Year") ytitle("{&alpha}") legend(off) msymbol(i) title("Distribution of {&alpha} parameter on tariffs across years", pos(11) ring(0) size(medium))   ///
|| line beta_Fds_tariff_lise year
graph export "$dir/results/IV_referee1_yearly/alpha_tariff_SITC5.pdf", as(pdf) replace




sort year 

*OK jusque là


forvalues x=1975(1)2019 {

	erase "$dir/results/IV_referee1_yearly/FS_parameters_`x'_both.dta"
}

erase "$dir/results/IV_referee1_yearly/FS_parameters_both_yearly.dta"




**********************************************************
**********First stage regressions: PREDICTIONS***********
**********************************************************
set more off 

forvalues x=1975(1)2019{
	use "$dir/hummels_FS_SITC5.dta", clear
	keep if year==`x'
	
reghdfe lprix_fob llprix_fob ds_tariff_lise, a(FEc= cntry FEs= sector_3d)  vce (ro) resid

predict lprix_yearly_air_hat_allFE,xbd 
	drop FEc FEs
	
save "$dir/results/IV_referee1_yearly/FS_predictions_`x'_both.dta", replace

}




use "$dir/results/IV_referee1_yearly/FS_predictions_1975_both.dta", replace
save "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta", replace


sort year 

*OK jusque là

forvalues x=1976(1)2019{

	use "$dir/results/IV_referee1_yearly/FS_predictions_`x'_both.dta", clear
	append using "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta"
	sort iso_o year mode sitc2
	order iso_o year mode sitc2 sitc2_3d
	keep sitc2 sitc2_3d iso_o year mode lprix_fob *prix_yearly*
	save "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta", replace
}




forvalues x=1975(1)2019 {

	erase "$dir/results/IV_referee1_yearly/FS_predictions_`x'_both.dta"
}


count if lprix_yearly_air_hat_allFE==.
drop if lprix_yearly_air_hat_allFE==.

save "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly_prod5_sect3.dta", replace

capture log close

erase "$dir/results/IV_referee1_yearly/FS_predictions_both_yearly.dta"
erase "$dir/hummels_FS_SITC5.dta"




