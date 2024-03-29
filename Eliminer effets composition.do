

*** Programme qui élimine les effets de composition pays d'origine / produit
*** des coûts de transport estimés
*** de manière à récupérer l'évolution "pure" des coûts de transport, via les effets fixes pays

*****Août 2021 : je fais le calcul sur terme_Adoll et non pas sur terme_A (comme dans l’équation, quoi...
*******je fais la même chose pour prix_fob, de manière à pouvoir le comparer à terme_Adoll

version 16.0

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767

**Il faut créer un dossier results/Effets de composition

*Programme fait à partir de "Comparaison.do

if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaisons_various"
	global dir_temp ~/Downloads/temp_stata
	global dir_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results"
	global dir_git "~/Répertoires Git/trade_costs_git"
	
	
}


*** Juillet 2020: Lise, tout sur mon OneDrive


/* Fixe Lise P112*/

/* Nouveau fixe Bureau Lise: Tout en local sur MyWork. Pour la base et les résultats, dossier Lise ; pgms dans le dossier Git (de MyWork) */
if "`c(hostname)'" =="LAB0661F" {
	
	 * baseline results sur hummels_tra dans son intégralité
	 global dir_baseline_results "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\baseline"

	 

	* résultats selon méthode référé 1
    global dir_referee1 "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	
	
	* stocker la comparaison des résultats
	global dir_comparaison "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\comparaison_baseline_referee1"
	
	/* Il me manque pour faire méthode 2 en IV 
	- IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta
	- IV_referee1_yearly/results_estimTC_`year'_sitc2_3_`mode'.dta
	
	*/
	
	global dir_temp "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
	global dir "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_results "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results"
	 
	 
	}

/* Nouveau portable Lise */
if "`c(hostname)'" =="MSOP112C" {

	* baseline results sur hummels_tra dans son intégralité
    global dir_baseline_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\baseline"
		
	* résultats selon méthode référé 1
	global dir_referee1 "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	
	* stocker la comparaison des résultats
	global dir_comparaison "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\comparaison_baseline_referee1"
	
	/* Il me manque pour faire méthode 2 en IV 
	- IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta
	- IV_referee1_yearly/results_estimTC_`year'_sitc2_3_`mode'.dta
	
	*/
	
	global dir_temp "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
	global dir "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results"
	}



set more off

capture log using "`c(current_time)' `c(current_date)'"

do "$dir_git/Open_year_mode_method_model.do"

* En cohérence avec l'estimation via nl, qui minimise la variance de l'erreur additive




******************************************************************
*** FONCTION ESTIMATION NON-LINEAIRE pour ADDITIFS ****
******************************************************************

capture program drop nldeter_couts_add
program nldeter_couts_add
	version 14.1
	summarize group_iso_o, meanonly	
	* Tip du Sata Technical support pour cette ligne : ce serait mieux d'utiliser des tempvar. «it would be advisable to use local varnames on all occasions, as opposed to hard-coding variable names in your  program, but this is an unrelated comment.»
	local nbr_iso_o=r(max)
	summarize group_sect, meanonly	
	local nbr_sect=r(max)
	summarize year, meanonly
	local nbr_year=r(max)-r(min)+1
	local nbr_var = `nbr_iso_o'+`nbr_sect'+`nbr_year'+1-2
	*En effet, je garde toutse les variables pour les produits, et j'enlève une pour les années et une pour les pays 
		
	syntax varlist (min=`nbr_var' max=`nbr_var') if [iw/], at(name)

	
	tempvar terme_Adoll_dsbcle
	generate double `terme_Adoll_dsbcle'=0
	local ln_terme_Adoll : word 1 of `varlist'
		

**Ici, on fait les effets fixes (dans le terme additif)
	
	local n 1
	foreach type_FE in iso_o sect year {
		foreach num_FE of num 1/`nbr_`type_FE'' {
			if "`type_FE'"=="sect" | `num_FE'!=1 {
				tempname feA_`type_FE'_`num_FE' 


				scalar `feA_`type_FE'_`num_FE'' =`at'[1,`n']

				if ("`type_FE'"!="year") replace `terme_Adoll_dsbcle' = `terme_Adoll_dsbcle' + (exp(`feA_`type_FE'_`num_FE'') * `type_FE'_`num_FE')
				if ("`type_FE'"=="year") replace `terme_Adoll_dsbcle' = `terme_Adoll_dsbcle' * (exp(`feA_`type_FE'_`num_FE'' * `type_FE'_`num_FE'))
				local n = `n'+1
			}
		}
	}

	
	replace `ln_terme_Adoll' = ln(`terme_Adoll_dsbcle') `if'

	end
**********************************************************************
************** FIN FONCTION
**********************************************************************	



capture drop program eliminer_effets_composition
program eliminer_effets_composition
args mode sitc type_TC

if "`type_TC'"=="obs_Hummels" local type_TCm obs

