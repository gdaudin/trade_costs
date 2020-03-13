
*version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
	global dir_db ~/Documents/Recherche/2013 -- Trade Costs -- local/data
	global dir_temp ~/Downloads/temp_stata
	global dir_results ~/Documents/Recherche/2013 -- Trade Costs -- local/results
	
}


/* Fixe Lise - Trvail sur MyWork*/
if "`c(hostname)'" =="LAB0271A" {
	global dir \\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\JEGeo
	global dir_db \\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\JEGeo\data		/* base de données */
	global dir_temp \\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\JEGeo\temp		/* pour stocker les bases temporaires */
	global dir_results \\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\JEGeo\results /* résultats */
	*global dir_git C:\Users\lpatureau\Documents\Git\trade_costs /* stocker les .smcl */
	
	** temporairement
	global dir_git \\storage2016.windows.dauphine.fr\home\l\lpatureau\My_Work\Git\trade_costs
}

/* Vieux portable Lise */
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost\JEGeo
}

/* Nouveau portable Lise */
if "`c(hostname)'" =="MSOP112C" {
    global dir_db C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\database
	global dir_temp C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\temp/* pour stocker les bases temporaires */
	global dir_results C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\results
}







*cd $dir
capture log close

log using "$dir_temp/`c(current_date)'", append 


set more off


*----------------------------------------------------------
*** START FROM NEW YEARS 2005-2013
*----------------------------------------------------------

*****************************************************************
*** STEP 1: BUILD THE DATASET ***********************************
*****************************************************************

**** See Program Build_dataHS10_refere1.do *****

******************************************************
*** STEP 2: PREPARER LA BASE  pour la régression *****
******************************************************

capture program drop prep_reg
program prep_reg
args year class preci mode


use "$dir_db/base_hs10_newyears.dta", clear

drop if prix_fob==prix_caf

*** JUSTE POUR TESTER

*keep if iso_o =="FRA"

*** A ENLEVER ENSUITE

keep if year==`year'
keep if mode=="`mode'"
rename `class' sector
replace sector = substr(sector,1,3)
** on est au niveau SITC 3d

drop if sector==""

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"

rename hs product
replace product = substr(product,1,`preci')
* On se laisse de la marge de manoeuvre sur HS 6, HS4, HS10 (mais on sait que ça ne marche pas en HS 10)
 
label var product "HS `preci' classification"

* Nettoyer la base de données

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************

display "Nombre avant bas et haut " _N

bys sector: egen c_95_prix_trsp = pctile(prix_trsp),p(95)
bys sector: egen c_05_prix_trsp = pctile(prix_trsp),p(05)
drop if prix_trsp < c_05_prix_trsp | prix_trsp > c_95_prix_trsp 


display "Nombre après bas et haut " _N

*egen prix_min = min(prix_trsp), by(sector)
*egen prix_max = max(prix_trsp), by(sector)

**********Sur le produits

*codebook sector
egen group_sector=group(sector)
su group_sector, meanonly	
drop group_sector
local nbr_sector_exante=r(max)
display "Nombre de produits (3 digits) : `nbr_sector_exante'" 

bysort sector: drop if _N<=5


g lprix_trsp2 = ln(prix_trsp2)
label variable lprix_trsp2 "log(prix_caf/prix_fob)"
label variable prix_trsp2 "prix_caf/prix_fob"

g lprix_trsp = ln(prix_trsp)
label variable lprix_trsp "log((prix_caf - prix_fob)/prix_fob)"
label variable prix_trsp "(prix_caf - prix_fob)/prix_fob"

g lprix_fob = ln(prix_fob)
label variable lprix_fob "log(prix_fob)"


save "$dir_db/temp_`year'_`class'_HS`preci'_`mode'.dta", replace


end

******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE DU BETA ****
******************************************************************

