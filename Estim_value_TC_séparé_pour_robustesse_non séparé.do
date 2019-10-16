**Reprise Novembre 2017 du programme «Estim_value_TC» pour faire le calcul en non séparé





*************************************************
* Programme : Estimer les additive & iceberg trade costs
* Using Hummels trade data
*
*	Octobre 2016
* 
*************************************************

*version 12

/* Itération sur forme d'estimation 


**** on coupe les extrêmes à 5%
**** Stratégie d'estimation

** 1. Toutes les années pour air/ vessel en 3 digits
** 2. Tous les 5 ans pour 4 digits, air/vessel
** 3. Trois programmes, trois fonctions, pour 3 modèles

* A. Modele iceberg seulement / Modele additif seulement / Modele I et A

**Version 9 : GD j'essaye d'implémenter la contrainte comme expliqué là: http://www.stata.com/support/faqs/statistics/linear-regression-with-interval-constraints/
**voir lignes 102-111 // 124-130

*/

if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost
}

cd $dir


***************** Avril 2015 ***********************************************************
*** v10 : On impose les contraintes termeA>=0 et termeI<=1 (v9)
*** Et on réfléchit "bien" sur le terme d'erreur, pour avoir une erreur centrée réduite

*** Ce qui nous amène à l'estimation

** ln (obs -1) = ln(predit -1) ¨eps(ik)
** Avec obs = pcif(ik)/pfob(ik)
** Et predit = tau(i)*tau(k) + (t(i)+t(k))/p(fob)ik

*** En cohérence avec l'estimation via nl, qui minimise la variance de l'erreur additive

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



* stocker sur la dropbox, depuis mon laptop
*cd "C:\Users\lise\Dropbox\trade_cost\results\New_years"

* sur le serveur
*cd "C:\Echange\trade_costs\results"

****** timer clear ********


****************Calcul pour trouver les pays qui font 80% du commerce********

capture program drop a_garder
program a_garder
args mode year



use "$dir/data/hummels_tra.dta", clear

keep if year==`year' & mode=="`mode'"
gen tot_val = `mode'_val
collapse (sum) tot_val, by(iso_o)
gsort - tot_val
egen val_tous_pays=total(tot_val)
gen share = tot_val/val_tous_pays
gen share_cum = sum(share)
drop if share_cum >= 0.8
levelsof iso_o, local(pays_a_garder) clean
global pays_a_garder "`pays_a_garder'"

*************Idem pour les produits
use "$dir/data/hummels_tra.dta", clear

keep if year==`year' & mode=="`mode'"
gen tot_val = `mode'_val
gen sitc2_3 = substr(sitc2,1,3)
collapse (sum) tot_val, by(sitc2_3)
gsort - tot_val
egen val_tous_sitc=total(tot_val)
gen share = tot_val/val_tous_sitc
gen share_cum = sum(share)
drop if share_cum >= 0.8
levelsof sitc2_3, local(sitc_a_garder) clean
global sitc_a_garder "`sitc_a_garder'"

end




******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE AVEC ADDITIFS ET ICEBERG ****
******************************************************************

capture program drop nlcouts_IetA