local type_TCm `type_TC'

local terme_type_TC terme_`type_TC'
local terme_type_TCm terme_`type_TCm'

if "`type_TC'"=="prix_fob" local terme_type_TC prix_fob
if "`type_TC'"=="prix_fob" local terme_type_TCm prix_fob

assert "`sitc'"=="manuf" | "`sitc'"=="primary" | "`sitc'"=="all"

*Exemple : eliminer_effets_composition 6 ou eliminer_effets_composition all A (faux !)



* On part de la base estim_TC.dta, qui collecte déjà l'essentiel de l'information nécessaire, pour 3 digits



***************CRÉATION DE LA BASE POUR STOCKER LES DONNÉES AVEC LE COÛT EN 1974

*use "$dir/results/estimTC.dta", clear
*keep if year == 1974

open_year_mode_method_model 1974 `mode' baseline nlAetI




foreach secteur of num 0(1)8 {
	if "`sitc'"=="`secteur'" keep if substr(sector,1,1)=="`sitc'"
}



*Based on UNCTAD Stat "product groupings" DimSitcRev3Products_DsibSpecialGroupings_Hierarchy.xls 
*http://unctadstat.unctad.org/EN/Classifications.html

if "`sitc'"=="primary" keep if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68"




if "`sitc'"=="manuf" drop if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68" | substr(sector,1,1)=="9"



gen terme_obs = prix_caf/prix_fob

 


* Créer la base pour sauver les résultats
* Et intégrer les valeurs initiales des trade costs (valeur moyenne en 1974)

*gen ves_val=.
*replace ves_val = val if mode =="ves"
*gen air_val=.
*replace air_val = val if mode =="air"
*drop val

*replace terme_A = terme_A





sum `terme_type_TCm' [fweight= val] if mode=="`mode'" 
generate `terme_type_TCm'_`mode'_mp = r(mean)
label var `terme_type_TCm'_`mode'_mp "Weighted mean value of estimated TC of type `type_TC', 1974, mode `mode'"
generat ecart_type_`type_TCm'_`mode'_mp=.



keep year `terme_type_TCm'_`mode'_mp
keep if _n==1

save "$dir_temp/start_year_`mode'_`sitc'_`type_TC'", replace

* La base pour stocker les résultats des estimations
* On enlève 1974, c'est l'année de référence, les EF sont estimés par rapport à cette année là

**************************DÉBUT DE L'ANALYSE PROPREMENT DITE

*use "$dir/results/estimTC.dta", clear

local time_span 1975 (1) 2019


foreach year of num `time_span'  {
	open_year_mode_method_model `year' `mode' baseline nlAetI
	keep if _n ==1
	
	capture append "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'.dta"
	save "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'.dta", replace
}


*drop if year == 1974
*keep year
*keep if mode=="`mode'"
*bys year: keep if _n ==1





*use "$dir/results/estimTC.dta", clear


