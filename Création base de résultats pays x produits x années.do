*************************************************
* Programme 7 : Programme pour estimer les d�terminants des trade costs - 2d stage - ESSAI
* On part de terme_icberg, terme_I, terme_A plut�t que de la composante pays seulement

*************************************************


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


	 
** charger la base de donn�es

global dir \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\resultats

cd $dir

*** Lancer le programme d'estimation de la 2e �tape

** on est en 3 digits **
local preci 3

forvalues year =1974(1)2013 {

foreach mode in air ves {


	use $dir\raw_results_sept15\blouk_`year'_sitc2_`preci'_`mode'.dta, clear

	keep product prix_caf prix_fob `mode'_val iso_o name terme_iceberg terme_I terme_A coef_iso_nlI coef_iso_A coef_iso_I contig-distwces mode 
	rename `mode'_val val

keep if mode ==`mode'

bysort iso_o product : keep if _n==1


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



** Bug sur "name" � partir de 2005,jamais renseign�

use estimTC, clear

sort iso_o year
foreach x in iso_o {

forvalues z = 2005(1)2013 {


replace name = name[_n-1] if iso_o == `x' & year ==`z'
}

}

save estimTC, replace

