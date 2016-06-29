

*** GD LP Dec 23/12/2106


version 14.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/trade_cost
if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost
if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost


use $dir/results/estimTC_augmented.dta, clear


generate wgt=ves_wgt
replace wgt=air_wgt if mode=="air"

*drop air_wgt ves_wgt


bys iso_o year mode : egen TWim = total(wgt) 
label var TWim "Total weight imported by the US by that mode from that country"

* Essai sur observé
gen prix_trsp2 = prix_caf/prix_fob 


generate random=runiform()
*sort random
*keep if _n<=1000


generate expl_costs = Cost_to_export*Vk/prix_fob
generate expl_freight = Vk*dist/prix_fob
generate margin_proxy = expl_freight*TWim



generate ln_TC_ik =.
generate expl_ins=.

cd $dir
putexcel set Résultats_déterminants_des_coûts_`year'.xlsx, replace

foreach year of num 2005 {
	foreach controle in 0 1 dist {
	
		foreach mode in ves air  {
			
			
			replace expl_ins = ins_`mode'
			
			foreach term in prix_trsp2 terme_A terme_I terme_iceberg { 
			
				if "`term'"!="terme_A" replace ln_TC_ik = ln(`term'-1) 
				* A prendre en % ?
				if "`term'"=="terme_A" replace ln_TC_ik = ln(`term')
				* A prendre en % ?
	
			
				preserve
				drop if expl_ins==. | expl_freight==. | expl_costs==.
				keep if year==`year'
				keep if mode=="`mode'"
				assert _N>=10
				if `controle'==0 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight/*
					*/+{coef_margin=1}*margin_proxy +{beta_5=1}*TWim))
				if `controle'==1 nl (ln_TC_ik = log({coef_costs=1}*expl_costs+{coef_ins=1}*expl_ins+{coef_freight=1}*expl_freight/*
					*/+{coef_margin=1}*margin_proxy +{beta_5=1}*TWim/*
					*/+ {coef_EC=1}*Cost_to_export + {coef_Vk=1}*Vk + {coef_dist=1}*dist + {coef_prix_fob=1}/prix_fob))
				if "`controle'"=="dist" nl (ln_TC_ik = log({coef_dist=1}*dist))
			
				putexcel set Résultats_déterminants_des_coûts_`year'.xlsx, sheet(`controle'_`mode'_`term') modify
			
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
}


** Essais de régresion "brute"

/*
reg terme_A Cost_to_export ins_ves dist if mode == "ves", nocons


      Source |       SS           df       MS      Number of obs   =   106,642
-------------+----------------------------------   F(3, 106639)    =   3613.89
       Model |  72.0872823         3  24.0290941   Prob > F        =    0.0000
    Residual |  709.052368   106,639  .006649091   R-squared       =    0.0923
-------------+----------------------------------   Adj R-squared   =    0.0923
       Total |  781.139651   106,642  .007324878   Root MSE        =    .08154

--------------------------------------------------------------------------------
       terme_A |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
Cost_to_export |   9.64e-06   3.64e-07    26.51   0.000     8.93e-06    .0000104
       ins_ves |   .0029869   .0002613    11.43   0.000     .0024747    .0034991
          dist |   1.36e-06   4.86e-08    27.90   0.000     1.26e-06    1.45e-06
--------------------------------------------------------------------------------

* Ne change pas si fondamentalement si on ajoute Vk (signif) et prix_fob (signif) dans les régresseurs

reg terme_A Cost_to_export ins_ves dist Vk prix_fob if mode == "ves", nocons

      Source |       SS           df       MS      Number of obs   =   104,375
-------------+----------------------------------   F(5, 104370)    =   2146.54
       Model |  72.0407239         5  14.4081448   Prob > F        =    0.0000
    Residual |  700.558269   104,370  .006712257   R-squared       =    0.0932
-------------+----------------------------------   Adj R-squared   =    0.0932
       Total |  772.598993   104,375  .007402146   Root MSE        =    .08193

--------------------------------------------------------------------------------
       terme_A |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
Cost_to_export |   .0000112   3.85e-07    29.01   0.000     .0000104    .0000119
       ins_ves |   .0050018   .0003127    16.00   0.000      .004389    .0056146
          dist |   1.63e-06   5.23e-08    31.06   0.000     1.52e-06    1.73e-06
            Vk |  -.0208424   .0013039   -15.98   0.000     -.023398   -.0182868
      prix_fob |  -1.42e-06   4.39e-07    -3.22   0.001    -2.28e-06   -5.55e-07
--------------------------------------------------------------------------------

** attention il manque le temps


. reg terme_A Cost_to_export ins_air dist Vk prix_fob if mode == "air" & year == 2010, nocons

      Source |       SS           df       MS      Number of obs   =    11,096
-------------+----------------------------------   F(5, 11091)     =    465.36
       Model |  25.3460363         5  5.06920725   Prob > F        =    0.0000
    Residual |  120.815472    11,091  .010893109   R-squared       =    0.1734
-------------+----------------------------------   Adj R-squared   =    0.1730
       Total |  146.161508    11,096   .01317245   Root MSE        =    .10437

--------------------------------------------------------------------------------
       terme_A |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
Cost_to_export |    .000017   1.41e-06    11.98   0.000     .0000142    .0000197
       ins_air |   .0031883   .0014576     2.19   0.029      .000331    .0060455
          dist |   4.64e-06   2.08e-07    22.27   0.000     4.23e-06    5.05e-06
            Vk |  -.0439961     .00513    -8.58   0.000    -.0540519   -.0339404
      prix_fob |  -5.56e-06   7.28e-07    -7.63   0.000    -6.98e-06   -4.13e-06
--------------------------------------------------------------------------------

Pour comparaison


. reg terme_I Cost_to_export ins_air dist Vk prix_fob if mode == "air" & year == 2010, nocons

      Source |       SS           df       MS      Number of obs   =    11,096
-------------+----------------------------------   F(5, 11091)     =  30676.38
       Model |  11737.3886         5  2347.47772   Prob > F        =    0.0000
    Residual |  848.727087    11,091  .076523946   R-squared       =    0.9326
-------------+----------------------------------   Adj R-squared   =    0.9325
       Total |  12586.1157    11,096  1.13429305   Root MSE        =    .27663

--------------------------------------------------------------------------------
       terme_I |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
---------------+----------------------------------------------------------------
Cost_to_export |    .000287   3.75e-06    76.54   0.000     .0002796    .0002943
       ins_air |   .0871348   .0038635    22.55   0.000     .0795617    .0947078
          dist |   .0000514   5.52e-07    93.18   0.000     .0000504    .0000525
            Vk |     .40441   .0135969    29.74   0.000     .3777576    .4310625
      prix_fob |  -9.86e-06   1.93e-06    -5.11   0.000    -.0000136   -6.08e-06
--------------------------------------------------------------------------------

*/

