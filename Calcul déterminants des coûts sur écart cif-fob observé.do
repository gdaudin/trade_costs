
*** GD LP Dec 29/06/2106


version 14.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767

** Dans ce programme, on estime les déterminants des coûts de transport version "structurelle" **

if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/2013 -- trade_cost -- dropbox
if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost
if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost



use $dir/results/estimTC_augmented.dta, clear


generate wgt=ves_wgt
replace wgt=air_wgt if mode=="air"

*drop air_wgt ves_wgt


bys iso_o year mode : egen TWim = total(wgt) 
label var TWim "Total weight imported by the US by that mode from that country"


generate random=runiform()
*sort random
*keep if _n<=1000

* repartir sur coûts de transport observés
gen prix_trsp2 = prix_caf/prix_fob
gen ln_ratio_minus1 = ln(prix_trsp2 -1)

label variable prix_trsp2 "prix_caf/prix_fob"


* Variables déterminants des coûts

* arbitrage sur Vk, avec : permet d'avoir un coefficient sur insurance positif, mais corrélation terme_I terme_struct_I <0 + des termes pensés additifs autorisés multiplicatifs sirtent NS en multiplicatif
* sans : l'inverse


* Vk "nul part"
 ** couts a dditifs
generate expl_costs_add = Cost_to_export/prix_fob
generate expl_ins_add = .
generate expl_freight_add  = dist/prix_fob
generate margin_proxy_add = expl_freight_add*TWim


** couts multiplicatifs - on autorise aussi les composantes freight et handling costs
** à avoir une composante multiplicative


generate expl_ins_mult   =.
generate expl_costs_mult = Cost_to_export
generate expl_freight_mult  = dist
generate margin_proxy_mult = dist*TWim




/*
** Vk "partout"
** couts a dditifs
generate expl_costs_add = Cost_to_export*Vk/prix_fob
generate expl_ins_add = .
generate expl_freight_add  = Vk*dist/prix_fob
generate margin_proxy_add = expl_freight_add*TWim


** couts multiplicatifs - on autorise aussi les composantes freight et handling costs
** à avoir une composante multiplicative


generate expl_ins_mult=.
generate expl_costs_mult = Cost_to_export*Vk
generate expl_freight_mult  = Vk*dist
generate margin_proxy_mult = Vk*dist*TWim
*/



/*
** Vk "dans add pas dans mult"
** couts a dditifs
generate expl_costs_add = Cost_to_export*Vk/prix_fob
generate expl_ins_add = .
generate expl_freight_add  = Vk*dist/prix_fob

generate margin_proxy_add = expl_freight_add*TWim


** couts multiplicatifs - on autorise aussi les composantes freight et handling costs
** à avoir une composante multiplicative


generate expl_ins_mult=.
generate expl_costs_mult = Cost_to_export
generate expl_freight_mult  = dist

generate margin_proxy_mult = dist*TWim
*/



cd $dir
putexcel set Résultats_déterminants_des_coûts_sur_observé.xlsx, replace