*Pour faire la bdd : on peut commenter pour les tests 
local start 1974
local end 2019

capture erase "$dir_temp/temp.dta"
foreach year of num `start' (1) `end'  {
	open_year_mode_method_model `year' `mode' baseline nlAetI
	if `year' !=`start' append using "$dir_temp/temp.dta"
	save "$dir_temp/temp.dta", replace
}



use "$dir_temp/temp.dta", clear

foreach secteur of num 0(1)9 {
	if "`sitc'"=="`secteur'" keep if substr(sector,1,1)=="`sitc'"
}



*Based on UNCTAD Stat "product groupings" DimSitcRev3Products_DsibSpecialGroupings_Hierarchy.xls 
*http://unctadstat.unctad.org/EN/Classifications.html

if "`sitc'"=="primary" keep if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68"




if "`sitc'"=="manuf" drop if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68" | substr(sector,1,1)=="9"





gen terme_obs = prix_caf/prix_fob




local limit 15
/*
***Pour test
keep if year < 1977
keep if iso_o=="FRA" | iso_o=="DEU" | iso_o=="GBR" | iso_o=="FIN" 
local limit 1
*****
*/


bys iso_o : drop if _N<=`limit'
bys sector : drop if _N<=`limit'
bys iso_o : drop if _N<=`limit'
bys sector : drop if _N<=`limit'
bys iso_o : drop if _N<=`limit'
bys sector : drop if _N<=`limit'
bys iso_o : drop if _N<=`limit'
bys sector : drop if _N<=`limit'
bys iso_o : drop if _N<=`limit'
bys sector : drop if _N<=`limit'
	
egen c_95_`type_TCm' = pctile(`terme_type_TCm'),p(95)
egen c_05_`type_TCm' = pctile(`terme_type_TCm'),p(05)
drop if `terme_type_TCm' < c_05_`type_TCm' | `terme_type_TCm' > c_95_`type_TCm'

	
*Création du poids pertinent
*Qui est la part occupée chaque année par chaque secteur x pays
bys year : egen annual_trade = total(val)
generate yearly_share=val/annual_trade
label var yearly_share "part dans le commerce de cette année-là"


save "$dir_temp/tmp_`mode'_`sitc'_`type_TC'.dta", replace



if "`type_TC'"== "obs" |  "`type_TC'"== "I" |  "`type_TC'"== "prix_fob" {
	*** Step 1 et 2 - Estimation sur couts de transport estimés en obs/terme_I seulement
	*** On précise l'équation en log

	** log (tau ikt) = log (taui) + log (tauk) + log (taut) + residu
	** avec i : pays origine, k = sector, t = year
	use "$dir_temp/tmp_`mode'_`sitc'_`type_TC'.dta", clear
	if ("`type_TC'"== "obs" |  "`type_TC'"== "I")  replace `terme_type_TC' = `terme_type_TC'-1
	
	if "`type_TC'"== "I" collapse (sum) yearly_share (mean) terme_I, by(iso_o year sector mode)
	
	gen ln_`terme_type_TC' = ln(`terme_type_TC')
	

	display "Regression `type_TC' `mode'"
	
	encode sector, gen(sector_num)
	encode iso_o, gen(iso_o_num)
	
	reg ln_`terme_type_TC' i.year i.sector_num i.iso_o_num [iweight=yearly_share], /*nocons*/ robust 
	
	estimates save "$dir_results/Effets de composition/estimate_deter_couts_add_`mode'_`type_TC'.ster", replace
	
	predict ln_`terme_type_TC'_predict
	if "`type_TC'"== "obs" |  "`type_TC'"== "I"  generate `terme_type_TC'_predict=exp(ln_`terme_type_TC'_predict)+1
	if "`type_TC'"== "prix_fob" `terme_type_TC'_predict=exp(ln_`terme_type_TC'_predict)
	collapse (mean) `terme_type_TC'_predict, by(year)
	rename `terme_type_TC'_predict `terme_type_TC'_`mode'_np
	label var `terme_type_TC'_`mode'_np "Moyenne non-pondérée des predicts du 2e stage"
	
	
	
	* Enregistrer les effets fixes temps
	
	su year, meanonly	
	local nbr_year=r(max)
	quietly levelsof year, local (liste_year) clean
	display "`liste_year'"
	
	* matrice des coefficients estimés
	capture	matrix X= e(b)
	capture matrix V=e(V)
	
	generate effet_fixe=.
	generate ecart_type=.
	 
	keep year effet_fixe ecart_type  `terme_type_TC'_`mode'_np
	bys year : keep if _n==1
	
	
	local n 1
