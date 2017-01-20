*************************************************
* Programme 7 : Programme pour estimer les déterminants des trade costs - 2d stage - ESSAI
* On part de terme_icberg, terme_I, terme_A plutôt que de la composante pays seulement

*************************************************


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


	 
** charger la base de données

if ("`c(hostname)'" =="????") global dir \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results

if "`c(username)'" =="guillaumedaudin" global dir  "~/Documents/Recherche/Trade Costs/Results"

cd "$dir"

*** Lancer le programme d'estimation de la 2e étape

** on est en 3 digits **
local preci 3

forvalues year =1974(1)2013 {

disp "year = `year'"

foreach mode in air ves {


	use blouk_`year'_sitc2_`preci'_`mode'.dta, clear

	keep product prix_caf prix_fob `mode'_val `mode'_wgt iso_o name terme_iceberg terme_I terme_A coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 
	rename `mode'_val val
	rename `mode'_wgt wgt
	label var val "Value"
	label var wgt "Weight"
	rename product sector
	

keep if mode =="`mode'"

gen prix_caf_pond = prix_caf*val
gen prix_fob_pond = prix_caf*val

bys sector iso_o mode : gen nbr_prod=_N

collapse (sum) prix_caf_pond prix_fob_pond val , by(sector iso_o name terme_iceberg terme_I terme_A coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode nbr_prod)

gen prix_caf = prix_caf_pond/val
gen prix_fob = prix_fob_pond/val

drop prix_caf_pond prix_fob_pond

gen nbdigits =`preci'
gen year = `year'


** Append la base originelle

if "`mode'" !="air" | `year' !=1974 {

	save temp, replace
	use estimTC, clear
	append using temp
	erase temp.dta
}
	
save estimTC, replace
}
*log close
}



** Bug sur "name" à partir de 2005,jamais renseigné

use estimTC, clear

sort iso_o year
foreach x in iso_o {

forvalues z = 2005(1)2013 {


replace name = name[_n-1] if iso_o == `x' & year ==`z'
}

}

save estimTC, replace

** Bug sur "name" à partir de 2011 sur iso_o "SDN"

use estimTC, clear

replace name = "Sudan" if iso_o =="SDN" 
bys iso_o: count if name==""

save estimTC, replace

* Sauver sur la dropbox
use estimTC, clear

if ("`c(hostname)'" =="????") save "C:\Users\lpatureau\Dropbox\trade_cost\results\estimTC.dta", replace
if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") save  ~/dropbox/trade_cost/results/estimTC.dta, replace

