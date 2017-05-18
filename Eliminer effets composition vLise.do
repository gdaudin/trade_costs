***************************************************************************

* ---------- Programme pour reconstruire les coûts de commerce
* ---------- estimés "overall" et "pure", en base 100 en 1974 tous les deux

* Mai 2017: Construire la somme des deux termes IetA, overall et purs

****************************************************************************



version 14.1


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

cd $dir/results/

** On part sur estimation en 3 digits ***

capture program drop compare_trends_inTC
program compare_trends_inTC
	args year mode sitc


use "estimTC.dta", clear

keep if year==`year'
keep if mode=="`mode'"


foreach secteur in 0(1)9 {
	if "`sitc'"=="`secteur'" keep if substr(sector,1,1)=="`sitc'"
}

if "`sitc'"=="primary" keep if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68"
	
	
	
	
if "`sitc'"=="manuf" drop if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68" | substr(sector,1,1)=="9"
	

gen prix_trsp = prix_caf/prix_fob -1
replace terme_I = terme_I-1

gen terme_AetI = terme_A+terme_I-1
*gen termeiceberg = terme_iceberg -1


local type prix_trsp terme_I terme_A terme_AetI /*termeiceberg */
keep `type' year mode val

foreach x in `type' {

	quietly sum `x'  [fweight= val], det
	generate `x'_mp = r(mean)
	generate `x'_med = r(p50)
		
}



keep year mode prix_trsp_mp terme_I_mp terme_A_mp terme_AetI_mp /* termeiceberg_mp prix_trsp_med termeAetI_med termeiceberg_med */
rename prix_trsp_mp terme_obs_mp
keep if _n ==1

save "temp_`year'_`mode'_`sitc'", replace 


end

********************************

** Compiler les résultats sur toutes les années



capture program drop compilation_effets_compositions
program compilation_effets_compositions
args sitc
* expl : compilation_effets_compositions 6


set more off
local mode ves air



foreach x in `mode' {

	use temp_1974_`x'_`sitc', clear
	
	
	save compil_results_`x'_`sitc', replace
	erase temp_1974_`x'_`sitc'.dta
	
}

* Les années ultérieures


foreach x in `mode' {

	foreach z of num 1975(1)2013 {
	
		use compil_results_`x'_`sitc', clear
		append using temp_`z'_`x'_`sitc'
		
		save compil_results_`x'_`sitc', replace
		erase temp_`z'_`x'_`sitc'.dta
	
	}

}

* Fusionner les deux bases (air, vessel)
* Cette base contient le cout de transport (observé, estimé nlI, estimé I&A) moyen et médian par année et par mode de transport
* Le prix moyen et médian: calcul pondéré par la valeur du flux

use compil_results_air_`sitc', clear

append using compil_results_ves_`sitc'

save compil_results_`sitc', replace

erase compil_results_air_`sitc'.dta
erase compil_results_ves_`sitc'.dta

use compil_results_`sitc', clear

local type terme_obs terme_A terme_I terme_AetI


foreach z in `type' {
	
	rename `z'_mp `z'
	

}



*reshape wide prix_trsp termeAetI termeiceberg, i(year) j(mode) string
reshape wide terme_obs terme_A terme_I terme_AetI, i(year) j(mode) string

local type terme_obs terme_A terme_I terme_AetI
local mode air ves

foreach z in `type' {
	foreach x in `mode' {
	rename `z'`x' `z'_overall_`x'
	
}
}


save compil_results_`sitc', replace

*** Etape : Construire les variables de TC "overall" pour avoir 100 en 1974

use compil_results_`sitc', clear
sort year

local type terme_obs terme_A terme_I terme_AetI
local mode air ves


foreach x in `type' {
	foreach z in `mode'{

	gen ref_`x'_`z' = `x'_overall_`z'[1]
	replace `x'_overall_`z' = 100*`x'_overall_`z'/ref_`x'_`z'

}
}

drop ref*

save compil_results_`sitc', replace


*** Etape suivante : Y ajouter l'estimation des coûts de transport composition effects excluded


use "$dir/resultats_finaux/database_pureTC_`sitc'", clear

count
keep year terme_A_air_mp terme_A_ves_mp terme_I_air_mp terme_I_ves_mp terme_AetI_air_mp terme_AetI_ves_mp terme_obs_air_mp terme_obs_ves_mp 

local type terme_A terme_I terme_AetI terme_obs
local mode air ves

foreach z in `type' {
	foreach x in `mode' {
	
			rename `z'_`x'_mp `z'_pure_`x'
	}
}


sort year

save temp, replace

use "$dir/results/compil_results_`sitc'", clear

