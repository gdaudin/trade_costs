
*************************************************
* Programme Révision JEGeo

*** Trois parties

*** 1. Construire la base de données identique entre les deux méthodes d'estimation 

*** 2. Lancer les estimations "old method"

*	Pour estimer les additive & iceberg trade costs
* 	Méthode estimation "old" (comme soumission) mais sur base réduite issue méthode référé 1

*** 3. Comparer les résultats
*** Entre méthode "old" et "referee 1", sur la même base
*
*	Mars 2020
* 
*************************************************

*version 12



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_db ~/Documents/Recherche/2013 -- Trade Costs -- local/data
	global dir_referee1 ~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1
	global dir_pgms ~/Documents/Recherche/2013 -- Trade Costs -- local/trade_costs_git
	global dir_baseline_results ~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1/baselinesamplereferee1
}

** Fixe Lise bureau
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}

/* Vieux portable Lise
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}
*/

/* Nouveau portable Lise */

if "`c(hostname)'" =="MSOP112C" {
  
	*global dir C:\Lise\trade_costs
	global dir_pgms C:\Users\Ipatureau\Documents\trade_costs
	
	global dir_db C:\Lise\trade_costs\data
	* baseline results sur hummels_tra dans son intégralité
    * global dir_baseline_results C:\Lise\trade_costs\results\baseline
	
	*résultats méthode soumission sur même base que celle méthode référé 1
	global dir_baseline_results C:\Lise\trade_costs\results\referee1\baselinesamplereferee1
	
	* résultats selon méthode référé 1
	global dir_referee1 C:\Lise\trade_costs\results\referee1
	

	
	
}


***********************************************************************
*******************   CONSTRUCTION DES PROGRAMMES   *******************
***********************************************************************
***********************************************************************

*********************************************************************
*** PROGRAMME SELECTION BASE DE DONNEES
*** REVISION JEGeo
*********************************************************************

	
* Etape PRELIMINAIRE: CONSTITUER BASE POUR FAIRE tourner la régression baseline sur le même sample
* que le sample méthode estimation du référé 1

capture program drop build_same_sample

program build_same_sample
args class preci

cd "$dir_db"
use hummels_tra, clear


* On part directement sur SITC2, 3 digits
rename `class' sector
replace sector = substr(sector,1,`preci')

sort iso_o sector
save temp_hummels_tra, replace

count

* Initier la base: 2005, air et vessel

use "$dir_referee1/results_beta_contraint_2005_sitc2_HS8_air.dta", clear

gen year=2005
gen mode ="air"

save temp, replace

use temp_hummels_tra, clear
keep if year == 2005
keep if mode=="air"
merge m:1 year mode iso_o sector using temp

keep if _merge==3

count
drop _merge
* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
* on doit logiquement avoir bcp moins d'observations
save db_samesample_`class'_`preci', replace


use "$dir_referee1/results_beta_contraint_2005_sitc2_HS8_ves.dta", clear

gen year=2005
gen mode ="ves"

save temp, replace

use temp_hummels_tra, clear
keep if year==2005
keep if mode=="ves"
merge m:1 year mode iso_o sector using temp

keep if _merge==3

count
drop _merge
* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
* on doit logiquement avoir bcp moins d'observations
save temp_2005_ves, replace

use db_samesample_`class'_`preci', clear

count 
append using temp_2005_ves

count

* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
* on doit logiquement avoir bcp moins d'observations
save db_samesample_`class'_`preci', replace

** Les années ultérieures
forvalues x = 2006(1)2013 {

	foreach z in air ves {
	
	use "$dir_referee1/results_beta_contraint_`x'_sitc2_HS8_`z'.dta", clear
	
	gen year=`x'
	gen mode ="`z'"
	
	save temp, replace
	
	use temp_hummels_tra, clear
	keep if year==`x'
	keep if mode=="`z'"
	
	
	merge m:1 iso_o sector using temp
	
	keep if _merge==3
	
	count
	drop _merge
	* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
	* on doit logiquement avoir bcp moins d'observations
	save temp_`x'_`z', replace
	
	use db_samesample_`class'_`preci', clear
	
	count 
	append using temp_`x'_`z'
	
	count
	
	save db_samesample_`class'_`preci', replace
	erase temp_`x'_`z'.dta
	}

}
capture drop temp

* mise en conformité avec hummels_tra
rename sector `class'
save db_samesample_`class'_`preci', replace

