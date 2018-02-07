

version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



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

capture log using "`c(current_time)' `c(current_date)'"


use "$dir/results/estimTC.dta", clear

gen beta =(terme_A)/(terme_A+terme_I-1)
*Si on prend le TC observé, cela ne marche pas !!

foreach pond in yes no {
	foreach year in 1974 1994 2013 {
		foreach mode in ves air {
			if "`pond'"=="no" histogram beta if year==`year' & mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) ///
			title ("`year' (`mode')") /// 
			saving (`year'_`mode', replace)
			if "`pond'"=="yes" histogram beta [fweight=val] if year==`year' & mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) ///
			title ("`year' (`mode')") ///
			saving (`year'_`mode', replace)
		}
	}
	graph combine 1974_ves.gph 1994_ves.gph 2013_ves.gph 1974_air.gph 1994_air.gph 2013_air.gph, ///
	ycommon xcommon col(3) ///
	note("Ponderation by value of flow: `pond'") ///
	saving("$dir/results/Etude_beta_pond_`pond'.pdf", replace)
	
	foreach year in 1974 1994 2013 {
		foreach mode in ves air {
			erase `year'_`mode'.gph
		}
	}
	
	
	
	
}






