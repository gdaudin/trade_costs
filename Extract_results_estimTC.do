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



* nb obs = variable nbr_obs utilisées dans l'estimation
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

** Estimation non-linéaire sur I et A"
	
sum terme_A  [fweight= air_val], det 	
gen terme_A_min = r(min)
gen terme_A_max = r(max)

sum terme_I  [fweight= air_val], det 	
gen terme_I_min=r(min)
gen terme_I_max=r(max)

*** Novembre 2015 : On ajoute le calcul de l'écart-type de la régression ***



gen prediction_nlI = ln(predict_nlI-1)
gen prediction_nl = ln(predict_nl-1)

gen observe = ln(prix_trsp)

gen gap_nlI = (observe - prediction_nlI)^2
gen gap_nl = (observe - prediction_nl)^2

egen sum_gap_nlI = sum(gap_nlI)
egen sum_gap_nl = sum(gap_nl)

gen ecr_nlI = (sum_gap_nlI/(_N-nbr_iso_o -nbr_prod))^0.5
gen ecr_nl = (sum_gap_nl/(_N-nbr_iso_o -nbr_prod))^0.5


# delimit ;
keep nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max terme_I_mp 
	terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nl Rp2_nlI aic_nl aic_nlI logL_nl logL_nlI ecr_nlI ecr_nl;

# delimit cr

keep if _n==1



*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace

** Ajouter informations : Année, mode, degré de classification


gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"

order year digits mode nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min /*
*/ terme_A_max terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nlI Rp2_nl aic_nlI aic_nl logL_nlI logL_nl ecr_nlI ecr_nl

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace


end

***********************************
**** SORTIR LES RESULTATS *********

*capture log close
*log using get_table, replace



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost\results\New_Years
	*global dir \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost\results\New_Years
}

cd $dir


*** 3 digits, all years ***
/*
set more off

local preci 3

foreach x in air ves {

foreach k in `preci' {

forvalues z = 2005(1)2013 {

get_table `z' sitc2 `preci' `x'

*log close

}

}
}

*/

*** 4 digits, new years ***
set more off

local preci 4

foreach x in air ves {

foreach k in `preci' {

*forvalues z = 2005(1)2013 {
foreach z in 1974 1977 1981 1985 1989 1993 1997 2001 {

get_table `z' sitc2 `preci' `x'

*log close

}

}
}

***************************************
*** Step 2 - compiler en une même base
***************************************

cd $dir


* ---------------------------------
*** Pour 3 digits ***
* ---------------------------------
/*
local preci 3


foreach x in air ves {
use results_estim_2005_sitc2_`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années

set more off
local preci 3

foreach x in air ves {

foreach k in `preci' {

forvalues z = 2006(1)2013 {

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
*/


* ---------------------------------
*** Pour 4 digits, new years ***
* ---------------------------------

local preci 4


foreach x in air ves {
use results_estim_1974_sitc2_`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années

set more off
local preci 4

foreach x in air ves {

foreach k in `preci' {

forvalues z = 1977(4)2001 {

use table_`k'_`x', clear
append using results_estim_`z'_sitc2_`k'_`x'

save table_`k'_`x', replace

}
}
}

** Exporter en excel

local preci 4

foreach x in air ves {

foreach k in `preci' {

use table_`k'_`x'
export excel using table_`k'_`x', replace firstrow(varlabels)

}
}


**