capture program drop nlestim_beta
program nlestim_beta
	version 14
	
	** Estimation par pays d'origine / secteur 3 ou 4 digits
	** Estimer beta is
	** Hétérogénéité dans les districts of entry + produits HS 10
	su group_prod, meanonly	
	local nbr_prod=r(max)
	
	su group_dentry, meanonly	
	local nbr_dentry=r(max)
	local nbr_var = `nbr_prod'+`nbr_dentry' -1 +2 /*+11*/  /* -1 pour produit de référence, + 2 pour ln cttrp2 ln prixfob */
		
	macro list

	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)
	local n 1
	
	
	foreach var in lprix_trsp  lprix_fob  {
		local `var' : word `n' of `varlist'
		local n = `n'+1
	}

	
		
**Début de l'évaluation		
	tempvar blif
	tempname x
	* on impose que beta est compris entre 0 et 1 via la fonction logistique
	scalar `x' =`at'[1,1]
	generate double `blif' =`lprix_fob'*(-1/(1+exp(`x'))) `if'

		
**Ici, on fait les effets fixes (produit-pays-point d'entrée)

local n 2
		foreach p in prod dentry {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="prod" | `j'!=1 {
					tempname fe_`p'_`j'
					scalar `fe_`p'_`j'' =`at'[1,`n']
************************

					replace `blif' = `blif' + `fe_`p'_`j'' * `p'_`j' `if'
					local n = `n'+1
				}
			}
		}
	
	


	replace `lprix_trsp' = `blif' `if'
	
	
end
**********************************************************************
************** FIN FONCTION
**********************************************************************	

*** PROGRAMME DE REGRESSION **********


capture program drop do_reg
program do_reg
args year class preci mode

*** Pour stocker les résultats
clear
gen sector = ""
gen iso_o = ""
gen beta = .

save  "$dir_results/referee1/results_beta_contraint_`year'_`class'_HS`preci'_`mode'.dta", replace

*** Faire les régressions

cd "$dir_temp"

use "$dir_db/temp_`year'_`class'_HS`preci'_`mode'.dta", clear

gen beta    = .
gen coeff_x = .
gen predit = .
gen std_x = .


** JUSTE POUR TESTER SUR DEUX PAYS (ou pas...)
*local liste_iso_o FRA GBR
quietly levelsof iso_o, local(liste_iso_o) clean
***************


* ok la suite on garde tous les secteurs
quietly levelsof sector, local(liste_sector) clean

generate pays_sector=iso_o+ "--" + sector

quietly levelsof pays_sector, local(liste_pays_sector) clean

save temp, replace


/*
** On crée les bases par pays/secteur 
**Cela me semble singulièrement ineficace. J’enlève... 
foreach i in `liste_iso_o' {

	use temp, clear
	keep if iso_o=="`i'"
	save temp_`i', replace
	
	foreach k in `liste_sector' {
		use temp_`i', clear
		keep if sector =="`k'"
		save temp_`i'_`k', replace
	}
	erase temp_`i'.dta
	}

*/	
** Travail sur la base pays/secteur	
	
foreach pays_sector in `liste_pays_sector' {
	
		use temp, clear
		
		disp "couple pays--sector `pays_sector'"
		keep if pays_sector=="`pays_sector'"
		
	
		local nb = _N
	
	*	* il faut que la base soit non vide
	*	if `nb' !=0 {
		
		disp "ok base non vide"
	
	egen group_dentry=group(dist_entry)
	su group_dentry, meanonly	
	local nbr_dentry=r(max)
	display "For `pays_sector': Nombre de district of entry = `nbr_dentry'" 
	
	
	egen group_prod=group(product)
	su group_prod, meanonly	
	local nbr_prod=r(max)
	
	** Initialiser les listes des variables, des paramètres, des valeurs initiales
	
	* Produits HS niveau finesse classification `preci'
	quietly levelsof product, local (liste_prod) clean
	quietly tabulate product, gen (prod_)
		
	* District of entry
	quietly levelsof dist_entry, local(liste_dentry) clean
	quietly tabulate dist_entry, gen(dentry_)
	
	foreach i in prod dentry	{
	
		* Liste des variables
		local liste_variables_`i' 
		forvalue j =  1/`nbr_`i'' {
			if "`i'" !="prod" | `j' !=1 {
				local liste_variables_`i'  `liste_variables_`i'' `i'_`j'
		}
	}
			
			
		* Liste des paramètres associés
		
	local liste_parametres_`i'
		forvalue j =  1/`nbr_`i'' {
			if  "`i'" !="prod" | `j'!=1 {			
				local liste_parametres_`i'  `liste_parametres_`i'' fe_`i'_`j'
		}
	}
			
		* Initialiser les valeurs initiales
	local initial_`i'
		forvalue j =  1/`nbr_`i'' {
			if  "`i'" !="prod" |`j'!=1 {
				local initial_`i'  `initial_`i'' fe_`i'_`j' 0.5
	****ln(0.05) = -3
			}
		}

	} /* Fin de la boucle d'initialisation  */ 
	
	
		
	local liste_variables `liste_variables_prod' `liste_variables_dentry'
	local liste_parametres x `liste_parametres_prod' `liste_parametres_dentry'
	local initial  x 0 `initial_prod' `initial_dentry'
	
		
	*macro dir
	
	display "For `pays_sector': Nombre de products (HS `preci') = `nbr_prod'" 
	display "For `pays_sector': Nombre de districts of entry = `nbr_dentry'" 
	
	local nbr_var = `nbr_prod' -1 + `nbr_dentry' +1 /* -1 pour EF produit initial, +1 pour lprixfob */
	
	disp "nb of explicatives : `nbr_var'"
	
	* il faut plus d'observations que de nombre de variables explicatives pour faire la régression
	
	*if `nb' > `nbr_var' {
	**la barre est-elle bien assez haut ?
	
	*if `nb' > 2*`nbr_var' {
	if `nb' > `nbr_var' +2 {
		disp "ok assez d'observations par rapport aux explicatives nb-nb var = : `nb'-`nbr_var'"
		
		
		*histogram prix_trsp, by(dist_entry) freq
		
	*		disp "nl estim_beta  @ lprix_trsp lprix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')"
	
			nl estim_beta  @ lprix_trsp lprix_fob `liste_variables' , eps(1e-5) iterate(500) parameters(`liste_parametres' ) initial (`initial') 
	*Ne marche pas avec lnlsq(0)
	
		
	* Récupérer le résultat sur le beta
	capture	matrix X= e(b)
	capture matrix ET=e(V)

	
	* Récupérer le predict de la régression
	capture	predict blink
	replace predit = blink
	
	*matrix list X 
	disp "`nbr_var'"
	
	
	* le coefficient x sur ln prix fob arrive en dernier
	replace coeff_x=X[1,1] 
	replace std_x = ET[1,1]^0.5
	
	
	
	
	replace beta = - 1/(1+exp(coeff_x)) 
	gen beta_min = - 1/(1+exp(coeff_x+1.96*std_x)) 
	gen beta_max = - 1/(1+exp(coeff_x-1.96*std_x)) 
	summarize beta 
	
		** Récupérer le beta estimé
	*keep iso_o sector beta coeff_x predit lprix_trsp `mode'_val 
	collapse (sum) `mode'_val `mode'_wgt, by (iso_o sector beta beta_min beta_max coeff_x std_x )
	keep if _n==1
	append using "$dir_results/referee1/results_beta_contraint_`year'_`class'_HS`preci'_`mode'.dta"
	save "$dir_results/referee1/results_beta_contraint_`year'_`class'_HS`preci'_`mode'.dta", replace	
	
	
	} /* Fin de la boucle si on fait la régression */ 
*	} /* Fin de la boucle si base non vide */
		
	*save `temp_`ii'_`k'.dta', replace
	
	
	
*	}
}

