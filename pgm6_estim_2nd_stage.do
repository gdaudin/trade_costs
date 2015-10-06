*************************************************
* Programme 6 : Programme pour estimer les déterminants des trade costs - 2d stage

*************************************************
version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox/trade_cost
}


	 
	 
** charger la base de données

cd $dir/results
use estimTC_bycountry_augmented.dta, clear
