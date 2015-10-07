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

* en seconde étape on va exprimer les trade costs en % du prix fob

for
bys iso: gen prix_fob_val = prix_fob*air_val
bys iso_o: egen tt = total(prix_fob_val)
bys iso_o: egen tt1 = total(air_val)
bys iso_o: gen prix_fob_mp = tt/tt1  

* On fait pareil pour le prix caf

drop tt tt1* prix_fob_val



bysort iso_o : keep if _n==1

gen nbdigits =3
gen year = 1974



label var nbdigits "Product classification precision"
label var year "Year of estimation"

save estimTC_bycountry, replace

** Append with vessel
use blouk_1974_sitc2_3_ves.dta, clear

keep prix_caf prix_fob ves_val iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 


* en seconde étape on va exprimer les trade costs en % du prix fob
bys iso: gen prix_fob_val = prix_fob*ves_val
bys iso_o: egen tt = total(prix_fob_val)
bys iso_o: egen tt1 = total(ves_val)
bys iso_o: gen prix_fob_mp = tt/tt1  
drop tt tt1*


bysort iso_o : keep if _n==1

gen nbdigits =3
gen year = 1974

label var nbdigits "Product classification precision"
label var year "Year of estimation"

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


* en seconde étape on va exprimer les trade costs en % du prix fob
bys iso: gen prix_fob_val = prix_fob*`mode'_val
bys iso_o: egen tt = total(prix_fob_val)
bys iso_o: egen tt1 = total(`mode'_val)
bys iso_o: gen prix_fob_mp = tt/tt1  
drop tt tt1*

bysort iso_o : keep if _n==1

gen nbdigits =`preci'
gen year = `z'

label var nbdigits "Product classification precision"
label var year "Year of estimation"

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