sort year
merge 1:1 year using temp

keep if _merge==3
drop _merge

order year terme_obs* terme_A* terme_I*

save compil_results_`sitc', replace


* Exporter sous excel

use compil_results_`sitc', clear
keep year terme*


export excel using table_moreon_effetscomposition_`sitc', replace firstrow(var)

*** Comparer les purs TC entre transport mode, selon qu'effets de composition élevés ou pas
*** Cf discussion de Hummels, les TC ont-ils plus baissé dans l'aérien que dans le vessel?

* Mai 2017, laisser de côté l'écart cif-fob observé

local type terme_A terme_I terme_AetI /* terme_obs */
local mode air ves
*capture rename terme_iceberg* termeiceberg*
 

foreach z in `type' {
	foreach x in `mode' {
		replace `z'_pure_`x' = . if `z'_pure_`x' > 200
*		label var `z'_pure_`x' "TC `z'_`x' hors effets de composition"
		
		if "`z'"== "terme_AetI" & "`x'"== "air" label var `z'_overall_`x' "(a) Total transport costs, Air"
		if "`z'"== "terme_AetI" & "`x'"== "ves" label var `z'_overall_`x' "(a) Total transport costs, Ocean"
		if "`z'"== "terme_I" label var `z'_overall_`x' "(b) Multiplicative transport costs, `x'"
		if "`z'"== "terme_A" label var `z'_overall_`x' "(c) Additive transport costs, `x'"
		
		if "`z'"== "terme_AetI" & "`x'"== "air" local title_graph  "(a) Total transport costs, Air"
		if "`z'"== "terme_AetI" & "`x'"== "ves" local title_graph  "(a) Total transport costs, Ocean"
		
		if "`z'"== "terme_A" & "`x'"== "air" local title_graph  "(c) Additive transport costs, Air"
		if "`z'"== "terme_A" & "`x'"== "ves" local title_graph  "(c) Additive transport costs, Ocean"
		
		if "`z'"== "terme_I" & "`x'"== "air" local title_graph  "(b) Multiplicative transport costs, Air"
		if "`z'"== "terme_I" & "`x'"== "ves" local title_graph  "(b) Multiplicative transport costs, Ocean"
		
		label var `z'_pure_`x' "idem, corrected for composition"
	
		replace `z'_overall_`x' = . if `z'_overall_`x' > 200

		if "`sitc'"!="all" twoway (line `z'_overall_`x' year) (line `z'_pure_`x' year) , ///
				name(`z'_`x', replace) nodraw legend(label(1 "Transport cost") label(2 "Composition effects excluded") row(1) size(vsmall)) ///
				title("`title_graph'", size(small)) ///
				yscale(range(0 200)) ylabel(0(50)200, angle(horizontal) labsize(vsmall))
		if "`sitc'"=="all" twoway (line `z'_overall_`x' year) (line `z'_pure_`x' year) , ///
				name(`z'_`x', replace) nodraw legend(label(1 "Transport cost") label(2 "Composition effects excluded") row(1) size(vsmall)) ///
				title("`title_graph'", size (small)) ///
				yscale(range(0 125)) ylabel(0(25)125, angle(horizontal) labsize(vsmall))
	}
}

if "`sitc'"=="all" grc1leg terme_obs_air terme_obs_ves terme_I_air terme_I_ves terme_A_air terme_A_ves, cols(2) title("Goods: All", size(small)) 
if "`sitc'"=="primary" grc1leg terme_obs_air terme_obs_ves terme_I_air terme_I_ves terme_A_air terme_A_ves, cols(2) title("Goods: Primary", size(small)) 
if "`sitc'"=="manuf" grc1leg terme_obs_air terme_obs_ves terme_I_air terme_I_ves terme_A_air terme_A_ves, cols(2) title("Goods: Manufacturing", size(small)) 
graph save "$dir/resultats_finaux/graph_composition_`sitc'", replace
graph export "$dir/resultats_finaux/graph_composition_`sitc'.pdf", replace


erase temp.dta 

end

*****************************************************


set more off
local mode ves air
local sitc all
foreach sitc in primary manuf all  {
	foreach x in `mode' {
		*foreach z in `year' {
			foreach z of num 1974(1)2013 {	
			compare_trends_inTC `z' `x' `sitc'
		}
	}
	compilation_effets_compositions `sitc'	
}




foreach sitc of num 0 1 2 3 4 5 6 7 8 9 {
	foreach x in `mode' {
		*foreach z in `year' {
			foreach z of num 1974(1)2013 {
			compare_trends_inTC `z' `x' `sitc'
		}
	}
	compilation_effets_compositions `sitc'	
}


