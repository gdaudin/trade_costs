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
	global dir ~/dropbox/2013 -- trade_cost -- dropbox
	cd "~/Documents/Recherche/2013 -- Trade Costs -- local/Results/raw_results_sept15"
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

display "`year'_`mode'"


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

save "$dir/results/estimTC_bycountry.dta", replace


*******************Ajout des variables


if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\dropbox/2013 -- trade_cost -- dropbox
}

	 
***Au lieu de changer le working directory pour s'adapter à nous deux, je fais en sorte qu'il n'y ait
*qu'une macro à changer

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
*rm "$dir/estimTC_bycountry.dta"



