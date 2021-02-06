

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

** Fixe Lise bureau, en local sur MyWork
if "`c(hostname)'" =="LAB0271A" {
	global dir "\\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_costs"
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
  
	* En local sur le disque dur
	global dir_pgms C:\Users\Ipatureau\Documents\trade_costs
	global dir_log "C:\Users\lpatureau\Dropbox\trade_cost\Log divers"
	
}

*******************************************************


set more off


do "$dir_pgms/Estim_value_TC.do"



***** LANCER LES ESTIMATIONS **************************
*******************************************************



*local year 1974 

*** À adapter suivant les besoins

*******************************************************

capture program drop EstimTC
program EstimTC
args year mode level_product level_sector bdd

capture log close
	
* sauver le log file chez Guillaume
if "`c(username)'" =="guillaumedaudin" {
	log using "Logs divers/log_prep_reg_base_hs10_newyears_`year'_`level_product'_`level_sector'_`mode'", replace
}
	
* sauver le log file chez Lise
if "`c(hostname)'" =="LAB0271A" | "`c(hostname)'" =="MSOP112C"{
	log using "$dir_log/log_prep_reg_base_`year'_1`level_product'_`level_sector'_`mode'", replace
}
	
prep_reg `bdd' `year' `level_product' `level_sector' `mode'
	
	
	* 2013 air ne converge pas 

log close



end



local mode ves air
forvalues y = 2014/2019 {
	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 hummels_tra_qy1_qy
	}

}

/*

********4 digits
**Cela ne marche pas lorsque les produits sont à 10-digits : c’est trop long
**7 jours pour 18 itérations sur 2005 par exemple

set more off
local mode air ves /*ves*/
local year /*1974 1977 1981 1985 1989 1993 1997 2001*/ 2005 2009 2013
* attention pb en 1989 air il faut passer à 300 itérations pour 5/3


foreach m in `mode' {
	
	foreach y in `year' {
			
		capture log close
		log using log_prep_reg_base_hs10_newyears_`y'_10_4_`m', replace
		
		*prep_reg `y' sitc2 4 `m'
		
		prep_reg base_hs10_newyears `y' 10 4 `m'
		
		*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
		*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"
		
		log close
	
	}
}


