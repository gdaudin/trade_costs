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
	args year mode


use "$dir/results/estimTC.dta", clear

* Base qui synthétise les résultats des estimations sur 3 digits, en intégrant en plus les variables observées

keep if year==`year'
keep if mode=="`mode'"

gen prix_trsp = prix_caf/prix_fob -1
gen lnprix_trsp = log(prix_trsp)
gen lnterme_ice = log(terme_iceberg -1)

local type prix_trsp lnprix_trsp lnterme_ice

foreach x in `type' {

sum `x'  [fweight= val], det
generate `x'_mp = r(mean)
generate `x'_med = r(p50)
generate `x'_et = r(sd)
generate `x'_min = r(min)
generate `x'_max = r(max)

}

keep if _n ==1

keep year mode prix_trsp_mp prix_trsp_med prix_trsp_et prix_trsp_min prix_trsp_max lnprix_trsp_mp lnprix_trsp_med lnprix_trsp_et lnprix_trsp_min /*
*/ lnprix_trsp_max lnterme_ice_mp lnterme_ice_med lnterme_ice_et lnterme_ice_min  lnterme_ice_max 

save "$dir/results/describe_db_`year'_`mode'", replace 


end


*** Lancer le programme



set more off
local mode ves air

foreach x in `mode' {

*foreach z in `year' {
foreach z of num 1974(1)2013 {


stats_des `z' `x'


}
}



** Compiler les résultats sur toutes les années

cd $dir/results/

* Première année 1974


set more off
local mode ves air


foreach x in `mode' {

use describe_db_1974_`x', clear


save compil_describedb_`x', replace
*erase describe_db_1974_`classe'_`preci'_`x'.dta

}

* Les années ultérieures


foreach x in `mode' {

foreach z of num 1975(1)2013 {

use compil_describedb_`x', clear
append using describe_db_`z'_`x'

save compil_describedb_`x', replace
*erase describe_db_`z'_`x'.dta

}

}


** Exploiter la base de données

* Pour 3 digits
local mode ves air


foreach x in `mode' {
use compil_describedb_`x', clear

display "Mode de transport = `x'" 


local type prix_trsp_mp prix_trsp_med lnprix_trsp_mp lnprix_trsp_med lnterme_ice_mp lnterme_ice_med

foreach y in `type' {

sum `y'
generate `y'_meanperiod = r(mean)


}

save compil_describedb_`x', replace


}

