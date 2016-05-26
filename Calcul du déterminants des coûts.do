

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


generate random=runiform()
sort random
*keep if _n<=1000


generate expl_costs = Cost_to_export*Vk/prix_fob
generate expl_freight = Vk*dist/prix_fob



generate ln_TC_ik =.
generate expl_ins=.

putexcel set Résultats_déterminants_des_coûts_`year'.xlsx, replace

foreach year of num 2005/2013 {
	foreach controle in 0 1 dist {
	
		foreach mode in ves air  {
			
			
			replace expl_ins = ins_`mode'
			
			foreach term in terme_A terme_I terme_iceberg { 
			
				if "`term'"!="terme_A" replace ln_TC_ik = ln(`term'-1)
				if "`term'"=="terme_A" replace ln_TC_ik = ln(`term')
	
			
				preserve
				drop if expl_ins==. | expl_freight==. | expl_costs==.
				keep if year==`year'
				keep if mode=="`mode'"
				assert _N>=10
				if `controle'==0 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight))
				if `controle'==1 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight /*
					*/+ {coef_EC=1}*Cost_to_export + {coef_Vk=1}*Vk + {coef_dist=1}*dist + {coef_prix_fob}/prix_fob))
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
blourk

 ln_TC_ik prix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')






******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE AVEC ADDITIFS ET ICEBERG ****
******************************************************************

capture program drop nldeter_trsp
program nldeter_trsp
	version 14.1
	su group_iso_o, meanonly	
	local nbr_iso_o=r(max)
	su group_prod, meanonly	
	local nbr_prod=r(max)
	local nbr_var = `nbr_iso_o'+`nbr_prod'-1 +2 /*+11*/
		
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)
	local n 1
	
	
	foreach var in ln_TC_ik  prix_fob /*dist contig comlang_off comlang_ethno colony comcol curcol col45 smctry*/ {
		local `var' : word `n' of `varlist'
		local n = `n'+1
	}
	*/
	local n 1

	
	
	
	ln(`ln_TC_ik')=ln(Cost_to_export*effet_fixe_Vk/prix_fob + ins + effet_fixe_Vk*dist/prix_fob + Cost_to_export + effet_fixe_Vk)
	
	
	
	
	capture drop terme_A
	capture drop terme_I
	generate double terme_A=0
	generate double terme_I=1
	
		

**Ici, on fait les effets fixes (à la fois dans le terme additif et le terme multiplicatif)
	
		foreach p in iso_o prod {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="iso_o" | `j'!=1 {
					tempname feA_`p'_`j'
***************Remplac v9				
*					scalar `feA_`p'_`j'' =`at'[1,`n']
*Si on suppose que des coûts de transport additifs, des cdt multiplicatifs, des droits
*de douane ad valorem, des droits de douane en quantité => il faudrait "+" dans le terme_A
*et "*" dans le terme_I
***********************
					tempname lnfeA_`p'_`j'
					scalar `lnfeA_`p'_`j'' =`at'[1,`n']
					scalar `feA_`p'_`j'' =exp(`lnfeA_`p'_`j'')
************************

					replace terme_A = terme_A + `feA_`p'_`j'' * `p'_`j'
					local n = `n'+1
				}
			}
		}
	
	
			foreach p in iso_o prod {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="iso_o" | `j'!=1 {	
					tempname feI_`p'_`j'
***************Remplac v9			
*					scalar `feI_`p'_`j'' =`at'[1,`n']
*****************************ln(fe-1)
					tempname lnfem1I_`p'_`j'
					scalar `lnfem1I_`p'_`j'' =`at'[1,`n']
					scalar `feI_`p'_`j'' =exp(`lnfem1I_`p'_`j'')+1
****************************
*outv9				replace terme_I = terme_I *exp(`p'_`j'*`feI_`p'_`j'' )
					replace terme_I = terme_I *`feI_`p'_`j'' if `p'_`j'==1
*Si on suppose que des coûts de transport additifs, des cdt multiplicatifs, des droits
*de douane ad valorem, des droits de douane en quantité => il faudrait "+" dans le terme_I
*et "*" dans le terme_I
					local n = `n'+1
				}
			}
		}

	
*out v9	replace terme_A=(terme_A-1)/`prix_fob'

	replace terme_A=terme_A/`prix_fob'

* v10 on modifie la forme fonctionnelle
* de cette façon les erreurs sont bien centrées sur 0
	replace `ln_ratio_minus1'=ln(terme_A  +terme_I-1)
	
*Si je mets des "*" dans le terme_I, il me faut une constante
*Mais dans la forme fonctionnelle, il n'y a pas de constante, donc pas besoin ?
	
	
end
**********************************************************************
************** FIN FONCTION
**********************************************************************	





