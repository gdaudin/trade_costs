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

** 3 digits
** Premi�re ann�e 1974

** On commence par air, vessel append ensuite
use blouk_1974_sitc2_3_air.dta, clear

keep prix_caf prix_fob iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 

bysort iso_o : keep if _n==1

gen nbdigits =3
gen year = 1974


label var nbdigits "Product classification precision"
label var year "Year of estimation"

save estimTC_bycountry, replace

** Append with vessel
use blouk_1974_sitc2_3_ves.dta, clear

keep prix_caf prix_fob iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 

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
** Boucle sur les ann�es suivantes

local preci 3

forvalues z =1975(1)2013 {

foreach mode in air ves {


use blouk_`z'_sitc2_`preci'_`mode'.dta, clear

keep prix_caf prix_fob iso_o name coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 

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


** Bug sur "name" � partir de 2005,jamais renseign�

use estimTC_bycountry, clear

sort iso_o year
foreach x in iso_o {

forvalues z = 2005(1)2013 {


replace name = name[_n-1] if iso_o == `x' & year ==`z'
}

}

save estimTC_bycountry, replace

