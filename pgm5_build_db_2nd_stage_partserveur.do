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



* sur mon laptop
*cd "C:\Lise\trade_costs\Hummels\resultats\new"

* sur le serveur
cd "C:\Echange\trade_costs\results"

*********************************************************
*** On compile tout dans une même base
*** Une variable indicatrice du mode
*** Une variable indicatrice du degré de classification
*********************************************************

** 3 digits
** Première année 1974

** On commence par air, vessel append ensuite
use blouk_1974_sitc2_3_air.dta, clear

keep prix_caf prix_fob air_val iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 

* en seconde étape on va exprimer les trade costs en % du prix fob moyen, par pays
* On fait pareil pour le prix caf

local prix prix_fob prix_caf 
foreach x in `prix' {

bys iso: gen `x'_val = `x'*air_val
bys iso_o: egen tt = total(`x'_val)
bys iso_o: egen tt1 = total(air_val)
bys iso_o: gen `x'_mp = tt/tt1  



drop tt tt1* `x'_val

}


bysort iso_o : keep if _n==1


* Générer l'écart caf-fob
gen prix_trsp_mp = (prix_caf_mp - prix_fob_mp)/prix_fob_mp

gen nbdigits =3
gen year = 1974

label var nbdigits "Product classification precision"
label var year "Year of estimation"

label var prix_caf_mp  "Caf price by country/year (weighted by mode val over all products)"
label var prix_fob_mp  "Fob price by country/year (weighted by mode val over all products)"
label var prix_trsp_mp "(Caf-Fob)/fob, by country/year"


drop prix_fob prix_caf

save estimTC_bycountry, replace

** Append with vessel
use blouk_1974_sitc2_3_ves.dta, clear

keep prix_caf prix_fob ves_val iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 


* en seconde étape on va exprimer les trade costs en % du prix fob moyen, par pays
* On fait pareil pour le prix caf

local prix prix_fob prix_caf 
foreach x in `prix' {

bys iso: gen `x'_val = `x'*ves_val
bys iso_o: egen tt = total(`x'_val)
bys iso_o: egen tt1 = total(ves_val)
bys iso_o: gen `x'_mp = tt/tt1  



drop tt tt1* `x'_val

}

bysort iso_o : keep if _n==1

* Générer l'écart caf-fob
gen prix_trsp_mp = (prix_caf_mp - prix_fob_mp)/prix_fob_mp

gen nbdigits =3
gen year = 1974

label var nbdigits "Product classification precision"
label var year "Year of estimation"

label var prix_caf_mp  "Caf price by country/year (weighted by mode val over all products)"
label var prix_fob_mp  "Fob price by country/year (weighted by mode val over all products)"
label var prix_trsp_mp "(Caf-Fob)/fob, by country/year"


drop prix_fob prix_caf

save temp, replace

** Append la base originelle

use estimTC_bycountry, clear
append using temp

save estimTC_bycountry, replace
erase temp.dta

************************************
** Boucle sur les années suivantes

local preci 3

forvalues z =1975(1)2013 {

foreach mode in air ves {


use blouk_`z'_sitc2_`preci'_`mode'.dta, clear

keep prix_caf prix_fob `mode'_val iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 

local prix prix_fob prix_caf 
foreach x in `prix' {

bys iso: gen `x'_val = `x'*`mode'_val
bys iso_o: egen tt = total(`x'_val)
bys iso_o: egen tt1 = total(`mode'_val)
bys iso_o: gen `x'_mp = tt/tt1  



drop tt tt1* `x'_val

}

bysort iso_o : keep if _n==1


* Générer l'écart caf-fob
gen prix_trsp_mp = (prix_caf_mp - prix_fob_mp)/prix_fob_mp


gen nbdigits =`preci'
gen year = `z'

label var prix_caf_mp  "Caf price by country/year (weighted by mode val over all products)"
label var prix_fob_mp  "Fob price by country/year (weighted by mode val over all products)"
label var prix_trsp_mp "(Caf-Fob)/fob, by country/year"


drop prix_fob prix_caf

save temp, replace


** Append la base originelle

use estimTC_bycountry, clear
append using temp

save estimTC_bycountry, replace
erase temp.dta
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

save estimTC_bycountry, replace

