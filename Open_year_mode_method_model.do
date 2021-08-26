
capture program drop open_year_mode_method_model
program open_year_mode_method_model
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

if "`method'"=="baseline5_4" & "`model'"=="nlI"  {
	use "$dir_baseline_results/results_estimTC_`model'_`year'_prod5_sect4_`mode'.dta", clear
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



if "`method'"=="non_separé" {
	use "$dir_results/robustesse_non_separe/results_estimTC_non_séparé_`year'_5_3_`mode'_hummels_tra.dta", clear
	generate beta_method = -(terme_A/(terme_I+terme_A-1))
	capture rename `mode'_val val 
	capture drop *_val
	capture rename product sector
	*rename product sector /*Product is in fact 3 digits*/
	*drop _merge
}	

if "`method'"=="séparé_pour_robustesse_ns" {
	use "$dir_results/robustesse_non_separe/results_estimTC_séparé_pour_robustesse_ns_`year'_5_3_`mode'_hummels_tra.dta", clear
	generate beta_method = -(terme_A/(terme_I+terme_A-1))
	capture rename `mode'_val val 
	capture drop *_val
	capture rename product sector
	*rename product sector /*Product is in fact 3 digits*/
	*drop _merge
}	


capture egen cover_`method'=total(val)

capture drop year
gen year=`year'

*save $dir_temp/data_`method'_`year'_`mode'.dta, replace

end