*foreach year of num 2005/2013 {

foreach year of num 2005 {	

foreach controle in 0 1 {

foreach mode in ves air  {

preserve

keep if mode =="`mode'"
keep if year == `year'

bys product: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys product: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 

replace expl_ins_mult = ins_`mode'
replace expl_ins_add = ins_`mode'/prix_fob


drop if expl_ins_mult==. | expl_freight_add==. | expl_costs_add==.			
assert _N>=10


if `controle' == 0 nl (ln_ratio_minus1= log({coef_costs_add=1}*expl_costs_add +{coef_freight_add=1}*expl_freight_add /*
			*/+ {coef_ins_add=1}*expl_ins_add + {coef_margin_add=1}*margin_proxy_add +{coef_margin_mult=1}*margin_proxy_mult + {coef_ins_mult=1}*expl_ins_mult /*
			*/+ {coef_costs_mult=1}*expl_costs_mult +{coef_freight_mult=1}*expl_freight_mult ))  
	

if `controle' == 1 nl (ln_ratio_minus1= log({coef_costs_add=1}*expl_costs_add +{coef_freight_add=1}*expl_freight_add /*
			*/+ {coef_ins_add=1}*expl_ins_add  + {coef_ins_mult=1}*expl_ins_mult /*
			*/+ {coef_costs_mult=1}*expl_costs_mult +{coef_freight_mult=1}*expl_freight_mult ))  

			
putexcel set Résultats_déterminants_des_coûts_sur_observe.xlsx, sheet(`year'_`mode'_`controle') modify

if `controle' == 1 putexcel A1="Régression sans la variable de marge"
if `controle' == 0 putexcel A1="Régression avec la variable de marge"

				putexcel C2="Coef."
				matrix b = e(b)'
				putexcel A3=matrix(b), rownames nformat(scientific_d2)
				mata: ecart_types_mata=sqrt(diagonal(st_matrix("e(V)")))
				*matrix ecart_types=(vecdiag(e(V)*e(V)))'
				mata: st_matrix("ecart_types",ecart_types_mata)
				putexcel D2="écart-type"
				putexcel D3=matrix(ecart_types),  nformat(scientific_d2)
				
					
				putexcel E2="R2 adjusted"
				local R2_a = e(r2_a)
				putexcel E3=`e(r2_a)', nformat(number_d2) 
				
			
predict blink_nl

gen predict_nl = exp(blink_nl)+1 

* Faire la décomposition additif / multiplicatif

* Sauvegarder les variables

foreach var in expl_costs_add expl_ins_add expl_freight_add margin_proxy_add expl_costs_mult expl_ins_mult expl_freight_mult margin_proxy_mult {
	gen old_`var' = `var' 
	}
	
* Reconstruire le terme additif (mettre tous les termes en multiplicatif à 0)

foreach var in expl_ins_mult margin_proxy_mult expl_costs_mult expl_freight_mult {
	replace `var' = 0
}

predict terme_A_struct
replace terme_A_struct = exp(terme_A_struct)

foreach var in expl_ins_mult margin_proxy_mult expl_costs_mult expl_freight_mult {
	replace `var' = old_`var'
	*erase old_`var'
}

* Reconstruire le terme multiplicatif (mettre tous les termes en additif à 0)

foreach var in expl_costs_add expl_ins_add expl_freight_add margin_proxy_add  {
	replace `var' = 0
}

predict terme_I_struct
replace terme_I_struct = exp(terme_I_struct)+1

foreach var in expl_costs_add expl_ins_add expl_freight_add margin_proxy_add {
	replace `var' = old_`var'
	*erase old_`var'
}

putexcel A12="Corrélation entre terme_A estimé première étape et terme_A structurel"

pwcorr (terme_A terme_A_struct)
local correlation = r(rho)

putexcel A13=`correlation', nformat(number_d2) 


putexcel A14="Corrélation entre terme_I estimé première étape et terme_I structurel"

pwcorr (terme_I terme_I_struct)
local correlation = r(rho)

putexcel A15=`correlation', nformat(number_d2)

restore



}
}
}



/* pour garder une trace du resultat, en 2005

Vk nul part 


      Source |      SS            df       MS
-------------+----------------------------------    Number of obs =      9,909
       Model |  75639.263          7   10805.609    R-squared     =     0.8963
    Residual |  8754.5942       9902  .884123834    Adj R-squared =     0.8962
-------------+----------------------------------    Root MSE      =   .9402786
       Total |  84393.857       9909  8.51688938    Res. dev.     =   26893.15

-----------------------------------------------------------------------------------
  ln_ratio_minus1 |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
  /coef_costs_add |   .0003297   .0000296    11.13   0.000     .0002716    .0003877
/coef_freight_add |   .0001076   4.63e-06    23.23   0.000     .0000985    .0001167
 /coef_margin_add |  -7.15e-13   9.66e-14    -7.40   0.000    -9.04e-13   -5.25e-13
/coef_margin_mult |   1.47e-14   6.85e-15     2.15   0.032     1.30e-15    2.81e-14
        /coef_ins |  -.0025384   .0001393   -18.22   0.000    -.0028115   -.0022653
 /coef_costs_mult |   .0000174   8.33e-07    20.84   0.000     .0000157     .000019
/coef_freight_m~t |   1.73e-06   1.16e-07    14.93   0.000     1.50e-06    1.96e-06
-----------------------------------------------------------------------------------


. pwcorr (terme_A terme_struct_A)

             |  terme_A term~t_A
-------------+------------------
     terme_A |   1.0000 
terme_stru~A |   0.5465   1.0000 

. 
. pwcorr (terme_I terme_struct_I)

             |  terme_I term~t_I
-------------+------------------
     terme_I |   1.0000 
terme_stru~I |   0.0574   1.0000 


** Vk partout

** couts a dditifs, avec Vk
generate expl_costs_add = Cost_to_export*Vk/prix_fob
generate expl_freight_add  = Vk*dist/prix_fob
generate margin_proxy_add = expl_freight*TWim


** couts multiplicatifs - on autorise aussi les composantes freight et handling costs
** à avoir une composante multiplicative


generate expl_ins=.
generate expl_costs_mult = Cost_to_export*Vk
generate expl_freight_mult  = Vk*dist
generate margin_proxy_mult = Vk*dist*TWim


      Source |      SS            df       MS
-------------+----------------------------------    Number of obs =      9,611
       Model |  68681.314          7  9811.61627    R-squared     =     0.8810
    Residual |  9277.4595       9604  .965999531    Adj R-squared =     0.8809
-------------+----------------------------------    Root MSE      =   .9828528
       Total |  77958.773       9611  8.11141124    Res. dev.     =   26935.37

-----------------------------------------------------------------------------------
  ln_ratio_minus1 |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
  /coef_costs_add |   .0012724   .0001088    11.69   0.000     .0010591    .0014858
/coef_freight_add |   .0003686   .0000164    22.51   0.000     .0003365    .0004007
 /coef_margin_add |   4.32e-13   4.77e-13     0.91   0.365    -5.02e-13    1.37e-12
/coef_margin_mult |  -8.38e-15   1.51e-14    -0.55   0.579    -3.80e-14    2.13e-14
        /coef_ins |   .0263963   .0007883    33.48   0.000      .024851    .0279416
 /coef_costs_mult |  -3.38e-06   1.86e-06    -1.82   0.069    -7.02e-06    2.60e-07
/coef_freight_m~t |  -1.16e-06   2.90e-07    -4.00   0.000    -1.73e-06   -5.92e-07
-----------------------------------------------------------------------------------


             |  terme_A term~t_A
-------------+------------------
     terme_A |   1.0000 
terme_stru~A |   0.6102   1.0000 

. 
. pwcorr (terme_I terme_struct_I)

             |  terme_I term~t_I
-------------+------------------
     terme_I |   1.0000 
terme_stru~I |  -0.2023   1.0000 

** Vk dans additif, pas dans multiplicatif


** Vk "dans add pas dans mult"
** couts a dditifs
generate expl_costs_add = Cost_to_export*Vk/prix_fob
generate expl_freight_add  = Vk*dist/prix_fob
generate margin_proxy_add = expl_freight*TWim


** couts multiplicatifs - on autorise aussi les composantes freight et handling costs
** à avoir une composante multiplicative


generate expl_ins=.
generate expl_costs_mult = Cost_to_export
generate expl_freight_mult  = dist
generate margin_proxy_mult = dist*TWim


   Source |      SS            df       MS
-------------+----------------------------------    Number of obs =      9,611
       Model |  69930.514          7  9990.07339    R-squared     =     0.8970
    Residual |  8028.2596       9604  .835928742    Adj R-squared =     0.8969
-------------+----------------------------------    Root MSE      =   .9142914
       Total |  77958.773       9611  8.11141124    Res. dev.     =   25545.43

-----------------------------------------------------------------------------------
  ln_ratio_minus1 |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
  /coef_costs_add |   .0010436   .0000986    10.59   0.000     .0008503    .0012368
/coef_freight_add |   .0002895   .0000147    19.69   0.000     .0002606    .0003183
 /coef_margin_add |  -1.28e-12   3.79e-13    -3.39   0.001    -2.03e-12   -5.41e-13
/coef_margin_mult |   2.34e-14   7.98e-15     2.93   0.003     7.77e-15    3.91e-14
        /coef_ins |   -.002542   .0003605    -7.05   0.000    -.0032488   -.0018353
 /coef_costs_mult |   .0000195   1.04e-06    18.79   0.000     .0000175    .0000216
/coef_freight_m~t |   1.98e-06   1.41e-07    14.01   0.000     1.70e-06    2.25e-06
-----------------------------------------------------------------------------------


. pwcorr (terme_A terme_struct_A)

             |  terme_A term~t_A
-------------+------------------
     terme_A |   1.0000 
terme_stru~A |   0.6122   1.0000 

. 
. pwcorr (terme_I terme_struct_I)

             |  terme_I term~t_I
-------------+------------------
     terme_I |   1.0000 
terme_stru~I |   0.0412   1.0000 


/* Juste pour garder une trace d'une méthode alternative de décomposition terme A/ terme I


matrix list e(b)
matrix X = e(b)



replace coef_costs= X[1,1]
replace coef_ins   = X[1,2]
replace coef_freight = X[1,3]

gen terme_struct_I = .
gen terme_struct_A = .


replace terme_struct_I = coef_ins* expl_ins +1
replace terme_struct_A = coef_costs*expl_costs + coef_freight*expl_freight

generate blink_nl_false = log(terme_struct_I -1 + terme_struct_A)
* on verifie que donne la même chose que blink_nl

sum terme_struct_I terme_struct_A, det

* on obtient la même chose que plus haut

*/

** Reprendre les estimations en boucle - A faire quand stabilisé sur 2005

/*
putexcel set Résultats_déterminants_couts_observes_`year'.xlsx, replace

		
foreach year of num 2005/2013 {
	foreach controle in 0 1 {
	
		foreach mode in ves air  {
			
			
				replace expl_ins = ins_`mode'
			
				preserve
				drop if expl_ins==. | expl_freight==. | expl_costs==.
				keep if year==`year'
				keep if mode=="`mode'"
				
				assert _N>=10
				
				* sans la marge
				if `controle'==0 nl (ln_ratio_minus1 = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight))
				/*
					+{coef_margin=1}*margin_proxy +{beta_5=1}*TWim)) */
					
				if `controle'==1 nl (ln_ratio_minus1  = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight /*
					*/+ {coef_EC=1}*Cost_to_export + {coef_Vk=1}*Vk + {coef_dist=1}*dist + {coef_prix_fob=1}/prix_fob))
				/*
					+{coef_margin=1}*margin_proxy +{beta_5=1}*TWim */
				*if "`controle'"=="dist" nl (ln_ratio_minus1= log({coef_dist=1}*dist))
			
				putexcel set Résultats_déterminants_couts_observes_`year'.xlsx, sheet(`controle'_`mode'_`term') modify
			
				putexcel C1="Coef."
				matrix b = e(b)'
				putexcel A2=matrix(b), rownames nformat(scientific_d2)
				mata: ecart_types_mata=sqrt(diagonal(st_matrix("e(V)")))
				*matrix ecart_types=(vecdiag(e(V)*e(V)))'
				mata: st_matrix("ecart_types",ecart_types_mata)
				putexcel D1="écart-type"
				putexcel D2=matrix(ecart_types),  nformat(scientific_d2)
				putexcel E1="R2 adjusted"
				local R2_a = e(r2_a)
				putexcel E2=`e(r2_a)', nformat(number_d2) 
				restore
			
		}
	}
}

*/

** essai sur 2005, air



** reprendre la dimension de chaque variable explicative
** c'est cohérent sur terme I struct
** pb sur terme A struct


*preserve
