

*************************************************

* 
*************************************************

*version 12





if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaisons_various"
	global dir_temp ~/Downloads/temp_stata
	global dir_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results"
	global dir_redaction  "~/Répertoires Git/trade_costs_git/redaction/JEGeo/revision_JEGeo/revised_article"
	global dir_git  "~/Répertoires Git/trade_costs_git/"
	
	
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
*******************************************************


set more off
local mode ves air
*local year 1974 

cd "$dir_git"
do Estim_value_TC.do


***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


capture program drop collecte_beta
program collecte_beta
args mode year




capture log close
log using hummels_3digits_complet_`year'_`mode', replace

global test
*global test test
prep_reg db_samesample_5_3_HS10 `year' 5 3 `mode'

*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close


matrix Esperance_`mode'_`year'=X
matrix Var_Covariance_`mode'_`year'=ET	

set seed 525245224
drawnorm $liste_parametres, n(10000) means(Esperance_`mode'_`year') cov(Var_Covariance_`mode'_`year') clear

save temp.dta, replace

clear
clear matrix
clear mata
global number_var = max(11000,wordcount("$liste_iso_o")*wordcount("$liste_sect")*2+1000)
*set maxvar  $number_var, perm
set maxvar 50000




use "$dir_data/db_samesample_sitc2_3", clear
generate pair = iso_o + "_" + sitc2
levelsof pair, local(list_sample)

use temp.dta, clear
*local z `year'
*local x "`mode'"

local prod_num=0
**La référence est prod_num=1
foreach prod of global liste_sect {
	local prod_num=`prod_num'+1	
	local iso_num=0
	foreach iso of global liste_iso_o { 
		local iso_num=`iso_num'+1
		
		local danssample 0
		if strpos(`"`list_sample'"',"`iso'_`prod'") !=0 local danssample 1
		
		display "`danssample'"				
			
		if `prod_num' !=1 & `danssample'==1 {
			generate t_`prod'_`iso' = exp(lnfeA_sect_`prod_num')+exp(lnfeA_iso_o_`iso_num')
		}
		
		if `prod_num' ==1 & `danssample'==1 {
			generate t_`prod'_`iso' = exp(lnfeA_iso_o_`iso_num')
		}




/*
		preserve
		collapse (p5) beta*
		gen type = "p5beta"
		save temp2.dta,replace
		
		restore
		preserve
		
		collapse (p50) beta*
		gen type = "p50beta"
		append using temp2.dta
		save temp2.dta,replace
		
		restore
		preserve 
		
		collapse (p95) beta*
		gen type = "p95beta"
		append using save temp2.dta
		
		xpose, clear varname
		
		save disp_beta_`mode'_`year'.dta,replace
		
		
	*/	
		
		
	}
}


drop ln*
xpose, clear varname
rename v* t*
replace _varname = substr(_varname,3,.)
save temp2_t.dta,replace



use temp.dta, clear
local prod_num=0
**La référence est prod_num=1
foreach prod of global liste_sect {
	local prod_num=`prod_num'+1	
	local iso_num=0
	foreach iso of global liste_iso_o { 
		local iso_num=`iso_num'+1
		
		local danssample 0
		if strpos(`"`list_sample'"',"`iso'_`prod'") !=0 local danssample 1
		
		
		
		if `prod_num' !=1 & `danssample'==1 {
			generate tau_`prod'_`iso' = (exp(lnfem1I_sect_`prod_num')+1)*(exp(lnfem1I_iso_o_`iso_num')+1)
		}
		
		if `prod_num' ==1 & `danssample'==1 {
			generate tau_`prod'_`iso' = exp(lnfem1I_iso_o_`iso_num')+1
		}
	}
}

drop ln*
xpose, clear varname
rename v* tau*
replace _varname = substr(_varname,5,.)
merge 1:1 _varname using temp2_t.dta
gen iso_o = substr(_varname,5,3)
gen sitc2 = substr(_varname,1,3)
order sitc2 iso_o _varname
drop _merge	
save temp_t_tau.dta, replace
use "$dir_data/db_samesample_sitc2_3.dta", clear
keep if year==`year'
merge m:1 iso_o sitc2  using temp_t_tau.dta

foreach i of numlist 1(1)1000 {
	generate beta`i' =-(t`i'/prix_fob)/(tau`i' -1 + t`i'/prix_fob)
}


save temp_beta.dta, replace

egen beta_baseline_05=rowpctile(beta1-beta1000), p(05)
egen beta_baseline_50=rowpctile(beta1-beta1000), p(50)
egen beta_baseline_95=rowpctile(beta1-beta1000), p(95)

save temp_beta.dta, replace

drop tau1-beta1000
drop country

collapse (sum) `mode'_val (mean) beta_min beta_max beta_baseline_05 beta_baseline_50 beta_baseline_95,by(iso_o sitc2)
drop if `mode'_val==0

gen amplitude_baseline = abs(beta_baseline_95-beta_baseline_05)
gen amplitude_referee1 = abs(beta_max-beta_min)

gen ratio_amplitude = amplitude_baseline/amplitude_referee1

gen log_ratio_amplitude=ln(ratio_amplitude)
hist log_ratio_amplitude
gen log_ratio_amplitude_censored = max(log_ratio_amplitude,-4)

save "$dir_comparaison/comparaison_amplitude_baseline_referee1_`year'_`mode'", replace
	
end

*****Programme pour le graphique


capture program drop graphique
program graphique
args mode year


use "$dir_comparaison/comparaison_amplitude_baseline_referee1_`year'_`mode'", clear

label var log_ratio_amplitude_censored "Log of the ratio of the confidence intervals, censored at -4 (`mode', `year')"


hist log_ratio_amplitude_censored, percent start(-4) bin(20) scheme(s1mono)
graph export "$dir_comparaison/comparaison_amplitude_baseline_referee1_`year'_`mode'.png", replace
graph export "$dir_redaction/comparaison_amplitude_baseline_referee1_`year'_`mode'.png", replace

/*Pour le pondéré
hist log_ratio_amplitude_censored [fweight=ves_val], percent start(-4) title(Weighted by value of trade flow) bin(20) scheme(s1mono)
graph export "$dir_comparaison/comparaison_amplitude_baseline_referee1_`year'_`mode'_weighted.png", replace
*/
end




*collecte_beta ves 2013
collecte_beta air 2013
*graphique ves 2013
graphique air 2013

erase temp_beta.dta
erase temp_t_tau.dta
erase temp2_t.dta


/*
reshape long termeA,i(tirage) j(prod_iso) string
save temp3.dta
use temp2.dta
keep tirage termeI*
reshape long termeA,i(tirage) j(prod_iso) string
merge 1:1 prod_iso using temp3.dta


blif
*/