*	list
*	matrix list X
	
	foreach i in `liste_year' {
			*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
			replace effet_fixe= X[1,`n'] in `n'
			replace ecart_type=V[`n',`n'] in `n'	
			local n=`n'+1
	}
	
	gen `terme_type_TC'_`mode'_74_np=`terme_type_TC'_`mode'_np[1]
	drop if year==1974

*	list
	
	replace ecart_type=(ecart_type)^0.5
	
	drop if effet_fixe == .
	
	rename effet_fixe effetfixe_`type_TC'_`mode'
	rename ecart_type ecart_type_`type_TC'_`mode'
	label var effetfixe_`type_TC'_`mode' "pure_FE_`type_TC'_`mode'"
	label var ecart_type_`type_TC'_`mode' "ecart_type_`type_TC'_`mode'"
	
	keep year effetfixe_`type_TC'_`mode' ecart_type_`type_TC'_`mode' ///
			`terme_type_TC'_`mode'_np `terme_type_TC'_`mode'_74_np
	
	sort year
	list
	
	
	
	save "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'", replace
	
	append using "$dir_temp/start_year_`mode'_`sitc'_`type_TC'"
	
	sort year
	
	save "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'", replace
	

}



*** Step 2 - Estimation sur couts de transport additifs
*** On NE PEUT PAS PROCEDER de la même façon que pour les autres

** On se dit que les effets fixes temps sont multiplicatives des deux autres composantes
** (les couts additifs augmentent de 30% d'un an sur l'autre)
** D'où
** ln (tikt) = ln(ti+tk) + ln (tt)

** Idée pour rester en linéaire
** ln (tikt) = ln(tik) + ln (tt)


