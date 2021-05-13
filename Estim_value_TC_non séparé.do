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
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_data ~/Documents/Recherche/2013 -- Trade Costs -- local/data
	global dir_log "$dir/Logs divers"
}

** Fixe Lise bureau
if "`c(hostname)'" =="LAB0271A" {
	global dir "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_data "$dir/data"
}

/* Vieux portable Lise
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}
*/

/* Nouveau portable Lise */

if "`c(hostname)'" =="MSOP112C" {
  
	global dir C:\Lise\trade_costs
	global dir_data "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data"
	
}
cd "$dir"




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
levelsof sitc2_3, local(secteur_a_garder) clean
global secteur_a_garder "`secteur_a_garder'"

end





******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE AVEC ADDITIFS ET ICEBERG ****
******************************************************************

capture program drop nlcouts_IetA
program nlcouts_IetA
	version 12
	su group_sect_pays, meanonly	
	local nbr_sect_pays=r(max)
	local nbr_var = `nbr_sect_pays' +2 /*+11*/
	
	*Pas de problème de colinéarité, donc on garde tout
		
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
	
		foreach p in sect_pays {
			forvalue j = 1/`nbr_`p'' {
				if  1==1 {
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
	
	
			foreach p in sect_pays {
			forvalue j =  1/`nbr_`p'' {
				if 1==1 {	
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

* Soumission JEGeo
*args year class preci mode

* exemple : prep_reg hummels_tra 2006 sitc2 3 air
* Hummels : sitc2

* Révision JEGeo
* On ajoute le choix de la base de données
args database year class preci mode 


**On va changer en prep_reg hummels_tra 2006 5 3 air ou prep_reg base_hs10_newyears 2005 10 3 air 

**"class" donne la précision des produits. "preci" donne la précision des secteurs

a_garder `mode' `year'
**Détermine les secteurs / pays que l’on va garder

** Définir macro pour lieu de stockage des résultats selon base utilisée

if "`database'"=="hummels_tra" | "`database'"=="base_hs10_newyears" {
	global stock_results $dir/results/baseline
}

if "`database'"=="db_samesample_`class'_`preci'_HS10" {
	global stock_results $dir/results/referee1/baselinesamplereferee1
}


if "`database'"=="predictions_FS_panel" {
	global stock_results $dir/results/IV_referee1_panel
}


if "`database'"=="FS_predictions_both_yearly_prod10_sect3" | "`database'"=="FS_predictions_both_yearly_prod5_sect3"  {
	global stock_results $dir/results/IV_referee1_yearly
}

if "`database'"=="hummels_tra_qy1_qy" {
	global stock_results $dir/results/qy1_qy
}


if "`database'"=="hummels_tra_qy1_wgt" {
	global stock_results $dir/results/qy1_wgt
}


if "`database'"=="hs10_qy1_qy" {
	global stock_results $dir/results/hs10_qy1_qy
}


if "`database'"=="hs10_qy1_wgt" {
	global stock_results $dir/results/hs10_qy1_wgt
}

****************Préparation de la base blouk


*** Aller chercher la base au bon endroit

*** Si on utilise méthode ancienne sur database soumission (large) en s=3, k=5
** database = hummels_tra 

*** Si on utilise méthode ancienne sur database large s=3, k=10
** database =base_hs10_newyears 

*** Si on utilise méthode ancienne sur base révision selon méthode référé 1 (plus petite)
** database = db_samesample_sitc2_3_HS10

*** Si on utilise la base IV first stage
** database = referee1_IV


