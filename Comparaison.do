*** Programme de comparaison des résultats entre notre façon d'estimer les transport costs, et celle proposée par le référé 1
*** Étendu à d’autres comparaisons
*** Juillet 2020



if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaisons_various"
	global dir_temp ~/Downloads/temp_stata
	global dir_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results"
	global dir_redaction  "~/Répertoires Git/trade_costs_git/redaction/JEGeo/revision_JEGeo/revised_article"
	
	
}


*** Juillet 2020: Lise, tout sur mon OneDrive


/* Fixe Lise P112*/
if "`c(hostname)'" =="LAB0271A" {
	 

	* baseline results sur hummels_tra dans son intégralité
    global dir_baseline_results "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\baseline"
	
		
	* résultats selon méthode référé 1
	global dir_referee1 "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	
	* stocker la comparaison des résultats
	global dir_comparaison "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\comparaison_baseline_referee1"
	
	/* Il me manque pour faire méthode 2 en IV 
	- IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta
	- IV_ref1_y/results_estimTC_`year'_sitc2_3_`mode'.dta
	
	*/
	
	global dir_temp "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
	global dir "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_results "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results"
	 
	 
	 
	}

/* Nouveau portable Lise */
if "`c(hostname)'" =="MSOP112C" {

	* baseline results sur hummels_tra dans son intégralité
    global dir_baseline_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\baseline"
		
	* résultats selon méthode référé 1
	global dir_referee1 "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	
	* stocker la comparaison des résultats
	global dir_comparaison "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\comparaison_baseline_referee1"
	
	/* Il me manque pour faire méthode 2 en IV 
	- IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta
	- IV_ref1_y/results_estimTC_`year'_sitc2_3_`mode'.dta
	
	*/
	
	global dir_temp "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
	global dir "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results"
	}



set more off

	
	
/*

************Comparaison de base
use "$dir/data/hummels_tra.dta", clear
contract year iso_o sitc2 mode
tab _freq
/*Cela confirme que year iso_o sitc2 mode sont les clefs du fichier*/

use "$dir/data/base_hs10_newyears.dta", clear
contract year iso_o mode hs dist_entry
tab _freq
*Ce n’est pas une clef unique ?! Donc il y a plusieurs consignements par produit/district dans base_hs10_newyears ?


use "$dir/data/hummels_tra.dta", clear
keep if year >=2005
merge 1:m year iso_o sitc2 mode using "$dir/data/base_hs10_newyears.dta", force
tab mode _merge
**Semble suggérer qu’il y a plus de choses dans HS10 que dans hummels_tra... (même au delà des cnt)
drop if sitc2==""
tab mode _merge
drop if mode=="cnt"
tab _merge
*****Donc tout le problème est bien lié à mode=="cnt" et aux sitc vides

generate sector = substr(sitc2,1,3)
codebook sector
contract year iso_o sector mode
describe
******************************************	




***************** Pour vérifier que le merge se fait sur les bases d’orgine... c’est bon aussi

use "$dir/data/hummels_tra.dta", clear
rename sitc2 sector
drop if sector==""
assert strlen(sector)==5
replace sector = substr(sector,1,3)
keep if year >=2005
contract year iso_o sector mode
save temp_hummels_tra.dta, replace

use "$dir/data/base_hs10_newyears.dta", clear
rename sitc2 sector
drop if sector==""
assert strlen(sector)==5
replace sector = substr(sector,1,3)
drop if mode=="cnt"
contract year iso_o sector mode

merge 1:1 year sector iso_o mode using temp_hummels_tra.dta, force
erase temp_hummels_tra.dta

***********************
*/

	
** Faire tourner sur toutes les années /mode



/* method1 peut être

- "baseline" (nos benchmark results en s=3 digits, k=5 digits)
- "baseline10" (nos benchmark results en s=3 digits, k=10 digits)
- "baselinesamplereferee1" = notre methode sur le sample issu de la méthode du référé 1, en s=3, k=5 ou 10 (A ACTUALISER)

method2 peut être 
- "referee1" (methode OLS référé 1), s=3 k=10
- "baseline10" (nos benchmark results en s=3 digits, k=10 digits)
- "IV_referee1_panel" (??)
- "IV_ref1_y" (??)

*/ 

do "$dir_git/Open_year_mode_method_model.do"
******************************************************
******************************************************
	
