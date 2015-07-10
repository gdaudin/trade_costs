*************************************************
* Programme 2 : Programme pour estimer les additive & iceberg trade costs
* Using Hummels trade data
* 
*************************************************

version 12

/* Itération sur forme d'estimation 
*v1 : vient de Cožts de commerce_v4
*Adaptation aux donnŽes de Hummels
*v2 : reprise 18/2
* v3: on relache contrainte "replace terme_A= 0 if terme_A+terme_I <=0" l. 201
* v4: on remet la contrainte l. 201 "replace terme_A= 0 if terme_A+terme_I <=0"
* 	  mais on modifie la construction de terme A: replace terme_A=(terme_A-1)/`prix_fob' devient 
*	  replace terme_A=(terme_A)/`prix_fob'
* v5 : On réactive terme A: replace terme_A=(terme_A-1)/`prix_fob' et on remplace la contrainte de v2 
* 		quand termeA+termeI=0, par "replace replace `lprix_trsp2'=ln(1) if (terme_A+terme_I) <= 0) "

* v6: on (re)part sur une estimation sur le niveau (prif cif/fob) et non le log

**** 1 avril 2014 (ce n'est pas un poisson)
**** vfinal : on reprend version 6, sauf qu'on coupe les extrêmes à 5%
**** Stratégie d'estimation

** 1. Toutes les années pour air/ vessel en 3 digits
** 2. Tous les 5 ans pour 4 digits, air/vessel
** 3. En 1974, 1989 et 2004 (tous les 15 ans) en 5 digits, air/vessel

**Version 9 : GD j'essaye d'implŽmenter la contrainte comme expliquŽ lˆ : http://www.stata.com/support/faqs/statistics/linear-regression-with-interval-constraints/
**voir lignes 102-111 // 124-130

*/

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



* sur mon laptop
*cd "C:\Lise\trade_costs\Hummels\resultats\new"

* sur le serveur
cd "C:\Echange\trade_costs\results"

****** timer clear ********

******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE AVEC ADDITIFS ET ICEBERG ****
******************************************************************

capture program drop nlcouts_trsp
program nlcouts_trsp
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
/*
	tempname rho_ice rho_add add_contig add_comlang_off add_comlang_ethno add_colony add_comcol add_curcol add_col45 add_smctry ice_contig ice_comlang_off ice_comlang_ethno ice_colony ice_comcol ice_curcol ice_col45 ice_smctry 


	foreach para in rho_ice rho_add add_contig add_comlang_off add_comlang_ethno add_colony add_comcol add_curcol add_col45 add_smctry  {
		scalar ``para'' = `at'[1,`n']
		local n = `n'+1
	}
	

	foreach para in ice_contig ice_comlang_off ice_comlang_ethno ice_colony ice_comcol ice_curcol ice_col45 ice_smctry  {
		scalar ``para'' = `at'[1,`n']
		local n = `n'+1
	}

	capture drop terme_A
	capture drop terme_I
	generate double terme_A=(`dist'^`rho_add'+`contig'*`add_contig' + `comlang_off'*`add_comlang_off' +`comlang_ethno'*`add_comlang_ethno' +`colony'*`add_colony' +`comcol'*`add_comcol' +`curcol'*`add_curcol' +`col45'*`add_col45' +`smctry'*`add_smctry')
	generate double terme_I=(`dist'^`rho_ice'*exp(`contig'*`ice_contig')* exp(`comlang_off'*`ice_comlang_off')*exp(`comlang_ethno'*`ice_comlang_ethno')*exp(`colony'*`ice_colony')*exp(`comcol'*`ice_comcol')* exp(`curcol'*`ice_curcol')*exp(`col45'*`ice_col45')*exp(`smctry'*`ice_smctry'))
*/
	
	
	capture drop terme_A
	capture drop terme_I
	generate double terme_A=0
	generate double terme_I=1
	
		

