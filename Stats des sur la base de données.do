*************************************************
* Programme : Avoir qqs stats des sur la base de données
* 
*************************************************

version 14.1


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
gen termeAetI = terme_A+terme_I-1
gen termeiceberg = terme_iceberg -1

local type prix_trsp termeAetI termeiceberg

foreach i of local type {
	gen ln`i' = log(prix_trsp)
}
	


local type prix_trsp termeAetI termeiceberg lnprix_trsp lntermeAetI lntermeiceberg
keep `type' year mode val

foreach x in `type' {

	quietly sum `x'  [fweight= val], det
	generate `x'_mp = r(mean)
	generate `x'_med = r(p50)
	generate `x'_et = r(sd)
	generate `x'_min = r(min)
	generate `x'_max = r(max)

}

keep if _n ==1


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
	
		foreach  y of varlist prix_trsp* termeAetI* termeiceberg* lnprix_trsp* lntermeAetI* lntermeiceberg* {
		
		quietly sum `y'
		generate `y'_meanperiod = r(mean)
		
		
		}
	
	save compil_describedb_`x', replace
	
	
}

edit *mp_meanperiod in 1