if "`database'"=="hummels_tra" {
	use "$dir_data/`database'", clear
	keep if year==`year'
	keep if mode=="`mode'"
	generate sector = substr(sitc,1,`preci')
}


if "`database'"=="base_hs10_newyears"  {
	use "$dir_data/base_hs10_`year'", clear
	keep if year==`year'
	keep if mode=="`mode'"
}




/* Pourquoi faire ça, on le fait ensuite? 
if "`database'"=="base_hs10_newyears" | "`database'"=="db_samesample_sitc2_3_HS10"{
	generate prix_fob=prix_fob_wgt
	generate prix_caf=prix_caf_wgt
}
	*/
	

if "`database'"=="predictions_FS_panel" {
	use "$stock_results/`database'"
	keep if year==`year'
	keep if mode=="`mode'"
	keep sitc2-mode lprix_panel_hat_air_allFE2 lprix_panel_hat_ves_allFE2
	drop sitc2_3d
	merge 1:1 sitc2-mode using "$dir_data/hummels_tra"
	rename prix_fob prix_fob_non_instru
	generate prix_fob = .
	replace prix_fob=exp(lprix_panel_hat_air_allFE2) if mode=="air"
	replace prix_fob=exp(lprix_panel_hat_ves_allFE2) if mode=="ves"
}

if "`database'"=="FS_predictions_both_yearly_prod10_sect3" {
	use "$stock_results/`database'"
	keep if year==`year'
	keep if mode=="`mode'"
	keep hs10 year mode sitc2 sitc2_3d iso_o lprix_yearly_hat_allFE 
	order sitc2 year iso_o mode
	rename hs10 hs
	merge 1:m hs year mode iso_o using "$dir_data/base_hs10_`year'"
	rename prix_fob_wgt prix_fob_non_instru
	generate prix_fob = . 
	replace prix_fob=exp(lprix_yearly_hat_allFE)
}


if "`database'"=="FS_predictions_both_yearly_prod5_sect3"{
	use "$stock_results/`database'"
	keep if year==`year'
	keep if mode=="`mode'"
	drop sitc2_3d
	merge 1:1 sitc2 year iso_o mode using "$dir_data/hummels_tra"
	rename prix_fob prix_fob_non_instru
	generate prix_fob = .
	replace prix_fob=exp(lprix_yearly_hat_allFE)
}


if "`database'"=="hs10_qy1_qy" | "`database'"=="hs10_qy1_wgt" {
	use "$dir_data/base_hs10_`year'", clear
	
	drop if qy1==0
	collapse (sum) val qy1 cha wgt, by(hs iso_o dist_entry dist_unlad rate_prov mode sitc)
	bysort hs iso_o dist_entry dist_unlad rate_prov mode: drop if _N!=1
	**Remarque : la régression est à faire en 5/3
	
	keep if mode=="`mode'"
	collapse (sum) val qy1 cha wgt, by(sitc iso_o mode)
	generate sector = substr(sitc2,1,`preci')
	
	generate prix_trsp  = cha/val  			/* (pcif - pfas) / pfas */
	generate prix_trsp2 = (val+cha)/val	/* pcif / pfas */
	
	if "`database'"=="hs10_qy1_qy" {
		generate prix_caf   = (val+cha)/qy1
		generate prix_fob   = val/qy1
	}
	if "`database'"=="hs10_qy1_wgt" {
		generate prix_caf   = (val+cha)/wgt
		generate prix_fob   = val/wgt
	}
	codebook prix_fob
	
}




if "`database'"=="hummels_tra_qy1_qy" | "`database'"=="hummels_tra_qy1_wgt" {
	use "$dir_data/hummels_tra"
	keep if year==`year'
	bys sitc2 iso_o year : drop if _N==2
	keep if mode=="`mode'"
	generate sector = substr(sitc,1,`preci')
	
	**on utilise con_val parce que Hummels ne donne pas gen_val
	keep if con_val==`mode'_val
	keep if con_cha==`mode'_cha
	keep if con_qy1 !=. & con_qy1 !=0
	keep if con_val !=. & con_val !=0
	keep if con_cha !=. & con_cha !=0
	capture assert if con_cif==con_val+con_cha
	if "`database'"=="hummels_tra_qy1_qy" {
		replace prix_caf   = (con_val+con_cha)/con_qy1
		replace prix_fob   = con_val/con_qy1
		replace prix_trsp  = con_cha/con_val  			/* (pcif - pfas) / pfas */
		replace prix_trsp2 = (con_val+con_cha)/con_val	/* pcif / pfas */
		rename con_val val
	}
	if "`database'"=="hummels_tra_qy1_wgt" {
		rename `mode'_val val
	}
	
}


***Pour restreindre
*keep if substr(sitc2,1,1)=="0"
*************************
capture label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"


if "`database'"=="base_hs10_newyears" | "`database'"=="db_samesample_sitc2_3_HS10" {
	generate sector = substr(hs,1,`preci')
	collapse (sum) val wgt cha qy1 qy2 (first) sector sitc2 hs6, by(iso_o hs mode)
	gen prix_caf = (val+cha)/wgt
	gen prix_fob = val/wgt
	gen prix_trsp=cha/val  			/* (pcif - pfas) / pfas */
	gen prix_trsp2 = (val+cha)/val	/* pcif / pfas */
	

	drop if sector==""
	*drop if prix_fob==prix_caf
	/* A METTRE ? */
}

if "`database'"=="FS_predictions_both_yearly_prod10_sect3" {
	generate sector = substr(hs,1,`preci')
	collapse (sum) val wgt cha qy1 qy2 (first) sector sitc2 hs6, by(iso_o hs mode)
	gen prix_caf = (val+cha)/wgt
	gen prix_fob = val/wgt
	gen prix_trsp=cha/val  			/* (pcif - pfas) / pfas */
	gen prix_trsp2 = (val+cha)/val	/* pcif / pfas */
	

	drop if sector==""
	*drop if prix_fob==prix_caf
	/* A METTRE ? */
}



if  "`database'"=="FS_predictions_both_yearly_prod5_sect3" {
	generate sector = substr(sitc2,1,`preci')
	rename `mode'_* *
	collapse (sum) val wgt cha (first) sector, by(iso_o sitc2 mode)
	gen prix_caf = (val+cha)/wgt
	gen prix_fob = val/wgt
	gen prix_trsp=cha/val  			/* (pcif - pfas) / pfas */
	gen prix_trsp2 = (val+cha)/val	/* pcif / pfas */
	

	drop if sector==""
	*drop if prix_fob==prix_caf
	/* A METTRE ? */
}
* Nettoyer la base de donnÈes

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************


/*

display "Nombre avant bas et haut " _N

bys sector: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys sector: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 


display "Nombre après bas et haut " _N

egen prix_min = min(prix_trsp2), by(sector)
egen prix_max = max(prix_trsp2), by(sector)

g lprix_trsp2 = ln(prix_trsp2)
label variable lprix_trsp2 "log(prix_caf/prix_fob)"
*g lprix_trsp2 = ln(prix_trsp2)

/*
g ldist = ln(dist)
label variable ldist "log(distance)"
*/

**********Sur les secteurs

codebook sector


egen group_sect=group(sector)
su group_sect, meanonly	
local nbr_sect_exante=r(max)
display "Nombre de secteurs ex ante: `nbr_sect_exante'" 
drop group_sect

bysort sector: drop if _N<=5

egen group_sect=group(sector)
su group_sect, meanonly	
local nbr_sect_expost=r(max)
display "Nombre de secteurs ex post: `nbr_sect_expost'" 
drop group_sect
*/



macro dir

keep if strpos("$pays_a_garder",iso_o)!=0
keep if strpos("$secteur_a_garder",sector)!=0



*** Tester le pgm
if "${test}"!="" {
	* Pour faire un plus petit sample
	local limite 80
	
	* On enlève les pays les plus petits (<=80% des flux, par mode considéré)
	bys iso_o: egen total_iso_o = total(val)
	egen seuil_pays = pctile(total_iso_o),p(`limite')
	
	drop if total_iso_o <= seuil_pays
	
	
	* On enlève les secteurs les plus petits (<=80% des flux, par mode considéré)
	bys sector: egen total_sector = total(val)
	egen seuil_sector = pctile(total_sector),p(`limite')
	
	drop if total_sector <= seuil_sector

}

*** reprendre ici








timer clear

/*
*Pour nombre de sector
quietly egen group_sect=group(sector)
su group_sect, meanonly	
local nbr_sect=r(max)
quietly levelsof sector, local (liste_sect) clean
quietly tabulate sector, gen (sect_)
	
*Pour nombre d'iso_o
quietly egen group_iso_o=group(iso_o)
su group_iso_o, meanonly	
local nbr_iso_o=r(max)
*Donne le nbr d'iso_o
quietly levelsof iso_o, local(liste_iso_o) clean
quietly tabulate iso_o, gen(iso_o_)
*/

generate sect_pays = sector+"_"+iso_o
*Pour nombre de sect_pays
quietly egen group_sect_pays=group(sect_pays)
su group_sect_pays, meanonly	
local nbr_sect_pays=r(max)
*Donne le nbr d'iso_o
quietly levelsof sect_pays, local(liste_sect_pays) clean
quietly tabulate sect_pays, gen(sect_pays_)



local liste_variables_sect_pays 
forvalue j =  1/`nbr_sect_pays' {
	local liste_variables_sect_pays  `liste_variables_sect_pays' sect_pays_`j'
}


***************************************

local liste_parametres_sect_pays_A
forvalue j =  1/`nbr_sect_pays' {		
	local liste_parametres_sect_pays_A  `liste_parametres_sect_pays_A' lnfeA_sect_pays_`j'
}



local liste_parametres_sect_pays_I
forvalue j =  1/`nbr_sect_pays' {		
	local liste_parametres_sect_pays_I  `liste_parametres_sect_pays_I' lnfem1I_sect_pays_`j'
}


**************************************

	
	foreach g in A I {
		local initial_sect_pays_`g'
		forvalue j =  1/`nbr_sect_pays' {
			if  1==1 {
				if "`g'" =="A" {
*out v9			local initial_sect_pays_`g'  `initial_sect_pays_`g'' fe`g'_sect_pays_`j' 1 
					local initial_sect_pays_`g'  `initial_sect_pays_`g'' lnfeA_sect_pays_`j' -3
				}
				if "`g'" =="I" {
*out v9			local initial_sect_pays_`g'  `initial_sect_pays_`g'' fe`g'_sect_pays_`j' 1
					local initial_sect_pays_`g'  `initial_sect_pays_`g'' lnfem1I_sect_pays_`j' -3
****ln(0.05) = -3
				}
			}
		}		
	}



* v10, on estime le log du ratio ob -1
gen ln_ratio_minus1 = ln(prix_trsp2 -1)



local liste_variables `liste_variables_sect_pays'

display  wordcount("`liste_variables'")

** pour estimation NL both A & I
local liste_parametres `liste_parametres_sect_pays_A'  `liste_parametres_sect_pays_I' 
local initial `initial_sect_pays_A'  `initial_sect_pays_I'

* ------------------------------------------------
******** ESTIMATION AVEC COUTS ADDITIF ET ICEBERG
* ------------------------------------------------


timer on 3

* attention on durçit la règle pour 1987, vess

sum ln_ratio_minus1
sum prix_fob

summarize ln_ratio_minus1 prix_fob, det



display "nl couts_IetA @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')"

*nl couts_trsp @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-2) iterate(200) parameters(`liste_parametres' ) initial (`initial')
capture noisily nl couts_IetA @ ln_ratio_minus1 prix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')


local result_reg = _rc
if `result_reg' ==0 {
	display "La Regression a tourné"
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
	
	noisily capture  order iso_o iso_d sector sect_pays prix_fob prix_trsp2 converge predict lpredict terme* t /* e_t_rho* predict_calcul couts FE* 	*/
	
	capture	matrix X= e(b)
	capture matrix ET=e(V)
	local nbr_var = e(k)/2
	
	generate nbr_obs=e(N)
	bysort sector : generate nbr_obs_sect=_N
	bysort iso_o : generate nbr_obs_iso=_N
	generate  coef_iso_sect_A =.
	generate  coef_iso_sect_I =.
	generate  ecart_type_iso_sect_A=.
	generate  ecart_type_iso_sect_I=.
	
	
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
		if strmatch("`i'","*sect_pays*")==1 {
			quietly replace coef_iso_sect_A =exp(X[1,`n']) if `i'==1
			quietly replace coef_iso_sect_I =exp(X[1,`m'])+1 if `i'==1
			quietly replace ecart_type_iso_sect_A =ET[`n',`n']^0.5 if `i'==1
			quietly replace ecart_type_iso_sect_I =ET[`m',`m']^0.5 if `i'==1
		}
		
		local n = `n'+1
		local m = `m'+1
	}
	
	sum terme_A  [fweight=val], det
	generate terme_A_mp = r(mean)
	generate terme_A_med = r(p50)
	generate terme_A_et = r(sd)
	gen terme_A_min = r(min)
	gen terme_A_max = r(max)
	
	sum terme_I  [fweight=val], det 	
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
	
	global liste_parametres `liste_parametres'
	
	global liste_parametres_sect_pays_A 	`liste_parametres_sect_pays_A' 
	global liste_parametres_sect_pays_I 	`liste_parametres_sect_pay_I' 
	global liste_sect_pays `liste_sect_pays'
	
	
	drop sect_pays*

}

if `result_reg' !=0 {
		generate rc=`result_reg' 
		keep if _n==1
		keep sector year mode rc terme_A terme_I val
		replace terme_A=.
		replace terme_I=.
		replace val=.
}


save "$dir/results/${test}results_estimTC_non_séparé_`year'_`class'_`preci'_`mode'_`database'", replace



end



*******************************************************
***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


set more off
local mode_list ves air
*global test test
global test




	
foreach year of numlist 1997(1)1999 2002(1)2019 {
		
	foreach mode in `mode_list' {
		
		foreach base in hs10_qy1_qy hs10_qy1_wgt {
		
			capture log close
			log using "$dir_log/${test}log_prep_reg_non_séparé_`year'_5_3_`mode'_`base'.smcl", replace
		
	
		
			prep_reg `base' `year' 5 3 `mode'
			
			log close
		
			translate "$dir_log/${test}log_prep_reg_non_séparé_`year'_5_3_`mode'_`base'.smcl" /*
			*/"$dir_log/${test}log_prep_reg_non_séparé_`year'_5_3_`mode'_`base'.pdf", replace

			erase "$dir_log/${test}log_prep_reg_non_séparé_`year'_5_3_`mode'_`base'.smcl"

		}
	
	}
}





