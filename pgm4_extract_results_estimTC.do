*version 12


** -------------------------------------------------------------
** Programme pour extraire les résultats de l'estimation Etape 1

** Valeur des coûts de transport
** issus de l'estimation v10, barre à 5% au départ

** 	Septembre 2015 
** -------------------------------------------------------------

clear all
set mem 700m
*set matsize 8000
set more off
*set maxvar 32767


** Programme pour sortir les résultats
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

*** S'assurer que le calcul du R2 sur estimation additif & iceberg est le bon

drop Rp2_nl

* R2 sur estimpation nl iceberg set additifs
correlate ln_ratio_minus1 blink_nl
generate Rp2_nl = r(rho)^2


** Estimation NL avec iceberg trade costs ONLY"
sum terme_iceberg  [fweight= air_val], det 
gen terme_nlI_min = r(min)
gen terme_nlI_max = r(max)

** Estimation non-linéaire"

	
sum terme_A  [fweight= air_val], det 	
gen terme_A_min = r(min)
gen terme_A_max = r(max)

sum terme_I  [fweight= air_val], det 	
gen terme_I_min=r(min)
gen terme_I_max=r(max)


# delimit ;
keep nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max terme_I_mp 
	terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nl Rp2_nlI aic_nl aic_nlI logL_nl logL_nlI;

# delimit cr

keep if _n==1



*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace

** Ajouter informations : Année, mode, degré de classification


gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"

order year digits mode nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min /*
*/ terme_A_max terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nlI Rp2_nl aic_nlI aic_nl logL_nlI logL_nl

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace


end

***********************************
**** SORTIR LES RESULTATS *********

*capture log close
*log using get_table, replace

*** 3 digits, all years ***


* sur le serveur
cd "C:\Echange\trade_costs\results"

* sur fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\resultats\results_v10\vessel_3d"

** Fait sur le serveur 28/08/2015

set more off
local mode ves air
local preci 3

foreach x in `mode' {

foreach k in `preci' {

forvalues z = 2013(-1)1974 {

get_table `z' sitc2 `preci' `mode'

*log close

}

}
}



***************************************
*** Step 2 - compiler en une même base
***************************************


* sur le serveur
cd "C:\Echange\trade_costs\results"

* sur fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\resultats\results_v10\vessel_3d"

* ---------------------------------
*** Pour 3 digits ***
* ---------------------------------

local preci 3

foreach x in ves air {
use results_estim_1974_sitc2_`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années

set more off
local preci 3

foreach x in air ves {

foreach k in `preci' {

forvalues z = 1975(1)2013 {

use table_`k'_`x', clear
append using results_estim_`z'_sitc2_`k'_`x'

save table_`k'_`x', replace

}
}
}

** Exporter en excel

local preci 3

foreach x in air ves {

foreach k in `preci' {

use table_`k'_`x'
export excel using table_`k'_`x', replace firstrow(varlabels)

}
}


**
