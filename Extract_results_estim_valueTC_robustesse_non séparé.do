version 14.2


** -------------------------------------------------------------
** Programme pour extraire les résultats de l'estimation Etape 1

** Valeur des coûts de transport
** Robustesse à l'hypothèse de non séparabilité

*** ATTENTION, on n'a fait tourner l'estimation QUE SUR LA VERSION avec additifs

** 	Mai 2018 
** -------------------------------------------------------------

version 14

if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Dropbox/trade_cost/results
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:/Users/lpatureau/Dropbox/trade_cost/results
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:/Users/lise/Dropbox/trade_cost/results
}

if "`c(hostname)'" =="LABP112" {
    global dir C:/Users/lpatureau/Dropbox/trade_cost/results
}

cd "$dir"


clear all
set mem 700m
set matsize 8000
set more off
set maxvar 32767


** Programme pour sortir les résultats
* conditionnel à l'année, au mode de transport et à l'exercice (séparé non séparé)


capture program drop get_table

program get_table
args year exo preci mode

dis "year = " `year'
dis "exercice =  `exo'"
* sitc2ns ou sitc2separe
dis "/# digits= " `preci'
dis "mode = `mode'"

use results_estimTC_`year'_`exo'_`preci'_`mode'.dta, clear



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

*local model nlI nlA nl

*foreach x in `model'  {
gen prediction_nl = ln(predict_nl-1)

gen observe = ln(prix_trsp)

gen gap_nl = (observe - prediction_nl)^2

egen sum_gap_nl = sum(gap_nl)

gen ecr_nl = (sum_gap_nl/(_N-nbr_iso_o -nbr_prod))^0.5

drop observe

*}




** Sélection variables d'intérêt
# delimit ;
keep nbr_obs nbr_iso_o nbr_prod 
	terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max 
	terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max 
	Rp2_nl ecr_nl aic_nl logL_nl ;

# delimit cr

keep if _n==1



*save "E:/Lise/BQR_Lille/Hummels/resultats/results_estim_`year'_`class'_`preci'_`mode'", replace
save "$dir/robustesse_non_separe/selected_results_estim_`year'_`exo'_`preci'_`mode'", replace

** Ajouter informations : Année, mode, degré de classification


gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"

# delimit ;
order year digits mode nbr_obs nbr_iso_o nbr_prod  
	terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max 
	terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max 
	Rp2_nl ecr_nl aic_nl ;

# delimit cr

*save "E:/Lise/BQR_Lille/Hummels/resultats/results_estim_`year'_`class'_`preci'_`mode'", replace
save "$dir/robustesse_non_separe/selected_results_estim_`year'_`exo'_`preci'_`mode'", replace


end


***************************************
*** Step 2 - faire tourner et compiler en une même base (par exercice, séparé / non séparé)
***************************************

cd "$dir"

*capture prog drop from_result_to_table
*program from_result_to_table

* ---------------------------------
*** Pour 3 digits SEULEMENT, on ne fait plus de boucle dessus ***
* ---------------------------------


foreach k in sitc2ns sitc2separe {

foreach x in air ves {

get_table 1974 `k' 3 `x'

use "$dir/robustesse_non_separe/selected_results_estim_1974_`k'_3_`x'", clear


save "$dir/robustesse_non_separe/table_`k'_3_`x'", replace

}
}

** Ajouter ensuite les autres années

set more off


foreach k in sitc2ns sitc2separe {

foreach x in air ves {

forvalues z = 1975(1)2013 {

get_table `z' `k' 3 `x'

use "$dir/robustesse_non_separe/table_`k'_3_`x'", clear
append using "$dir/robustesse_non_separe/selected_results_estim_`z'_`k'_3_`x'"

save "$dir/robustesse_non_separe/table_`k'_3_`x'", replace

}
}
}

** Moyenne sur toute la période


foreach x in air ves {

foreach k in sitc2ns sitc2separe {

use "$dir/robustesse_non_separe/table_`k'_3_`x'"

foreach var in terme_A_mp terme_A_med terme_I_mp terme_I_med nbr_iso_o nbr_prod Rp2_nl ecr_nl aic_nl logL_nl {
		egen avg_`var' = mean(`var')
	
}
	
save "$dir/robustesse_non_separe/table_`k'_3_`x'", replace

}
}

	
	

***************************************
*** Step 3 - Synthétiser sur toute la période et extraire dans EXCEL
***************************************

*** Toutes les années

cd "$dir/robustesse_non_separe"

