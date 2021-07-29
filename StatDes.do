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
args year mode method model


if "`method'"=="baseline" & ("`model'"=="" | "`model'"=="nlAetI" | "`model'"=="nl") {
	use "$dir_baseline_results/results_estimTC_`year'_prod5_sect3_`mode'.dta", clear
	capture rename `mode'_val val 
	capture drop *_val
	capture rename product sector
	generate beta=-(terme_A/(terme_I+terme_A-1))
}	

if "`method'"=="baseline5_4" & ("`model'"=="" | "`model'"=="nlAetI") {
	use "$dir_baseline_results/results_estimTC_`year'_prod5_sect4_`mode'.dta", clear
	capture rename `mode'_val val 
	capture drop *_val
	capture rename product sector
	generate beta=-(terme_A/(terme_I+terme_A-1))
}	

if "`method'"=="baseline" & ("`model'"=="nlA" | "`model'"=="nlI") {
	use "$dir_baseline_results/results_estimTC_`model'_`year'_prod5_sect3_`mode'.dta", clear
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


capture egen cover_`method'=total(val)

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

/*
******************Pour la table 1 du texte
collect clear
global method baseline
foreach mode in air ves {

	foreach model in nlAetI nlI {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num 1974/2019  {
			open_year_mode `year' `mode' $method `model'
			capture append using $dir_temp/data_`model'_${method}_`mode'.dta
			save $dir_temp/data_`model'_${method}_`mode'.dta, replace
		}
		
		
		use $dir_temp/data_`model'_${method}_`mode'.dta, replace
		egen value_year=total(val), by(year)
		generate weight = value/value_year
		
		
		
		if "`model'"=="nlAetI" {
			generate N = 0
			generate Nb_sectors = 0
			generate Nb_partners = 0
			label var prix_trsp "Observed transport costs"
			
			foreach year of num 1974/2019 {
				capture tabulate iso_o if year==`year'
				replace Nb_partners=r(r) if year==`year'
				capture tabulate sector if year==`year'
				replace Nb_sectors=r(r) if year==`year'
				egen N_`year'=count(prix_trsp), by(year)
				replace N=N_`year' if year==`year'
				drop N_`year'
				}	
			collect, tags(model[data] var[N] mode[`mode'] digit[${method}]): /*
				*/ sum N [aweight=weight]
			collect, tags(model[data] var[Nb_sectors] mode[`mode'] digit[${method}]): /*
				*/ sum Nb_sectors [aweight=weight]
			collect, tags(model[data] var[Nb_partners] mode[`mode'] digit[${method}]): /*
			    */ sum Nb_partners[aweight=weight] 		

			replace prix_trsp=prix_trsp *100
			replace terme_A=terme_A *100
			replace terme_I=(terme_I-1) *100
			


			collect, tags(model[data] var[prix_trsp] mode[`mode'] digit[${method}]) /*
				*/ : sum prix_trsp [aweight=weight], det
			collect, tags(model[nlAetI] var[terme_I] mode[`mode'] digit[${method}]) /*
			    */ : sum terme_I [aweight=weight], det
			collect, tags(model[nlAetI] var[terme_A] mode[`mode'] digit[${method}]) /*
				*/ : sum terme_A [aweight=weight], det
			collect, tags(model[nlAetI] var[beta] 	 mode[`mode'] digit[${method}]) /*
			    */ : sum beta [aweight=weight], det
		}
		
		quietly if "`model'"=="nlI" {
			replace terme_nlI=(terme_nlI-1) *100
			collect, tags(model[`model'] var[terme_nlI] mode[`mode'] digit[${method}]) :/*
			*/ sum terme_nlI [aweight=val], det
		}
			
	}
	
	
}



global method baseline5_4

foreach mode in air ves {

	foreach model in nlAetI /*nlI*/ {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num 1974 1977(4)2013  {
			open_year_mode `year' `mode' $method `model'
			capture append using $dir_temp/data_`model'_${method}_`mode'.dta
			save $dir_temp/data_`model'_${method}_`mode'.dta, replace
		}
		
		
		use $dir_temp/data_`model'_${method}_`mode'.dta, replace
		egen value_year=total(val), by(year)
		generate weight = val/value_year
		
		
		
		if "`model'"=="nlAetI" {
			generate N = 0
			generate Nb_sectors = 0
			generate Nb_partners = 0
			label var prix_trsp "Observed transport costs"
			
			foreach year of num 1974 1977(4)2013  {
				capture tabulate iso_o if year==`year'
				replace Nb_partners=r(r) if year==`year'
				capture tabulate sector if year==`year'
				replace Nb_sectors=r(r) if year==`year'
				egen N_`year'=count(prix_trsp), by(year)
				replace N=N_`year' if year==`year'
				drop N_`year'
				}	
			collect, tags(model[data] var[N] mode[`mode'] digit[${method}]): /*
				*/ sum N [aweight=weight]
			collect, tags(model[data] var[Nb_sectors] mode[`mode'] digit[${method}]): /*
				*/ sum Nb_sectors [aweight=weight]
			collect, tags(model[data] var[Nb_partners] mode[`mode'] digit[${method}]): /*
			    */ sum Nb_partners[aweight=weight] 		

			replace prix_trsp=prix_trsp *100
			replace terme_A=terme_A *100
			replace terme_I=(terme_I-1) *100
			


			collect, tags(model[data] var[prix_trsp] mode[`mode'] digit[${method}]) /*
				*/ : sum prix_trsp [aweight=weight], det
			collect, tags(model[nlAetI] var[terme_I] mode[`mode'] digit[${method}]) /*
			    */ : sum terme_I [aweight=weight], det
			collect, tags(model[nlAetI] var[terme_A] mode[`mode'] digit[${method}]) /*
				*/ : sum terme_A [aweight=weight], det
			collect, tags(model[nlAetI] var[beta] 	 mode[`mode'] digit[${method}]) /*
			    */ : sum beta [aweight=weight], det
		}
		
		quietly if "`model'"=="nlI" {
			replace terme_nlI=(terme_nlI-1) *100
			collect, tags(model[`model'] var[terme_nlI] mode[`mode'] digit[${method}]) :/*
			*/ sum terme_nlI [aweight=val], det
		}
			
	}
	
	
}





	
	
	collect layout (model[data]#result[max]#var[N Nb_sectors Nb_partners] /*
		*/ model[data]#var[prix_trsp]#result[mean p50 sd] /*
		*/ model[nlI]#var[terme_nlI]#result[mean p50 sd]/*
		*/ model[nlAetI]#var[terme_I terme_A beta]#result[mean p50 sd]) /* 
		*/ (digit#mode)

	 
	
	
	collect label levels digit baseline "3-digit"
	collect label levels digit baseline5_4 "4-digit"
	collect label levels var N "{$#$ obs.}"
	collect label levels var Nb_sectors "{$#$ sectors}"
	collect label levels var Nb_partners "{$#$ origin countries}"
	collect label levels result max "\textbf{Data}", modify
	collect label levels result mean "Mean (in $%$)", modify
	collect label levels result p50 "Median (in $%$)", modify
	collect label levels var prix_trsp "{\textit{Observed transport costs}}", modify
	collect label levels var terme_I "{\textit{Multiplicative term} ($\widehat{\tau}^{adv}$)}", modify
	collect label levels var terme_nlI "{\textit{Multiplicative term} ($\widehat{\tau}^{ice}$)}", modify
	collect label levels var terme_A "{\textit{Additive term} ($\widehat{t}/\widetilde{p}$)}", modify
	collect label levels var terme_nlA "{\textit{Additive term} ($\widehat{t}^{add}/\widetilde{p}$)}", modify
	collect label levels var beta "{\textit{Elasticity of transport cost to price} ($\widehat{\beta}$)}", modify
	collect label levels model data "\textbf{Data}"
	collect label levels model nlAetI "{\textbf{Model (B)}}"
	collect label levels model nlI "{\textbf{Model (A)}}"
	collect style cell, warn nformat (%3.1f)
	collect style cell var[beta], warn nformat(%3.2f)
	collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0gc)
	collect style header result[max], level(hide)
	collect style column, nodelimiter dups(center) position(top) width(asis)
	
	collect style save myappendixAB, replace
	
	
	collect preview
	
	collect export /* 		 
	*/ $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Table1.tex, /*
	*/ tableonly replace
	
	




*/


***Pour les tables A1 et A2 de l’appendix
/*

foreach mode in air ves {
	collect clear
	foreach model in nlAetI nlI nlA {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num 1974 1980 1990 2000 2010 2019 {
			open_year_mode `year' `mode' $method `model'
			capture append using $dir_temp/data_`model'_${method}_`mode'.dta
			save $dir_temp/data_`model'_${method}_`mode'.dta, replace
		}
		label var year "year ($method, `mode')"
		
		
		if "`model'"=="nlAetI" {
			generate N = 0
			generate Nb_sectors = 0
			generate Nb_partners = 0
			label var prix_trsp "Observed transport costs"
			
			foreach year of num 1974 1980 1990 2000 2010 2019 {
				capture tabulate iso_o if year==`year'
				replace Nb_partners=r(r) if year==`year'
				capture tabulate sector if year==`year'
				replace Nb_sectors=r(r) if year==`year'
				egen N_`year'=count(prix_trsp), by(year)
				replace N=N_`year' if year==`year'
				drop N_`year'
			}
		}
		


		

		sort year
	*	macro list
		quietly if "`model'"=="nlAetI" {
			
			replace prix_trsp=prix_trsp *100
			replace terme_A=terme_A *100
			replace terme_I=(terme_I-1) *100
			
			by year: collect r(max), tags(model[data] var[N]): 	sum N
			by year: collect get r(max), tags(model[data] var[Nb_sectors]): 	sum Nb_sectors
			by year: collect get r(max), tags(model[data] var[Nb_partners]): 	sum Nb_partners 

			by year: collect get, tags(model[data] var[prix_trsp]) : sum prix_trsp [aweight=val], det
			by year: collect get, tags(model[nlAetI] var[terme_I]) : sum terme_I [aweight=val], det
			by year: collect get, tags(model[nlAetI] var[terme_A]) : sum terme_A [aweight=val], det
			by year: collect get, tags(model[nlAetI] var[beta]) : sum beta [aweight=val], det
		}
		
		quietly if "`model'"=="nlI" {
			replace terme_nlI=(terme_nlI-1) *100
			by year: collect get, tags(model[`model'] var[terme_nlI]) : sum terme_nlI [aweight=val], det
		}
		
		quietly if "`model'"=="nlA" {
			replace terme_nlA=terme_nlA *100
			by year: collect get, tags(model[`model'] var[terme_nlA]) : sum terme_nlA [aweight=val], det
		}
		
			
	}
	
	
	
	
	
	collect layout (model[data]#result[max]#var[N Nb_sectors Nb_partners] /*
		*/ model[data]#var[prix_trsp]#result[mean p50 sd] /*
		*/ model[nlI]#var[terme_nlI]#result[mean p50 sd]/*
		*/ model[nlAetI]#var[terme_I terme_A beta]#result[mean p50 sd] /* 
		*/ model[nlA]#var[terme_nlA]#result[mean p50 sd]) /* 
		*/ (year)

	
	collect label levels var N "{$#$ obs.}"
	collect label levels var Nb_sectors "{$#$ sectors}"
	collect label levels var Nb_partners "{$#$ origin countries}"
	collect label levels result max "\textbf{Data}", modify
	collect label levels result mean "Mean (in $%$)", modify
	collect label levels result p50 "Median (in $%$)", modify
	collect label levels var prix_trsp "{\textit{Observed transport costs}}", modify
	collect label levels var terme_I "{\textit{Multiplicative term} ($\widehat{\tau}^{adv}$)}", modify
	collect label levels var terme_nlI "{\textit{Multiplicative term} ($\widehat{\tau}^{ice}$)}", modify
	collect label levels var terme_A "{\textit{Additive term} ($\widehat{t}/\widetilde{p}$)}", modify
	collect label levels var terme_nlA "{\textit{Additive term} ($\widehat{t}^{add}/\widetilde{p}$)}", modify
	collect label levels var beta "{\textit{Elasticity of transport cost to price} ($\widehat{\beta}$)}", modify
	collect label levels model data "\textbf{Data}"
	collect label levels model nlAetI "{\textbf{Model (B)}}"
	collect label levels model nlI "{\textbf{Model (A)}}"
	collect label levels model nlA "{\textbf{Model (C)}}"
	collect style cell, warn nformat (%3.1f)
	collect style cell var[beta], warn nformat(%3.2f)
	collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0gc)
	collect style header result[max], level(hide)
	
	collect style save myappendixAB, replace
	
	
	collect preview
	
	collect export /* 		 
	*/ $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/TableA1_`mode'.tex, /*
	*/ tableonly replace

	
	
}

*/

******Pour les tables A3 et A4 de l’appendix (quality of fit)


foreach mode in air ves {
	collect clear
	foreach model in nl nlI nlA {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num 1974 1980 1990 2000 2010 2019 {
			open_year_mode `year' `mode' $method `model'
			capture append using $dir_temp/data_`model'_${method}_`mode'.dta
			save $dir_temp/data_`model'_${method}_`mode'.dta, replace
		}
		
		sort year
		
	
	
			
			

		****Pour la standard error of regression (https://en.wikipedia.org/wiki/Reduced_chi-squared_statistic)
		egen value_year=total(val), by(year)
		by year: generate weightN = val/value_year*_N
		
		gen Nb_partners=.
		gen Nb_sectors=.
		
		foreach year of num 1974 1980 1990 2000 2010 2019 {
			capture tabulate iso_o if year==`year'
			replace Nb_partners=r(r) if year==`year'
			
			capture tabulate sector if year==`year'
			replace Nb_sectors=r(r) if year==`year'
		}
		
		gen error =prix_trsp2 - predict_`model'
		egen blouf = total(error^2*weightN), by(year)
		
		by year : gen SER = (blouf/(_N-Nb_sectors-Nb_partners))^0.5*100
		
		
		drop blouf
	*	gen error =abs(ln(prix_trsp2) - ln(predict_`model'))
		by year: collect r(mean), tags(model[`model'] var[SER]): 	sum SER
		
		by year: collect r(mean), tags(model[`model'] var[R2]): 	sum Rp2_`model'
		by year: collect r(mean), tags(model[`model'] var[aic]): 	sum aic_`model'
		by year: collect r(mean), tags(model[`model'] var[LL]): 	sum logL_`model'
		
			
			
	}
	
	
	
	
	
	collect layout (var[R2 SER aic LL]#model[nlI nl nlA]#result[mean])/* 
		*/ (year)

	
	collect label levels model nl "{Model (B)}"
	collect label levels model nlI "{Model (A)}"
	collect label levels model nlA "{Model (C)}"
	collect label levels var R2 "\textbf{\textit{R}$^2$}"
	collect label levels var SER "\textbf{SER (in $%$)}"
	collect label levels var aic "\textbf{AIC criteria}"
	collect label levels var LL "\textbf{Log-likelihood}"
	
	collect style cell, warn nformat (%3.1f)
	collect style cell var[R2], warn nformat(%3.2f)
	collect style cell var[SER], warn nformat(%2.1f)
	collect style cell var[LL aic], warn nformat(%9.0fc)
	collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0gc)
	collect style header result[mean], level(hide)
	

	collect preview
	
	collect export /* 		 
	*/ $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/TableA3_`mode'.tex, /*
	*/ tableonly replace

	
}




















blif




******Pour les tables B appendix

capture program drop tablesB
program tablesB
args start end mode method

collect clear

foreach model in nlAetI nlI nlA {
	capture erase $dir_temp/data_`model'_${method}_`mode'.dta
	foreach year of num `start'/`end'  {
		open_year_mode `year' `mode' $method `model'
		capture append using $dir_temp/data_`model'_${method}_`mode'.dta
		save $dir_temp/data_`model'_${method}_`mode'.dta, replace
	}
	label var year "year ($method, `mode')"
	
	
	if "`model'"=="nlAetI" {
		generate N = 0
		generate Nb_sectors = 0
		generate Nb_partners = 0
		label var prix_trsp "Observed transport costs"
		
		foreach year of num `start'/`end'  {
			capture tabulate iso_o if year==`year'
			replace Nb_partners=r(r) if year==`year'
			capture tabulate sector if year==`year'
			replace Nb_sectors=r(r) if year==`year'
			egen N_`year'=count(prix_trsp), by(year)
			replace N=N_`year' if year==`year'
			drop N_`year'
		}
	}
	


	

	sort year
*	macro list
	quietly if "`model'"=="nlAetI" {
		
		replace prix_trsp=prix_trsp *100
		replace terme_A=terme_A *100
		replace terme_I=(terme_I-1) *100
		
		by year: collect r(max), tags(model[data] var[N]): 	sum N
		by year: collect get r(max), tags(model[data] var[Nb_sectors]): 	sum Nb_sectors
		by year: collect get r(max), tags(model[data] var[Nb_partners]): 	sum Nb_partners 

		by year: collect get, tags(model[data] var[prix_trsp]) : sum prix_trsp [aweight=val], det
		by year: collect get, tags(model[nlAetI] var[terme_I]) : sum terme_I [aweight=val], det
		by year: collect get, tags(model[nlAetI] var[terme_A]) : sum terme_A [aweight=val], det
		by year: collect get, tags(model[nlAetI] var[beta]) : sum beta [aweight=val], det
	}
	
	quietly if "`model'"=="nlI" {
		replace terme_nlI=(terme_nlI-1) *100
		by year: collect get, tags(model[`model'] var[terme_nlI]) : sum terme_nlI [aweight=val], det
	}
	
	quietly if "`model'"=="nlA" {
		replace terme_nlA=terme_nlA *100
		by year: collect get, tags(model[`model'] var[terme_nlA]) : sum terme_nlA [aweight=val], det
	}
	
		
}





collect layout (model[data]#result[max]#var[N Nb_sectors Nb_partners] /*
	*/ model[data]#var[prix_trsp]#result[mean p50 sd] /*
	*/ model[nlI]#var[terme_nlI]#result[mean p50 sd]/*
	*/ model[nlAetI]#var[terme_I terme_A beta]#result[mean p50 sd] /* 
	*/ model[nlA]#var[terme_nlA]#result[mean p50 sd])/*
	*/ (year)


collect label levels var N "{$#$ obs.}"
collect label levels var Nb_sectors "{$#$ sectors}"
collect label levels var Nb_partners "{$#$ origin countries}"
collect label levels result max "\textbf{Data}", modify
collect label levels result mean "Mean (in $%$)", modify
collect label levels result p50 "Median (in $%$)", modify
collect label levels var prix_trsp "{\textit{Observed transport costs}}", modify
collect label levels var terme_I "{\textit{Mult. term} ($\widehat{\tau}^{adv}$)}", modify
collect label levels var terme_nlI "{\textit{Mult. term} ($\widehat{\tau}^{ice}$)}", modify
collect label levels var terme_A "{\textit{Additive term} ($\widehat{t}/\widetilde{p}$)}", modify
collect label levels var terme_nlA "{\textit{Additive term} ($\widehat{t}^{add}/\widetilde{p}$)}", modify
collect label levels var beta "{\textit{Elasticity} ($\widehat{\beta}$)}", modify
collect label levels model data "\textbf{Data}"
collect label levels model nlAetI "{\textbf{Model (B)}}"
collect label levels model nlI "{\textbf{Model (A)}}"
collect label levels model nlA "{\textbf{Model (C)}}"
collect style cell, warn nformat (%3.1f)
collect style cell var[beta], warn nformat(%3.2f)
collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0gc)
collect style header result[max], level(hide)





collect preview

collect export /* 		 
*/ $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/TableB`start'_`end'_`mode'.tex, /*
*/ tableonly replace



end

foreach mode in air ves {
	tablesB 1974 1987 `mode' $method
	tablesB 1988 2001 `mode' $method
	tablesB 2002 2015 `mode' $method
	tablesB 2016 2019 `mode' $method
}