program nlcouts_IetA
	version 12
	su group_iso_o, meanonly	
	local nbr_iso_o=r(max)
	su group_prod, meanonly	
	local nbr_prod=r(max)
	local nbr_var = `nbr_iso_o'+`nbr_prod'-1 +2 /*+11*/
		
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)
	local n 1
	
	
	foreach var in ln_ratio_minus1  prix_fob /*dist contig comlang_off comlang_ethno colony comcol curcol col45 smctry*/ {
		local `var' : word `n' of `varlist'
		local n = `n'+1
	}
	*/
	local n 1
	
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


**********************************************************************
************** PROGRAMME PREPARATION BASE DE DONNEES 
**********************************************************************	


capture program drop prep_reg
program prep_reg

args year class preci mode
* exemple : prep_reg 2006 sitc2ns 3 air
* Hummels : sitc2
* On utilise class pour indiquer que c'est non séparé

a_garder `mode' `year'
macro dir


****************Préparation de la base blouk

use "$dir/data/hummels_tra.dta", clear



***Pour restreindre
*keep if substr(sitc2,1,1)=="0"
*************************

keep if year==`year'
keep if mode=="`mode'"
rename sitc2 product
replace product = substr(product,1,`preci')
egen total_trade = total(`mode'_val)
keep if strpos("$pays_a_garder",iso_o)!=0
keep if strpos("$sitc_a_garder",product)!=0


egen study_trade = total(`mode'_val)
gen share_of_trade = study_trade/total_trade
tab share_of_trade

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"


* Nettoyer la base de donnÈes

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************


/*
display "Nombre avant bas et haut " _N

bys product: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys product: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 


display "Nombre après bas et haut " _N

*/

egen prix_min = min(prix_trsp2), by(product)
egen prix_max = max(prix_trsp2), by(product)

g lprix_trsp2 = ln(prix_trsp2)
label variable lprix_trsp2 "log(prix_caf/prix_fob)"
*g lprix_trsp2 = ln(prix_trsp2)

g ldist = ln(dist)
label variable ldist "log(distance)"

**********Sur le produits

codebook product


egen group_prod=group(product)
su group_prod, meanonly	
drop group_prod
local nbr_prod_exante=r(max)
display "Nombre de produits : `nbr_prod_exante'" 

bysort product: drop if _N<=5

egen group_prod=group(product)
su group_prod, meanonly	
local nbr_prod_expost=r(max)
drop group_prod
display "Nombre de produits : `nbr_prod_expost'" 

*/
timer clear


*Pour nombre de product
quietly egen group_prod=group(product)
su group_prod, meanonly	
local nbr_prod=r(max)
quietly levelsof product, local (liste_prod) clean
quietly tabulate product, gen (prod_)
	
*Pour nombre d'iso_o
quietly egen group_iso_o=group(iso_o)
su group_iso_o, meanonly	
local nbr_iso_o=r(max)
*Donne le nbr d'iso_o
quietly levelsof iso_o, local(liste_iso_o) clean
quietly tabulate iso_o, gen(iso_o_)


foreach i in prod iso_o	{
	local liste_variables_`i' 
	forvalue j =  1/`nbr_`i'' {
		if "`i'" !="prod" | `j' !=1 {
			local liste_variables_`i'  `liste_variables_`i'' `i'_`j'
		}
	}


***************************************

		local liste_parametres_`i'_A
		forvalue j =  1/`nbr_`i'' {
			if  "`i'" !="prod" | `j'!=1 {			
				local liste_parametres_`i'_A  `liste_parametres_`i'_A' lnfeA_`i'_`j'
			}
		}


		local liste_parametres_`i'_I
		forvalue j =  1/`nbr_`i'' {
			if  "`i'" !="prod" | `j'!=1 {			
				local liste_parametres_`i'_I  `liste_parametres_`i'_I' lnfem1I_`i'_`j'
			}
		}

**************************************

	
	foreach g in A I {
		local initial_`i'_`g'
		forvalue j =  1/`nbr_`i'' {
			if  "`i'" !="prod" |`j'!=1 {
				if "`g'" =="A" {
*out v9			local initial_`i'_`g'  `initial_`i'_`g'' fe`g'_`i'_`j' 1 
					local initial_`i'_`g'  `initial_`i'_`g'' lnfeA_`i'_`j' -3
				}
				if "`g'" =="I" {
*out v9			local initial_`i'_`g'  `initial_`i'_`g'' fe`g'_`i'_`j' 1
					local initial_`i'_`g'  `initial_`i'_`g'' lnfem1I_`i'_`j' -3
****ln(0.05) = -3
				}
			}
		}		
	}
/*
foreach g in A {
		local initial_additif_`i'_`g'
		forvalue j =  1/`nbr_`i'' {
			if  "`i'" !="prod" |`j'!=1 {
				if "`g'" =="A" {
*out v9			local initial_`i'_`g'  `initial_`i'_`g'' fe`g'_`i'_`j' 1 
					local initial_additif_`i'_`g'  `initial_additif_`i'_`g'' lnfeA_`i'_`j' 
				}
				
			}
		}		
	}
	
*/
	
}


* v10, on estime le log du ratio ob -1
gen ln_ratio_minus1 = ln(prix_trsp2 -1)



local liste_variables `liste_variables_prod' `liste_variables_iso_o'

** pour estimation NL both A & I
local liste_parametres `liste_parametres_prod_A' `liste_parametres_iso_o_A' `liste_parametres_prod_I' `liste_parametres_iso_o_I'  
local initial `initial_prod_A' `initial_iso_d_A' `initial_prod_I' `initial_iso_d_I' 

** pour estimation NL iceberg only
local liste_parametres_iceberg `liste_parametres_prod_I' `liste_parametres_iso_o_I'  
local initial_iceberg `initial_prod_I' `initial_iso_d_I' 

** pour estimation NL additif only
local liste_parametres_additif `liste_parametres_prod_A' `liste_parametres_iso_o_A' 
local initial_additif `initial_prod_A' `initial_iso_d_A' 
*local initial_additif `initial_additif_prod_A' `initial_additif_iso_d_A'


* ------------------------------------------------
******** ESTIMATION AVEC COUTS ADDITIF ET ICEBERG
* ------------------------------------------------


timer on 3

* attention on durçit la règle pour 1987, vess


display "nl couts_IetA @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')"

*nl couts_trsp @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-2) iterate(200) parameters(`liste_parametres' ) initial (`initial')
nl couts_IetA @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')


capture	generate rc=_rc
*capture	predict predict
capture	predict blink_nl

gen predict_nl = exp(blink_nl)+1 
*capture	generate predict=exp(lpredict)	
capture	generate converge=e(converge)
*capture generate R2 = e(r2)
capture generate t = terme_A*prix_fob

** Mesurer le fit du modèle
** (1) Coefficient R2
*capture correlate lnprix_obs lnpredit_nl
capture correlate ln_ratio_minus1 blink_nl
capture generate Rp2_nl = r(rho)^2

noisily capture  order iso_o iso_d product prod_pays prix_fob prix_trsp2 converge predict lpredict terme* t /* e_t_rho* predict_calcul couts FE* 	*/

capture	matrix X= e(b)
capture matrix ET=e(V)
local nbr_var = e(k)/2

generate nbr_obs=e(N)
bysort product : generate nbr_obs_prod=_N
bysort iso_o : generate nbr_obs_iso=_N
generate  coef_iso_A =.
generate  coef_iso_I =.
generate  coef_prod_A =.
generate  coef_prod_I =.
generate  ecart_type_iso_A=.
generate  ecart_type_iso_I=.
generate  ecart_type_prod_A=.
generate  ecart_type_prod_I=.


** Mesurer le fit du modèle (cont')
gen aic_nl= .
gen logL_nl = .

estat ic
capture matrix Z= r(S)

* (2) AIC 
replace aic_nl = Z[1,5]

* (3) log-likelihood
replace logL_nl = Z[1,3]


display "`liste_variables'"
local n 1
local m = `nbr_var'+1
foreach i in `liste_variables' {
	if strmatch("`i'","*prod*")==1 {
		quietly replace coef_prod_A =exp(X[1,`n']) if `i'==1
		quietly replace coef_prod_I =exp(X[1,`m'])+1 if `i'==1
		quietly replace ecart_type_prod_A =ET[`n',`n']^0.5 if `i'==1
		quietly replace ecart_type_prod_I =ET[`m',`m']^0.5 if `i'==1
	}
	if strmatch("`i'","*iso*")==1 {
		quietly replace coef_iso_A =exp(X[1,`n']) if `i'==1
		quietly replace coef_iso_I =exp(X[1,`m'])+1 if `i'==1
		quietly replace ecart_type_iso_A =ET[`n',`n']^0.5 if `i'==1
		quietly replace ecart_type_iso_I =ET[`m',`m']^0.5 if `i'==1
	}
	
	local n = `n'+1
	local m = `m'+1
}


sum terme_A  [fweight=`mode'_val], det
generate terme_A_mp = r(mean)
generate terme_A_med = r(p50)
generate terme_A_et = r(sd)
gen terme_A_min = r(min)
gen terme_A_max = r(max)

sum terme_I  [fweight=`mode'_val], det 	
generate terme_I_mp = r(mean)
generate terme_I_med = r(p50)
generate terme_I_et=r(sd)
gen terme_I_min = r(min)
gen terme_I_max = r(max)

duplicates report


timer off 2
timer list 2

capture drop Duree_estimation_secondes
generate Duree_estimation_secondes = r(t2)
capture generate machine =  "`c(hostname)'__`c(username)'"


*/

timer clear


save "$dir/results/results_estimTC_`year'_`class'_`preci'_`mode'", replace



end



*******************************************************
***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


set more off
local mode ves air
*local year 1974 

foreach x in `mode' {

*foreach z in `year' {

forvalues z = 1974(1)2013 {


capture log close
log using hummels_3d_séparé_pour_robustesse_`z'_`x', replace

prep_reg `z' sitc2separe 3 `x'


*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close

}
}





