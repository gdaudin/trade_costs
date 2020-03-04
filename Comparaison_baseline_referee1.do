
if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	
	
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



local year 2013
local mode ves


use "$dir_baseline_results/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
rename product sector
bys iso_o sector : keep if _N==1
merge 1:1 iso_o sector using "$dir_referee1/results_beta_contraint_`year'_sitc2_HS8_`mode'.dta"



***************** Pour vérifier que le merge se fait sur les bases d’orgine... pas très bon

use "$dir/data/hummels_tra.dta", clear
rename sitc2 sector
replace sector = substr(sector,1,3)
bys year iso_o sector : keep if _N==1
keep if year >=2005
save temp_hummels_tra.dta, replace

use "$dir/data/base_hs10_newyears.dta", clear

rename sitc2 sector
replace sector = substr(sector,1,3)
bys year iso_o sector : keep if _N==1

merge 1:1 year sector iso_o using temp_hummels_trad.dta, force





erase temp_hummels_tra.dta, replace