capture program drop comparaison_by_year_mode
program comparaison_by_year_mode
args year mode method1 method2


open_year_mode_method_model `year' `mode' `method1' `model'
	
	
bys iso_o sector : keep if _n==1
capture drop _merge
rename beta beta_method1

save "$dir_temp/`method1'_`method2'.dta", replace

open_year_mode_method_model `year' `mode' `method2' `model'

bys iso_o sector : keep if _n==1
capture drop _merge
rename beta beta_method2

merge 1:1 iso_o sector using "$dir_temp/`method1'_`method2'.dta"
drop _merge

erase "$dir_temp/`method1'_`method2'.dta"

*** Comparaison des beta
graph twoway (scatter beta_method2 beta_method1) (lfit beta_method2 beta_method1), ///
	title("For `year', `mode'") scheme(s1mono)

graph export "$dir_comparaison/scatter_`year'_`mode'_`method1'_`method2'.png", replace



*** Statistiques

clear

open_year_mode_method_model `year' `mode' `method1' `model'
rename beta beta_`method1'

gen Nb_baseline=_N
summarize beta_`method1', det
generate beta_`method1'_mean = r(mean)
generate beta_`method1'_med = r(p50)
summarize beta_`method1' [fweight=val], det
generate beta_`method1'_mean_pd = r(mean)
generate beta_`method1'_med_pd = r(p50)
generate blif = iso_o+sector
quietly levelsof blif
generate Nb_cx3ds_baseline = r(r)

label var Nb_cx3ds_baseline "Number of country x 3 digit sector included in the `method1'"
label var cover_`method1' "Total value of trade flows covered in the `method1'"

** pourquoi ça ne marche plus ??? Nb_cx3ds_baseline est totalement missing??? *** 


drop blif

keep mode cover_`method1'-Nb_cx3ds_baseline
keep if _n==1
capture gen year=`year'
capture gen methode1 = "`method1'"



capture append using "$dir_comparaison/stats_comp_`method1'_`method2'.dta"


save "$dir_comparaison/stats_comp_`method1'_`method2'.dta", replace

clear

open_year_mode_method_model `year' `mode' `method2' `model'



capture drop group_sect
egen group_sect=group(sector)
su group_sect, meanonly	
gen Nb_sector=r(max)

drop group_sect
label var Nb_sector "Nb of sectors in `method2'" 

egen group_iso=group(iso_o)
su group_iso, meanonly	
gen Nb_iso=r(max)

drop group_iso
label var Nb_iso "Nb of origin countries in `method2'" 

rename beta beta_`method2'

gen Nb_`method2'=_N
summarize beta_`method2', det
generate beta_`method2'_mean = r(mean)
generate beta_`method2'_med = r(p50)
summarize beta_`method2' [fweight=val], det
generate beta_`method2'_mean_pd = r(mean)
generate beta_`method2'_med_pd = r(p50)
generate blif = iso_o+sector
quietly levelsof blif
generate Nb_cx3ds = r(r)
label var Nb_cx3ds "Number of country x 3 digit sector included in `method2' test"
label var cover_`method2' "Total value of trade flows covered in `method2' test"
drop blif
drop beta_`method2'


keep Nb_iso Nb_sector cover_`method2'-Nb_cx3ds
keep if _n==1
capture gen year=`year'
capture gen mode="`mode'"

gen methode2 = "`method2'"


merge 1:1 year mode using "$dir_comparaison/stats_comp_`method1'_`method2'.dta"
drop _merge
save "$dir_comparaison/stats_comp_`method1'_`method2'.dta", replace

end


*** A FAIRE APRES PGM comparaison_by_year_mode
capture program drop comparaison_graph
program comparaison_graph
args method1 method2


use "$dir_comparaison/stats_comp_`method1'_`method2'.dta", clear





