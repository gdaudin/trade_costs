
*************************************************
* Programme Révision JEGeo

*** DEUX PARTIES

*** 1. Construire la base de données identique entre les deux méthodes d'estimation 

*** 2. Lancer les estimations "old method" sur la base restreinte (celle de la méthode Référé 1)

*	Pour estimer les additive & iceberg trade costs
* 	Méthode estimation "old" (comme soumission) mais sur base réduite issue méthode référé 1

*** A ACTUALISER POUR INSERER CONTROLE FINESSE NIVEAU PRODUIT *****
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

*** ACTUALISER POUR HS10 ****

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
	
	*** ACTUALISER POUR HS10 ****
	
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

