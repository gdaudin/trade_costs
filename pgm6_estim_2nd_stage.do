*************************************************
* Programme 6 : Programme pour estimer les déterminants des trade costs - 2d stage

*************************************************
version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox/trade_cost
}


	 
	 
** charger la base de données

cd $dir/results
use estimTC_bycountry_augmented.dta, clear



capture program drop reg_FE_h
program reg_FE_h
args year preci mode

* exemple : reg_FE 2006 sitc3 3 air
* rod_var "hs hs6 SIC sitc2 sitc3 naics"


use estimTC_bycountry_augmented, clear

preserve
* on ne retient que la dimension digits / mode / année
keep if mode == `mode'
keep if nbdigits ==`preci'
keep if year == `year'

** Génerer les explicatives


generate lndist=ln(dist)



** CASE 1: DANS LE CAS SANS ADDITIFS
************************************************
generate lncoef_iso_nlI= ln(coef_iso_nlI)

* dans les variables de gravité on ne considère que distance
reg lncoef_iso_nlI lndist , robust

/*capture*/	matrix X=e(b)
/*capture*/ matrix ET=e(V)

generate rho_dist_nlI=X[1,1]
generate rho_contig_nlI=X[1,2]
generate rho_comlang_off_nlI=X[1,3]
generate rho_comlang_ethno_nlI=X[1,4]
generate rho_colony_nlI=X[1,5]
generate rho_comcol_nlI=X[1,6]
generate rho_curcol_nlI=X[1,7]
generate rho_col45_nlI=X[1,8]
generate rho_smctry_nlI=X[1,9]


generate et_dist_nlI=ET[1,1]^0.5
generate et_contig_nlI=ET[2,2]^0.5
generate et_comlang_off_nlI=ET[3,3]^0.5
generate et_comlang_ethno_nlI=ET[4,4]^0.5
generate et_colony_nlI=ET[5,5]^0.5
generate et_comcol_nlI=ET[6,6]^0.5
generate et_curcol_nlI=ET[7,7]^0.5
generate et_col45_nlI=ET[8,8]^0.5
generate et_smctry_nlI=ET[9,9]^0.5


** CASE 2: DANS LE CAS AVEC ADDITIFS 
************************************************

* Sur la composante "pays" de terme I
generate lncoef_iso_I = ln(coef_iso_I)

reg lncoef_iso_I lndist contig-smctry, robust

capture	matrix X= e(b)
capture matrix ET=e(V)

generate rho_dist_I=X[1,1]
generate rho_contig_I=X[1,2]
generate rho_comlang_off_I=X[1,3]
generate rho_comlang_ethno_I=X[1,4]
generate rho_colony_I=X[1,5]
generate rho_comcol_I=X[1,6]
generate rho_curcol_I=X[1,7]
generate rho_col45_I=X[1,8]
generate rho_smctry_I=X[1,9]


generate et_dist_I=ET[1,1]^0.5
generate et_contig_I=ET[2,2]^0.5
generate et_comlang_off_I=ET[3,3]^0.5
generate et_comlang_ethno_I=ET[4,4]^0.5
generate et_colony_I=ET[5,5]^0.5
generate et_comcol_I=ET[6,6]^0.5
generate et_curcol_I=ET[7,7]^0.5
generate et_col45_I=ET[8,8]^0.5
generate et_smctry_I=ET[9,9]^0.5


* Sur la composante "pays" de terme A
generate lncoef_iso_A = ln(coef_iso_A)


reg lncoef_iso_A lndist contig-smctry, robust

capture	matrix X= e(b)
capture  matrix ET=e(V)

generate rho_dist_A=X[1,1]
generate rho_contig_A=X[1,2]
generate rho_comlang_off_A=X[1,3]
generate rho_comlang_ethno_A=X[1,4]
generate rho_colony_A=X[1,5]
generate rho_comcol_A=X[1,6]
generate rho_curcol_A=X[1,7]
generate rho_col45_A=X[1,8]
generate rho_smctry_A=X[1,9]


generate et_dist_A=ET[1,1]^0.5
generate et_contig_A=ET[2,2]^0.5
generate et_comlang_off_A=ET[3,3]^0.5
generate et_comlang_ethno_A=ET[4,4]^0.5
generate et_colony_A=ET[5,5]^0.5
generate et_comcol_A=ET[6,6]^0.5
generate et_curcol_A=ET[7,7]^0.5
generate et_col45_A=ET[8,8]^0.5
generate et_smctry_A=ET[9,9]^0.5



save result_NLiso_`year'_`class'_`preci'_`mode', replace
