
if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaison_baseline_referee1"
	global dir_temp ~/Downloads/temp_stata
	
	
}


/* Fixe Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir_baseline_results ??????
	}

/* Vieux portable Lise */
if "`c(hostname)'" =="lise-HP" {
	global dir_baseline_results ??????
}

/* Nouveau portable Lise */
if "`c(hostname)'" =="MSOP112C" {
    global dir_baseline_results ??????
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


capture erase "$dir_comparaison/stats_comp.dta"

foreach year of num 2005/2013 {
	foreach mode in air ves {
	comparaison `year' `mode'
	}
}

use "$dir_comparaison/stats_comp.dta", clear
gen referee1_as_value_share_baseline=couverture_referee1/couverture_baseline
gen referee1_nb_pairs_share_baseline=Nb_cx3ds/Nb_cx3ds_baseline
sort mode year

save "$dir_comparaison/stats_comp.dta", replace

graph twoway (scatter beta_mean beta_baseline_mean) (lfit beta_mean beta_baseline_mean) ///
			 (scatter beta_mean_pond beta_baseline_mean_pond) (lfit beta_mean_pond beta_baseline_mean_pond) ///
			 (scatter beta_med beta_baseline_med) (lfit beta_med beta_baseline_med) ///
			 (scatter beta_med_pond beta_baseline_med_pond) (lfit beta_med_pond beta_baseline_med_pond), ///
			 ytitle("baseline") xtitle("referee1")
			 
graph export "$dir_comparaison/scatter_comparaison.pdf", replace


keep year mode beta*
reshape long beta_, i(year mode) j(type) string
gen method="referee1"
replace method="baseline" if strmatch(type,"baseline*")!=0
replace type = substr(type, 10,.) if strmatch(type,"baseline*")!=0
reshape wide beta_,i(year mode type) j(method) string
graph twoway (connected beta_baseline year) (connected beta_referee1 year), by(mode type)


graph export "$dir_comparaison/scatter_chronology.pdf", replace
