

*** GD LP Dec 23/12/2106


version 14.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/trade_cost



if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost


if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost


if ("`c(os)'"=="MacOSX") use $dir/results/estimTC_augmented.dta, clear
if ("`c(os)'"!="MacOSX") use $dir\results\estimTC_augmented.dta, clear

generate random=runiform()
sort random
*keep if _n<=1000


*generate expl_costs = Cost_to_export*Vk/prix_fob
*generate expl_freight = Vk*dist/prix_fob

generate expl_costs = Cost_to_export/prix_fob
generate expl_freight = dist/prix_fob

generate ln_TC_ik =.
generate expl_ins=.

putexcel set Résultats_déterminants_des_coûts_`year'.xlsx, replace

foreach year of num 2005/2013 {
	foreach controle in 0 1 dist {
	
		foreach mode in ves air  {
			
			
			replace expl_ins = ins_`mode'
			
			foreach term in terme_A terme_I terme_iceberg { 
			
				if "`term'"!="terme_A" replace ln_TC_ik = ln(`term'-1) 
				* A prendre en % ?
				if "`term'"=="terme_A" replace ln_TC_ik = ln(`term')
				* A prendre en % ?
	
			
				preserve
				drop if expl_ins==. | expl_freight==. | expl_costs==.
				keep if year==`year'
				keep if mode=="`mode'"
				assert _N>=10
				if `controle'==0 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight))
				*if `controle'==1 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight /*
			*		*/+ {coef_EC=1}*Cost_to_export + {coef_Vk=1}*Vk + {coef_dist=1}*dist + {coef_prix_fob=1}/prix_fob))
				if `controle'==1 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight /*
					*/+ {coef_EC=1}*Cost_to_export +  {coef_dist=1}*dist + {coef_prix_fob=1}/prix_fob))
				if "`controle'"=="dist" nl (ln_TC_ik = log({coef_dist=1}*dist))
			
				putexcel set Résultats_déterminants_des_coûts_`year'.xlsx, sheet(`controle'_`mode'_`term') modify
			
				putexcel C1="Coef."
				matrix b = e(b)'
				putexcel A2=matrix(b), rownames nformat(scientific_d2)
				mata: ecart_types_mata=sqrt(diagonal(st_matrix("e(V)")))
				*matrix ecart_types=(vecdiag(e(V)*e(V)))'
				mata: st_matrix("ecart_types",ecart_types_mata)
				putexcel D1="écart-type"
				putexcel D2=matrix(ecart_types),  nformat(scientific_d2)
				putexcel E1="R2 adjusted"
				local R2_a = e(r2_a)
				putexcel E2=`e(r2_a)', nformat(number_d2) 
				restore
			}
		}
	}
}
