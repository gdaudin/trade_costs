*************************************************
* Programme : Avoir qqs stats des sur la base de données
* 
*************************************************

version 14.1


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost
}

cd $dir


***************************************************************
** Question endogénéité tau ik, t ik et prix fob

use $dir/data/hummels_tra, clear

gen sitc2_3d = substr(sitc2,1,3)

bys year sitc2_3d mode country: gen nb_par_sitc2_c_y_m = _N
sum nb_par_sitc2_c_y_m, det
gen val=air_val+ves_val
sum nb_par_sitc2_c_y_m [fw=val], det

bys year sitc2_3d mode country: keep if _n==1

sum nb_par_sitc2_c_y_m, det


** En moyenne, chaque observation a 182 co-obs dans la même catg sitc2 3d, pays, mode, année
** En moyenne, chaque dollar importé a 143 obs au sein d'une catg

** Autres éléments d'info:
** Par catg sitc2 à digits, pays, mode, année : 4 observations


* Si on supprime la dimension pays

use $dir/data/hummels_tra, clear

gen sitc2_3d = substr(sitc2,1,3)

bys year sitc2_3d mode: gen nb_par_sitc2_y_m = _N
sum nb_par_sitc2_y_m, det
gen val=air_val+ves_val
sum nb_par_sitc2_y_m [fw=val], det

bys year sitc2_3d mode : keep if _n==1

sum nb_par_sitc2_y_m, det


** En moyenne, chaque observation a 255 co-obs dans la même catg sitc2 3d, mode, année
** En moyenne, chaque dollar importé a 320 obs au sein d'une catg sitc2 3d, mode, année

*** Répond à la question de l'endogénéité entre tauik, til et prix fob ik

* Mettre en avant hétérogénéité des termes A et I entre pays d'origine / entre secteurs

* Stats des dans la dimension secteur
local stats mean median sd min max
local dim sector country

foreach x in `stats' {
	foreach y in `dim' {
	
	use "$dir/results/estimTC.dta", clear

rename iso_o country
		collapse (`x') terme_A terme_I terme_iceberg [fweight= val], by(`y')
		
		foreach type in terme_A terme_I terme_iceberg {
		 rename `type' `type'_`x'_`y'
		}
		
		collapse terme_A_`x'_`y' terme_I_`x'_`y' terme_iceberg_`x'_`y'
		
		save $dir\results\stats_des\temp_`x'_`y', replace

}
}


*
* Compiler

cd $dir\results\stats_des

use temp_mean_sector, clear

merge using temp_mean_country
drop _merge

save base_statsdes_bycountry_byproduct, replace


local stats median sd min max
local dim sector country

foreach x in `stats' {
foreach y in `dim' {


	use base_statsdes_bycountry_byproduct, clear
	merge using temp_`x'_`y'
	drop _merge

save base_statsdes_bycountry_byproduct, replace


}
}

use base_statsdes_bycountry_byproduct, clear

export excel using base_statsdes_bycountry_byproduct, firstrow(variables) replace


********************************************************************
*** Faire un programme qui calcule l'écart cif-fob observé / prédit*** 
*** De même que le prix fob et le cout additif en monetaire


use "$dir/results/estimTC.dta", clear
save "$dir/results/estimTC_3d.dta", replace

capture program drop stats_des
program stats_des
	args year mode classif


*local db 3d 4d

foreach k in `classif' {
use "$dir/results/estimTC_`k'.dta", clear

* Base qui synthétise les résultats des estimations sur 3 digits, en intégrant en plus les variables observées

keep if year==`year'
keep if mode=="`mode'"

gen prix_trsp = prix_caf/prix_fob -1
gen termeAetI = terme_A+terme_I-1
gen termeiceberg = terme_iceberg -1
gen addcost= terme_A*prix_fob

local type prix_trsp termeAetI termeiceberg

foreach i of local type {
	gen ln`i' = log(`i')
}
	


local type prix_trsp prix_fob addcost terme_A terme_I termeAetI termeiceberg lnprix_trsp lntermeAetI lntermeiceberg 
keep `type' year mode val

foreach x in `type' {

	quietly sum `x'  [fweight= val], det
	generate mp_`x' = r(mean)
	generate med_`x' = r(p50)
	generate et_`x' = r(sd)
	generate min_`x' = r(min)
	generate max_`x' = r(max)

	
	quietly sum `x', det
	generate uwm_`x' = r(mean)
	generate uwmed_`x'= r(p50)
	
}

keep year mode mp* med* et* min* max* uwm* 

keep if _n ==1


save "$dir/results/describe_db_`year'_`mode'_`k'", replace 

}


end

******************************
*** Lancer le programme, sur 3 digits et 4 digits

set more off
local mode ves air 
local classif 3d 4d


foreach x in `mode' {
	foreach k in `classif' {

		*foreach z of num 1974(1)2013 {
		foreach z of num 1974  {
				
		stats_des `z' `x' `k'
		
		}
	}
}








** Compiler les résultats sur toutes les années

cd $dir/results/

* Première année 1974
set more off
local mode ves air
local classif 3d 4d

foreach x in `mode' {

	foreach z in `classif' {
		use describe_db_1974_`x'_`z', clear
	
	
		save compil_describedb_`x'_`z', replace
	
	}
}

