*** DHP Septembre 2019, révision Journal of Economic Geography

*** Estimer forme fonctionnelle du référé 2


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\lpatureau\Dropbox\trade_cost\data
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\lpatureau\Dropbox\trade_cost\data /* pour aller chercher la base de données au départ */ 
}


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767

cd $dir

**** Programme pour nettoyer la base de données par année / mode / degré de classification

capture program drop prep_reg
program prep_reg

args year class preci mode
* exemple : prep_reg 2006 sitc2 3 air
* Hummels : sitc2


****************Préparation de la base blouk

use "$dir_db/hummels_tra.dta"

***Pour restreindre
*keep if substr(sitc2,1,1)=="0"
*************************

keep if year==`year'
keep if mode=="`mode'"
rename `class' product
replace product = substr(product,1,`preci')

label variable iso_d "pays importateur"
label variable iso_o "pays exportateur"


* Nettoyer la base de données

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

**********Sur le produits

codebook product


egen group_prod=group(product)
su group_prod, meanonly	
drop group_prod
local nbr_prod_exante=r(max)
display "Nombre de produits : `nbr_prod_exante'" 

bysort product: drop if _N<=5

*** Génerer les effets fixes secteur / pays


egen group_prod=group(product)
su group_prod, meanonly	
local nbr_prod=r(max)
display "Nombre de produits : `nbr_prod'" 

egen group_country=group(iso_o)
su group_country, meanonly	
local nbr_country=r(max)

tab(iso_o), gen(country)
tab(product),gen(prod)

foreach j of num 1/`nbr_country' {
	gen prixfob_country`j' = prix_fob*country`j'
}

foreach j of num 1/`nbr_prod' {
	gen prixfob_prod`j' = prix_fob*prod`j'
}

save $dir/database/temp_`year'_`class'_`preci'_`mode', replace

end


** Programme: faire la régression en OLS
** prix caf = prix fob*tau(i)+ prix fob*tau(k) + t(i)+t(k) =residu

capture program drop do_reg
capture program do_reg
args year class preci mode


use $dir/database/temp_`year'_`class'_`preci'_`mode', clear

*egen group_country=group(iso_o)
su group_country, meanonly	
local nbr_country=r(max)
drop group_country

su group_prod, meanonly	
local nbr_prod=r(max)
drop group_prod

reg prix_caf prixfob_country2-prixfob_country`nbr_country' prixfob_prod1-prixfob_prod`nbr_prod' country2-country`nbr_country' prod1-prod`nbr_prod'

*** Enregistrer les résultats et calculer termeA et termeI

local n 1
	
capture drop terme_A
capture drop terme_I
generate double terme_A=0
generate double terme_I=0

capture matrix X= e(b)
	
**Ici, on enregistre les effets fixes (à la fois dans le terme additif et le terme multiplicatif)
	
		foreach p in country prod {
		*disp "Country or product ?"
		*disp "`p'"
			foreach j of num 1/`nbr_`p'' {
			*disp "Country or product number"
			*disp "`j'"
				if "`p'"!="country" | `j'!=1 {
					tempname feI_`p'_`j'

					scalar `feI_`p'_`j'' =X[1,`n']
					disp `feI_`p'_`j''
					replace terme_I = terme_I + `feI_`p'_`j'' * `p'`j'
					*disp "Terme I"
					local n = `n'+1
					*sum terme_I
					*disp "n"
					*disp "`n'"
					*sleep 20000
				}
			}
		}
	
	
			foreach p in country prod {
			*disp "Country or product ?"
			*disp "`p'"
			foreach j of num 1/`nbr_`p'' {
			*disp "Country or product number"
			*disp "`j'"
				if "`p'"!="country" | `j'!=1 {	
					tempname feA_`p'_`j'
					scalar `feA_`p'_`j'' =X[1,`n']
					replace terme_A = terme_A + `feA_`p'_`j''* `p'`j'

					local n = `n'+1

				}
			}
		}

	
*out v9	replace terme_A=(terme_A-1)/`prix_fob'

*replace terme_A=terme_A/prix_fob

/*
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
*/


save "$dir/results_revision/results_estimTC_ref2_`year'_`class'_`preci'_`mode'", replace


foreach x in terme_A terme_I {
histogram `x', title("Distribution of `x', `year', `mode', `preci' digits") 
graph export $dir/results/histogram_`x'_`year'_`class'_`preci'_`mode'.pdf, replace

}

end

********************************

*** Lancer les programmes

** Préparer la base de données


set more off
local mode air ves 
local year 1980 1990 2000 2010


foreach x in `mode' {

foreach z in `year' {

*forvalues z = 1974(1)2013 {


capture log close
log using results_estim_TC_referee2_`z'_`x', replace

prep_reg `z' sitc2 3 `x'
do_reg `z' sitc2 3 `x'

*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"

log close

}
}