**Ici, on fait les effets fixes (à la fois dans le terme additif et le terme multiplicatif)
	
		foreach p in iso_o prod {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="iso_o" | `j'!=1 {
					tempname feA_`p'_`j'
***************RemplacŽ v9				
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
***************RemplacŽ v9			
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


******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE AVEC ICEBERG SEULEMENT ****
******************************************************************

capture program drop nlcouts_iceberg

program nlcouts_iceberg
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
	
	local n 1

	capture drop terme_iceberg
	generate double terme_iceberg=1
	
**Ici, on fait les effets fixes 
	
			foreach p in iso_o prod {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="iso_o" | `j'!=1 {	
					tempname feI_`p'_`j'
***************RemplacŽ v9			
*					scalar `feI_`p'_`j'' =`at'[1,`n']
*****************************ln(fe-1)
					tempname lnfem1I_`p'_`j'
					scalar `lnfem1I_`p'_`j'' =`at'[1,`n']
					scalar `feI_`p'_`j'' =exp(`lnfem1I_`p'_`j'')+1
****************************
*outv9				replace terme_iceberg = terme_iceberg *exp(`p'_`j'*`feI_`p'_`j'' )
					replace terme_iceberg = terme_iceberg *`feI_`p'_`j'' if `p'_`j'==1

					local n = `n'+1
				}
			}
		}

* v10 idem on change la forme fonctionnelle
	replace `ln_ratio_minus1'= ln(terme_iceberg -1)
	
	
end
**********************************************************************
************** FIN FONCTION
**********************************************************************	

**********************************************************************
************** PROGRAMME ESTIMATION 
**********************************************************************	


capture program drop reg_termes_h
program reg_termes_h
	args year class preci mode
* exemple : reg_termes_h 2006 sitc2 3 air
*Hummels : sitc2


****************Préparation de la base blouk
* sur mon laptop
*use "C:\Lise\trade_costs\Hummels\database\hummels_tra.dta", clear

* sur le serveur
use "C:\Echange\trade_costs\database\hummels_tra.dta", clear

***Pour restreindre
*keep if substr(sitc2,1,1)=="0"
*************************

keep if year==`year'
keep if mode=="`mode'"
rename `class' product
replace product = substr(product,1,`preci')

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"


* Nettoyer la base de donnÈes

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************



display "Nombre avant bas et haut " _N

bys product: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys product: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 


display "Nombre après bas et haut " _N

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

*** Tester le pgm

/*
* Pour faire un plus petit sample
local limite 80

* On enlève les pays les plus petits (<=80% des flux, par mode considéré)
bys iso_o: egen total_iso_o = total(`mode'_val)
egen seuil_pays = pctile(total_iso_o),p(`limite')

drop if total_iso_o <= seuil_pays


* On enlève les roduits les plus petits (<=80% des flux, par mode considéré)
bys product: egen total_product = total(`mode'_val)
egen seuil_product = pctile(total_product),p(`limite')

drop if total_product <= seuil_product
*/

timer clear



******************************************Régression


*	bysort iso_o: drop if _N==1
*	bysort iso_d: drop if _N==1

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


**********ModifiŽ v9
*	foreach g in A I {
*		local liste_parametres_`i'_`g'
*		forvalue j =  1/`nbr_`i'' {
*			if  "`i'" !="prod" | `j'!=1 {			
*				local liste_parametres_`i'_`g'  `liste_parametres_`i'_`g'' fe`g'_`i'_`j'
*			}
*		}
*	}



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


	
	
}

* v10, on estime le log du ratio ob -1
gen ln_ratio_minus1 = ln(prix_trsp2 -1)



local liste_variables `liste_variables_prod' `liste_variables_iso_o'

** pour estimation NL both A & I
local liste_parametres `liste_parametres_prod_A' `liste_parametres_iso_o_A' `liste_parametres_prod_I' `liste_parametres_iso_o_I'  
local initial `initial_prod_A' `initial_iso_d_A' `initial_prod_I' `initial_iso_d_I' 

** pour estimation NL iceberg only
local initial_iceberg `initial_prod_I' `initial_iso_d_I' 
local liste_parametres_iceberg `liste_parametres_prod_I' `liste_parametres_iso_o_I'  

timer on 1

*** ESTIMATION NL SUR ICEBERG SEULEMENT



nl couts_iceberg @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-2) iterate(100) parameters(`liste_parametres_iceberg' ) initial (`initial_iceberg')



capture	generate rc_nlI=_rc
*capture	predict predict
capture	predict blink_nlI

gen predict_nlI = exp(blink_nlI)+1

*capture generate predict_nlI=exp(lpredict)	
*rename lpredict lpredict_nlI
capture	generate converge_nlI=e(converge)
*capture generate R2_nlI = e(r2)

** Mesurer le fit du modèle
** (1)  R2 sur la relation entre le log(ratio obs) et log(predict_nlI)

capture correlate ln_ratio_minus1 blink_nlI
capture generate Rp2_nlI = r(rho)^2


noisily capture  order iso_o iso_d product prix_fob prix_trsp2 converge_nlI predict_nlI predict_nlI 

capture	matrix X= e(b)
capture matrix ET=e(V)
local nbr_var_nlI = e(k)/2

generate nbr_obs_nlI=e(N)
bysort product : generate nbr_obs_prod_nlI=_N
bysort iso_o : generate nbr_obs_iso_nlI=_N
generate  coef_iso_nlI =.
generate  coef_prod_nlI =.
generate  ecart_type_iso_nlI=.
generate  ecart_type_prod_nlI=.

** Mesurer le fit du modèle (cont')
gen aic_nlI = .
gen logL_nlI = .

estat ic
capture matrix Y=r(S)

* (2) AIC 
replace aic_nlI = Y[1,5]

* (3) log-likelihood
replace logL_nlI =Y[1,3]

display "`liste_variables'"
local n 1
*local m = `nbr_var'+1
foreach i in `liste_variables' {
	if strmatch("`i'","*prod*")==1 {
		quietly replace coef_prod_nlI =exp(X[1,`n'])+1 if `i'==1
		*quietly replace coef_prod_I =X[1,`m'] if `i'==1
		quietly replace ecart_type_prod_nlI =ET[`n',`n']^0.5 if `i'==1
		*quietly replace ecart_type_prod_I =ET[`m',`m']^0.5 if `i'==1
	}
	if strmatch("`i'","*iso*")==1 {
		quietly replace coef_iso_nlI =exp(X[1,`n'])+1 if `i'==1
		*quietly replace coef_iso_I =X[1,`m'] if `i'==1
		quietly replace ecart_type_iso_nlI =ET[`n',`n']^0.5 if `i'==1
		*quietly replace ecart_type_iso_I =ET[`m',`m']^0.5 if `i'==1
	}
	
	local n = `n'+1
	*local m = `m'+1
}


sum terme_iceberg  [fweight=`mode'_val], det
generate terme_nlI_mp = r(mean)
generate terme_nlI_med = r(p50)
generate terme_nlI_et=r(sd)	

* on veut regarder si la médiane de Terme A est isolée du pb des points extrêmes (vers le haut)


save blouk_nlI_`year'_`class'_`preci'_`mode', replace



timer off 1
timer list 1


/*
*** ESTIMATION NL SUR ICEBERG ET ADDITIF
timer on 2


nl couts_trsp @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-2) iterate(200) parameters(`liste_parametres' ) initial (`initial')

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
capture correlate lnprix_obs lnpredit_nl
capture generate Rp2_nl = r(rho)^2

noisily capture  order iso_o iso_d product prix_fob prix_trsp2 converge predict lpredict terme* t /* e_t_rho* predict_calcul couts FE* 	*/

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

sum terme_I  [fweight=`mode'_val], det 	
generate terme_I_mp = r(mean)
generate terme_I_med = r(p50)
generate terme_I_et=r(sd)


save blouk_`year'_`class'_`preci'_`mode', replace
capture erase blouk.dta


timer off 2
timer list 2
generate Duree_estimation_secondes = r(t2)
timer clear
*/



end


********************************************************************************************
*Programme de rŽgression sur les effets fixes__ et sortie des rŽsultats
***********************************************************

capture program drop reg_FE_h
program reg_FE_h
	args year class preci mode
* exemple : reg_FE 2006 sitc3 3 air
* rod_var "hs hs6 SIC sitc2 sitc3 naics"


*** STEP 1 - SAUVER LES RESULTATS ETAPE 1 *
******************************************************************************

use blouk_`year'_`class'_`preci'_`mode', clear

merge m:m iso_o iso_d product prix_fob using blouk_nlI_`year'_`class'_`preci'_`mode'
drop _merge

display "`year'_`class'_`preci'_`mode'"

save blouk_`year'_`class'_`preci'_`mode', replace

use blouk_`year'_`class'_`preci'_`mode', clear
keep product coef_prod_nlI ecart_type_prod_nlI coef_iso_nlI ecart_type_iso_nlI coef_prod_A coef_prod_I  ecart_type_prod_A ecart_type_prod_I terme_nlI_mp terme_nlI_et terme_A_mp terme_A_et terme_I_mp terme_I_et nbr_obs nbr_obs_prod

bysort product : keep if _n==1

save result_prod_`year'_`class'_`preci'_`mode', replace



*** STEP 2 - EVALUER L'EFFET DES VARIABLES DE GRAVITE
****************************************************************************

** On garde la même forme fonctionnelle sur cette seconde étape

use blouk_`year'_`class'_`preci'_`mode', clear

keep iso_o coef_iso_nlI ecart_type_iso_nlI coef_iso_A coef_iso_I ecart_type_iso_A ecart_type_iso_I terme_A_mp terme_A_et terme_I_mp terme_I_et nbr_obs  nbr_obs_iso contig-dist 

bysort iso_o : keep if _n==1

generate lndist=ln(dist)

** CASE 1: DANS LE CAS SANS ADDITIFS
************************************************
generate lncoef_iso_nlI= ln(coef_iso_nlI)


reg lncoef_iso_nlI lndist contig-smctry, robust

/*capture*/	matrix X=e(b)
/*capture*/ matrix ET=e(V)

generate rho_dist_nlI=X[1,1]
generate rho_contig_nlI=X[1,2]
generate rho_comlang_off_nlI=X[1,3]
generate rho_comlang_ethno_nlI=X[1,4]
generate rho_colony_nlI=X[1,5]
generate rho_comcol_nlI=X[1,6]
generate rho_curcol_nlI=X[1,7]
generate rho_col45_nlI=X[1,8]
generate rho_smctry_nlI=X[1,9]


generate et_dist_nlI=ET[1,1]^0.5
generate et_contig_nlI=ET[2,2]^0.5
generate et_comlang_off_nlI=ET[3,3]^0.5
generate et_comlang_ethno_nlI=ET[4,4]^0.5
generate et_colony_nlI=ET[5,5]^0.5
generate et_comcol_nlI=ET[6,6]^0.5
generate et_curcol_nlI=ET[7,7]^0.5
generate et_col45_nlI=ET[8,8]^0.5
generate et_smctry_nlI=ET[9,9]^0.5


** CASE 2: DANS LE CAS AVEC ADDITIFS 
************************************************

* Sur la composante "pays" de terme I
generate lncoef_iso_I = ln(coef_iso_I)

reg lncoef_iso_I lndist contig-smctry, robust

capture	matrix X= e(b)
capture matrix ET=e(V)

generate rho_dist_I=X[1,1]
generate rho_contig_I=X[1,2]
generate rho_comlang_off_I=X[1,3]
generate rho_comlang_ethno_I=X[1,4]
generate rho_colony_I=X[1,5]
generate rho_comcol_I=X[1,6]
generate rho_curcol_I=X[1,7]
generate rho_col45_I=X[1,8]
generate rho_smctry_I=X[1,9]


generate et_dist_I=ET[1,1]^0.5
generate et_contig_I=ET[2,2]^0.5
generate et_comlang_off_I=ET[3,3]^0.5
generate et_comlang_ethno_I=ET[4,4]^0.5
generate et_colony_I=ET[5,5]^0.5
generate et_comcol_I=ET[6,6]^0.5
generate et_curcol_I=ET[7,7]^0.5
generate et_col45_I=ET[8,8]^0.5
generate et_smctry_I=ET[9,9]^0.5


* Sur la composante "pays" de terme A
generate lncoef_iso_A = ln(coef_iso_A)


reg lncoef_iso_A lndist contig-smctry, robust

capture	matrix X= e(b)
capture  matrix ET=e(V)

generate rho_dist_A=X[1,1]
generate rho_contig_A=X[1,2]
generate rho_comlang_off_A=X[1,3]
generate rho_comlang_ethno_A=X[1,4]
generate rho_colony_A=X[1,5]
generate rho_comcol_A=X[1,6]
generate rho_curcol_A=X[1,7]
generate rho_col45_A=X[1,8]
generate rho_smctry_A=X[1,9]


generate et_dist_A=ET[1,1]^0.5
generate et_contig_A=ET[2,2]^0.5
generate et_comlang_off_A=ET[3,3]^0.5
generate et_comlang_ethno_A=ET[4,4]^0.5
generate et_colony_A=ET[5,5]^0.5
generate et_comcol_A=ET[6,6]^0.5
generate et_curcol_A=ET[7,7]^0.5
generate et_col45_A=ET[8,8]^0.5
generate et_smctry_A=ET[9,9]^0.5



save result_NLiso_`year'_`class'_`preci'_`mode', replace



end


******************************************************
***** LANCER LES ESTIMATIONS *************************
*******************************************************


*** 3 digits, all years ***

***** AIR *******************************
**** Pas de pb sur air, toutes les années - SAUF 2007 et 2009
*****************************************
set more off
local mode air 


foreach x in `mode' {

/*forvalues z = 2006(-1)1974 {


capture log close
log using hummels_3digits_`z'_`x', replace

reg_termes_h `z' sitc2 3 `x'
reg_FE_h `z' sitc2 3 `x'

erase blouk_nlI_`z'_sitc2_3_`mode'.dta

log close

}
*/



*local year 2010 2011 2012 2013
local year 2011

** Pour l'instant on ne lance que le step 1
foreach z in `year' {


capture log close
log using hummels_3digits_`z'_`x', replace

reg_termes_h `z' sitc2 3 `x'
*reg_FE_h `z' sitc2 3 `x'

*erase blouk_nlI_`z'_sitc2_3_`mode'.dta

log close

}
}



*}


**** ON s'arrete ICI pour l'instant *****
/*

**************************************
** VESSEL ****************************
**************************************

** Attention pb sur 1984 vessel
** ne peut estimer en seconde étape car terme I (estimé seul) tjs négatif, or on prend le log pour estimer l'effet des variables de gravité
** Cf pgm à part pgm_temp1984.do
** Ici on fait en deux étapes



set more off
local mode ves 


foreach x in `mode' {


forvalues z = 1983(-1)1974 {

capture log close
log using hummels_3digits_`z'_`x', replace

reg_termes_h `z' sitc2 3 `x'
reg_FE_h `z' sitc2 3 `x'

erase blouk_nlI_`z'_sitc2_3_`mode'.dta

log close

}

forvalues z = 2006(-1)1985 {

capture log close
log using hummels_3digits_`z'_`x', replace

reg_termes_h `z' sitc2 3 `x'
reg_FE_h `z' sitc2 3 `x'

erase blouk_nlI_`z'_sitc2_3_`mode'.dta

log close

}

* pour les années récentes
local year 2008 2010 2011 2012 2013
foreach z in `year' {


capture log close
log using hummels_3digits_`z'_`x', replace

reg_termes_h `z' sitc2 3 `x'
reg_FE_h `z' sitc2 3 `x'

erase blouk_nlI_`z'_sitc2_3_`mode'.dta

log close

}

}

*/



*** stop pour l'instant sur la finesse de la classification
/*
*** 5 digits, all ten years ***

set more off
local mode air ves 


foreach x in `mode' {

forvalues z = 2004(-10)1974 {
*forvalues z = 1983(-1)1974 {

capture log close
log using hummels_5digits_`z'_`x', replace

reg_termes_h `z' sitc2 5 `x'
reg_FE_h `z' sitc2 5 `x'

erase blouk_nlI_`z'_sitc2_5_`mode'.dta

log close

}

}

*/


