*version 12
*v1 : vient de Cožts de commerce_v4
*Adaptation aux donnŽes de Hummels
*v2 : reprise 18/2


** Programme pour extraire les résultats
** issus de l'estimation v6 (en niveau), barre à 5% au départ

clear all
set mem 700m
*set matsize 8000
set more off
*set maxvar 32767


cd "E:\Lise\BQR_Lille\data\USdata"
*cd "C:\Echange\trade_costs\database\hummels_db"

**** Le travail sur la BDD est fait ailleurs, dans coûts de commerce_v2.do


***********************************************************************
**** STEP 1. Programme pour décrire la base de données
**** 	Notamment, qqs stats des sur la finesse de la classification
***********************************************************************


capture program drop describe_db
program describe_db
args year class preci mode

use E:\Lise\BQR_Lille\data\USdata\hummels_tra.dta, clear
*use hummels_tra.dta, clear
keep if year==`year'
keep if mode=="`mode'"
rename `class' product
replace product = substr(product,1,`preci')

save temp, replace

** La base au départ, avant d'enlever les queues de distribution

use temp, clear
dis "distrib prix_trsp2 = cif/fob"
codebook prix_trsp2 

dis "nb pays exportateurs"
egen _ = group(iso_o)
sum _
drop _


dis "nb produits"

