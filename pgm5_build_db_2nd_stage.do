*************************************************
* Programme 5 : Programme pour constuire la bdd permettant ensuite d'estimer les déterminants des TC
*NB : il y a un programme sur le serveur pour rapatrier les données pertinentes à partir des blouks
*************************************************

version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


global dir ~
***Au lieu de changer le working directory pour s'adapter à nous deux, je fais en sorte qu'il n'y ait
*qu'une macro à changer

cd $dir/dropbox/trade_cost/data
import excel "DoingBusiness_exportscosts_for_stata.xlsx", sheet("Feuille1") firstrow clear
note : Coming from http://www.doingbusiness.org/custom-query, downloaded on September 28th, 2015
save DoingBusiness_exportscosts.dta, replace

cd $dir/dropbox/trade_cost/results
use estimTC_bycountry.dta, clear
cd $dir/dropbox/trade_cost/data
merge m:1 name year using "DoingBusiness_exportscosts.dta"
drop if year==2014
tabulate _merge
drop if _merge==2
drop nameDB _merge

merge m:1 year using "oil/oil prices, BP energy outlook.dta"

drop if _merge==2

cd $dir/dropbox/trade_cost/results
save estimTC_bycountry_augmented.dta, replace