graph twoway (scatter beta_`method2'_mean beta_`method1'_mean) (lfit beta_`method2'_mean beta_`method1'_mean) ///
			 (scatter beta_`method2'_mean_pd beta_`method1'_mean_pd) (lfit beta_`method2'_mean_pd beta_`method1'_mean_pd) ///
			 (scatter beta_`method2'_med beta_`method1'_med) (lfit beta_`method2'_med beta_`method1'_med) ///
			 (scatter beta_`method2'_med_pd beta_`method1'_med_pd) (lfit beta_`method2'_med_pd beta_`method1'_med_pd), ///
			 ytitle("`method1'") xtitle("`method2'") scheme(s1mono)
			 
graph export "$dir_comparaison/scatter_comparaison_`method1'_`method2'.png", replace


keep year mode beta* 



reshape long beta_, i(year mode) j(type) string
gen method="`method2'"
tab type
replace method="`method1'" if strmatch(type,"`method1'_*")!=0


* faire les différents cas possibles**Mais je ne crois plus que ce soit utile ? GD 2 mars 2021
/*
if method=="baseline" {
replace type = substr(type, 10,.) if strmatch(type,"`method1'*")!=0
}

if method=="baseline10" {
replace type = substr(type, 12,.) if strmatch(type,"`method1'*")!=0
}

if method=="baselinesamplereferee1" {
replace type = substr(type, 24,.) if strmatch(type,"`method1'*")!=0
}
*/

replace type = subinstr(type,"${method1}_","",.)
replace type = subinstr(type,"${method2}_","",.)

reshape wide beta_,i(year mode type) j(method) string





graph twoway (scatter beta_`method2' beta_`method1') (lfit beta_`method2' beta_`method1'), ///
			 ytitle("`method1'") xtitle("`method2'") by(mode type) scheme(s1mono)
			 
graph export "$dir_comparaison/scatter_comparaison_by_type_`method1'_`method2'.png", replace

capture label var beta_IV_ref1_y_5_3 "beta computed by IV"
capture label var beta_baseline "beta baseline" 
capture label var beta_baseline10 "beta 10/3"
capture label var beta_dbsamesample10_5_3 "beta baseline" 
replace type="Unweighted mean" if type=="mean"
replace type="Unweighted median" if type=="med"
replace type="Weighted median" if type=="med_pd"
replace type="Weighted mean" if type=="mean_pd"
replace mode="Air" if mode=="air"
replace mode="Vessel" if mode=="ves"


graph twoway (line beta_`method1' year) (line beta_`method2' year), by(mode type, cols(4) iscale(*.8)) scheme(s1mono)


graph export "$dir_comparaison/scatter_chronology_`method1'_`method2'.png", replace
graph export "$dir_redaction/scatter_chronology_`method1'_`method2'.png", replace


end


*****************************************************************************************
***on lance les comparaisons
*****************************************************************************************


*global method1 baseline
global method1 baseline10
*baseline pour baseline 5/3
*global method2 IV_ref1_y_5_3
*global method1 qy1_wgt
*global method1 hs10_qy1_wgt
******


*global method2 IV_referee1_panel
*global method2 IV_ref1_y_5_3
*global method2 baseline10
*global method2 qy1_qy
*global method2 hs10_qy1_qy
global method2  dbsamesample10_5_3


if "$method"=="baseline10" | "$method"=="dbsamesample10_5_3" local time_span 2005/2019



capture erase "$dir_comparaison/stats_comp_${method1}_$method2.dta"

foreach year of num `time_span'  {
*foreach year of num 1998 1999 2002(1)2019 {
*foreach year of num 2011/2015 {
	foreach mode in air ves {
	*if ("`mode'"!="air" | `year' != 2013) comparaison_by_year_mode `year' `mode' $method1 $method2
		if "$method1"=="qy1_wgt" {
			if (`year' != 1987 | "`mode'"=="air") & (`year' != 2002 | "`mode'"=="air") & (`year' != 2012 | "`mode'"=="ves") & (`year' != 2013) comparaison_by_year_mode `year' `mode' $method1 $method2
		}
		else comparaison_by_year_mode `year' `mode' $method1 $method2
	}
}



use "$dir_comparaison/stats_comp_${method1}_$method2.dta", clear
gen method2_value_method1=cover_$method2/cover_$method1
label var method2_value_method1 "Covered value of trade flows by $method2 as a share of $method1"
gen method2_nbpair_method1=Nb_cx3ds/Nb_cx3ds_baseline
label var method2_nbpair_method1 "Covered bilateral trade flows by products by $method2 as a share of $method1"
sort mode year
save "$dir_comparaison/stats_comp_${method1}_$method2.dta", replace



cd "$dir_comparaison"
use stats_comp_${method1}_$method2.dta
export excel using stats_comp_${method1}_$method2.xls, firstrow(varl) replace

* Pb sur les graphiques sur baseline10 as methode1
*/
comparaison_graph $method1 $method2



