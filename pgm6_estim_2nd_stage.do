*************************************************
* Programme 6 : Programme pour estimer les déterminants des trade costs - 2d stage

*************************************************


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if "`c(hostname)'" =="MacBook-Pro-Lysandre.local" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox/trade_cost
}


	 
	 
** charger la base de données

cd $dir/results

/*
capture program drop reg_FE_h
program reg_FE_h
args preci mode
*/

*pour test du pgm 

** 3 digits, air ***


local mode air
local preci 3


* exemple : reg_FE 2006 sitc3 3 air
* rod_var "hs hs6 SIC sitc2 sitc3 naics"


use estimTC_bycountry_augmented, clear



* on ne retient que la dimension digits / mode 
keep if mode == "`mode'"
keep if nbdigits ==`preci'

** La variable "cost_to-export" n'est renseignée qu'à partir de 2004, dans la benchmark regression on ne regarde que sur 2004-2013

keep if year>=2004

egen tt = group(year)
egen tt1 = max(tt)

local nb_year = tt1 -1

egen year_start = min(year)

** Exprimer les dépendantes en % du fob price

replace coef_iso_nlI = coef_iso_nlI -1
replace coef_iso_I = coef_iso_I -1

** Génerer les explicatives

* oil price / prix fob = price of a barrel per USD exported
* attention on divise par le prix fob moyen par pays/ année (en moyenne sur les produits)
gen oil_perusd_exported = oilprice/prix_fob_mp

* (oil price / prix fob)*dist = price of a barrel per km exported
gen oil_perkm_exported = oil_perusd_exported*dist

* export cost/prox fob = overall cost of export formality, per USD exported
* attention on divise par le prix fob moyen par pays/ année (en moyenne sur les produits)
gen formality_perusd_exported = Cost_to_export/prix_fob_mp


forvalues x = 0(1)`nb_year' {
local z= year_start +`x'
gen yearFE_`z' = 0 
replace yearFE_`z' = 1 if year== `z'

gen oil_perkm_exported_yearFE_`z' = oil_perkm_exported*yearFE_`z'

drop yearFE*
}

preserve

** CASE 1: DANS LE CAS SANS ADDITIFS
************************************************


** sans tenir compte de la dimension temporelle

* dans les variables de gravité on ne considère que distance
*reg coef_iso_nlI dist formality_perusd_exported oil_perusd_exported oil_perkm_exported oil_perkm_exported*i.year  i.year, robust

local start = year_start
reg coef_iso_nlI dist oil_perusd_exported oil_perkm_exported oil_perkm_exported_yearFE_`start'-oil_perkm_exported_yearFE_2013  i.year [iweight=val_tot]

/*capture*/	matrix X=e(b)
/*capture*/ matrix ET=e(V)

generate rho_dist_nlI=X[1,1]
generate rho_formality_nlI=X[1,2]
generate rho_oil_perusd_nlI=X[1,3]
generate rho_oil_perkm_nlI=X[1,4]

forvalues x = 0(1)`nb_year' {

* enregistrer le vecteur des beta3
* année de référence 1974 TBC
local z= year_start +`x'

generate rho_oil_perkm_year`z'_nlI = X[1,5+`x']
}





generate et_dist_nlI=ET[1,1]^0.5
generate et_formality_nlI=ET[2,2]^0.5
generate et_oil_perusd_nlI=ET[3,3]^0.5
generate et_oil_perkm_nlI=ET[4,4]^0.5


forvalues x = 0(1)`nb_year' {

local z= year_start +`x'
generate et_oil_perkm_year`z'_nlI = ET[5+`x',5+`x']^0.5

}



** CASE 2: DANS LE CAS AVEC ADDITIFS 
************************************************

* Sur la composante "pays" de terme I



* Sur la composante "pays" de terme A


*sauver les résultats : 1 .dta par mode/degré de précision
keep rho_* et_* nbdigits mode 
keep if _n==1

save result_NLiso_`preci'_`mode', replace

end


break

*** Lancer le programme d'estimation de la 2e étape

set more off
local mode air
local preci 3

foreach x in `mode' {
foreach k in `preci' {

capture log close
log using 2dstage_`k'_`x', replace

reg_FE_h `k' `x'

}
}