if "`type_TC'"== "A" {
	
	use "$dir_temp/tmp_`mode'_`sitc'_`type_TC'.dta", clear
	drop if terme_A==0 | terme_A==.
	gen terme_Adoll = terme_A*prix_fob
	collapse (sum) yearly_share (mean) terme_Adoll, by(iso_o year sector mode)
	gen ln_terme_Adoll = ln(terme_Adoll)
	
	
	************************ Importé de Estim_value_TC
		******************************************Régression
	
	replace iso_o = "0ARG" if iso_o=="ARG"
	**Le premier pays (AFG) ne fait pas de commerce du premier bien (001) en 1974. Je change de manière à ce que l'Argentine passe en tête
	**L'argentine fait bien du commerce de 001 en 1974
	**Sinon, j'ai un soucis avec les EF que j'enlève dans l'équation non-linéaire.
	
	*Pour nombre de sector
	capture drop group_sect
	quietly egen group_sect=group(sector)
	quietly summarize group_sect
	local nbr_sect=r(max)
	quietly levelsof sector, local (liste_sect) clean
	quietly tabulate sector, gen (sect_)
		
	*Pour nombre d'iso_o
	capture drop group_iso_o
	quietly egen group_iso_o=group(iso_o)
	quietly summarize group_iso_o	
	local nbr_iso_o=r(max)
	quietly levelsof iso_o, local(liste_iso_o) clean
	quietly tabulate iso_o, gen(iso_o_)
	
	*Pour nombre d'années
	capture drop group_yearquietly
	quietly egen group_year=group(year)
	quietly summarize group_year	
	local nbr_year=r(max)-r(min)+1
	quietly levelsof year, local(liste_year) clean
	quietly tabulate year, gen(year_)
	
	
	
	
	**Cette boucle crée les variables, les paramètres et leurs valeurs initales	
	foreach type_FE in  iso_o sect year {
	
		local liste_variables_`type_FE' 
		forvalue num_FE =  1/`nbr_`type_FE'' {
			if "`type_FE'" =="sect" | `num_FE' !=1 {
				local liste_variables_`type_FE'  `liste_variables_`type_FE'' `type_FE'_`num_FE'
			}
		}
	
	
	***REGARDER NOMBRE DE VARIABLES
	
		local liste_parametres_`type_FE'
			forvalue num_FE =  1/`nbr_`type_FE'' {
				if  "`type_FE'" =="sect" | `num_FE'!=1 {			
					local liste_parametres_`type_FE'  `liste_parametres_`type_FE'' fe_`type_FE'_`num_FE'
				}
			}
	
	
		
		
		local initial_`type_FE'
		forvalue num_FE =  1/`nbr_`type_FE'' {
			if  "`type_FE'" =="sect" |`num_FE'!=1 {
						if ("`type_FE'" !="year") local initial_`type_FE'  `initial_`type_FE'' fe_`type_FE'_`num_FE' -2
						if ("`type_FE'" =="year") local initial_`type_FE'  `initial_`type_FE'' fe_`type_FE'_`num_FE' 0.02
			}
				
		}		
	}
	
	
		
		
	
	
	
	local liste_variables `liste_variables_iso_o' `liste_variables_sect'  `liste_variables_year' 
	
	** pour estimation NL both A & I
	local liste_parametres  `liste_parametres_iso_o' `liste_parametres_sect'  `liste_parametres_year'
	local initial  `initial_iso_o' `initial_sect'  `initial_year'
	
	*	display "Liste des variables :" "`liste_variables'"
	*	display "Liste des paramètres :" "`liste_parametres'"
	*	display "Initial :" "`initial'"
	
	display "Nombre des variables :" wordcount("`liste_variables'")
	display "Liste des paramètres :" wordcount("`liste_parametres'")
	display "Initial :" wordcount("`initial'")
	
	timer on 1
	
	
	display "Regression terme_A `mode'"
	
	
	display "nl deter_couts_add @ ln_terme_Adoll `liste_variables' , iterate(100) parameters(`liste_parametres' ) initial(`initial')"
	
	replace yearly_share = yearly_share*100000
******	Ce bout là soit fait l'estimation, soit la récupère si elle a déjà été faite.
	nl deter_couts_add @ ln_terme_Adoll `liste_variables' [iweight=yearly_share], iterate(100) parameters(`liste_parametres' ) initial(`initial')

	
	estimates save "$dir_results/Effets de composition/estimate_deter_couts_add_`mode'_`type_TC'.ster", replace
	
	

	estimates use "$dir_results/Effets de composition/estimate_deter_couts_add_`mode'_`type_TC'.ster"

	
*******
	predict ln_terme_Adoll_predict
	generate terme_Adoll_predict=exp(ln_terme_Adoll_predict)
	twoway (scatter ln_terme_Adoll_predict ln_terme_Adoll)
	
	save "$dir_temp/blouk.dta", replace
	collapse (mean) terme_Adoll_predict, by(year)
	rename terme_Adoll_predict `terme_type_TC'_`mode'_np
	label var `terme_type_TC'_`mode'_np "Moyenne non-pondérée des predicts du 2e stage"
	
	
	
	
	* Enregistrer les effets fixes temps
	
	
	* matrice des coefficients estimés
	
	*	set trace on
	capture	matrix X= e(b)
	capture matrix V=e(V)
	matrix dir
	
	generate effet_fixe=.
	generate ecart_type=.
	 
	keep year effet_fixe ecart_type `terme_type_TC'_`mode'_np
	bys year : keep if _n==1
	sort year
	gen `terme_type_TC'_`mode'_74_np=`terme_type_TC'_`mode'_np[1]
	drop if year==1974
	quietly levelsof year, local (liste_year) clean
	
	
	display "local n = `nbr_iso_o' + `nbr_sect' - 1 + 1"
	local n = `nbr_iso_o' + `nbr_sect' - 1 + 1
	
		
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
	
	keep year effetfixe_A_`mode' ecart_type_A_`mode' ///
			terme_A_`mode'_np terme_A_`mode'_74_np

	sort year
	save "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'.dta", replace
	
	
	list
}
*	set trace off