erase temp_hummels_tra.dta

end

******************************************************
**** PROGRAMME COMPARAISON DES RESULTATS
******************************************************
******************************************************
	
capture program drop comparaison
program comparaison
args year mode 


use "$dir_baseline_results/results_estimTC_`year'_sitc2_3_`mode'.dta", clear

rename product sector
bys iso_o sector : keep if _n==1
generate beta_baseline=-(terme_A/(terme_I+terme_A-1))
save "$dir_temp/baseline.dta", replace

use "$dir_referee1/results_beta_contraint_`year'_sitc2_HS8_`mode'.dta", clear
bys iso_o sector : keep if _n==1

merge 1:1 iso_o sector using "$dir_temp/baseline.dta"

erase "$dir_temp/baseline.dta"

graph twoway (scatter beta beta_baseline) (lfit beta beta_baseline), ///
	title("For `year', `mode'")

graph export "$dir_comparaison/scatter_`year'_`mode'.pdf", replace

use "$dir_baseline_results/results_estimTC_`year'_sitc2_3_`mode'.dta", clear

generate beta_baseline=-(terme_A/(terme_I+terme_A-1))
egen couverture_baseline=total(`mode'_val)
gen Nb_baseline=_N
summarize beta_baseline, det
generate beta_baseline_mean = r(mean)
generate beta_baseline_med = r(p50)
summarize beta_baseline [fweight=`mode'_val], det
generate beta_baseline_mean_pond = r(mean)
generate beta_baseline_med_pond = r(p50)
generate blif = iso_o+product
levelsof blif
generate Nb_cx3ds_baseline = r(r)
label var Nb_cx3ds_baseline "Number of country x 3 digit sector included in the baseline"
drop blif

keep mode couverture_baseline-Nb_cx3ds_baseline
keep if _n==1
gen year=`year'

capture append using "$dir_comparaison/stats_comp.dta"

save "$dir_comparaison/stats_comp.dta", replace

use "$dir_referee1/results_beta_contraint_`year'_sitc2_HS8_`mode'.dta", clear

egen couverture_referee1=total(`mode'_val)
gen Nb_referee1=_N
summarize beta, det
generate beta_mean = r(mean)
generate beta_med = r(p50)
summarize beta [fweight=`mode'_val], det
generate beta_mean_pond = r(mean)
generate beta_med_pond = r(p50)
generate blif = iso_o+sector
levelsof blif
generate Nb_cx3ds = r(r)
label var Nb_cx3ds "Number of country x 3 digit sector included in referee1 test"
drop blif


keep couverture_referee1-Nb_cx3ds
keep if _n==1
gen year=`year'
gen mode="`mode'"


merge 1:1 year mode using "$dir_comparaison/stats_comp.dta"
drop _merge

save "$dir_comparaison/stats_comp.dta", replace

end


***********************************************************************
***********************************************************************
***** 	FAIRE TOURNER LES PROGRAMMES   ********************************
***********************************************************************
***********************************************************************


***********************************************************************
*** 1. CONSTRUIRE LA MEME BASE DE DONNEES SUR ESTIMATION "ORIGINAL METHOD"
*** ET "REFEREE 1 METHOD"
***********************************************************************

cd "$dir_pgms"

* SITC2, 3 digits
build_same_sample sitc2 3
* génère db_samesample_sitc2_3.dta


***********************************************************************
***** 2. LANCER LES ESTIMATIONS ***************************************
***********************************************************************

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


set more off
local mode ves air
*local year 1974 

cd "$dir_pgms"
do Estim_value_TC.do

foreach x in `mode' {

*foreach z in `year' {

forvalues z = 2005(1)2013 {

*** SOUMISSION: hummels_tra.dta

capture log close
log using hummels_3digits_complet_`z'_`x', replace

prep_reg db_samesample_sitc2_3 `z' sitc2 3 `x'

*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close

}
}


***********************************************************************
***** 3. COMPARER LES RESULTATS ***************************************
***********************************************************************


do "$dir_pgms/Comparaison_baseline_referee1.do"

capture erase "$dir_comparaison/stats_comp_baselinesamplereferee1_referee1.dta"

foreach year of num 2005/2013 {
	foreach mode in air ves {
	comparaison_by_year_mode `year' `mode' baselinesamplereferee1 referee1
	}
}


comparaison_graph baselinesamplereferee1 referee1
