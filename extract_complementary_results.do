*version 12
*v1 : vient de Cožts de commerce_v4
*Adaptation aux donnŽes de Hummels
*v2 : reprise 18/2




***********************************************************************
**** Programme pour extraire les résultats complémentaires
**** 2002, 2009 à 2013 manquent, en 3 d, air
**** issus de l'estimation v10
***********************************************************************
** 

clear all
set mem 700m
*set matsize 8000
set more off
*set maxvar 32767



***********************************************************************
**** STEP 0. Travail préliminaire : fusionner pour 2009 blouk et blouk_nlI
***********************************************************************

* sur le serveur
cd "C:\Echange\trade_costs\results"

* sur mon laptop
*cd "C:\Lise\trade_costs\Hummels\resultats\new"

use blouk_2009_sitc2_3_air_onlyI_and_A


merge m:m iso_o iso_d product prix_fob using blouk_nlI_2009_sitc2_3_air
drop _merge


save blouk_2009_sitc2_3_air, replace



***********************************************************************
**** STEP 1. Etudier les résultats : Tableau de résultats, année par année
***********************************************************************

capture program drop get_table

program get_table
args year class preci mode

dis "year = " `year'
*dis "classification = " `class'
dis "\# digits= " `preci'
dis "mode = `mode'"

use blouk_`year'_`class'_`preci'_`mode'.dta, clear


* nb obs = variable nbr_obs
* nb de pays dans l'estimation

egen _ = group(iso_o)
sum _
gen nbr_iso_o = r(max)

drop _

* nd de produits
egen _ = group(product)
sum _
gen nbr_prod = r(max)

drop _


dis "******************************"
dis "Estimation NL avec iceberg trade costs ONLY"
sum Rp2_nlI 


dis "Terme iceberg: distribution (moyenne pondérée par `mode'_val)"
sum terme_iceberg  [fweight=`mode'_val], detail


gen terme_nlI_min = r(min)
gen terme_nlI_max = r(max)

dis "******************************"
dis "Estimation non-linéaire"
dis "******************************"

sum Rp2_nl  

dis "Terme A: distribution (moyenne pondérée par `mode'_val)"
sum terme_A  [fweight=`mode'_val], detail

*gen terme_A_med = r(p50)
gen terme_A_min = r(min)
gen terme_A_max = r(max)

dis "Terme A: distribution (sans moyenne pondérée)"
sum terme_A

** nb: on a la valeur moyenne et l'écart-type dans terme_A_mp et terme_A_et resp.

dis "Terme I: distribution (moyenne pondérée par `mode'_val)"
sum terme_I  [fweight=`mode'_val], detail

*gen terme_I_med = r(p50)
gen terme_I_min=r(min)
gen terme_I_max=r(max)

#delimit ;

keep nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp 
terme_A_med terme_A_et terme_A_min terme_A_max terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nlI aic_nlI logL_nlI Rp2_nl aic_nl logL_nl ;

#delimit cr
keep if _n==1

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace

/* On ne prend plus les résultats de l'estimation Step 2 */ 

gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"

order year digits mode nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med  terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max /*
*/ terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nlI aic_nlI logL_nlI  Rp2_nl aic_nl logL_nl 


*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace

end

***********************************
**** SORTIR LES RESULTATS *********

*capture log close
*log using get_table, replace

*** 3 digits, all years ***

*cd "E:\Lise\BQR_Lille\Hummels\resultats\sauv-07-04-2014"
*cd "E:\Lise\BQR_Lille\Hummels\resultats"
*cd "C:\Lise\trade_costs\Hummels\resultats\new"

set more off
local mode air
local preci 3
* pour 2009 et 2002

local year 2002 2009 2010 2012 2013

* pb sur 2011 manque l'estimation sur iceberg seulement

foreach x in `mode' {

foreach k in `preci' {

foreach z in `year' {

get_table `z' sitc2 `preci' `mode'

*log close

}

}
}
***************************************
*** Step 3 - compiler en une même table
***************************************
set more off

use results_estim_2002_sitc2_3_air, clear

save table_3_air_complement, replace



** Ajouter ensuite les autres années


*forvalues z = 2009(1) 2013 {
local year 2002 2009 2010 2012 2013

foreach z in `year' {

use table_3_air_complement, clear
append using results_estim_`z'_sitc2_3_air


save table_3_air_complement, replace
}

** Exporter en excel


use table_3_air_complement
export excel using table_3_air_complement, replace firstrow(varlabels)

