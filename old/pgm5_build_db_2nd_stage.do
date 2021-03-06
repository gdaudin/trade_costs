*************************************************
* Programme 5 : Programme pour constuire la bdd permettant ensuite d'estimer les d�terminants des TC
*NB : il y a un programme sur le serveur pour rapatrier les donn�es pertinentes � partir des blouks
*************************************************

version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\dropbox/2013 -- trade_cost -- dropbox
}


	 
***Au lieu de changer le working directory pour s'adapter � nous deux, je fais en sorte qu'il n'y ait
*qu'une macro � changer

cd $dir/data
import excel "DoingBusiness_exportscosts_for_stata.xlsx", sheet("Feuille1") firstrow clear
note : Coming from http://www.doingbusiness.org/custom-query, downloaded on September 28th, 2015
destring Cost_to_export, replace
save DoingBusiness_exportscosts.dta, replace

cd $dir/results
use estimTC_bycountry.dta, clear
cd $dir/data
merge m:1 name year using "DoingBusiness_exportscosts.dta"
drop if year==2014
tabulate _merge
drop if _merge==2
drop nameDB _merge

merge m:1 year using "oil/oil prices, BP energy outlook.dta"

drop if _merge==2
drop _merge


cd $dir/results
saveold estimTC_bycountry_augmented.dta, replace




