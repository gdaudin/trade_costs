*************************************************
* Programme : Avoir qqs stats des sur la base de données
* Using Hummels trade data
* 
*************************************************

*version 12


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

cd $dir


*** Faire un programme *** 

capture program drop stats_des
program stats_des
	args year class preci mode
* exemple : reg_termes_h 2006 sitc2 3 air
*Hummels : sitc2


**************** On reprend le traitement de la database comme pour la préparation de la base blouk

use "$dir/data/hummels_tra.dta", clear



save "$dir/results/describe_db_`year'_`class'_`preci'_`mode'", replace 

use "$dir/results/describe_db_`year'_`class'_`preci'_`mode'", clear


***Pour restreindre
*keep if substr(sitc2,1,1)=="0"
*************************

keep if year==`year'
keep if mode=="`mode'"
rename `class' product
replace product = substr(product,1,`preci')

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"


* Nettoyer la base de donnÈes

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************



display "Nombre avant bas et haut " _N

bys product: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys product: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 


display "Nombre après bas et haut " _N

egen prix_min = min(prix_trsp2), by(product)
egen prix_max = max(prix_trsp2), by(product)

g lprix_trsp2 = ln(prix_trsp2)
label variable lprix_trsp2 "log(prix_caf/prix_fob)"
*g lprix_trsp2 = ln(prix_trsp2)

g ldist = ln(dist)
label variable ldist "log(distance)"

**********Sur le produits

codebook product


egen group_prod=group(product)
su group_prod, meanonly	
drop group_prod
local nbr_prod_exante=r(max)
display "Nombre de produits : `nbr_prod_exante'" 

bysort product: drop if _N<=5

egen group_prod=group(product)
su group_prod, meanonly	
local nbr_prod_expost=r(max)
drop group_prod
display "Nombre de produits : `nbr_prod_expost'" 


sum prix_trsp  [fweight=`mode'_val], det
generate prix_trsp_mp = r(mean)
generate prix_trsp_med = r(p50)
generate prix_trsp_et = r(sd)
generate prix_trsp_min = r(min)
generate prix_trsp_max = r(max)

keep if _n ==1

keep year mode prix_trsp_mp prix_trsp_med prix_trsp_et prix_trsp_min prix_trsp_min

save "$dir/results/describe_db_`year'_`class'_`preci'_`mode'", replace 


end


*** Lancer le programme



set more off
local mode ves air

foreach x in `mode' {

*foreach z in `year' {
foreach z of num 1974(1)2013 {


*stats_des `z' sitc2 3 `x'
stats_des `z' sitc2 4 `x'


}
}

** Compiler les résultats sur toutes les années

cd $dir/results/

* Première année 1974


set more off
local mode ves air
local classe sitc2
local preci 4

foreach x in `mode' {

use describe_db_1974_`classe'_`preci'_`x', clear


save compil_describedb_`classe'_`preci'_`x', replace
erase describe_db_1974_`classe'_`preci'_`x'.dta

}

* Les années ultérieures


foreach x in `mode' {

foreach z of num 1975(1)2013 {

use compil_describedb_`classe'_`preci'_`x', clear
append using describe_db_`z'_`classe'_`preci'_`x'

save compil_describedb_`classe'_`preci'_`x', replace
erase describe_db_`z'_`classe'_`preci'_`x'.dta

}

}


** Exploiter la base de données

* Pour 3 digits
local mode ves air
local classe sitc2
local preci 3 


foreach x in `mode' {
use compil_describedb_`classe'_`preci'_`x', clear

display "Mode de transport = `x'" 

sum prix_trsp_mp

sum prix_trsp_med


}


* Pour 4 digits on ne garde que les années sur lesquelles on a fait l'estimation

local mode ves air
local classe sitc2
local preci 4

 

foreach x in `mode' {
use compil_describedb_`classe'_`preci'_`x', clear

keep if year == 1974 | year == 1977|year == 1981| year == 1985|	year == 1989| year == 1993|	year ==1997|year ==2001|year ==2005	|year ==2009| year ==2013

display "Mode de transport = `x'" 

sum prix_trsp_mp

sum prix_trsp_med


}

