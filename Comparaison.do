
if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaison_baseline_referee1"
	global dir_temp ~/Downloads/temp_stata
	global dir_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/"
	
	
}


/* Fixe Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir_baseline_results ???
	}

/* Nouveau portable Lise */
if "`c(hostname)'" =="MSOP112C" {

	* baseline results sur hummels_tra dans son intégralité
    * global dir_baseline_results C:\Lise\trade_costs\results\baseline
	
	*résultats méthode soumission sur même base que celle méthode référé 1
	global dir_baseline_results C:\Lise\trade_costs\results\referee1\oldmethod
	
	* résultats selon méthode référé 1
	global dir_referee1 C:\Lise\trade_costs\results\referee1
	

	
	global dir C:\Lise\trade_costs
	global dir_data C:\Lise\trade_costs\data
	}




/*

************Comparaison de base
use "$dir/data/hummels_tra.dta", clear
contract year iso_o sitc2 mode
tab _freq
/*Cela confirme que year iso_o sitc2 mode sont les clefs du fichier*/

use "$dir/data/base_hs10_newyears.dta", clear
contract year iso_o mode hs dist_entry
tab _freq
*Ce n’est pas une clef unique ?! Donc il y a plusieurs consignements par produit/district dans base_hs10_newyears ?


use "$dir/data/hummels_tra.dta", clear
keep if year >=2005
merge 1:m year iso_o sitc2 mode using "$dir/data/base_hs10_newyears.dta", force
tab mode _merge
**Semble suggérer qu’il y a plus de choses dans HS10 que dans hummels_tra... (même au delà des cnt)
drop if sitc2==""
tab mode _merge
drop if mode=="cnt"
tab _merge
*****Donc tout le problème est bien lié à mode=="cnt" et aux sitc vides

generate sector = substr(sitc2,1,3)
codebook sector
contract year iso_o sector mode
describe
******************************************	




***************** Pour vérifier que le merge se fait sur les bases d’orgine... c’est bon aussi

use "$dir/data/hummels_tra.dta", clear
rename sitc2 sector
drop if sector==""
assert strlen(sector)==5
replace sector = substr(sector,1,3)
keep if year >=2005
contract year iso_o sector mode
save temp_hummels_tra.dta, replace

use "$dir/data/base_hs10_newyears.dta", clear
rename sitc2 sector
drop if sector==""
assert strlen(sector)==5
replace sector = substr(sector,1,3)
drop if mode=="cnt"
contract year iso_o sector mode

merge 1:1 year sector iso_o mode using temp_hummels_tra.dta, force
erase temp_hummels_tra.dta

***********************
*/

	
** Faire tourner sur toutes les années /mode


	
******************************************************
******************************************************
	
capture program drop comparaison_by_year_mode
program comparaison_by_year_mode
args year mode method1 method2

if "`method1'"=="baseline" {
	use "$dir_baseline_results/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
}	
	
if "`method1'"=="baselinesamplereferee1" {
	use "$dir_referee1/baselinesamplereferee1/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
}	
	

		
	
rename product sector
bys iso_o sector : keep if _n==1
generate beta_baseline=-(terme_A/(terme_I+terme_A-1))
save "$dir_temp/`method1'_`method2'.dta", replace

if "`method2'"=="referee1" {
	use "$dir_referee1/results_beta_contraint_`year'_sitc2_HS8_`mode'.dta", clear
}

if "`method2'"=="IV_referee1_panel" {
	use "$dir_results/IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
	generate beta = -(terme_A/(terme_I+terme_A-1))
	rename product sector /*Product is in fact 3 digits*/
	drop _merge
}	


if "`method2'"=="IV_referee1_yearly" {
	use "$dir_results/IV_referee1_yearly/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
	generate beta = -(terme_A/(terme_I+terme_A-1))
	rename product sector /*Product is in fact 3 digits*/
	drop _merge
}	
	
	

bys iso_o sector : keep if _n==1

merge 1:1 iso_o sector using "$dir_temp/`method1'_`method2'.dta"

erase "$dir_temp/`method1'_`method2'.dta"

graph twoway (scatter beta beta_baseline) (lfit beta beta_baseline), ///
	title("For `year', `mode'")

graph export "$dir_comparaison/scatter_`year'_`mode'_`method1'_`method2'.png", replace

if "`method1'"=="baseline" {
	use "$dir_baseline_results/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
}	

