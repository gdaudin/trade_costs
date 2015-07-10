***************************************************************
** 

clear all
set mem 700m
*set matsize 8000
set more off
*set maxvar 32767



***********************************************************************
**** Calculer les R2 selon la nouvelle méthode
***********************************************************************

* sur le serveur
*cd "C:\Echange\trade_costs\results"

* sur la dropbox
cd "C:\Users\lpatureau\Dropbox\trade_cost\new\results"


set more off
local mode air
local preci 3


* pb sur 2011 manque l'estimation sur iceberg seulement

foreach x in `mode' {

foreach k in `preci' {

*forvalues z=1974(1)2010 {
forvalues z=2012(1)2013 {

use blouk_`z'_sitc2_`k'_`mode', clear

drop Rp2_nl

* R2 sur estimpation nl iceberg set additifs
correlate ln_ratio_minus1 blink_nl
generate Rp2_nl = r(rho)^2


keep year mode Rp2_nlI Rp2_nl
keep if _n==1

save tabR2_`z'_sitc2_`k'_`mode', replace

}
}
}

*** Compiler en une même base
local mode air
local preci 3


use tabR2_1974_sitc2_`preci'_`mode', clear

save tabR2_sitc2_`preci'_`mode', replace


foreach x in `mode' {

foreach k in `preci' {

*forvalues z=1975(1)2010 {
forvalues z=2012(1)2013 {


use tabR2_sitc2_`k'_`x' clear

append using tabR2_`z'_sitc2_`k'_`mode'

save tabR2_sitc2_`k'_`mode', replace

}
}
}

*** Exporter en excel

local mode air
local preci 3

use tabR2_sitc2_`preci'_`mode'
export excel using tabR2_`preci'_`mode', replace firstrow(varlabels)

** Effacer les .dta intermédiaires

foreach x in `mode' {

foreach k in `preci' {

forvalues z=1974(1)2010 {

erase tabR2_sitc2_`k'_`x'.dta

}


forvalues z=2012(1)2013 {

erase tabR2_sitc2_`k'_`x'.dta

}
}
}
