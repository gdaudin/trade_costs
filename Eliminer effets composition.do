

*** Programme qui élimine les effets de composition pays d'origine / produit
*** des coûts de transport estimés
*** de manière à récupérer l'évolution "pure" des coûts de transport, via les effets fixes pays

version 14.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



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

capture log using "`c(current_time)' `c(current_date)'"

* En cohérence avec l'estimation via nl, qui minimise la variance de l'erreur additive




******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE pour ADDITIFS ****
******************************************************************

capture program drop nldeter_couts_add
program nldeter_couts_add
	version 14.1
	summarize group_iso_o, meanonly	
	local nbr_iso_o=r(max)
	summarize group_prod, meanonly	
	local nbr_prod=r(max)
	summarize year, meanonly
	local nbr_year=r(max)-r(min)+1
	local nbr_var = `nbr_iso_o'+`nbr_prod'+`nbr_year'+1-2
	*En effet, je garde toutse les variables pour les produits, et j'enlève une pour les années et une pour les pays 
		
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)

	
	tempvar terme_A_dsbcle
	generate double `terme_A_dsbcle'=0
	local ln_terme_A : word 1 of `varlist'
		

**Ici, on fait les effets fixes (à la fois dans le terme additif et le terme multiplicatif)
	
	local n 1
	foreach type_FE in iso_o prod year {
		foreach num_FE of num 1/`nbr_`type_FE'' {
			if "`type_FE'"=="prod" | `num_FE'!=1 {
				tempname feA_`type_FE'_`num_FE' 


				scalar `feA_`type_FE'_`num_FE'' =`at'[1,`n']

				if ("`type_FE'"!="year") replace `terme_A_dsbcle' = `terme_A_dsbcle' + (exp(`feA_`type_FE'_`num_FE'') * `type_FE'_`num_FE')
				if ("`type_FE'"=="year") replace `terme_A_dsbcle' = `terme_A_dsbcle' * (exp(`feA_`type_FE'_`num_FE'' * `type_FE'_`num_FE'))
				local n = `n'+1
			}
		}
	}

	
	replace `ln_terme_A' = ln(`terme_A_dsbcle') `if'

	end
**********************************************************************
************** FIN FONCTION
**********************************************************************	



capture drop program eliminer_effets_composition
program eliminer_effets_composition
args sitc
*Exemple : eliminer_effets_composition 6 ou eliminer_effets_composition all



* On part de la base estim_TC.dta, qui collecte déjà l'essentiel de l'information nécessaire, pour 3 digits


use "$dir/results/estimTC.dta", clear
if "`sitc'" != "all" keep if substr(product,1,1)=="`sitc'"
gen terme_obs = prix_caf/prix_fob

 


* Créer la base pour sauver les résultats
* Et intégrer les valeurs initiales des trade costs (valeur moyenne en 1974)

*gen ves_val=.
*replace ves_val = val if mode =="ves"
*gen air_val=.
*replace air_val = val if mode =="air"
*drop val

*replace terme_A = terme_A
keep if year == 1974

foreach mode in air ves {
	foreach type_TC in A I obs {
	
		sum terme_`type_TC' [fweight= val] if mode=="`mode'" 
		generate terme_`type_TC'_`mode'_mp = r(mean)
		label var terme_`type_TC'_`mode'_mp "Weighted mean value of estimated TC of type `type_TC', 1974, mode `mode'"
		generat ecart_type_`type_TC'_`mode'_mp=.
	
	}
}

keep year terme_*_mp
keep if _n==1

save start_year_`sitc', replace

* La base pour stocker les résultats des estimations
* On enlève 1974, c'est l'année de référence, les EF sont estimés par rapport à cette année là



use "$dir/results/estimTC.dta", clear

drop if year == 1974
keep year
bys year: keep if _n ==1
save database_pureTC_`sitc', replace






