

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
	global dir ~/dropbox/2013 -- trade_cost -- local
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
***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


set more off
local mode ves air
*local year 1974 

cd $dir_pgms
do Estim_value_TC.do

foreach x in `mode' {

*foreach z in `year' {

forvalues z = 1974(1)2013 {

*** SOUMISSION: hummels_tra.dta

capture log close
log using hummels_3digits_complet_`z'_`x', replace

prep_reg hummels_tra `z' sitc2 3 `x'

*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close

}
}




********4 digits

set more off
local mode air
local year 1974 1977 1981 1985 1989 1993 1997 2001 2005 2009 2013
* attention pb en 1989 air il faut passer à 300 itérations


foreach x in `mode' {

foreach z in `year' {

*forvalues z = 1974(1)2013 {


capture log close
log using hummels_4digits_complet_`z'_`x', replace

*prep_reg `z' sitc2 4 `x'

prep_reg hummels_tra `z' sitc2 4 `x'

*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close

}
}

