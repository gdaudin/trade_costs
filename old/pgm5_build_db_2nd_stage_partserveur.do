*************************************************
* Programme 5a (sur le serveur) : Constituer la base de données de 2e étape

* Compiler les blouk en une seule base
* Ne garder que les variables pertinentes
* 
*************************************************


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767

if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/trade_cost
	cd "~/Documents/Recherche/Trade Costs/Results/raw_results_sept15"
}


if "`c(hostname)'" =="LAB0271A" {
	global dir dropbox ?
	cd "C:\Lise\trade_costs\Hummels\resultats\new"
}


	 


* sur mon laptop


* sur le serveur
*cd "C:\Echange\trade_costs\results"

*********************************************************
*** On compile tout dans une même base
*** Une variable indicatrice du mode
*** Une variable indicatrice du degré de classification
*********************************************************


local preci 3

forvalues year =1974(1)2013 {

foreach mode in air ves {


	use blouk_`year'_sitc2_`preci'_`mode'.dta, clear
	
	keep if mode=="`mode'"

	keep prix_caf prix_fob `mode'_val iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode terme_I terme_A terme_iceberg
	rename `mode'_val val



	local prix prix_fob prix_caf terme_I terme_A terme_iceberg
	foreach x in `prix' {

		bys iso_o : gen `x'_val = `x'*val
		bys iso_o : egen tt = total(`x'_val)
		bys iso_o : egen tt1 = total(val)
		bys iso_o : gen `x'_mp = tt/tt1  


		drop tt tt1* `x'_val
}

	bys iso_o : egen val_tot = total (val)
	label var val_tot  "total value of imports by country and transport mode"
	drop val

	bysort iso_o mode : keep if _n==1


	* Générer l'écart caf-fob
	gen prix_trsp_mp = (prix_caf_mp - prix_fob_mp)/prix_fob_mp


	gen nbdigits =`preci'
	gen year = `year'

	label var prix_caf_mp  "Caf price by country/year (weighted by val over all products)"
	label var prix_fob_mp  "Fob price by country/year (weighted by val over all products)"
	label var prix_trsp_mp "(Caf-Fob)/fob, by country/year"
	label var terme_I_mp "Terme I by country/year (weighted by mode val over all products)"
	label var terme_A_mp "Terme A by country/year (weighted by mode val over all products)"
	label var terme_iceberg_mp "Terme iceberg by country/year (weighted by mode val over all products)"


	drop prix_fob prix_caf


	** Append la base originelle

	if "`mode'" !="air" | `year' !=1974 {

	save temp, replace
	use estimTC_bycountry, clear
	append using temp
	erase temp.dta
}
	
save estimTC_bycountry, replace
}
*log close
}



** Bug sur "name" à partir de 2005,jamais renseigné

use estimTC_bycountry, clear

sort iso_o year
foreach x in iso_o {

forvalues z = 2005(1)2013 {


replace name = name[_n-1] if iso_o == `x' & year ==`z'
}

}

save "$dir/estimTC_bycountry.dta", replace