foreach mode in air ves {

	
	
	
	use "$dir/results/estimTC.dta", clear

	if "`sitc'" != "all" keep if substr(product,1,1)=="`sitc'"
	gen terme_obs = prix_caf/prix_fob
	
	keep if mode=="`mode'"
	
	
*	keep if year < 1980
	local limit 15
	bys iso_o : drop if _N<=`limit'
	bys product : drop if _N<=`limit'
	bys iso_o : drop if _N<=`limit'
	bys product : drop if _N<=`limit'
	bys iso_o : drop if _N<=`limit'
	bys product : drop if _N<=`limit'
	bys iso_o : drop if _N<=`limit'
	bys product : drop if _N<=`limit'
	bys iso_o : drop if _N<=`limit'
	bys product : drop if _N<=`limit'
	
	foreach type_TC in obs I A {
		
		bys mode : egen c_95_`type_TC' = pctile(terme_`type_TC'),p(95)
		bys mode : egen c_05_`type_TC' = pctile(terme_`type_TC'),p(05)
		drop if terme_`type_TC' < c_05_`type_TC' | terme_`type_TC' > c_95_`type_TC'
	}
	
		

	




	foreach type_TC in obs I {
		*** Step 1 et 2 - Estimation sur couts de transport estimés en obs/terme_I seulement
		*** On précise l'équation en log

		** log (tau ikt) = log (taui) + log (tauk) + log (taut) + residu
		** avec i : pays origine, k = product, t = year
		preserve
	
	
		
	
	
	
		
		gen ln_terme_`type_TC' = ln(terme_`type_TC')
		
		display "Regression `type_TC' `mode'"
		
		xi: reg ln_terme_`type_TC' i.year i.product i.iso_o if mode =="`mode'", /*nocons*/ robust 
		
		
		* Enregistrer les effets fixes temps
		
		su year, meanonly	
		local nbr_year=r(max)
		quietly levelsof year, local (liste_year) clean
		
		* matrice des coefficients estimés
		capture	matrix X= e(b)
		capture matrix V=e(V)
		
		generate effet_fixe=.
		generate ecart_type=.
		 
		keep year effet_fixe ecart_type
		bys year : keep if _n==1
		drop if year==1974
		
		insobs `nbr_year'
		local n 1
		
		foreach i in `liste_year' {
				*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
				replace effet_fixe= X[1,`n'] in `n'
				replace ecart_type=V[`n',`n'] in `n'
			
				local n=`n'+1
		}
		
		replace ecart_type=(ecart_type)^0.5
		
		drop if effet_fixe == .
		
		rename effet_fixe effetfixe_`type_TC'_`mode'
		rename ecart_type ecart_type_`type_TC'_`mode'
		label var effetfixe_`type_TC'_`mode' "pure_FE_`type_TC'_`mode'"
		label var ecart_type_`type_TC'_`mode' "ecart_type_`type_TC'_`mode'"
		
		keep year effetfixe_`type_TC'_`mode' ecart_type_`type_TC'_`mode'
		
		sort year
		merge 1:1 year using database_pureTC_`sitc' 
		keep if _merge==3
		drop _merge
		
		save database_pureTC_`sitc', replace
		restore
	
	}





*** Step 2 - Estimation sur couts de transport additifs
*** On NE PEUT PAS PROCEDER de la même façon que pour les autres

** On se dit que les effets fixes temps sont multiplicatives des deux autres composantes
** (les couts additifs augmentent de 30% d'un an sur l'autre)
** D'où
** ln (tikt) = ln(ti+tk) + ln (tt)

** Idée pour rester en linéaire
** ln (tikt) = ln(tik) + ln (tt)


	
	drop if terme_A==0 | terme_A==.
	gen ln_terme_A = ln(terme_A)
	
	************************ Importé de Estim_value_TC
		******************************************Régression
	
replace iso_o = "0ARG" if iso_o=="ARG"
**Le premier pays (AFG) ne fait pas de commerce du premier bien (001) en 1974. Je change de manière à ce que l'Argentine passe en tête
**L'argentine fait bien du commerce de 001 en 1974
**Sinon, j'ai un soucis avec les EF que j'enlève dans l'équation non-linéaire.
	
	*Pour nombre de product
	quietly egen group_prod=group(product)
	quietly summarize group_prod
	local nbr_prod=r(max)
	quietly levelsof product, local (liste_prod) clean
	quietly tabulate product, gen (prod_)
		
	*Pour nombre d'iso_o
	quietly egen group_iso_o=group(iso_o)
	quietly summarize group_iso_o	
	local nbr_iso_o=r(max)
	quietly levelsof iso_o, local(liste_iso_o) clean
	quietly tabulate iso_o, gen(iso_o_)
	
	*Pour nombre d'années
	quietly egen group_year=group(year)
	quietly summarize group_year	
	local nbr_year=r(max)-r(min)+1
	quietly levelsof year, local(liste_year) clean
	quietly tabulate year, gen(year_)
	
	
	
	
	**Cette boucle crée les variables, les paramètres et leurs valeurs initales	
	foreach type_FE in  iso_o prod year {
	
		local liste_variables_`type_FE' 
		forvalue num_FE =  1/`nbr_`type_FE'' {
			if "`type_FE'" =="prod" | `num_FE' !=1 {
				local liste_variables_`type_FE'  `liste_variables_`type_FE'' `type_FE'_`num_FE'
			}
		}
	
	
	***REGARDER NOMBRE DE VARIABLES
	
		local liste_parametres_`type_FE'
			forvalue num_FE =  1/`nbr_`type_FE'' {
				if  "`type_FE'" =="prod" | `num_FE'!=1 {			
					local liste_parametres_`type_FE'  `liste_parametres_`type_FE'' fe_`type_FE'_`num_FE'
				}
			}
	
	
		
		
		local initial_`type_FE'
		forvalue num_FE =  1/`nbr_`type_FE'' {
			if  "`type_FE'" =="prod" |`num_FE'!=1 {
						if ("`type_FE'" !="year") local initial_`type_FE'  `initial_`type_FE'' fe_`type_FE'_`num_FE' -2
						if ("`type_FE'" =="year") local initial_`type_FE'  `initial_`type_FE'' fe_`type_FE'_`num_FE' 0.02
			}
				
		}		
	}
	
	
		
		
	
	
	
	local liste_variables `liste_variables_iso_o' `liste_variables_prod'  `liste_variables_year' 
	
	** pour estimation NL both A & I
	local liste_parametres  `liste_parametres_iso_o' `liste_parametres_prod'  `liste_parametres_year'
	local initial  `initial_iso_o' `initial_prod'  `initial_year'
	
*	display "Liste des variables :" "`liste_variables'"
*	display "Liste des paramètres :" "`liste_parametres'"
*	display "Initial :" "`initial'"

	display "Nombre des variables :" wordcount("`liste_variables'")
	display "Liste des paramètres :" wordcount("`liste_parametres'")
	display "Initial :" wordcount("`initial'")
	
	timer on 1
	
	
	display "Regression terme_A `mode'"
	
	
	display "nl deter_couts_add @ ln_terme_A `liste_variables' , iterate(100) parameters(`liste_parametres' ) initial(`initial')"
	
	nl deter_couts_add @ ln_terme_A `liste_variables' , iterate(100) parameters(`liste_parametres' ) initial(`initial')
	
	
	predict ln_terme_A_predict
	generate terme_A_predict=exp(ln_terme_A_predict)
	twoway (scatter ln_terme_A_predict ln_terme_A)
	
	save blouk.dta, replace
	
	
	* Enregistrer les effets fixes temps
	
	
	* matrice des coefficients estimés
	
*	set trace on
	capture	matrix X= e(b)
	capture matrix V=e(V)
	matrix dir
	
	generate effet_fixe=.
	generate ecart_type=.
	 
	keep year effet_fixe ecart_type
	bys year : keep if _n==1
	drop if year==1974
	quietly levelsof year, local (liste_year) clean
	
	
	display "local n = `nbr_iso_o' + `nbr_prod' - 1 + 1"
	local n = `nbr_iso_o' + `nbr_prod' - 1 + 1
	
		
	display "`liste_year'"	
	foreach i in `liste_year' {
			display "effet_fixe= X[1,`n'] if year==`i'"
			replace effet_fixe= X[1,`n'] if year==`i'
			replace ecart_type= V[`n',`n'] if year==`i'
			local n=`n'+1
		}
	
	replace ecart_type=(ecart_type)^0.5
	list
	
	drop if effet_fixe == .
	
	rename effet_fixe effetfixe_A_`mode'
	label var effetfixe_A_`mode' "pure_FE_A_`mode'"
	
	rename ecart_type ecart_type_A_`mode'
	label var ecart_type_A_`mode' "Écart type du pure_FE_A_`mode'"
	
	keep year effetfixe_A_`mode' ecart_type_A_`mode'
	
	sort year
	merge 1:1 year using database_pureTC_`sitc' 
	keep if _merge==3
	drop _merge
	
	list
	
*	set trace off
	save database_pureTC_`sitc', replace

	
	
	
	
}


* Ajouter 1974 et partir d'une valeur 100 en 1974
*Puis construire le fichier de résultat

use database_pureTC_`sitc', clear

append using start_year_`sitc'
sort year


foreach mode in air ves {
	foreach type_TC in obs I {
		generate terme_`type_TC'_`mode'_74  = terme_`type_TC'_`mode'_mp[1]
		replace effetfixe_`type_TC'_`mode' = 0 if effetfixe_`type_TC'_`mode' == .
		replace terme_`type_TC'_`mode'_mp = 100*(terme_`type_TC'_`mode'_74*exp(effetfixe_`type_TC'_`mode')-1)/(terme_`type_TC'_`mode'_74-1)	
		*replace ecart_type_`type_TC'_`mode' = 100*(terme_`type_TC'_`mode'_74*exp(ecart_type_`type_TC'_`mode')-1)/(terme_`type_TC'_`mode'_74-1)	
		
		gen terme_95_`type_TC'_`mode'_mp=100*(terme_`type_TC'_`mode'_74*exp(effetfixe_`type_TC'_`mode'+1.96*ecart_type_`type_TC'_`mode')-1)/(terme_`type_TC'_`mode'_74-1)
		gen terme_05_`type_TC'_`mode'_mp=100*(terme_`type_TC'_`mode'_74*exp(effetfixe_`type_TC'_`mode'-1.96*ecart_type_`type_TC'_`mode')-1)/(terme_`type_TC'_`mode'_74-1)
		
		
		
		
		label var terme_`type_TC'_`mode'_mp "pure_TC_`type_TC'_`mode'"
		label var ecart_type_`type_TC'_`mode' "ecart_type_TC_`type_TC'_`mode'"
	}
}


foreach mode in air ves {
	foreach type_TC in  A {
		generate terme_`type_TC'_`mode'_74  = terme_`type_TC'_`mode'_mp[1]
		replace effetfixe_`type_TC'_`mode' = 0 if effetfixe_`type_TC'_`mode' == .
		replace terme_`type_TC'_`mode'_mp = 100*exp(effetfixe_`type_TC'_`mode')
*		replace ecart_type_`type_TC'_`mode' = 100*exp(ecart_type_`type_TC'_`mode')
		
		gen terme_95_`type_TC'_`mode'_mp=100*exp(effetfixe_`type_TC'_`mode'+1.96*ecart_type_`type_TC'_`mode')
		gen terme_05_`type_TC'_`mode'_mp=100*exp(effetfixe_`type_TC'_`mode'-1.96*ecart_type_`type_TC'_`mode')
		
		label var terme_`type_TC'_`mode'_mp "pure_TC_`type_TC'_`mode'"
		label var ecart_type_`type_TC'_`mode' "ecart_type_TC_`type_TC'_`mode'"
	}
}




export excel using table_extract_effetscomposition_`sitc', replace firstrow(varlabels)

save resultats_finaux/database_pureTC_`sitc', replace

erase start_year_`sitc'.dta

end


*/



***********LANCER LES PROGRAMMES********************


eliminer_effets_composition all