foreach x in air ves {

foreach k in sitc2ns sitc2separe {

* contient toutes les années, par mode et par exercice
use table_`k'_3_`x', clear


*gen mode= "`x'"
gen model = "`k'"
gen nbdigits = 3

keep avg* mode model nbdigits nbr_obs
order mode model nbdigits nbr_obs avg_terme_A_mp avg_terme_A_med avg_terme_I_mp avg_terme_I_med avg_Rp2_nl avg_ecr_nl avg_aic_nl avg_logL_nl
keep if _n==1


* contient la valeur moyenne sur la période, par mode et par exercice
save temp_`k'_3_`x', replace

*export excel using table_`k'_3_`x', replace firstrow(varlabels)

}
}

use temp_sitc2ns_3_air, clear
save table_synthese_robustesse_nonsepare, replace


foreach x in air ves {

foreach k in sitc2ns sitc2separe {

	use table_synthese_robustesse_nonsepare, clear
	append using temp_`k'_3_`x'

	bys mode model: keep if _n==1

	save table_synthese_robustesse_nonsepare, replace

	}
}

export excel using table_synthese_robustesse_nonsepare, replace firstrow(varlabels)

** Effacer tables inutiles


foreach x in ves {

foreach k in sitc2ns sitc2separe {

erase temp_`k'_3_`x'.dta

}
}


***************************************
*** Faire une table avec toutes les années en ns et separé
*** Etudier la corrélation entre part additif en non séparé sur toute la période
*** A peu près ok pour Air mais pas bonne pour Vessel
***************************************

foreach x in air ves {

	use table_sitc2ns_3_`x', clear
	gen model="ns"
	append using table_sitc2separe_3_`x'
	replace model="separé" if model==""
	drop avg*
	generate share_A_mp = terme_A_mp/(terme_A_mp + terme_I_mp-1)
	generate share_A_med = terme_A_med/(terme_A_med + terme_I_med-1)
	keep share* model year
	reshape wide share_A_mp share_A_med, i(year) j(model) string
	*save table_ns&separe_3_`x'.dta, replace
}




***************************************
*** Faire une table avec toutes les années en ns et separé
*** Comparer le trend pour terme_A en séparé / non séparé
*** Idem pour terme_I
***************************************


foreach x in air ves {

	use table_sitc2ns_3_`x', clear
	gen model="ns"
	append using table_sitc2separe_3_`x'
	replace model="separe" if model==""
	
	keep terme_A_mp terme_A_med terme_I_mp terme_I_med model year
	
		
	generate share_A_mp = terme_A_mp/(terme_A_mp + terme_I_mp-1)
	generate share_A_med = terme_A_med/(terme_A_med + terme_I_med-1)

	* In percent of the export price
	foreach k in terme_A_mp terme_A_med {
		replace `k' = 100*`k'
		}
	
	foreach k in terme_I_mp terme_I_med {
		replace `k' = 100*(`k'-1)
		}
	
	reshape wide terme_A_mp terme_A_med terme_I_mp terme_I_med share_A_mp share_A_med, i(year) j(model) string
	

	destring year, replace
	gen t = year - 1973
	*tostring year, replace
	
	foreach k in terme_A terme_I share_A {
	
	foreach z in mp med {
	regress `k'_`z'ns t
	
	
	if "`k'" == "terme_A" local title "Additive term"
	if "`k'" == "terme_I" local title "Multiplicative term"
	if "`x'" == "ves" local modetitle "Vessel"
	if "`x'" == "air" local modetitle "Air"
	
	
	*twoway lfit `k'_mpsepare t || lfit `k'_mpns t, xtitle("Year") ytitle("In % of the fas price") title("`k', `x'") legend(label(1 "Separated FE") label(2 "No separated FE")) 
	
	*scatter terme_A_mpns t || lfit terme_A_mpns t 
	*scatter terme_A_mpsepare t || lfit terme_A_mpsepare t
    *scatter terme_A_mpsepare t || lfit terme_A_mpsepare t || lfit terme_A_mpns t
	
	twoway (lfit `k'_`z'separe year, color(black) lpattern(-))(line `k'_`z'separe year, color(black) ) (lfit `k'_`z'ns year, lpattern(-) color(gs10)) (line `k'_`z'ns year, color(gs10) ) , xtitle("Year") ytitle("In % of the fas price") ///
	title("`title', `modetitle'") legend(on order (2 4) label(1 "Separated FE (trend)") label(2 "Separated FE (baseline)") label(3 "No separated FE (trend)") label(4 "No separated FE")) 
	
	
	
	quietly capture graph export graph_robustesse_ns_`z'_`k'_`x'.pdf, replace
	
	
	
	
	}

	}
	}


	
	
***************************************
*** Faire un graphique pour évaluer la dispersion de la part des additifs
*** Répliquer Figure 3 du papier
*** Pour chaque cas, séparable / non-séparable
***************************************


** Il faut repartir des bases par année car on n'a pas l'information sur la valeur sinon

