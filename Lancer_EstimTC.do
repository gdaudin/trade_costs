

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
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_pgms "~/Répertoires GIT/trade_costs_git"
	global dir_log "$dir/Logs divers"
	global dir_temp "~/Downloads/temp_stata"
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
	global dir_log "C:\Users\lpatureau\Dropbox\trade_cost\Logs divers"
	
}

if "`c(hostname)'" =="hericourt" {
  
	global dir D:\Hericourt\trade_costs
	global dir_data D:\Hericourt\trade_costs\data
	global dir_pgms D:\Hericourt\trade_costs\pgms
	global dir_log D:\Hericourt\trade_costs\Logs divers

	
}

/* Nouveau fixe Bureau Lise: Tout en local sur MyWork. Pour la base et les résultats, dossier Lise ; pgms dans le dossier Git (de MyWork) */
if "`c(hostname)'" =="LAB0661F" {
	
	global dir "//storage2016.windows.dauphine.fr/home/l/lpatureau/My_Work/Lise/trade_costs"
	global dir_data "$dir/data"
	global dir_pgms "//storage2016.windows.dauphine.fr/home/l/lpatureau/My_Work/Git/trade_costs"
	global dir_log "$dir/Log_divers"
	
}


*******************************************************


set more off

do "$dir_pgms/Estim_value_TC.do"
*do D:\Hericourt\trade_costs\pgms\Estim_value_TC.do



***** LANCER LES ESTIMATIONS **************************
*******************************************************



*local year 1974 

*** À adapter suivant les besoins

*******************************************************

capture program drop EstimTC
program EstimTC
args year mode level_product level_sector bdd model

capture log close


global test
****Si test
*global test test2
******



* sauver le log file chez Guillaume
if "`c(username)'" =="guillaumedaudin" {
	log using "$dir_log/${test}log_prep_reg_base_`year'_`mode'_`level_product'_`level_sector'_`bdd'.smcl", replace
}
	
* sauver le log file chez Lise
if "`c(hostname)'" =="LAB0271A" | "`c(hostname)'" =="MSOP112C" | "`c(hostname)'" =="LAB0661F" {
	log using "$dir_log/${test}log_prep_reg_base_`year'_`mode'_`level_product'_`level_sector'_`bdd'.smcl", replace
}
	
	* sauver le log file chez Jerome
if "`c(hostname)'" =="hericourt" {
	log using "$dir_log/${test}log_prep_reg_base_`year'_`mode'_`level_product'_`level_sector'_`bdd'.smcl", replace
}
	

prep_reg `bdd' `year' `level_product' `level_sector' `mode' `model'

	
	
	* 2013 air ne converge pas 

log close
translate "$dir_log/${test}log_prep_reg_base_`year'_`mode'_`level_product'_`level_sector'_`bdd'.smcl" /*
		*/"$dir_log/${test}log_prep_reg_base_`year'_`mode'_`level_product'_`level_sector'_`bdd'.pdf", replace

erase "$dir_log/${test}log_prep_reg_base_`year'_`mode'_`level_product'_`level_sector'_`bdd'.smcl"

end

/*
*Pour quand on a les quantités Hummels
local mode air
*foreach  year of numlist  1976(3)2019

foreach y of numlist 2014(-1) 1974 {
	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 hummels_tra_qy1_wgt
	EstimTC `y' `m' 5 3 hummels_tra_qy1_qy
	}
}
*/
/*
*Pour quand on a les quantités HS10
local mode air /*ves*/
*foreach  year of numlist  1976(3)2019
*/


/*
foreach y of numlist 2017(-1)2002 {


	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 hs10_qy1_qy
	EstimTC `y' `m' 5 3 hs10_qy1_wgt
	}
}

*/


***Pour IV 5/3
/*local mode ves 
foreach  y of numlist 2012 {
	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 FS_predictions_both_yearly_prod5_sect3
	}

}
*/

/*
***Pour IV 10/3
local mode air ves 
*foreach  y of numlist 2003(1)2019 {
foreach  y of numlist 2016(1)2019 {
	foreach m in `mode' {	
	EstimTC `y' `m' 10 3 FS_predictions_both_yearly_prod10_sect3
	}

}
*/


****Pour baseline
/*
local mode /*ves*/ air 
foreach  y of numlist 2017 2019 {
	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 hummels_tra nlAetI
	}
}
*/

*****Pour HS10 10/3
local year 1997 1998 1999 2002(1) 2019
local mode ves 
foreach  y of numlist 1997/1997 {
	foreach m in `mode' {	
	EstimTC `y' `m' 10 3 base_hs10_newyears
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

*/
/*
****Pour baseline nlA
local mode air ves 
foreach  y of numlist 1974/2019 {
	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 hummels_tra nlA
	}
}
*/

/*
****Pour baseline nlI
local mode air ves 
foreach  y of numlist 1974 1977(4)2017 2019 {
	foreach m in `mode' {	
	EstimTC `y' `m' 5 3 hummels_tra nlI
	}

}








