*************************************************
* Programme 6 : Programme pour estimer les déterminants des trade costs - 2d stage

*************************************************
version 12

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


capture program drop reg_FE_h
program reg_FE_h
args preci mode

* exemple : reg_FE 2006 sitc3 3 air
* rod_var "hs hs6 SIC sitc2 sitc3 naics"


use estimTC_bycountry_augmented, clear

egen tt = group(year)
gen nbyear = max(tt)

* on ne retient que la dimension digits / mode 
keep if mode == `mode'
keep if nbdigits ==`preci'

** Exprimer les dépendantes en % du fob price

replace coef_iso_nlI = coef_iso_nlI -1
replace coef_iso_I = coef_iso_I -1

** Génerer les explicatives

* oil price / prix fob = price of a barrel per USD exported
gen oil_perusd_exported = oilprice/prix_fob

* (oil price / prix fob)*dist = price of a barrel per km exported
gen oil_perkm_exported = oil_perusd_exported*dist

* export cost/prox fob = overall cost of export formality, per USD exported
gen formality_perusd_exported = Cost_to_export/prix_fob


** CASE 1: DANS LE CAS SANS ADDITIFS
************************************************


** sans tenir compte de la dimension temporelle

* dans les variables de gravité on ne considère que distance
reg coef_iso_nlI dist formality_perusd_exported oil_perusd_exported oil_perkm_exported oil_perkm_exported*i.year  i.year, robust

/*capture*/	matrix X=e(b)
/*capture*/ matrix ET=e(V)

generate rho_dist_nlI=X[1,1]
generate rho_formality_perusd_exported_nlI=X[1,2]
generate rho_oil_perusd_exported_nlI=X[1,3]
generate rho_oil_perkm_exported_nlI=X[1,4]

forvalues x = 0 (1) nbyear {

* enregistrer le vecteur des beta3
* année de référence 1974 TBC
local z= 1974 +`x'

generate rho_oil_perusd_exported_year_`z'_nlI = X[1,5+`x']
}





generate et_dist_nlI=ET[1,1]^0.5
generate et_formality_perusd_exported_nlI=ET[2,2]^0.5
generate et_oil_perusd_exported_nlI=ET[3,3]^0.5
generate et_oil_perkm_exported_nlI=ET[4,4]^0.5


forvalues x = 0 (1) nbyear {
local z= 1974+`x'
generate et_oil_perusd_exported_year_nlI = X[5+`x',5+`x']
}



** CASE 2: DANS LE CAS AVEC ADDITIFS 
************************************************

* Sur la composante "pays" de terme I



* Sur la composante "pays" de terme A


*sauver les résultats : 1 .dta par mode/degré de précision
keep rho_* et_* preci mode 


save result_NLiso_`preci'_`mode', replace

end

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

