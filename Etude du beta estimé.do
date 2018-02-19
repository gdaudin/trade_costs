

*version 15.1

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


if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost
}

cd $dir

capture log using "`c(current_time)' `c(current_date)'"


use "$dir/results/estimTC.dta", clear

gen beta =(terme_A)/(terme_A+terme_I-1)
*Si on prend le TC observé, cela ne marche pas !!
label var beta "Share of additive costs"


egen val_tot_year=total(val), by(year mode)
gen share_y_val = round((val/val_tot_year)*100000)

* Lise, pb avec le double if et saving - stata version?
* On enleve la boucle sur ponderation

foreach mode in ves air {
	
	histogram beta if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) xtitle("Share of additive costs") ytitle("Density") title("`mode' (no ponderation)")
	graph export $dir/results/Etude_beta_nopond_`mode'.pdf, replace

	histogram beta [fweight=share_y_val] if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) xtitle("Share of additive costs") ytitle("Density") title("`mode'")
	graph export $dir/results/Etude_beta_pondere_`mode'.pdf, replace

}

/*
foreach pond in yes no {
	
	foreach mode in ves air {

		if "`pond'"=="no" histogram beta if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) ///
		title ("`mode'")
		saving ("$dir/results/Etude_beta_pond_`pond'_TOT_`mode'.pdf", replace)
		
		
		if "`pond'"=="yes" histogram beta [fweight=share_y_val] if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) ///
		title ("`mode'") ///
		saving ("$dir/results/Etude_beta_pond_`pond'_TOT_`mode'.pdf", replace) 
		note("Ponderation by share of yearly value of flow : `pond'")
		graph export $dir/results/Etude_beta_pond_`pond'_TOT_`mode'.pdf, replace
	}	
}

*/
