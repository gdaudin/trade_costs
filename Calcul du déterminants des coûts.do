*** Pgm pour extraire la variable Vk de la Maritime Trnasport Costs database


**  traitement_mtc.do

*** GD LP Dec 23/12/2106


version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/trade_cost



if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost


if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost

if ("`c(os)'"=="MacOSX") use $dir/results/estimTC.dta, clear



*****On met ensemble les bases de données
rename product SITCRev2_3d
if ("`c(os)'"=="MacOSX") merge m:1 SITCRev2_3d using $dir/data/database_Vk.dta
rename _merge merge_pdvolum
if ("`c(os)'"=="MacOSX") merge m:1 SITCRev2_3d using "$dir/data/Pour assurance/insurance_cat.dta"
drop if _merge==2
rename ocean ins_ves
rename air ins_air
label var ins_ves "Insurance rate for maritime freight"
label var ins_air "Insurance rate for air freight"
rename _merge merge_insurance
rename SITCRev2_3d product
*****Les soucis de merge sont liés à nos problèmes anciens... Donc on laisse tomber pour l'instant

keep if year==2013
if ("`c(os)'"=="MacOSX") merge m:1 name year using "$dir/data/DoingBusiness_exportscosts.dta"
drop if _merge==2



end



keep if year==2013
generate random=runiform()
sort random
keep if _n<=1000



