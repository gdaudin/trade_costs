	

*************************************************
* Programme : Lancer les estimations 

*	Estimer les additive & iceberg trade costs
* 	Using Hummels trade data (version soumission)
*
*	Mars 2020
* 
*************************************************

*version 12



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_pgms "~/Répertoires GIT/trade_costs_git"
}

** Fixe Lise bureau
if "`c(hostname)'" =="LAB0271A" {
	*global dir "\\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_costs"
	global dir_pgms "\\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Git\trade_costs"
	
	global dir_log "C:\Users\lpatureau\Dropbox\trade_cost\Log divers"
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
	
}

*******************************************************



set more off

 
do "$dir_pgms/Estim_value_TC.do"




***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, 

***** VESSEL, puis AIR  *******************************
*******************************************************


global modelist /* air */ ves
*local year 1974 


foreach mode in $modelist {

	*foreach  year of numlist  1998 1999 2003(1)2019 {
	*foreach  year of numlist  1977(3)2017 {
	
	foreach  year of numlist  1975(3)1999 {
	
	** 27-01-2021, Lise : comparer 2002 air avec old_hummels_tra pour vérifier que c'est ok
	
		*** SOUMISSION: hummels_tra.dta
		
		capture log close
		log using hummels_3digits_complet_`year'_`mode', replace
		
		prep_reg FS_predictions_both_yearly_prod5_sect3 `year' 5 3 `mode'
		
		*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
		*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"
		
		log close
	
	}
}

/*
foreach mode in $modelist {

	foreach  year of numlist  /*1974*/ 2005(1)2013 {
	
		*** SOUMISSION: hummels_tra.dta
		
		capture log close
		log using hummels_3digits_complet_`year'_`node', replace
		
		prep_reg predictions_FS_panel `year' sitc2 3 `mode'
		
		*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
		*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"
		
		log close
	
	}
}
*/

