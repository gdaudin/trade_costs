

*************************************************
* Programme : Lancer les estimations 

*	Estimer les additive & iceberg trade costs
* 	Using Hummels trade data (version soumission)
*
*	Mars 2020
* 
*************************************************

*version 12



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_pgms $dir/trade_costs_git
}

** Fixe Lise bureau
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}

/* Vieux portable Lise
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}
*/

/* Nouveau portable Lise */

if "`c(hostname)'" =="MSOP112C" {
  
	*global dir C:\Lise\trade_costs
	global dir_pgms C:\Users\Ipatureau\Documents\trade_costs
	
}

*******************************************************


set more off
local mode ves air
*local year 1974 

cd "$dir_pgms"
do Estim_value_TC.do


***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


foreach x in `mode' {

	foreach z in 2013 {
	
		*** SOUMISSION: hummels_tra.dta ou db_samesample_sitc2_3
		
		capture log close
		log using hummels_3digits_complet_`z'_`x', replace
		
		prep_reg db_samesample_sitc2_3 `z' sitc2 3 `x'
		
		*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
		*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"
		
		log close
		
		
		matrix Esperance_`x'_`z'=X
		matrix Var_Covariance_`x'_`z'=ET	
	
		set seed 525245224
		drawnorm $liste_parametres, n(10000) means(Esperance_`x'_`z') cov(Var_Covariance_`x'_`z') clear
	
		save temp.dta, replace
		clear
		clear matrix
		clear mata
		local number_var = wordcount("$liste_iso_o")*wordcount("$liste_prod")*2+1000
		set maxvar  `number_var'
		
		
		use "$dir_data/db_samesample_sitc2_3", clear
		generate pair = iso_o + "_" + sitc2
		levelsof pair, local(list_sample)
		
		use temp.dta, clear
		local z 2013
		local x ves
		
		local prod_num=0
		**La référence est prod_num=1
		foreach prod of global liste_prod {
			local prod_num=`prod_num'+1	
			local iso_num=0
			foreach iso of global liste_iso_o { 
				local iso_num=`iso_num'+1
				
				local danssample 0
				if strpos(`"`list_sample'"',"`iso'_`prod'") !=0 local danssample 1
				
				display "`danssample'"				
					
				if `prod_num' !=1 & `danssample'==1 {
					generate t_`prod'_`iso' = exp(lnfeA_prod_`prod_num')+exp(lnfeA_iso_o_`iso_num')
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
				
				save disp_beta_`x'_`z'.dta,replace
				
				
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
		foreach prod of global liste_prod {
			local prod_num=`prod_num'+1	
			local iso_num=0
			foreach iso of global liste_iso_o { 
				local iso_num=`iso_num'+1
				
				local danssample 0
				if strpos(`"`list_sample'"',"`iso'_`prod'") !=0 local danssample 1
				
				
				
				if `prod_num' !=1 & `danssample'==1 {
					generate tau_`prod'_`iso' = (exp(lnfem1I_prod_`prod_num')+1)*(exp(lnfem1I_iso_o_`iso_num')+1)
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
		keep if year==2013
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
		
		gen amplitute_baseline = abs(beta_baseline_95-beta_baseline_05)
		gen amplitute_referee1 = abs(beta_max-beta_min)
		
		gen ratio_amplitude = amplitute_baseline/amplitute_referee1
		
		gen log_ratio_amplitude=ln(ratio_amplitude)
		hist log_ratio_amplitude
		gen log_ratio_amplitude_censored = max(log_ratio_amplitude,-4)
		
		save "$dir/results/comparaison_amplitute_baseline_referee1_`z'_`x'", replace
		
		
		label var log_ratio_amplitude_censored "ln(amplitude_beta_baseline/amplitude beta), censored at -4"

		
		hist log_ratio_amplitude_censored, percent start(-4) bin(20)
		graph export "$dir/results/comparaison_amplitute_baseline_referee1_`z'_`x'.pdf", replace
		
		hist log_ratio_amplitude_censored [fweight=ves_val], percent start(-4) title(Weighted by value of trade flow) bin(20)
		graph export "$dir/results/comparaison_amplitute_baseline_referee1_`z'_`x'_weighted.pdf", replace
		

		
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
	
	
		
	}
	
}