* Les années ultérieures


foreach x in `mode' {
foreach k in `classif' {

	foreach z of num 1975(1)2013 {
	
		use compil_describedb_`x'_`k', clear
		append using describe_db_`z'_`x'_`k'
		
		save compil_describedb_`x'_`k', replace
	
	}
}
}

** Exploiter la base de données

local mode ves air
local classif 3d 4d

foreach x in `mode' {
foreach k in `classif' {

	use compil_describedb_`x'_`k', clear
	
	display "Mode de transport = `x'" 
	
		*foreach  y of varlist prix_trsp* termeAetI* termeiceberg* prix_fob* addcost* lnprix_trsp* lntermeAetI* lntermeiceberg* {
		foreach  y of varlist mp* med* et* min* max* uwm* {
		
		quietly sum `y'
		generate avg_`y' = r(mean)
		
		
		}
		
	keep mode year avg*
	* Pour fusionner avec base par année
	replace year = .
	keep if _n==1
	
	
	save meanperiod_describedb_`x'_`k', replace
	}
	
}





* Synthèse pour Table 1

local mode ves air
local classif 3d 4d

foreach x in `mode' {
foreach k in `classif' {

use meanperiod_describedb_`x'_`k', clear

gen sitc2 = "`k'"

#delimit ;
keep mode sitc2 avg_mp_prix_trsp avg_med_prix_trsp avg_mp_termeiceberg avg_med_termeiceberg 
		avg_mp_terme_A avg_med_terme_A avg_mp_terme_I avg_med_terme_I 
		avg_uwm_prix_trsp avg_uwm_termeiceberg avg_uwm_terme_A avg_uwm_terme_I avg_uwm_prix_fob avg_uwm_addcost
		avg_uwmed_prix_trsp avg_uwmed_termeiceberg avg_uwmed_terme_A avg_uwmed_terme_I 
		avg_mp_prix_fob avg_med_prix_fob avg_uwm_prix_fob avg_uwmed_prix_fob   
		avg_mp_addcost avg_med_addcost avg_uwm_addcost avg_uwmed_addcost ;


order sitc2 mode avg_uwm_termeiceberg avg_uwmed_termeiceberg avg_mp_termeiceberg avg_med_termeiceberg 
		avg_uwm_terme_I avg_uwmed_terme_I avg_mp_terme_I avg_med_terme_I 
		avg_uwm_terme_A avg_uwmed_terme_A avg_mp_terme_A avg_med_terme_A 
		avg_uwm_addcost avg_uwmed_addcost avg_mp_addcost avg_med_addcost 
		avg_uwm_prix_trsp avg_uwmed_prix_trsp avg_mp_prix_trsp avg_med_prix_trsp 
		avg_uwm_prix_trsp avg_uwmed_prix_trsp avg_mp_prix_fob avg_med_prix_fob ;

#delimit cr

save temp_`x'_`k', replace
}
}

use temp_ves_3d, clear
append using temp_air_3d
append using temp_ves_4d
append using temp_air_4d

local type mp med uwm uwmed

foreach x in `type' {

replace avg_`x'_termeiceberg = 100*avg_`x'_termeiceberg
replace avg_`x'_terme_I = 100*(avg_`x'_terme_I-1)
replace avg_`x'_terme_A = 100*avg_`x'_terme_A
replace avg_`x'_prix_trsp = 100*avg_`x'_prix_trsp

foreach z in termeiceberg terme_I terme_A prix_trsp prix_fob addcost {

rename avg_`x'_`z' `x'_`z' 
}

}

save Tab1_estimationresults, replace
export excel using Tab1_estimationresults, firstrow(variables) replace

**** Avoir les résultats pour 2004 pour comparaison avec Irarrazabal et al.

local mode air ves
local classif 3d  

foreach x in `mode' {
foreach k in `classif' {

use describe_db_2004_`x'_`k', clear

gen sitc2 = "`k'"

#delimit ;
keep mode year sitc2 mp_prix_trsp med_prix_trsp uwm_prix_trsp uwmed_prix_trsp mp_prix_fob med_prix_fob uwm_prix_fob uwmed_prix_fob 
	mp_addcost med_addcost uwm_addcost uwmed_addcost mp_terme_A med_terme_A uwm_terme_A uwmed_terme_A 
	mp_terme_I med_terme_I uwm_terme_I uwmed_terme_I mp_termeiceberg med_termeiceberg uwm_termeiceberg uwmed_termeiceberg ;
	
#delimit cr
save temp2004_`x'_`k', replace

}
}

use temp2004_ves_3d, clear

append using temp2004_air_3d


save results_2004, replace

use results_2004, clear
export excel using results_2004, firstrow(variables) replace

* Eliminer bases temporaires

local mode air ves
local classif 3d 4d 

foreach x in `mode' {
foreach k in `classif' {

	foreach z of num 1974(1)2013 {
	erase describe_db_`z'_`x'_`k'.dta

	}
}
}


foreach x in `mode' {
foreach k in `classif' {

	erase temp_`x'_`k'.dta
	erase temp2004_`x'_`k'.dta

}
}

erase estimTC_3d.dta