/*

if "`type_TC'"== "obs_Hummels"  {
	
	*** On précise l'équation en log

	** log (tau ikt) = log (tauik) + beta. lag (weight/value) + log (taut) + residu
	** avec i : pays origine, k = sector, t = year
	use "$dir_temp/tmp_`mode'_`sitc'_`type_TC'.dta", clear
	rename `mode'_wgt wgt
	
	gen ln_`terme_type_TCm' = ln(`terme_type_TCm')
	
	display "Regression `type_TC' `mode'"
	
	encode sector, gen(sector_num)
	encode iso_o, gen(iso_o_num)
	
	egen ii = group(sector iso_o)
	
	
	*gen val_caf = prix_caf*wgt
	*rename val val_fob
	*collapse (sum) val_caf val_fob yearly_share wgt, by(ii year)
	*gen ln_`terme_type_TCm'=ln(val_caf/val_fob) 
	*gen ln_inv_unit_price=ln(wgt/val_fob)
	*xtset ii year
	*replace wgt = wgt/2.2  if year <=1988 (Hummels le fait. Mais pourquoi diable ???
	gen ln_inv_unit_price=ln(wgt/val)
	
	reghdfe ln_`terme_type_TCm'  i.year /*ln_inv_unit_price*/ /*[aweight=yearly_share]*/, /*nocons robust*/ absorb(ii)
	
	
	estimates save "$dir_results/Effets de composition/estimate_deter_couts_add_`mode'_`type_TC'.ster", replace
	
	* Enregistrer les effets fixes temps
	
	su year, meanonly	
	local nbr_year=r(max)
	quietly levelsof year, local (liste_year) clean
	display "`liste_year'"
	
	* matrice des coefficients estimés
	capture	matrix X= e(b)
	capture matrix V=e(V)
	
	generate effet_fixe=.
	generate ecart_type=.
	 
	keep year effet_fixe ecart_type
	bys year : keep if _n==1
	
	
	*local n 1
