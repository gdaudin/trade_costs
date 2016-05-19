*************************************************
* Programme pour constuire la bdd permettant ensuite d'estimer les déterminants des TC
*NB : il y a un programme sur le serveur pour rapatrier les données pertinentes à partir des blouks
*Fait à partir de programme 5
*************************************************


version 14

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/trade_cost



if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost


if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost


	 
***Au lieu de changer le working directory pour s'adapter à nous deux, je fais en sorte qu'il n'y ait
*qu'une macro à changer

cd $dir/data
import excel "DoingBusiness_exportscosts_for_stata.xlsx", sheet("Feuille1") firstrow clear
note : Coming from http://www.doingbusiness.org/custom-query, downloaded on September 28th, 2015
destring Cost_to_export, replace
save DoingBusiness_exportscosts.dta, replace

cd $dir/results
use estimTC.dta, clear
cd $dir/data
merge m:1 name year using "DoingBusiness_exportscosts.dta"
drop if year==2014
tabulate _merge
drop if _merge==2
drop nameDB _merge

merge m:1 year using "oil/oil prices, BP energy outlook.dta"

drop if _merge==2
drop _merge


*****On met ensemble les bases de données
rename product SITCRev2_3d
if ("`c(os)'"=="MacOSX") merge m:1 SITCRev2_3d using $dir/data/database_Vk.dta
rename _merge merge_pdvolum
if ("`c(os)'"=="MacOSX") merge m:1 SITCRev2_3d using "$dir/data/Pour assurance/insurance_cat.dta"

tabulate SITCRev2_3d if _merge==2
tabulate SITCRev2_3d if _merge==1


drop if _merge==2
rename ocean ins_ves
rename air ins_air
label var ins_ves "Insurance rate for maritime freight"
label var ins_air "Insurance rate for air freight"
rename _merge merge_insurance
rename SITCRev2_3d product


cd $dir/results
save estimTC_augmented.dta, replace




