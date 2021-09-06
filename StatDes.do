
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


******************Pour la table 1 du texte
collect clear

capture program drop table1_part
program table1_part
args method

global method `method'
if "$method"=="baseline" local time_span 1974 (1) 2019
if "$method"=="baseline5_4" local time_span 1974 1977 (4)2017 2019
if "$method"=="baseline10" | "$method"=="baseline_rob_10" local time_span 1997 1998 1999 2002(1) 2019

if "$method"=="baseline_rob_10" global method baseline /*En effet, tout ce qui change c’est la période*/


foreach mode in air ves {

	foreach model in nlAetI nlI {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num `time_span'  {
			open_year_mode_method_model `year' `mode' $method `model'
			capture append using $dir_temp/data_`model'_${method}_`mode'.dta
			save $dir_temp/data_`model'_${method}_`mode'.dta, replace
		}
		
		
		use $dir_temp/data_`model'_${method}_`mode'.dta, replace
		egen value_year=total(val), by(year)
		generate weight = val/value_year
		drop if year==1989 & mode=="air"  
		
		
		
		if "`model'"=="nlAetI" {
			generate N = 0
			generate Nb_sectors = 0
			generate Nb_partners = 0
			label var prix_trsp "Observed transport costs"
			
			foreach year of num `time_span' {
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
			
			collect, tags(model[data] var[prix_fob] mode[`mode'] digit[${method}]) /*
				*/ : sum prix_fob [aweight=weight], det
				
				
			gen p_add_dollar = terme_A*prix_fob/100
			collect, tags(model[nlAetI] var[p_add_dollar] mode[`mode'] digit[${method}]) /*
				*/ : sum  p_add_dollar [aweight=weight], det


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
			*/ sum terme_nlI [aweight=weight], det
		}
		save $dir_temp/data_`model'_${method}_`mode'.dta, replace
	}
	
	
}


end

/*

*************Pour tableau 1 : baseline + baseline 5_4
table1_part baseline
table1_part baseline5_4



	
	
	collect layout (model[data]#result[mean]#var[N Nb_sectors Nb_partners] /*
		*/ model[data]#var[prix_trsp prix_fob]#result[mean p50 sd] /*
		*/ model[nlI]#var[terme_nlI]#result[mean p50 sd]/*
		*/ model[nlAetI]#var[terme_I terme_A p_add_dollar beta]#result[mean p50 sd]) /* 
		*/ (digit#mode)

	 

	
	collect label levels digit baseline "3-digit"
	collect label levels digit baseline5_4 "4-digit"
	collect label levels var N "{$#$ obs.}"
	collect label levels var Nb_sectors "{$#$ sectors}"
	collect label levels var Nb_partners "{$#$ origin countries}"
	collect label levels result max "\textbf{Data}", modify
	collect label levels result mean "Mean", modify
	collect label levels result p50 "Median", modify
	collect label levels var prix_trsp "{\textit{Obs. transport costs $(p/\widehat{p}-1)$ (in $%$)}}", modify
	collect label levels var prix_fob "{\textit{Export price in USD per kg (\textit{$\widehat{p}$})}}", modify
	collect label levels var terme_I "{\textit{Multiplicative term (in $%$)} ($\widehat{\tau}^{adv}$)}", modify
	collect label levels var terme_nlI "{\textit{Multiplicative term (in $%$)} ($\widehat{\tau}^{ice}$)}", modify
	collect label levels var terme_A "{\textit{Additive term (in $%$)} ($\widehat{t}/\widetilde{p}$)}", modify
	collect label levels var p_add_dollar "{\textit{Additive term in USD per kg ($\widehat{t}$)}}", modify
	collect label levels var beta "$\widehat{\beta}$:  \textit{-Share of additive costs}", modify
	collect label levels model data "\textbf{Data}"
	collect label levels model nlAetI "{\textbf{Model (B)}}"
	collect label levels model nlI "{\textbf{Model (A)}}"
	
	collect style cell, warn nformat (%3.1f)
	collect style cell var[beta p_add_dollar], warn nformat(%3.2f)
	collect style cell var[prix_fob], warn nformat(%9.0fc)
	collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0fc)
	collect style column, nodelimiter dups(center) position(top) width(asis)
	
	collect style save myappendixAB, replace
	
	
	collect preview
	
	collect export /* 		 
	*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Table1.tex", /*
	*/ tableonly replace


*/



*************Pour tableau 1 : baseline10 + baseline sur période réduite
table1_part baseline10
table1_part baseline_rob_10


*************Pour tableau 1 : baseline + baseline 5_4
table1_part baseline
table1_part baseline5_4



	
	
	collect layout (model[data]#result[mean]#var[N Nb_sectors Nb_partners] /*
		*/ model[data]#var[prix_trsp prix_fob]#result[mean p50 sd] /*
		*/ model[nlI]#var[terme_nlI]#result[mean p50 sd]/*
		*/ model[nlAetI]#var[terme_I terme_A p_add_dollar beta]#result[mean p50 sd]) /* 
		*/ (digit#mode)

	 

	
	collect label levels digit baseline "5/3-digit"
	collect label levels digit baseline10 "10/3-digit"
	collect label levels var N "{$#$ obs.}"
	collect label levels var Nb_sectors "{$#$ sectors}"
	collect label levels var Nb_partners "{$#$ origin countries}"
	collect label levels result max "\textbf{Data}", modify
	collect label levels result mean "Mean", modify
	collect label levels result p50 "Median", modify
	collect label levels var prix_trsp "{\textit{Obs. transport costs $(p/\widehat{p}-1)$ (in $%$)}}", modify
	collect label levels var prix_fob "{\textit{Export price in USD per kg (\textit{$\widehat{p}$})}}", modify
	collect label levels var terme_I "{\textit{Multiplicative term (in $%$)} ($\widehat{\tau}^{adv}$)}", modify
	collect label levels var terme_nlI "{\textit{Multiplicative term (in $%$)} ($\widehat{\tau}^{ice}$)}", modify
	collect label levels var terme_A "{\textit{Additive term (in $%$)} ($\widehat{t}/\widetilde{p}$)}", modify
	collect label levels var p_add_dollar "{\textit{Additive term in USD per kg ($\widehat{t}$)}}", modify
	collect label levels var beta "$\widehat{\beta}$:  \textit{-Share of additive costs}", modify
	collect label levels model data "\textbf{Data}"
	collect label levels model nlAetI "{\textbf{Model (B)}}"
	collect label levels model nlI "{\textbf{Model (A)}}"
	
	collect style cell, warn nformat (%3.1f)
	collect style cell var[beta p_add_dollar], warn nformat(%3.2f)
	collect style cell var[prix_fob], warn nformat(%9.0fc)
	collect style cell var[N]#var[Nb_sectors]#var[Nb_partners], warn nformat(%9.0fc)
	collect style column, nodelimiter dups(center) position(top) width(asis)
	

	collect preview
	
	collect export /* 		 
	*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Table_baseline10.tex", /*
	*/ tableonly replace





/*
***Pour les tables A1 et A2 de l’appendix
collect clear
global method baseline
foreach mode in air ves {
	collect clear
	foreach model in nlAetI nlI nlA {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num 1974 1980 1990 2000 2010 2019 {
			open_year_mode_method_model `year' `mode' $method `model'
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
/*
******Pour les tables A3 et A4 de l’appendix (quality of fit)
global method baseline

foreach mode in air ves {
	collect clear
	capture erase $dir_temp/forLLratio_${method}_`mode'.dta, replace
	foreach model in nl nlI nlA {
		capture erase $dir_temp/data_`model'_${method}_`mode'.dta
		foreach year of num 1974 1980 1990 2000 2010 2019 {
			open_year_mode_method_model `year' `mode' $method `model'
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
		
		sort year
		gen error =prix_trsp2 - predict_`model'
		egen blouf = total(error^2*weightN), by(year)
		
		by year : gen SER = (blouf/(_N-Nb_sectors-Nb_partners))^0.5*100
		
		
		drop blouf
	*	gen error =abs(ln(prix_trsp2) - ln(predict_`model'))
		by year: collect r(mean), tags(model[`model'] var[SER]): 	sum SER
		
		by year: collect r(mean), tags(model[`model'] var[R2]): 	sum Rp2_`model'
		by year: collect r(mean), tags(model[`model'] var[aic]): 	sum aic_`model'
		by year: collect r(mean), tags(model[`model'] var[LL]): 	sum logL_`model'
		
		bys year : keep if _n==1
		keep year Nb_partners Nb_sectors logL_`model' mode
		rename Nb_partners Nb_partners_`model'
		rename Nb_sectors Nb_sectors_`model'
		capture drop _merge
		capture noisily merge 1:1 year mode using $dir_temp/forLLratio_${method}_`mode'.dta
		capture drop _merge
		save $dir_temp/forLLratio_${method}_`mode'.dta, replace
	}

	sort year
	gen statLLratioB_A = 2*abs(logL_nlI-logL_nl)
	gen restLLratioB_A = Nb_sectors_nl*2+Nb_partners_nl*2-Nb_sectors_nlI-Nb_partners_nlI
	
	gen statLLratioB_C = 2*abs(logL_nlA-logL_nl)
	gen restLLratioB_C = Nb_sectors_nl*2+Nb_partners_nl*2-Nb_sectors_nlA-Nb_partners_nlA
	
	gen p_value_B_A=chi2den(restLLratioB_A,statLLratioB_A)
	gen p_value_B_C=chi2den(restLLratioB_C,statLLratioB_C)
	
	by year: collect r(mean), tags(var[TestLL] varb[statLLratioB_A]): sum statLLratioB_A
	by year: collect r(mean), tags(var[TestLL] varb[restLLratioB_A]): sum restLLratioB_A
	by year: collect r(mean), tags(var[TestLL] varb[p_value_B_A]): sum p_value_B_A
	
	by year: collect r(mean), tags(var[TestLL] varb[statLLratioB_C]): sum statLLratioB_C
	by year: collect r(mean), tags(var[TestLL] varb[restLLratioB_C]): sum restLLratioB_C
	by year: collect r(mean), tags(var[TestLL] varb[p_value_B_C]): sum p_value_B_C
	
	
	collect layout (var[R2 SER aic LL]#model[nlI nl nlA]#result[mean] /*
		*/ var[TestLL]#varb#result[mean])/* 
		*/ (year)

	
	
	collect label levels model nl "{Model (B)}"
	collect label levels model nlI "{Model (A)}"
	collect label levels model nlA "{Model (C)}"
	collect label levels var R2 "\textbf{\textit{R}$^2$}"
	collect label levels var SER "\textbf{SER (in $%$)}"
	collect label levels var aic "\textbf{AIC criteria}"
	collect label levels var LL "\textbf{Log-likelihood}"
	collect label levels var TestLL "\textbf{Test LL}"
	collect label levels varb statLLratioB_A "Stat LL ratio (B vs A)"
	collect label levels varb statLLratioB_C "Stat LL ratio (B vs C)"
	collect label levels varb restLLratioB_A "$#$ of restrictions (B vs A)"
	collect label levels varb restLLratioB_C "$#$ of restrictions (B vs C)"
	collect label levels varb p_value_B_A "p-value (B vs A)"
	collect label levels varb p_value_B_C "p-value (B vs C)"
	
	
	
	collect style cell, warn nformat (%3.1f)
	collect style cell var[R2], warn nformat(%3.2f)
	collect style cell varb[p_value_B_C], warn nformat(%3.2f)
	collect style cell varb[p_value_B_A], warn nformat(%3.2f)
	collect style cell var[SER], warn nformat(%2.1f)
	collect style cell var[LL aic], warn nformat(%9.0fc)
	collect style cell varb[restLLratioB_C restLLratioB_A], warn nformat(%4.0fc)
	collect style cell varb[statLLratioB_C statLLratioB_A], warn nformat(%9.0fc)
	collect style header result[mean], level(hide)
	

	collect preview
	collect export /* 		 
	*/ $dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Online_Appendix/TableA3_`mode'.tex, /*
	*/ tableonly replace
	
	

	
}


*/
/*
******Pour les tables B appendix

capture program drop tablesB
program tablesB
args start end mode method

collect clear

foreach model in nlAetI nlI nlA {
	capture erase $dir_temp/data_`model'_${method}_`mode'.dta
	foreach year of num `start'/`end'  {
		open_year_mode_method_model `year' `mode' $method `model'
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

*/
/*

******************************Pour la figure 1 du texte
global method baseline

local model nlAetI

capture erase $dir_temp/data_`model'_${method}.dta
foreach mode in air ves {
	foreach year of num 1974/2019  {
		open_year_mode_method_model `year' `mode' $method `model'
		gen share_A = -beta
		egen mean_share_A = wtmean(share_A), weight(val) by(year)
		bys year :keep if _n==1
		keep year mode mean_share_A
		capture append using $dir_temp/data_`model'_${method}.dta
		save $dir_temp/data_`model'_${method}.dta, replace
	}	
}

reshape wide mean_share_A, i(year) j(mode) string
label var mean_share_Aair "Air"
label var mean_share_Aves "Vessel"
twoway (line  mean_share_Aves year, lcolor(black)) (line   mean_share_Aair year, lpattern(dash) lcolor(black)) ,scheme(s1mono)
graph export /*
*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Figure1_share_of_additive_in_totalTC.jpg", replace



******************************Pour la figure 2 du texte
global method baseline

local model nlAetI

capture erase $dir_temp/data_`model'_${method}.dta
foreach mode in air ves {
	foreach year of num 1974/2019  {
		open_year_mode_method_model `year' `mode' $method `model'
		gen est_trsp_cost = (terme_A+terme_I-1)*100
		egen mean_est_trsp_cost = wtmean(est_trsp_cost), weight(val) by(year)
		bys year :keep if _n==1
		keep year mode mean_est_trsp_cost
		capture append using $dir_temp/data_`model'_${method}.dta
		save $dir_temp/data_`model'_${method}.dta, replace
	}	
}

replace mode = "(a) Air" if mode=="air"
replace mode = "(b) Vessel" if mode=="ves"

twoway (line mean_est_trsp_cost year) (lfit mean_est_trsp_cost year), ///
			ytitle("In % of FAS price") yscale(range(0 12)) ylabel(0 (3) 12) xtitle(Year) ///
			xscale(range(1973 2019)) xlabel(1974 1980 (10) 2000 2019) by(mode, legend(off))  scheme(s1mono)

graph export /*
*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Figure2_Trend_of_totalTC_bymode.jpg", replace



************Pour la figure 3 du texte
global method baseline

local model nlAetI

capture erase $dir_temp/data_`model'_${method}.dta
foreach mode in air ves {
	foreach year of num 1974/2019  {
		open_year_mode_method_model `year' `mode' $method `model'
		capture append using $dir_temp/data_`model'_${method}.dta
		save $dir_temp/data_`model'_${method}.dta, replace
	}	
}

replace beta = -beta
label var beta "Share of additive costs"



egen val_tot_year=total(val), by(year mode)
gen share_y_val = round((val/val_tot_year)*100000)

replace mode = "(a) Air transport" if mode=="air"
replace mode = "(b) Vessel transport" if mode=="ves"

* Lise, pb avec le double if et saving - stata version?
* On enleve la boucle sur ponderation

foreach mode in "(a) Air transport" "(b) Vessel transport" {
	
	histogram beta if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) xtitle("Share of additive costs") ytitle("Density") title("`mode' (no ponderation)") scheme(s1mono)
	graph export /*
	*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Etude_beta_nopond_`mode'.jpg", /* */    replace

	histogram beta [fweight=share_y_val] if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) xtitle("Share of additive costs") ytitle("Density") title("`mode'") scheme(s1mono)
	graph export /*
	*/ "$dir_git/redaction/JEGeo/revision_JEGeo/revised_article/Etude_beta_pondere_`mode'.jpg", replace

}

/*
foreach pond in yes no {
	
	foreach mode in ves air {

		if "`pond'"=="no" histogram beta if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) ///
		title ("`mode'")
		saving ("$dir/results/Etude_beta_pond_`pond'_TOT_`mode'.pdf", replace)
		
		
		if "`pond'"=="yes" histogram beta [fweight=share_y_val] if mode=="`mode'" , width(0.025) kdensity kdenopts(bwidth(0.05)) ///
		title ("`mode'") ///
		saving ("$dir/results/Etude_beta_pond_`pond'_TOT_`mode'.pdf", replace) 
		note("Ponderation by share of yearly value of flow : `pond'")
		graph export $dir/results/Etude_beta_pond_`pond'_TOT_`mode'.pdf, replace
	}	
}

*/


	
