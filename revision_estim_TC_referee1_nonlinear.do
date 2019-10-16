

*version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
}


/* Fixe Lise */
if "`c(hostname)'" =="LAB0271A" {
	*global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\database		/* base de données */
	global dir_temp C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\temp		/* pour stocker les bases temporaires */
	global dir_results C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\results /* résultats */
}

/* Vieux portable Lise */
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost\JEGeo
}

/* Nouveau portable Lise */
if "`c(hostname)'" =="LABP112" {
    global dir_db C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\database
	global dir_temp C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\temp/* pour stocker les bases temporaires */
	global dir_results C:\Users\Ipatureau\Dropbox\trade_cost_nonpartage\results
}





*cd $dir


capture log using "`c(current_time)' `c(current_date)'"

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


use "$dir_db/base_hs10_newyears.dta"

keep if year==`year'
keep if mode=="`mode'"
rename `class' sector
replace sector = substr(sector,1,`preci')

drop if sector==""

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"
 
label var hs "HS 10 classification"

* Nettoyer la base de données

*****************************************************************************
* On enlève en bas et en haut 
*****************************************************************************

display "Nombre avant bas et haut " _N

bys sector: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys sector: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 


display "Nombre après bas et haut " _N

*egen prix_min = min(prix_trsp2), by(sector)
*egen prix_max = max(prix_trsp2), by(sector)

**********Sur le produits

*codebook sector
egen group_sector=group(sector)
su group_sector, meanonly	
drop group_sector
local nbr_sector_exante=r(max)
display "Nombre de produits (`preci' digits) : `nbr_sector_exante'" 

bysort sector: drop if _N<=5


save $dir_db/tempHS10_`year'_`class'_`preci'_`mode', replace


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
	local nbr_var = `nbr_prod'+`nbr_dentry' -1 +2 /*+11*/  /* -1 pour produit de référence, + 2 pour ??? */
		
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)
	local n 1
	
	
	foreach var in lprix_trsp2  lprix_fob  {
		local `var' : word `n' of `varlist'
		local n = `n'+1
	}

	local n 1
		
	capture drop blif
	generate double blif =0

		
**Ici, on fait les effets fixes (produit-pays-point d'entrée)
	
		foreach p in iso_o prod dist_entry {
			foreach j of num 1/`nbr_`p'' {
				if "`p'"!="iso_o" | `j'!=1 {
					tempname fe_`p'_`j'
					scalar `fe_`p'_`j'' =`at'[1,`n']
************************

					replace blif = blif + `fe_`p'_`j'' * `p'_`j'
					local n = `n'+1
				}
			}
		}
	
	tempname x
	scalar `x' =`at'[1,`n']


	replace blif =blif+ `lprix_fob'*(1/(1+exp(`x'))

* on impose que beta est compris entre 0 et 1 via la fonction logistique
	replace `lprix_trsp2' = blif
	
	
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
gen beta=.

save  $dir_results\results_beta_`year'_`class'_`preci'_`mode', replace

*** Faire les régressions

cd $dir_temp

use $dir_db/tempHS10_`year'_`class'_`preci'_`mode', clear

g lprix_trsp2 = ln(prix_trsp2)
label variable lprix_trsp2 "log(prix_caf/prix_fob)"
label variable prix_trsp2 "prix_caf/prix_fob"

g lprix_fob = ln(prix_fob)
label variable lprix_fob "log(prix_fob)"

* on fait la régression par secteur-pays: On ne garde que les observations pertinentes

quietly levelsof iso_o, local(liste_iso_o) clean
quietly levelsof sector, local(liste_sector) clean

save temp, replace

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

foreach i in `liste_iso_o' {
foreach k in `liste_sector' {

use temp_`i'_`k', clear

local nb = _N

 * il faut que la base soit non vide
if `nb' !=0 {

egen group_dentry=group(dist_entry)
su group_dentry, meanonly	
local nbr_dentry=r(max)
*local nbr_dentry_min=r(min)
display "For sector `k', country `i': Nombre de district of entry = `nbr_dentry'" 


egen group_prod=group(hs)
su group_prod, meanonly	
local nbr_prod=r(max)
local nbr_prod_min=r(min)

egen group_iso_o=group(iso_o)
su group_iso_o, meanonly	
local nbr_iso_o =r(max)
local nbr_iso_o_min=r(min)

display "For sector `k', country `i': Nombre de products (HS 10) = `nbr_product'" 

local nbr_var = `nbr_product' + `nbr_dentry' + `nbr_iso_o' +1

disp "nb of explicatives"
disp "`nbr_var'"

* il faut plus d'observations que de nombre de variables explicatives pour faire la régression
	

	if `nb' > `nbr_var' {

*** Génerer les effets fixes produit / district of entry
* On fait la régression par couple pays/secteur donc pas la peine de mettre des EF secteur / pays

tab(hs),gen(product)
tab(dist_entry),gen(dist_entry)

nl estim_beta  @ lprix_trsp2 lprix_fob `liste_variables' , eps(1e-3) iterate(200) parameters(`liste_parametres' ) initial (`initial')

capture matrix X= e(b)

replace beta=X[1,1] if iso_o=="`i'" & sector=="`k'"



}
}

keep iso_o sector beta 
keep if _n==1

save temp_`i'_`k', replace

}
}

*** Stocker les résultats

foreach i in `liste_iso_o'  {
foreach k in `liste_sector' {


use $dir_results\results_beta_`year'_`class'_`preci'_`mode', clear
append using $dir_temp\temp_`i'_`k'
save $dir_results\results_beta_`year'_`class'_`preci'_`mode', replace

erase $dir_temp/temp_`i'_`k'.dta
}

}
erase $dir_temp/temp.dta

histogram beta, title("Distribution of beta, `year', `mode', `preci' digits") 
graph export $dir_results/histogram_beta_`year'_`class'_`preci'_`mode'.pdf, replace


end

*******************************************************************************************
******* FIN DES PROGRAMMES ****************************************************************
*******************************************************************************************

**** lancer les programmes **************

* A FAIRE UNE FOIS POUR TOUTES
*program build_database


* PREPARER ET LANCER LES REGRESSIONS- Uniquement sur les années 2005 à 2013

cd $dir


set more off
local mode air ves
*local year 2005 


foreach x in `mode' {

forvalues z = 2006(1)2013 {
*foreach z in 2005 {

capture log close
log using results_estim_TC_referee1_`z'_`x', replace

prep_reg `z' sitc2 3 `x'
do_reg `z' sitc2 3 `x'


log close

}
}



