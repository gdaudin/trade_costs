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
	
capture program drop open_year_mode
program open_year_mode
args year mode method


if "`method'"=="baseline" {
	use "$dir_baseline_results/results_estimTC_`year'_prod5_sect3_`mode'.dta", clear
	capture rename `mode'_val val 
	capture drop *_val
	capture rename product sector
}	
	
if "`method'"=="baselinesamplereferee1" {
	use "$dir_referee1/baselinesamplereferee1/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
	
}	
	
if "`method'"=="baseline10" {
	use "$dir_baseline_results/results_estimTC_`year'_prod10_sect3_`mode'.dta", clear
}	


if "`method'"=="IV_referee1_yearly_10_3" {
	use "$dir_results/IV_referee1_yearly/results_estimTC_`year'_prod10_sect3_`mode'.dta", clear
	*rename product sector /*Product is in fact 3 digits*/
	*drop _merge
}	
	
	
if "`method'"=="qy1_wgt" | "`method'"=="hs10_qy1_wgt" |  {
	use "$dir_results/`method'/results_estimTC_`year'_prod5_sect3_`mode'.dta", clear
	*rename product sector /*Product is in fact 3 digits*/
	*drop _merge
}	
	

if "`method'"=="referee1" {
	*use "$dir_referee1/results_beta_contraint_`year'_sitc2_HS8_`mode'.dta", clear
	*** Actualisé EN HS10
	use "$dir_referee1/results_beta_contraint_`year'_sitc2_HS10_`mode'.dta", clear
}



if "`method'"=="qy1_qy" | "`method'"=="hs10_qy1_qy" {
	use "$dir_results/`method'/results_estimTC_`year'_prod5_sect3_`mode'.dta", clear
	generate beta_method = -(terme_A/(terme_I+terme_A-1))
}


if "`method'"=="IV_referee1_panel" {
	use "$dir_results/IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta", clear
	generate beta_method = -(terme_A/(terme_I+terme_A-1))
	rename product sector /*Product is in fact 3 digits*/
	drop _merge
}	


if "`method'"=="IV_referee1_yearly_10_3" {
	use "$dir_results/IV_referee1_yearly/results_estimTC_`year'_prod10_sect3_`mode'.dta", clear
	generate beta_method = -(terme_A/(terme_I+terme_A-1))
	*rename product sector /*Product is in fact 3 digits*/
	*drop _merge
}	
	
if "`method'"=="IV_referee1_yearly_5_3" {
	use "$dir_results/IV_referee1_yearly/results_estimTC_`year'_prod5_sect3_`mode'.dta", clear
	generate beta_method = -(terme_A/(terme_I+terme_A-1))
	*rename product sector /*Product is in fact 3 digits*/
	*drop _merge
}	


generate beta=-(terme_A/(terme_I+terme_A-1))
egen cover_`method'=total(val)

capture drop year
gen year=`year'

*save $dir_temp/data_`method'_`year'_`mode'.dta, replace

end




*****************************************************************************************
***on lance les programmes
*****************************************************************************************


global method baseline
*global method baseline10
*baseline pour baseline 5/3
*global method IV_referee1_yearly_5_3
*global method qy1_wgt
*global method hs10_qy1_wgt
******


*global method IV_referee1_panel
*global method IV_referee1_yearly_5_3
*global method baseline10
*global method qy1_qy
*global method hs10_qy1_qy


