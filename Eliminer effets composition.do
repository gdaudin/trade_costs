

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

replace terme_A = terme_A+1
keep if year == 1974

foreach mode in air ves {
	foreach type_TC in iceberg A I {
	
		sum terme_`type_TC' [fweight= val] if mode=="`mode'" 
		generate terme_`type_TC'_`mode'_mp = r(mean)
		label var terme_`type_TC'_`mode'_mp "Weighted mean value of estimated TC of type `type_TC', 1974, mode `mode'"
	
	}
}

keep year terme_iceberg_air_mp terme_iceberg_ves_mp terme_I_air_mp terme_I_ves_mp terme_A_air_mp terme_A_ves_mp
keep if _n==1

save start_year, replace

* La base pour stocker les résultats des estimations
* On enlève 1974, c'est l'année de référence, les EF sont estimés par rapport à cette année là


if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear

drop if year == 1974
keep year
bys year: keep if _n ==1
save database_pureTC, replace



*** Step 1 et 2 - Estimation sur couts de transport estimés en iceberg/terme_I seulement
*** On précise l'équation en log

** log (tau ikt) = log (taui) + log (tauk) + log (taut) + residu
** avec i : pays origine, k = product, t = year

foreach type_TC in iceberg I {

	
	foreach mode in air ves {
	
	
		if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
		if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear
		
		gen ln_terme_`type_TC' = ln(terme_`type_TC')
		
		* Pour air
		xi: reg ln_terme_`type_TC' i.year i.product i.iso_o if mode =="`mode'", nocons robust 
		
		
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
		
		rename effet_fixe effetfixe_`type_TC'_`mode'
		label var effetfixe_`type_TC'_`mode' "pure_FE_`type_TC'_`mode'"
		
		keep year effetfixe_`type_TC'_`mode'
		
		sort year
		merge 1:1 year using database_pureTC 
		keep if _merge==3
		drop _merge
		
		save database_pureTC, replace
	
	}

}



*** Step 2 - Estimation sur couts de transport additifs
*** On NE PEUT PAS PROCEDER de la même façon que pour les autres

** On se dit que les effets fixes temps sont multiplicatives des deux autres composantes
** (les couts additifs augmentent de 30% d'un an sur l'autre)
** D'où
** ln (tikt) = ln(ti+tk) + ln (tt)

** Idée pour rester en linéaire
** ln (tikt) = ln(tik) + ln (tt)




set more off
local mode air ves



foreach z in `mode' {

	
	if ("`c(os)'"!="MacOSX") use "$dir\results\estimTC", clear
	if ("`c(os)'"=="MacOSX") use "$dir/results/estimTC.dta", clear
	
	replace terme_A = terme_A +1
	gen ln_terme_A = ln(terme_A)
	
	xi: reg ln_terme_A i.year i.product i.iso_o if mode =="`z'", nocons robust 
	
	
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
*Puis construire le fichier de résultat


use database_pureTC, clear

append using start_year
sort year
local mode air ves
local type_tc nlI I A



foreach mode in air ves {
	foreach type_TC in iceberg I A {
		generate terme_`type_TC'_`mode'_74  = terme_`type_TC'_`mode'_mp[1]
		replace effetfixe_`type_TC'_`mode' = 0 if effetfixe_`type_TC'_`mode' == .
		replace terme_`type_TC'_`mode'_mp = 100*(terme_`type_TC'_`mode'_74*exp(effetfixe_`type_TC'_`mode')-1)/(terme_`type_TC'_`mode'_74-1)	
		label var terme_`type_TC'_`mode'_mp "pure_TC_`type_TC'_`mode'"
	}
}



export excel using table_extract_effetscomposition, replace firstrow(varlabels)

save database_pureTC, replace

*/


erase start_year.dta