** On crée une base pour le cas séparable / une base pour le cas non-séparable

*capture program drop creer_estimTC_robustesse
*program creer_estimTC_robustesse

cd "$dir"

foreach exo in sitc2ns sitc2separe {


** Première année, 1974, initialisation de la base

foreach mode in air ves {

	use results_estimTC_1974_`exo'_3_`mode'.dta, clear

	keep product prix_caf prix_fob `mode'_val `mode'_wgt iso_o name terme_I terme_A coef_iso_A coef_iso_I contig-distwces mode 
	rename `mode'_val val
	rename `mode'_wgt wgt
	label var val "Value"
	label var wgt "Weight"
	rename product sector
	

keep if mode =="`mode'"

gen prix_caf_pond = prix_caf*wgt
gen prix_fob_pond = prix_fob*wgt

bys sector iso_o mode : gen nbr_prod=_N

collapse (sum) prix_caf_pond prix_fob_pond val wgt, by(sector iso_o name terme_I terme_A coef_iso_A coef_iso_I contig-distwces mode nbr_prod)

gen prix_caf = prix_caf_pond/wgt
gen prix_fob = prix_fob_pond/wgt

drop prix_caf_pond prix_fob_pond

gen nbdigits = 3
gen year = 1974



** Créer la base de résultats

save "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3_`mode'", replace
* On augmente la base des années ultérieures

*** Les années ultérieures

local liste_year 1975(1)2013

foreach year of numlist `liste_year' {

disp "year = `year'"

	use results_estimTC_`year'_`exo'_3_`mode'.dta, clear

	keep product prix_caf prix_fob `mode'_val `mode'_wgt iso_o name terme_I terme_A coef_iso_A coef_iso_I contig-distwces mode 
	rename `mode'_val val
	rename `mode'_wgt wgt
	label var val "Value"
	label var wgt "Weight"
	rename product sector
	

keep if mode =="`mode'"

gen prix_caf_pond = prix_caf*wgt
gen prix_fob_pond = prix_fob*wgt

bys sector iso_o mode : gen nbr_prod=_N

collapse (sum) prix_caf_pond prix_fob_pond val wgt, by(sector iso_o name terme_I terme_A coef_iso_A coef_iso_I contig-distwces mode nbr_prod)

gen prix_caf = prix_caf_pond/wgt
gen prix_fob = prix_fob_pond/wgt

drop prix_caf_pond prix_fob_pond

gen nbdigits = 3
gen year = `year'

save temp, replace
	use "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3_`mode'", clear
	append using temp, force
	

save "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3_`mode'", replace
sleep 1000

erase temp.dta
}
*log close
}
}

*** Faire une base par modele qui englobe les deux modes

foreach exo in sitc2ns sitc2separe {

use "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3_air"

append using "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3_ves"

save "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3"


foreach mode in air ves {
erase "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3_`mode'.dta"
}
}


*** Corriger de certains "bugs" comme pour estimTC


foreach exo in sitc2ns sitc2separe {

** Bug sur "name" à partir de 2005,jamais renseigné

use "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3", clear

sort iso_o year
foreach x in iso_o {
	forvalues z = 2005(1)2013 {
		replace name = name[_n-1] if iso_o == `x' & year ==`z'
	}
}


save "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3d", replace

** Bug sur "name" à partir de 2011 sur iso_o "SDN"

use "$dir\robustesse_non_separe\estimTC_robustesse_`exo'_3", clear

replace name = "Sudan" if iso_o =="SDN" 
bys iso_o: count if name==""

save "$dir/robustesse_non_separe\estimTC_robustesse_`k'_3'.dta", replace



}




**** Construire le graphique de dispersion de la part des additifs


cd "$dir/robustesse_non_separe"

foreach k in sitc2ns sitc2separe {

use estimTC_robustesse_`k'_3.dta, clear

gen beta =(terme_A)/(terme_A+terme_I-1)
	
label var beta "Share of additive costs"


egen val_tot_year=total(val), by(year mode)
gen share_y_val = round((val/val_tot_year)*100000)

foreach mode in ves air {

	if "`k'" == "sitc2ns" local title "Non separability assumption"
	if "`k'" == "sitc2separe" local title "Separability assumption (baseline)"
	if "`mode'"== "ves" local modetitle "Vessel"
	if "`mode'" == "air" local modetitle "Air"


	
	histogram beta if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) xtitle("Share of additive costs") ytitle("Density") title("`title', `modetitle'")
	graph export Etude_beta_nopond_`k'_`mode'.pdf, replace

	histogram beta [fweight=share_y_val] if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) xtitle("Share of additive costs") ytitle("Density") title("`title', `modetitle'")
	graph export Etude_beta_pond_`k'_`mode'.pdf, replace

}
}

