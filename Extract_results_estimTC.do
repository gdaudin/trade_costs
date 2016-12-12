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

*use blouk_2009_sitc2_3_air, clear

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


** Attention il manque min et max dans estimation iceberg / I et A alone

sum terme_iceberg  [fweight=`mode'_val], det 	
gen terme_nlI_min = r(min)
gen terme_nlI_max = r(max)


sum terme_I  [fweight=`mode'_val], det 	
gen terme_I_min = r(min)
gen terme_I_max = r(max)

sum terme_A  [fweight=`mode'_val], det 	
gen terme_A_min = r(min)
gen terme_A_max = r(max)

** Génerer Ecart-type de la régression

local model nlI nlA nl

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



*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save "$dir\3_models\results_estim_`year'_`class'_`preci'_`mode'", replace

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

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save "$dir\3_models\results_estim_`year'_`class'_`preci'_`mode'", replace


end

***********************************
**** SORTIR LES RESULTATS *********

*capture log close
*log using get_table, replace



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost\results
	*global dir \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\results
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost\results
}

cd $dir


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

cd $dir\3_models


* ---------------------------------
*** Pour 3 digits ***
* ---------------------------------

local preci 3


foreach x in air ves {
use results_estim_1974_sitc2_`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années

set more off
local preci 3

foreach x in air  {

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
/*


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

forvalues z = 1977(4)2013 {

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
*/
