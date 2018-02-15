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


capture program drop creer_estimTC
program creer_estimTC
args preci
** Exemple creer_estimTC 3
*** Lancer le programme d'estimation de la 2e étape

** on est en 3 digits **

if `preci' == 3 local estimTC estimTC
if `preci' == 4 local estimTC estimTC_4d




if `preci' == 3 local liste_year 1974(1)2013
if `preci' == 4 local liste_year 1974 1977 1981 1985 1989 1993 1997 2001 2005 2009 2013

foreach year of numlist `liste_year' {

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

gen prix_caf_pond = prix_caf*wgt
gen prix_fob_pond = prix_fob*wgt

bys sector iso_o mode : gen nbr_prod=_N

collapse (sum) prix_caf_pond prix_fob_pond val wgt, by(sector iso_o name terme_iceberg terme_I terme_A coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode nbr_prod)

gen prix_caf = prix_caf_pond/wgt
gen prix_fob = prix_fob_pond/wgt

drop prix_caf_pond prix_fob_pond

gen nbdigits =`preci'
gen year = `year'


** Append la base originelle

if "`mode'" !="air" | `year' !=1974 {

	save temp, replace
	use `estimTC', clear
	append using temp
	erase temp.dta
}
	
save `estimTC', replace
}
*log close
}



** Bug sur "name" à partir de 2005,jamais renseigné

use `estimTC', clear

sort iso_o year
foreach x in iso_o {
	forvalues z = 2005(1)2013 {
		replace name = name[_n-1] if iso_o == `x' & year ==`z'
	}
}

save `estimTC', replace

** Bug sur "name" à partir de 2011 sur iso_o "SDN"

use `estimTC', clear

replace name = "Sudan" if iso_o =="SDN" 
bys iso_o: count if name==""

save `estimTC', replace

* Sauver sur la dropbox
use `estimTC', clear

if ("`c(hostname)'" =="????") save "C:\Users\lpatureau\Dropbox\trade_cost\results\`estimTC'.dta", replace
if ("`c(username)'" =="guillaumedaudin") save  ~/dropbox/trade_cost/results/`estimTC'.dta, replace

end

creer_estimTC 3
creer_estimTC 4
