*************************************************
* Programme 5a (sur le serveur) : Constituer la base de donn�es de 2e �tape

* Compiler les blouk en une seule base
* Ne garder que les variables pertinentes
* 
*************************************************


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



* sur mon laptop
*cd "C:\Lise\trade_costs\Hummels\resultats\new"

* sur le serveur
cd "C:\Echange\trade_costs\results"

*********************************************************
*** On compile tout dans une m�me base
*** Une variable indicatrice du mode
*** Une variable indicatrice du degr� de classification
*********************************************************


local preci 3

forvalues z =1975(1)2013 {

foreach mode in air ves {


	use blouk_`z'_sitc2_`preci'_`mode'.dta, clear

	keep prix_caf prix_fob `mode'_val iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 
	rename `mode'_val val

}

local prix prix_fob prix_caf 
foreach x in `prix' {

	bys iso: gen `x'_val = `x'*val
	bys iso_o: egen tt = total(`x'_val)
	bys iso_o: egen tt1 = total(val)
	bys iso_o: gen `x'_mp = tt/tt1  


	drop tt tt1* `x'_val
}

bys iso_o : egen val_tot = total (val)
label var val  "total value of imports by country"

bysort iso_o : keep if _n==1


* G�n�rer l'�cart caf-fob
gen prix_trsp_mp = (prix_caf_mp - prix_fob_mp)/prix_fob_mp


gen nbdigits =`preci'
gen year = `z'

label var prix_caf_mp  "Caf price by country/year (weighted by mode val over all products)"
label var prix_fob_mp  "Fob price by country/year (weighted by mode val over all products)"
label var prix_trsp_mp "(Caf-Fob)/fob, by country/year"


drop prix_fob prix_caf


** Append la base originelle

if "`mode'" !="air" � `year' !=1974 {
	save temp, replace
	use estimTC_bycountry, clear
	append using temp
	erase temp.dta
}
	
save estimTC_bycountry, replace
}
*log close

}


** Bug sur "name" � partir de 2005,jamais renseign�

use estimTC_bycountry, clear

sort iso_o year
foreach x in iso_o {

forvalues z = 2005(1)2013 {


replace name = name[_n-1] if iso_o == `x' & year ==`z'
}

}

save estimTC_bycountry, replace