foreach mode in air ves {
	capture erase $dir_temp/data_${method}_`mode'.dta
	foreach year of num 1974 1980 1990 2000 2010 2019 {
		open_year_mode `year' `mode' $method
		capture append using $dir_temp/data_${method}_`mode'.dta
		save $dir_temp/data_${method}_`mode'.dta, replace
	}
	label var year "year ($method, `mode')"
	label var prix_trsp "Observed transport costs"
	
	generate N = 0
	generate Nb_sectors = 0
	generate Nb_partners = 0
	
	foreach year of num 1974 1980 1990 2000 2010 2019 {
		capture tabulate iso_o if year==`year'
		replace Nb_partners=r(r) if year==`year'
		capture tabulate sector if year==`year'
		replace Nb_sectors=r(r) if year==`year'
		egen N_`year'=count(prix_trsp), by(year)
		replace N=N_`year' if year==`year'
		drop N_`year'
	}
	
	
	replace prix_trsp=prix_trsp *100
	replace terme_A=terme_A *100
	replace terme_I=(terme_I-1) *100
	
/*
	table (var) (year) [aweight=val], /*
	*/ statistic(max N) /*
	*/ statistic(max Nb_sectors) /*
	*/ statistic(max Nb_partners) /*
	*/ statistic(mean prix_trsp) statistic(median prix_trsp) statistic(sd prix_trsp) /*	
	*/ statistic(mean terme_I) statistic(median terme_I) statistic(sd terme_I) /*
	*/ statistic(mean terme_A)   statistic(median terme_A) statistic(sd terme_A) /*
	*/ statistic(mean beta) statistic(median beta) statistic(sd beta) /*
	*/ nformat(%3.1f) nototals /*
	*/ name(bloum) replace
*/


	collect clear

	sort year
	quietly {
		by year: collect r(max), tags(model[data] var[N]): 	sum N
		by year: collect get r(max), tags(model[data] var[Nb_sectors]): 	sum Nb_sectors
		by year: collect get r(max), tags(model[data] var[Nb_partners]): 	sum Nb_partners 

		by year: collect get, tags(model[data] var[prix_trsp]) : sum prix_trsp [aweight=val], det
		by year: collect get, tags(model[nlAetI] var[terme_I]) : sum terme_I [aweight=val], det
		by year: collect get, tags(model[nlAetI] var[terme_A]) : sum terme_A [aweight=val], det
		by year: collect get, tags(model[nlAetI] var[beta]) : sum beta [aweight=val], det
	}
	collect style cell, warn nformat (%3.1f)
	collect style header result[max], level(hide)
		
		
	collect layout (model[data]#result[max]#var[N Nb_sectors Nb_partners] /*
		*/ model[data]#var[prix_trsp]#result[mean p50 sd] /*
		*/ model[nlAetI]#var[terme_I terme_A beta]#result[mean p50 sd])  (year)

	
	collect label levels var N "{$#$ obs.}"
	collect label levels var Nb_sectors "{$#$ sectors}"
	collect label levels var Nb_partners "{$#$ origin countries}"
	collect label levels result max "\textbf{Data}", modify
	collect label levels result mean "Mean (in $%$)", modify
	collect label levels result p50 "Median (in $%$)", modify
	collect label levels var prix_trsp "{\textit{Observed transport costs}}", modify
	collect label levels var terme_I "{\textit{Multiplicative term} ($\widehat{\tau}^{adv}$)}", modify
	collect label levels var terme_A "{\textit{Additive term} ($\widehat{t}/\widetilde{p}$)}", modify
	collect label levels var beta "{\textit{Elasticity of transport cost to price} ($\widehat{\beta}$)}", modify
	collect label levels model data "\textbf{Data}"
	collect label levels model nlAetI "{\textbf{Model (B)}}"
	collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0gc)
	collect style cell var[beta], warn nformat(%3.2f)
	
	
	
	
	collect preview
	
	collect export /* 		 
	*/ $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/TableA1_`mode'.tex,tableonly replace
	
	
	
********Essai avec tables concaténées après ; ne marche pas.

/*	
	table (var) (year), /*
	*/ statistic(count prix_trsp) /*
	*/ command(r(r): tabulate iso_o) /*
	*/ name(blif) replace nototals
	
	collect label values statcmd 1 "N", modify
	collect style header statcmd, level(hide)
	collect style header var, level(hide)
	collect label levels result r "Number of partners", modify
	collect preview
	
	
	
	
	
	
	table () (year), /*
	*/ command(r(r): tabulate sector) /*
	*/ name(blouf) replace nototals
	
	collect style header statcmd, level(hide)
	collect style header var, level(hide)
	collect label levels result r "Number of sectors", modify
	
	collect preview
	
	collect combine blink = blif blouf, replace
	
	collect preview
	
	collect export $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/filk.tex, tableonly replace
	blif
	
	
		table (var) (year) (statcmd) [aweight=val], /*
	*/ statistic(mean prix_trsp) statistic(median prix_trsp) /*	
	*/ statistic(mean terme_I) statistic(median terme_I) /*
	*/ statistic(mean terme_A)   statistic(median terme_A) /*
	*/ statistic(mean beta) statistic(median beta) /*
	*/ command(r(r): tabulate iso_o) /*
	*/ nformat(%4.3f) nototals /*
	*/ name(bloum) replace
	
	
	
	
	
	
	
	table (var) (year) [aweight=val], /*
	*/ statistic(mean prix_trsp) statistic(median prix_trsp) /*	
	*/ statistic(mean terme_I) statistic(median terme_I) /*
	*/ statistic(mean terme_A)   statistic(median terme_A) /*
	*/ statistic(mean beta) statistic(median beta) /*
	*/ nformat(%4.3f) nototals /*
	*/ name(bloum) replace
	

	collect combine TableA1_`mode' = blif blouf bloum, replace
	
	collect preview
	
*/	
}