dis "finesse classification:" `preci'

egen _ = group(product)
sum _
drop _

** Top/Bottom 5% (couts_commerce_vfinal aujourd'hui)
use temp, clear

bys product: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys product: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 

dis "distrib prix_trsp2 if prix_trsp2 >= c_05_prix_trsp2 | prix_trsp2 <= c_95_prix_trsp2 "
codebook prix_trsp2 

dis "nb pays exportateurs"
egen _ = group(iso_o)
sum _
drop _

dis "nb produits"
egen _ = group(product)
sum _
drop _

erase temp.dta

end 


capture log close

log using describe_dbhummels, replace

describe_db 1974 sitc2 3 air


log close


***********************************************************************
**** STEP 2. Etudier les résultats : Tableau de résultats
***********************************************************************

*cd "C:\Documents and Settings\equippe64\Mes documents\Dropbox\trade_cost\Hummels\sauv-07-04-2014"
*cd "C:\Echange\trade_costs\database\hummels_db"

** Attention, on stocke les bases blouk et result_NL_.. dans un dossier \sauv-date
** Ce qui est issu de ces bases, appelé compil_results, est sauvé directement dans le dossier "resultats"

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



dis "******************************"
dis "Estimation NL avec iceberg trade costs ONLY"
sum Rp2_nlI 


dis "Terme iceberg: distribution (moyenne pondérée par `mode'_val)"
sum terme_iceberg  [iweight=`mode'_val]

dis "Terme iceberg: distribution (sans moyenne pondérée)"
sum terme_iceberg

gen terme_nlI_min = r(min)
gen terme_nlI_max = r(max)

dis "******************************"
dis "Estimation non-linéaire"
dis "******************************"

sum Rp2_nl  



dis "Terme A: distribution (moyenne pondérée par `mode'_val)"
sum terme_A  [iweight=`mode'_val]
gen terme_A_min = r(min)
gen terme_A_max = r(max)

dis "Terme A: distribution (sans moyenne pondérée)"
sum terme_A

** nb: on a la valeur moyenne et l'écart-type dans terme_A_mp et terme_A_et resp.

dis "Terme I: distribution (moyenne pondérée par `mode'_val)"
sum terme_I  [iweight=`mode'_val]

dis "Terme I: distribution (sans moyenne pondérée)"
sum terme_I

gen terme_I_min=r(min)
gen terme_I_max=r(max)

keep Rp2_nlI Rp2_nl nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_et terme_A_min terme_A_max terme_I_mp terme_I_et terme_I_min terme_I_max
keep if _n==1

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace


dis "******************************"

dis "Résultats estimation Etape 2"

dis "******************************"

use result_NLiso_`year'_`class'_`preci'_`mode', clear

keep rho_dist_nlI et_dist_nlI rho_dist_I et_dist_I rho_dist_A et_dist_A
keep if _n==1

save temp, replace

*use "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", clear
use results_estim_`year'_`class'_`preci'_`mode', clear

gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"
merge using temp
drop _merge



order year digits mode nbr_obs nbr_iso_o nbr_prod Rp2_nlI terme_nlI_mp terme_nlI_et terme_nlI_min terme_nlI_max Rp2_nl terme_A_mp terme_A_et terme_A_min /*
*/ terme_A_max terme_I_mp terme_I_et terme_I_min terme_I_max rho_dist_nlI et_dist_nlI rho_dist_I et_dist_I rho_dist_A et_dist_A

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace

erase temp.dta

end

***********************************
**** SORTIR LES RESULTATS *********

*capture log close
*log using get_table, replace

*** 3 digits, all years ***

*cd "E:\Lise\BQR_Lille\Hummels\resultats\sauv-07-04-2014"

cd "E:\Lise\BQR_Lille\Hummels\resultats"

set more off
local mode air
local preci 3

* pour test

local z 2004
local x sitc2

get_table `z' `x' `preci' `mode'



foreach x in `mode' {

foreach k in `preci' {

forvalues z = 2004(-1)1974 {

*local year = `z'

*capture log close
*log using results_`z'_`k'_`x', replace

get_table `z' sitc2 `preci' `mode'

*log close

}

}
}



*** 4 digits, all 5 years, 1974-79-84-89-94-99-2004 ***

cd "E:\Lise\BQR_Lille\Hummels\resultats\sauv-09-04-2014_4digits"

set more off

local preci 4


foreach x in ves  {

foreach k in `preci' {

forvalues z = 2004(-5)1974 {

*local year = `z'

*capture log close
*log using results_`z'_`k'_`x', replace

get_table `z' sitc2 `preci' `x'

*log close

}

}
}
***************************************
*** Step 2 - compiler en une même base
***************************************


cd "E:\Lise\BQR_Lille\Hummels\resultats"

cd "C:\Echange\trade_costs\database\hummels_db" 
*****************************************************
** Attention pas les mêmes années pour 3 et 4 digits
*****************************************************

* ---------------------------------
*** Pour 3 digits ***
* ---------------------------------

local preci 3

foreach x in air {
use results_estim_1974_sitc2_`preci'_`x', clear

save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années
set more off
local preci 3

foreach x in air {

foreach k in `preci' {

forvalues z = 1975(1)2004 {

use table_`k'_`x', clear
append using results_estim_`z'_sitc2_`k'_`x'

save table_`k'_`x', replace

}
}
}

** Exporter en excel
local preci 3

foreach x in air {

foreach k in `preci' {

use table_`k'_`x'
export excel using table_`k'_`x', replace firstrow(varlabels)

}
}


* ---------------------------------
*** Pour 4 digits ***
* ---------------------------------

local preci 4

foreach x in air ves {
use results_1974_sitc2_`preci'_`x', clear

save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années


local preci 4
foreach x in ves  {

foreach k in `preci' {

forvalues z = 1979(5)2004 {


use table_`k'_`x', clear
append using results_`z'_sitc2_`k'_`x'

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




*************************************************
*** STEP 3. Exploitation graphique des résultats
*************************************************

cd "E:\Lise\BQR_Lille\Hummels\resultats\sauv-07-04-2014"

capture program drop exploiterblouk

program exploiterblouk
args interet
**eg exploiterblouk 2004_sitc2_5_air


use "E:\Lise\BQR_Lille\Hummels\resultats\sauv-07-04-2014\blouk_`interet'.dta", clear

*histogram terme_A, bin(100) kdensity


quietly summarize terme_A, det
generate terme_A_born = terme_A if terme_A > r(p1) & terme_A < r(p99)
histogram terme_A_born, bin(100) kdensity
graph export 98_terme_A_`interet'.png, replace

quietly summarize terme_I, det
generate terme_I_born = terme_I if terme_I > r(p1) & terme_I < r(p99)
histogram terme_I_born, bin(100) kdensity
graph export 98_terme_I_`interet'.png, replace

generate product_1d = substr(product,1,1)
histogram terme_A_born, bin(100) kdensity by(product_1d)
graph export byprod_terme_A_`interet'.png, replace

histogram terme_I_born, bin(100) kdensity by(product_1d)
graph export byprod_terme_I_`interet'.png, replace

end

exploiterblouk 2004_sitc2_3_air
exploiterblouk 2003_sitc2_3_air


*************************************************
*** STEP 4. Différents tests
*************************************************


cd "C:\Echange\trade_costs\database\hummels_db" 

use blouk_2004_sitc2_3_air, clear


pwcorr  prix_trsp2 predict, sig

/*             | prix_t~2  predict

     predict |   0.6634   1.0000 
             |   0.0000
*/

*corrélation avec predict (en niveau), I seulement
pwcorr prix_trsp2 predict_nlI, sig

/*

 predict_nlI |   0.5855   1.0000 
             |   0.0000

*/
