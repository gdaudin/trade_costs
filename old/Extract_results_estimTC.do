version 14.2


** -------------------------------------------------------------
** Programme pour extraire les résultats de l'estimation Etape 1

** Valeur des coûts de transport
** issus de l'estimation v10, barre à 5% au départ

** 	Septembre 2015 
** -------------------------------------------------------------


*Deux programmes : le premier prends les blouk et fait des résultats. Le 2e prend les résultats et fait une table


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local/results
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost/results
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost/results
}

if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost\results
}

cd "$dir"


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

use "$dir//results_estimTC_`year'_`class'_`preci'_`mode'.dta", clear

*use results_estimTC_2009_sitc2_3_air, clear

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


** Génerer Ecart-type de la régression

local model nl

foreach x in `model'  {
gen prediction_`x' = ln(predict_`x'-1)

gen observe = ln(prix_trsp)

gen gap_`x' = (observe - prediction_`x')^2

egen sum_gap_`x' = sum(gap_`x')

gen ecr_`x' = (sum_gap_`x'/(_N-nbr_iso_o -nbr_prod))^0.5

drop observe

}




** Sélection variables d'intérêt
# delimit ;
keep nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max 
	terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max 
	terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max 
	terme_nlA_mp terme_nlA_med terme_nlA_et terme_nlA_min terme_nlA_max 
	Rp2_nlI Rp2_nlA Rp2_nl ecr_nlI ecr_nlA ecr_nl aic_nlI aic_nlA aic_nl logL_nlI logL_nlA logL_nl ;

# delimit cr

keep if _n==1



*save "E:\Lise\BQR_Lille\Hummels\resultats\extract_results_estimTC_`year'_`class'_`preci'_`mode'", replace
save "$dir\3_models\extract_results_estimTC_`year'_`class'_`preci'_`mode'", replace

** Ajouter informations : Année, mode, degré de classification


gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"

# delimit ;
order year digits mode nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max 
	terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max 
	terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max 
	terme_nlA_mp terme_nlA_med terme_nlA_et terme_nlA_min terme_nlA_max 
	Rp2_nlI Rp2_nlA Rp2_nl ecr_nlI ecr_nlA ecr_nl aic_nlI aic_nlA aic_nl logL_nlI logL_nlA logL_nl ;

# delimit cr

*save "E:\Lise\BQR_Lille\Hummels\resultats\extract_results_estimTC_`year'_`class'_`preci'_`mode'", replace
save "$dir\3_models\extract_results_estimTC_`year'_`class'_`preci'_`mode'", replace


end


/*


*** 4 digits, new years ***
set more off

local preci 4

foreach x in air ves {

foreach k in `preci' {

*forvalues z = 2005(1)2013 {
foreach z in 1974 1977 1981 1985 1989 1993 1997 2001 2005 2009 2013 {

get_table `z' sitc2 `preci' `x'

*log close

}

}
}
*/

***************************************
*** Step 2 - compiler en une même base
***************************************


capture prog drop from_result_to_table
program from_result_to_table



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/results
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost/results
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost/results
}

cd "$dir"



cd "$dir/3_models"


* ---------------------------------
*** Pour 3 digits ***
* ---------------------------------

local preci 3


foreach x in air ves {
use extract_results_estimTC_1974_sitc2_`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années

set more off
local preci 3

foreach x in air ves {

foreach k in `preci' {

forvalues z = 1975(1)2013 {

use table_`k'_`x', clear
append using extract_results_estimTC_`z'_sitc2_`k'_`x'

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
/*


* ---------------------------------
*** Pour 4 digits, new years ***
* ---------------------------------

local preci 4


foreach x in air ves {
use extract_results_estimTC_1974_sitc2_`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années

set more off
local preci 4

foreach x in air ves {

foreach k in `preci' {

forvalues z = 1977(4)2013 {

use table_`k'_`x', clear
append using extract_results_estimTC_`z'_sitc2_`k'_`x'

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
*/

end


***************

***********************************
**** SORTIR LES RESULTATS des blouks*********
/*
*capture log close
*log using get_table, replace




*** 3 digits, all years ***

set more off

local preci 3

foreach x in air ves {

foreach k in `preci' {

forvalues z = 1974(1)2013 {

get_table `z' sitc2 `preci' `x'

*log close

}

}
}
*/



************Passer des results aux tables
from_result_to_table