if "`method1'"=="baselinesamplereferee1" {
	use "$dir_referee1/baselinesamplereferee1/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
}	
	


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
quietly levelsof blif
generate Nb_cx3ds_baseline = r(r)
label var Nb_cx3ds_baseline "Number of country x 3 digit sector included in the baseline"
drop blif

keep mode couverture_baseline-Nb_cx3ds_baseline
keep if _n==1
gen year=`year'

capture append using "$dir_comparaison/stats_comp_`method1'_`method2'.dta"

save "$dir_comparaison/stats_comp_`method1'_`method2'.dta", replace

if "`method2'"=="referee1" {
	use "$dir_referee1/results_beta_contraint_`year'_sitc2_HS8_`mode'.dta", clear
}

if "`method2'"=="IV_referee1_panel" {
	use "$dir_results/IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
	generate beta = -(terme_A/(terme_I+terme_A-1))
	rename product sector /*Product is in fact 3 digits*/
	drop _merge
}

if "`method2'"=="IV_referee1_yearly" {
	use "$dir_results/IV_referee1_yearly/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
	generate beta = -(terme_A/(terme_I+terme_A-1))
	rename product sector /*Product is in fact 3 digits*/
	drop _merge
}	
		
	

egen couverture_`method2'=total(`mode'_val)
gen Nb_referee1=_N
summarize beta, det
generate beta_mean = r(mean)
generate beta_med = r(p50)
summarize beta [fweight=`mode'_val], det
generate beta_mean_pond = r(mean)
generate beta_med_pond = r(p50)
generate blif = iso_o+sector
quietly levelsof blif
generate Nb_cx3ds = r(r)
label var Nb_cx3ds "Number of country x 3 digit sector included in `method2' test"
drop blif


keep couverture_`method2'-Nb_cx3ds
keep if _n==1
gen year=`year'
gen mode="`mode'"


merge 1:1 year mode using "$dir_comparaison/stats_comp_`method1'_`method2'.dta"
drop _merge

save "$dir_comparaison/stats_comp_`method1'_`method2'.dta", replace

end



capture program drop comparaison_graph
program comparaison_graph
args method1 method2

use "$dir_comparaison/stats_comp_`method1'_`method2'.dta", clear

graph twoway (scatter beta_mean beta_baseline_mean) (lfit beta_mean beta_baseline_mean) ///
			 (scatter beta_mean_pond beta_baseline_mean_pond) (lfit beta_mean_pond beta_baseline_mean_pond) ///
			 (scatter beta_med beta_baseline_med) (lfit beta_med beta_baseline_med) ///
			 (scatter beta_med_pond beta_baseline_med_pond) (lfit beta_med_pond beta_baseline_med_pond), ///
			 ytitle("baseline") xtitle("referee1")
			 
graph export "$dir_comparaison/scatter_comparaison_`method1'_`method2'.png", replace


keep year mode beta*
reshape long beta_, i(year mode) j(type) string
gen method="`method2'"
replace method="`method1'" if strmatch(type,"`method1'*")!=0
replace type = substr(type, 10,.) if strmatch(type,"`method1'*")!=0
reshape wide beta_,i(year mode type) j(method) string


graph twoway (connected beta_`method1' year) (connected beta_`method2' year), by(mode type)


graph export "$dir_comparaison/scatter_chronology_`method1'_`method2'.png", replace


graph twoway (scatter beta_`method2' beta_`method1') (lfit beta_`method2' beta_`method1'), ///
			 ytitle("`method1'") xtitle("`method2'") by(mode type)
			 
graph export "$dir_comparaison/scatter_comparaison_by_type_`method1'_`method2'.png", replace

end


*********
***on lance les comparaisons

global method1 baseline
*global method2 IV_referee1_panel
global method2 IV_referee1_yearly

******





*capture erase "$dir_comparaison/stats_comp_baseline_referee1.dta"
capture erase "$dir_comparaison/stats_comp_${method1}_$method2.dta"

foreach year of num 2005/2013 {
	foreach mode in air ves {
	comparaison_by_year_mode `year' `mode' $method1 $method2
	}
}



use "$dir_comparaison/stats_comp_${method1}_$method2.dta", clear
gen method2_value_method1=couverture_$method2/couverture_$method1
label var method2_value_method1 "Covered value of trade by $method2 as a share of $method1"
gen method2_nbpair_method1=Nb_cx3ds/Nb_cx3ds_$method1
label var method2_nbpair_method1 "Covered bilateral trade flows by products by $method2 as a share of $method1"
sort mode year
save "$dir_comparaison/stats_comp_${method1}_$method2.dta", replace




*/
comparaison_graph $method1 $method2

*/

