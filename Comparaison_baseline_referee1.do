
if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
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

	
local year 2005
local mode air


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












