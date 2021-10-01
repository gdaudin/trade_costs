
*ssc inst _gwtmean

*Programme fait à partir de "Comparaison.do

if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaisons_various"
	global dir_temp ~/Downloads/temp_stata
	global dir_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results"
	global dir_git "~/Répertoires Git/trade_costs_git"
	
	
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
	- IV_referee1_yearly/results_estimTC_`year'_sitc2_3_`mode'.dta
	
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
	- IV_referee1_yearly/results_estimTC_`year'_sitc2_3_`mode'.dta
	
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



/* method peut être

- "baseline" (nos benchmark results en s=3 digits, k=5 digits)
- "baseline10" (nos benchmark results en s=3 digits, k=10 digits)
- "baselinesamplereferee1" = notre methode sur le sample issu de la méthode du référé 1, en s=3, k=5 ou 10 (A ACTUALISER)
- "referee1" (methode OLS référé 1), s=3 k=10
- "IV_referee1_panel" (??)
- "IV_referee1_yearly" (??)

*/ 

	
******************************************************
******************************************************
do "$dir_git/Open_year_mode_method_model.do"





*****************************************************************************************
***on lance les programmes
*****************************************************************************************


*global method baseline
*global method referee1
******

******************Pour la table de comparaison
collect clear

capture program drop table_comparaison_part
program table_comparaison_part
args method

global method `method'

local time_span 2005 (1) 2013
local model nlAetI


foreach mode in  air ves {
	
	capture erase $dir_temp/data_`model'_${method}_`mode'.dta
	foreach year of num `time_span'  {
		open_year_mode_method_model `year' `mode' $method `model'
		capture append using $dir_temp/data_`model'_${method}_`mode'.dta
		save $dir_temp/data_`model'_${method}_`mode'.dta, replace
	}
	
	
	use $dir_temp/data_`model'_${method}_`mode'.dta, replace
	egen value_year=total(val), by(year)
	generate weight = val/value_year 
	
	
	
	

	generate N = 0
	generate Nb_sectors  = 0
	generate Nb_partners = 0
	generate Nb_pairs   = 0
	gen paire =iso_o+sector
	gen value_tot = 0
	
	foreach year of num `time_span' {
		capture levelsof iso_o if year==`year'
		replace Nb_partners=r(r) if year==`year'
		
		capture levelsof sector if year==`year'
		replace Nb_sectors=r(r) if year==`year'
		
		capture levelsof paire if year==`year'
		replace Nb_pairs=r(r) if year==`year'
		
		egen N_`year'=count(beta), by(year)
		replace N=N_`year' if year==`year'
		
		egen value_`year'=total(val), by(year)
		replace value_tot=value_`year' if year==`year'
		
		drop N_`year'
		}
	
	collect, tags(var[N] 		   mode[`mode'] digit[${method}]): /*
		*/ sum N [aweight=weight]
	collect, tags(var[Nb_sectors]  mode[`mode'] digit[${method}]): /*
		*/ sum Nb_sectors [aweight=weight] 
	collect, tags(var[Nb_partners] mode[`mode'] digit[${method}]): /*
		*/ sum Nb_partners[aweight=weight] 
	collect, tags(var[Nb_pairs]   mode[`mode'] digit[${method}]): /*
		*/ sum Nb_pairs[aweight=weight] 		
	collect, tags(var[value_tot] mode[`mode'] digit[${method}]): /*
		*/ sum value_tot[aweight=weight] 	
	collect, tags(var[beta] 	 mode[`mode'] digit[${method}]) /*
		*/ : sum beta[aweight=weight], det

	quietly gen ln_beta=ln(beta)	
	collect _r_b, tags(mode[`mode'] digit[${method}]): regress ln_beta year [aweight=weight]
	

	save $dir_temp/data_`model'_${method}_`mode'.dta, replace
	
	collect, tags(var[beta_2005] 	 mode[`mode'] digit[${method}]) /*
		*/ : sum beta[aweight=weight] if year==2005, det
		
	collect, tags(var[beta_2013] 	 mode[`mode'] digit[${method}]) /*
		*/ : sum beta[aweight=weight] if year==2013, det

	
	
	collect layout (result[mean]#var[Nb_sectors Nb_partners Nb_pairs value_tot] /*
	*/ var[beta]#result[mean p50 sd] (colname[year]#result) (var[beta_2005 beta_2013]#result[mean])) /* 
	*/ (mode#digit)
	
	


	
	
}


end



table_comparaison_part referee1
table_comparaison_part baseline

collect style cell, warn nformat (%3.1f)
collect style cell var[beta beta_debut beta_fin], warn nformat(%3.2f)
collect style cell var[Nb_pairs]#var[value_tot]#var[Nb_sectors]#var[Nb_partners], warn 	nformat(%9.0fc)
collect style cell colname[year], warn nformat(%4.3f)
collect style column, nodelimiter dups(center) position(top) width(asis)

collect label levels colname year "Time trend", modify
collect label levels result p50  "Median", modify
collect label levels var value_tot  "Covered trade value", modify
collect label levels digit referee1  "Estimating $\widehat{\beta_{i,s}$", modify

collect preview

collect export /* 		 
*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/Comp_baseline_referee1.tex", /*
*/ tableonly replace