*	list
	matrix list X
	
	drop if year==1974
	
	
	foreach i of num 1(1)45 {
			*replace SITCRev2_3d_num= word("`liste_sitc'",`i') in `n'
			replace effet_fixe= X[1,`i'] in `i'
			replace ecart_type=V[`i',`i'] in `i'	
	*		local n=`n'+1
	}
	
	
	

*	list
	
	replace ecart_type=(ecart_type)^0.5
	
	drop if effet_fixe == .
	
	rename effet_fixe effetfixe_`type_TC'_`mode'
	rename ecart_type ecart_type_`type_TC'_`mode'
	label var effetfixe_`type_TC'_`mode' "pure_FE_`type_TC'_`mode'"
	label var ecart_type_`type_TC'_`mode' "ecart_type_`type_TC'_`mode'"
	
	keep year effetfixe_`type_TC'_`mode' ecart_type_`type_TC'_`mode'
	
	
	sort year
	list
	append using "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'.dta" 
	
	save "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'", replace
	
	append using "$dir_temp/start_year_`mode'_`sitc'_`type_TC'"
	sort year

	
	replace effetfixe_obs_Hummels_`mode'=0 if year==1974
	egen niv_1974=max(terme_obs_`mode'_mp)
	gen blif = niv_1974+ effetfixe_obs_Hummels_`mode'
	graph twoway (line  blif year) if year <=2004
	

}
*/
****************Fin des estimations
****************Début des contrefactuels

use "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'.dta", clear

if "`type_TC'"== "obs" |  "`type_TC'"== "I"  {
	generate `terme_type_TC'_`mode'_74  = `terme_type_TC'_`mode'_mp[1]
	replace effetfixe_`type_TC'_`mode' = 0 if effetfixe_`type_TC'_`mode' == .
	replace `terme_type_TC'_`mode'_mp = 100*exp(effetfixe_`type_TC'_`mode')	

	
	*replace ecart_type_`type_TC'_`mode' = 100*(`terme_type_TC'_`mode'_74*exp(ecart_type_`type_TC'_`mode')-1)/(`terme_type_TC'_`mode'_74-1)	
	
	* ATTENTION VERIFIER A CORRIGER 
	gen terme_95_`type_TC'_`mode'_mp=100*(`terme_type_TC'_`mode'_74*exp(effetfixe_`type_TC'_`mode'+1.96*ecart_type_`type_TC'_`mode')-1)/(`terme_type_TC'_`mode'_74-1)
	gen terme_05_`type_TC'_`mode'_mp=100*(`terme_type_TC'_`mode'_74*exp(effetfixe_`type_TC'_`mode'-1.96*ecart_type_`type_TC'_`mode')-1)/(`terme_type_TC'_`mode'_74-1)
	
	
	
	
	label var `terme_type_TC'_`mode'_mp "pure_TC_`type_TC'_`mode'"
	label var ecart_type_`type_TC'_`mode' "ecart_type_TC_`type_TC'_`mode'"
	
	egen blink = mean(`terme_type_TC'_`mode'_74_np)
	replace `terme_type_TC'_`mode'_74_np=blink
	drop blink
	
	replace `terme_type_TC'_`mode'_np=`terme_type_TC'_`mode'_74_np if year==1974
	replace `terme_type_TC'_`mode'_np=100*(`terme_type_TC'_`mode'_np-1)/(`terme_type_TC'_`mode'_74_np-1)
	label var `terme_type_TC'_`mode'_np "pure_TC_`type_TC'_`mode'_np"
}



if "`type_TC'"== "A" | "`type_TC'"== "prix_fob" {
	generate `terme_type_TC'_`mode'_74  = `terme_type_TC'_`mode'_mp[1]
	replace effetfixe_`type_TC'_`mode' = 0 if effetfixe_`type_TC'_`mode' == .
	replace `terme_type_TC'_`mode'_mp = 100*exp(effetfixe_`type_TC'_`mode')
*		replace ecart_type_`type_TC'_`mode' = 100*exp(ecart_type_`type_TC'_`mode')
	
	gen terme_95_`type_TC'_`mode'_mp=100*exp(effetfixe_`type_TC'_`mode'+1.96*ecart_type_`type_TC'_`mode')
	gen terme_05_`type_TC'_`mode'_mp=100*exp(effetfixe_`type_TC'_`mode'-1.96*ecart_type_`type_TC'_`mode')
	
	label var `terme_type_TC'_`mode'_mp "pure_TC_`type_TC'_`mode'"
	label var ecart_type_`type_TC'_`mode' "ecart_type_TC_`type_TC'_`mode'"
	
	egen blink = mean(`terme_type_TC'_`mode'_74_np)
	replace `terme_type_TC'_`mode'_74_np=blink
	drop blink
	
	replace `terme_type_TC'_`mode'_np=`terme_type_TC'_`mode'_74_np if year==1974
	replace `terme_type_TC'_`mode'_np=100*`terme_type_TC'_`mode'_np/`terme_type_TC'_`mode'_74_np
	
	label var `terme_type_TC'_`mode'_np "pure_TC_`type_TC'_`mode'_np"
	
}



save "$dir_results/Effets de composition/database_pureTC_`mode'_`sitc'_`type_TC'", replace

erase "$dir_temp/start_year_`mode'_`sitc'_`type_TC'.dta"
erase "$dir_temp/tmp_`mode'_`sitc'_`type_TC'.dta"

end


*/





**************Nouveau programme : agrégation entre les résultats



capture program drop aggreg
program aggreg
args secteur



* Ajouter 1974 et partir d'une valeur 100 en 1974
*Puis construire le fichier de résultat

use "$dir_results/Effets de composition/database_pureTC_air_`secteur'_I", clear

merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_air_`secteur'_obs"
drop _merge
merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_air_`secteur'_A"
drop _merge
merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_air_`secteur'_prix_fob"
drop _merge
merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_ves_`secteur'_I"
drop _merge
merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_ves_`secteur'_obs"
drop 	_merge
merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_ves_`secteur'_A"
drop _merge
merge 1:1 year using "$dir_results/Effets de composition/database_pureTC_ves_`secteur'_prix_fob"
drop _merge

rename *A* *Adoll*

generate terme_A_air_np = terme_Adoll_air_np /(prix_fob_air_np)*100
generate terme_A_air_mp = terme_Adoll_air_mp /(prix_fob_air_mp)*100
generate terme_A_ves_np = terme_Adoll_ves_np /(prix_fob_ves_np)*100
generate terme_A_ves_mp = terme_Adoll_ves_mp /(prix_fob_ves_mp)*100

generate terme_A_air_74=terme_Adoll_air_74/prix_fob_air_74
generate terme_A_ves_74=terme_Adoll_ves_74/prix_fob_ves_74
generate terme_A_ves_74_np=terme_Adoll_ves_74_np/prix_fob_ves_74_np
generate terme_A_air_74_np=terme_Adoll_air_74_np/prix_fob_air_74_np



export excel using "$dir_results/Effets de composition/table_extract_effetscomposition_`secteur'", replace firstrow(varlabels)
save "$dir_results/Effets de composition/database_pureTC_`secteur'", replace

end








***********LANCER LES PROGRAMMES********************

/*
eliminer_effets_composition ves all A


eliminer_effets_composition ves all obs
eliminer_effets_composition ves all I




eliminer_effets_composition air all obs
eliminer_effets_composition air all I
eliminer_effets_composition air all A
aggreg all



*/
/*En fait, aller voir "Calcul de l’effet de composition comme chez Hummels.do"
eliminer_effets_composition air all obs_Hummels
eliminer_effets_composition ves all obs_Hummels
*/


*local liste_secteurs all
/*
local liste_secteurs all primary manuf


foreach secteur of local  liste_secteurs {
	eliminer_effets_composition air `secteur'  prix_fob
	eliminer_effets_composition ves `secteur'  prix_fob
}

*/




local liste_secteurs all primary manuf

foreach secteur of local  liste_secteurs {
	eliminer_effets_composition air `secteur'  I
	eliminer_effets_composition air `secteur'  obs
	eliminer_effets_composition ves `secteur'  I
	eliminer_effets_composition ves `secteur'  obs
*	eliminer_effets_composition air `secteur'  A
*	eliminer_effets_composition ves `secteur'  A
}


*/
foreach secteur of local  liste_secteurs  {
	aggreg `secteur'
}





/*
foreach secteur of num /*0 1 2*/ 3 4 5 6 7 8 {
	eliminer_effets_composition air "`secteur'"  A
	eliminer_effets_composition air "`secteur'"  I
	eliminer_effets_composition air "`secteur'"  obs
	eliminer_effets_composition ves "`secteur'"  A
	eliminer_effets_composition ves "`secteur'"  I
	eliminer_effets_composition ves "`secteur'"  obs
}







foreach secteur of num /*0 1 2*/ 3 4 5 6 7 8 {
	aggreg `secteur'
}






