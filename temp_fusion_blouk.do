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

local mode ves air
*local mode air ves

*local year 1974

** 3 digits

/*
foreach x in `mode' {

forvalues z = 2010(1) 2013 {

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
*/


** 4 digits

local year 1974 1977 1981 1985 1989 1993 1997 2001 2005 2009 2013


foreach x in `mode' {

foreach z in `year'{

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

