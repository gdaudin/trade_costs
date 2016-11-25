*********************************************************************

*** Programme temporaire pour réunir les bases blouk

*** On a NL en (additif + iceber) et NL en iceberg (old version)
*** On fusionne avec les nouvelles bases blouk NL en additif seulement

***         Novembre 2016

**********************************************************************



** On fait la fusion sur mon 
global dir \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results\
cd $dir



*** Fusion des bases en 3 digits


set more off

local mode ves
*local mode air ves

*local year 1974

* stop en 2009 pour l'instant
* 2013 à faire

foreach x in `mode' {

forvalues z = 1974(1) 2009 {

*foreach z in `year' {

* la nouvelle base
*use blouk_`z'_sitc2_3_`x', clear

use $dir\results_I_IetA\blouk_`z'_sitc2_3_`x'


* de mon poste Dauphine
merge using "C:\Users\lpatureau\Dropbox\trade_cost\results\blouk_`z'_sitc2_3_`x'"

drop _merge

save "C:\Users\lpatureau\Dropbox\trade_cost\results\blouk_`z'_sitc2_3_`x'", replace


}

}

