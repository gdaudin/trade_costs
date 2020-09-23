
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
	*global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
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
  
	* Programmes sur le Git
	global dir_pgms C:\Users\Ipatureau\Documents\trade_costs
	
	* database sur mon OneDrive
	global dir_db "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data"
		
	*résultats méthode soumission sur même base que celle méthode référé 1
	global dir_baseline_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\baselinesamplereferee1"
	
	* résultats selon méthode référé 1
	global dir_referee1 "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	

	
	
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
args class preci prod 

cd "$dir_db"

if `prod' !=10 {
    use hummels_tra, clear
	local database hummels_tra
	* s=3, k=5
}


if `prod' ==10 {   
	use base_hs`prod'_newyears, clear
	local database base_hs`prod'_newyears
	}

* On part directement sur SITC2, 3 digits
rename `class' sector
replace sector = substr(sector,1,`preci')

sort iso_o sector
save temp_`database', replace

count

* Initier la base: 2005, air et vessel, en 10 digits = `prod'
* Attention, à ajuster si prod = 5 digits

use "$dir_referee1/results_beta_contraint_2005_sitc2_HS`prod'_air.dta", clear

* results_... est au niveau secteur/ pays (par année/mode)

gen year=2005
gen mode ="air"

keep iso_o sector mode year

save temp, replace

use temp_`database', clear
keep if year == 2005
keep if mode=="air"
merge m:1 year mode iso_o sector using temp

keep if _merge==3

count
drop _merge
* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
* on doit logiquement avoir bcp moins d'observations
save db_samesample_`class'_`preci'_HS`prod', replace

use "$dir_referee1/results_beta_contraint_2005_sitc2_HS`prod'_ves.dta", clear



gen year=2005
gen mode ="ves"

keep iso_o sector mode year

save temp, replace

use temp_`database', clear
keep if year==2005
keep if mode=="ves"
merge m:1 year mode iso_o sector using temp

keep if _merge==3

count
drop _merge
* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
* on doit logiquement avoir bcp moins d'observations
save temp_2005_ves, replace

use db_samesample_`class'_`preci'_HS`prod', clear

count 
append using temp_2005_ves

count

* temp_hummels_tra est année-secteur spécifique, sinon ça fait un merge compliqué
* on doit logiquement avoir bcp moins d'observations
save db_samesample_`class'_`preci'_HS`prod', replace

* A ce stade on a les données de la base originelle en 2005, mais uniquement sur les secteurs / pays de la base du référé 1

erase temp_2005_ves.dta


** Les années ultérieures
forvalues x = 2006(1)2013 {

	foreach z in air ves {
	
	*** ACTUALISER POUR HS10 ****
	
	use "$dir_referee1/results_beta_contraint_`x'_sitc2_HS`prod'_`z'.dta", clear
	
	gen year=`x'
	gen mode ="`z'"
	
	keep iso_o sector mode year
	
	save temp, replace
	
	use temp_`database', clear
	keep if year==`x'
	keep if mode=="`z'"
	
	
	merge m:1 iso_o sector using temp
	
	keep if _merge==3
	
	count
	drop _merge

	save temp_`x'_`z', replace
	
	use db_samesample_`class'_`preci'_HS`prod', clear
	
	count 
	append using temp_`x'_`z'
	
	count
	
	save db_samesample_`class'_`preci'_HS`prod', replace
	erase temp_`x'_`z'.dta
	}

}
capture drop temp

* mise en conformité avec hummels_tra
rename sector `class'
save db_samesample_`class'_`preci'_HS`prod', replace

erase temp_`database'.dta

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
*build_same_sample sitc2 3 10
* génère db_samesample_sitc2_3_HS10.dta


***********************************************************************
***** 2. LANCER LES ESTIMATIONS ***************************************
***********************************************************************

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


** Sept. 2020: On le lance sur une seule année pour faire la comparaison de la précision des beta

set more off
local mode ves air
local year 2012 

cd "$dir_pgms"
do Estim_value_TC.do

foreach x in `mode' {

foreach z in `year' {
*forvalues z = 2005(1)2013 {
 

*** SOUMISSION: hummels_tra.dta, s=3 k=5 digits
*** REVISION  : base_hs10_newyears.dta, s=3 k=10 digits


capture log close
log using hummels_3digits_baselinesampleref1_`z'_`x', replace

prep_reg db_samesample_sitc2_3_HS10 `z' sitc2 3 `x'

*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close

}
}