**J’intégre cela dans la boucle précédente
/*

foreach i in `liste_iso_o'  {
	foreach k in `liste_sector' {



		use "$dir_temp/temp_`i'_`k'.dta", clear
		if _N >0 {
		

			append using "$dir_results/referee1/results_beta_contraint_`year'_`class'_HS`preci'_`mode'.dta"
		
			save "$dir_results/referee1/results_beta_contraint_`year'_`class'_HS`preci'_`mode'.dta", replace	
		}
		
		erase "$dir_temp/temp_`i'_`k'.dta"
	
	}

}

*/
erase "$dir_temp/temp.dta"

use "$dir_results/referee1/results_beta_contraint_`year'_`class'_HS`preci'_`mode'.dta", clear


if _N !=0 {
	histogram beta, title("Distribution of beta, `year', `mode', HS`preci' digits, no weight") freq
	graph export "$dir_results/referee1/histogram_beta_`year'_`class'_HS`preci'_`mode'__noweight.pdf", replace
	generate freg_in_dollars=round(`mode'_val)
	histogram beta [fweight=freg_in_dollars], title("Distribution of beta, `year', `mode', HS`preci' digits, val weight")
	graph export "$dir_results/referee1/histogram_beta_`year'_`class'_HS`preci'_`mode'__valweight.pdf", replace
	generate freg_in_kg=round(`mode'_wgt)
	histogram beta [fweight=freg_in_kg], title("Distribution of beta, `year', `mode', HS`preci' digits, val weight")
	graph export "$dir_results/referee1/histogram_beta_`year'_`class'_HS`preci'_`mode'__massweight.pdf", replace
}


end

*******************************************************************************************
******* FIN DES PROGRAMMES ****************************************************************
*******************************************************************************************


set more off
local mode air ves
*local year 2005 


foreach x in `mode' {

forvalues z = 2005(1)2013 {
*foreach z in 2008 2013 {


** On se met en HS8 pour être cohérent avec 1ere étape ensuite
prep_reg `z' sitc2 8 `x'
do_reg `z' sitc2 8 `x'




}
}

log close


