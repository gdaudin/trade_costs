

*************************************************
* Programme : Lancer les estimations 

*	Estimer les additive & iceberg trade costs
* 	Using Hummels trade data (version soumission)
*
*	Mars 2020
* 
*************************************************

*version 12



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_pgms $dir/trade_costs_git
}

** Fixe Lise bureau
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}

/* Vieux portable Lise
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}
*/

/* Nouveau portable Lise */

if "`c(hostname)'" =="MSOP112C" {
  
	global dir C:\Lise\trade_costs
	global dir_pgms C:\Users\Ipatureau\Documents\trade_costs
	
}

*******************************************************


set more off
local mode ves air
*local year 1974 

cd "$dir_pgms"
do Estim_value_TC.do


***** LANCER LES ESTIMATIONS **************************
*******************************************************


*** 3 digits, all years ***

***** VESSEL, puis AIR  *******************************
**** toutes les années récentes (2005-2013)
*******************************************************


foreach x in `mode' {

	foreach z in 2013 {
	
		*** SOUMISSION: hummels_tra.dta ou db_samesample_sitc2_3
		
		capture log close
		log using hummels_3digits_complet_`z'_`x', replace
		
		prep_reg db_samesample_sitc2_3 `z' sitc2 3 `x'
		
		*erase "$dir/results/blouk_nlA_`year'_`class'_`preci'_`mode'.dta"
		*erase "$dir/results/blouk_nlI_`year'_`class'_`preci'_`mode'.dta"
		
		log close
		
		
		matrix Esperance_`x'_`z'=X
		matrix Var_Covariance_`x'_`z'=ET	
	
	
		drawnorm $liste_parametres, n(10000) means(Esperance_`x'_`z') cov(Var_Covariance_`x'_`y') clear
		
		save temp.dta, replace
		clear
		clear matrix
		set maxvar = wordcount("$liste_iso_o")*wordcount("$liste_prod")+1000
		use temp.dat
		** .dta? pourquoi + 1000?
		* Où sont stockées ces matrices?
		
		local prod_num=0
		**La référence est num=1
		foreach prod of global liste_prod {
			local prod_num=`prod_num'+1	
			local iso_num=0
			foreach iso of global liste_iso_o { 
				local iso_num=`iso_num'+1
				if `prod_num' !=1 {
					generate termeA_`prod'_`iso' = exp(lnfeA_prod_`prod_num')+exp(lnfeA_iso_o_`iso_num')
					generate termeI_`prod'_`iso' = (exp(lnfem1I_prod_`prod_num')+1)*(exp(lnfem1I_iso_o_`iso_num')+1)
					
	
				}
				
				if `prod_num' ==1 {
					generate termeA_`prod'_`iso' = exp(lnfeA_iso_o_`iso_num')
					generate termeI_`prod'_`iso' = exp(lnfem1I_iso_o_`iso_num')+1
				}
				
				
			}
		}
	
		blif
	
	
	
	
	}
	

		
	
}

*** cela me semble bon, 

* 1ere chose à faire: reste ensuite qu'à ce stade termeA = tik, il faut diviser par prix fob
*** Dans Hummels tra, une observation par secteur 5d/pays origine / année, c'est ça?
*** Donc, partir de Hummels tra, faire un prix fob agrégé niveau 3d (en pondérant par la valeur des flux), garder une base avec année / secteur 3d / mode/ prix fob 3d

*** 2e chose: faire le merge avec cette base; car dans temp.dta, on n'a pas les variables pays : secteur; mais juste des 1, 2, etc. Donc il faut recroiser... 

*** Est-ce que je vois les choses de manière juste?

