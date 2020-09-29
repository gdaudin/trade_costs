

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
	global dir_pgms "$dir/trade_costs_git"
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
	
}

*******************************************************


set more off

*local year 1974 

do "$dir_pgms/Estim_value_TC.do"


***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************
local mode ves air

foreach m in `mode' {

	forvalues y = 1998/1999 {
	
		*** SOUMISSION: hummels_tra.dta
		
		capture log close
		log using "Logs divers/log_prep_reg_base_hs10_newyears_`y'_10_3_`m'", replace
		
		if `y' !=1998 | "`m'"!="air" prep_reg base_hs10_newyears `y' 10 3 `m'
		
		
		*2013 air ne converge pas 
		*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
		*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"
		
		log close
	
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


