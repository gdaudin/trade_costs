

*** Programme qui élimine les effets de composition pays d'origine / produit
*** des coûts de transport estimés
*** de manière à récupérer l'évolution "pure" des coûts de transport, via les effets fixes pays



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

cd $dir

* En cohérence avec l'estimation via nl, qui minimise la variance de l'erreur additive

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767

* On part de la base estim_TC.dta, qui collecte déjà l'essentiel de l'information nécessaire, pour 3 digits

if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear



* Créer la base pour sauver les résultats
* Et intégrer les valeurs initiales des trade costs (valeur moyenne en 1974)

*gen ves_val=.
*replace ves_val = val if mode =="ves"
*gen air_val=.
*replace air_val = val if mode =="air"
*drop val

local mode air ves
local type_TC iceberg A I
replace terme_A = terme_A+1
keep if year == 1974

foreach z in `mode' {
	foreach x in `type_TC' {
	
	sum terme_`x' [fweight= val] if mode=="`z'" 
	generate terme_`x'_`z'_mp = r(mean)
	
	}
}

keep year terme_iceberg_air_mp terme_iceberg_ves_mp terme_I_air_mp terme_I_ves_mp terme_A_air_mp terme_A_ves_mp
keep if _n==1

foreach z in `mode' {
	foreach x in `type_TC' {
	
	
	label var terme_`x'_`z'_mp "Mean value of estimated TC of type `x', 1974, mode `z'"
	
	}
}

save start_year, replace

* La base pour stocker les résultats des estimations
* On enlève 1974, c'est l'année de référence, les EF sont estimés par rapport à cette année là


if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear

drop if year == 1974
keep year
bys year: keep if _n ==1
save database_pureTC, replace



*** Step 1 - Estimation sur couts de transport estimés en iceberg seulement
*** On précise l'équation en log

** log (tau ikt) = log (taui) + log (tauk) + log (taut) + residu
** avec i : pays origine, k = product, t = year


if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear
local mode air ves

foreach z in `mode' {


if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear

gen ln_terme_iceberg = ln(terme_iceberg)

* Pour air
xi: reg ln_terme_iceberg i.year i.product i.iso_o if mode =="`z'", nocons robust 


* Enregistrer les effets fixes temps

su year, meanonly	
local nbr_year=r(max)
quietly levelsof year, local (liste_year) clean

* matrice des coefficients estimés
capture	matrix X= e(b)

generate effet_fixe=.
 
keep year effet_fixe
bys year : keep if _n==1
drop if year==1974

insobs `nbr_year'
local n 1

foreach i in `liste_year' {
	*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
	replace effet_fixe= X[1,`n'] in `n'

	local n=`n'+1
}


drop if effet_fixe == .

rename effet_fixe effetfixe_nlI_`z'
label var effetfixe_nlI_`z' "pure_FE_nlI_`z'"

keep year effetfixe_nlI_`z'

sort year
merge 1:1 year using database_pureTC 
keep if _merge==3
drop _merge

save database_pureTC, replace

}



*** Step 2 - Estimation sur couts de transport estimés avec multiplicatif et additif 
*** On précise l'équation en log pour la composante iceberg

** log (tau ikt) = log (taui) + log (tauk) + log (taut) + residu
** avec i : pays origine, k = product, t = year


local mode air ves

foreach z in `mode' {


if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear

gen ln_terme_I = ln(terme_I)

* Pour air
xi: reg ln_terme_I i.year i.product i.iso_o if mode =="`z'", nocons robust 


* Enregistrer les effets fixes temps

su year, meanonly	
local nbr_year=r(max)
quietly levelsof year, local (liste_year) clean

* matrice des coefficients estimés
capture	matrix X= e(b)

generate effet_fixe=.
 
keep year effet_fixe
bys year : keep if _n==1
drop if year==1974

insobs `nbr_year'
local n 1

	foreach i in `liste_year' {
		*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
		replace effet_fixe= X[1,`n'] in `n'
	
		local n=`n'+1
	}


drop if effet_fixe == .

rename effet_fixe effetfixe_I_`z'
label var effetfixe_I_`z' "pure_FE_I_`z'"

keep year effetfixe_I_`z'

sort year
merge 1:1 year using database_pureTC 
keep if _merge==3
drop _merge

save database_pureTC, replace

}



*** Step 3 - Estimation sur couts de transport additifs
*** On NE PEUT PAS PROCEDER de la même façon que pour les autres

** On se dit que les effets fixes temps sont multiplicatives des deux autres composantes
** (les couts additifs augmentent de 30% d'un an sur l'autre)
** D'où
** ln (tikt) = ln(ti+tk) + ln (tt)

** Idée pour rester en linéaire
** ln (tikt) = ln(tik) + ln (tt)

/* TO BE DONE */


set more off
local mode air ves



foreach z in `mode' {


if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear

replace terme_A = terme_A +1
gen ln_terme_A = ln(terme_A)

xi: reg ln_terme_A i.year i.product*i.iso_o if mode =="`z'", nocons robust 


* Enregistrer les effets fixes temps

su year, meanonly	
local nbr_year=r(max)
quietly levelsof year, local (liste_year) clean

* matrice des coefficients estimés
capture	matrix X= e(b)

generate effet_fixe=.
 
keep year effet_fixe
bys year : keep if _n==1
drop if year==1974

insobs `nbr_year'
local n 1

	foreach i in `liste_year' {
		*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
		replace effet_fixe= X[1,`n'] in `n'
	
		local n=`n'+1
	}


drop if effet_fixe == .

rename effet_fixe effetfixe_A_`z'
label var effetfixe_A_`z' "pure_FE_A_`z'"

keep year effetfixe_A_`z'

sort year
merge 1:1 year using database_pureTC 
keep if _merge==3
drop _merge

save database_pureTC, replace

}


* Ajouter 1974 et partir d'une valeur 100 en 1974


use database_pureTC, clear

append using start_year
sort year

rename terme_iceberg_air_mp terme_nlI_air_mp
rename terme_iceberg_ves_mp terme_nlI_ves_mp


** Pour les termes en multiplicatifs
local mode air ves
local type_tc nlI I A



foreach z in `mode' {
foreach x in `type_tc' {




generate terme_`x'_`z'_74  = terme_`x'_`z'_mp[1]


replace effetfixe_`x'_`z' = 0 if effetfixe_`x'_`z' == .

replace terme_`x'_`z'_mp = 100*(terme_`x'_`z'_74*exp(effetfixe_`x'_`z')-1)/(terme_`x'_`z'_74-1)

}


}

** TO BE DONE SUR COUTS ADDITIFS **

** Last step : export to excel 


local mode air ves
local tc_type nlI I /* A */

foreach z in `mode' {
foreach x in `tc_type' {
label var terme_`x'_`z'_mp "pure_TC_`x'_`z'"
}
}

export excel using table_extract_effetscomposition, replace firstrow(varlabels)

save database_pureTC, replace

*/


erase start_year.dta
