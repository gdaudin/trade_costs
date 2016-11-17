*************************************************
* Programme : Avoir qqs stats des sur la base de données
* 
*************************************************

version 14.1


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


***************************************************************
** Question endogénéité tau ik, t ik et prix fob

use $dir/data/hummels_tra, clear

gen sitc2_3d = substr(sitc2,1,3)

bys year sitc2_3d mode country: gen nb_par_sitc2_c_y_m = _N
sum nb_par_sitc2_c_y_m, det
gen val=air_val+ves_val
sum nb_par_sitc2_c_y_m [fw=val], det

bys year sitc2_3d mode country: keep if _n==1

sum nb_par_sitc2_c_y_m, det


** En moyenne, chaque observation a 182 co-obs dans la même catg sitc2 3d, pays, mode, année

** Autres éléments d'info:
** Par catg sitc2 à digits, pays, mode, année : 4 observations
** En moyenne, chaque dollar importé a 143 obs au sein d'une catg

*** Répond à la question de l'endogénéité entre tauik, til et prix fob ik

********************************************************************
*** Faire un programme qui calcule l'écart cif-fob observé / prédit*** 

capture program drop stats_des
program stats_des
	args year mode


use "$dir/results/estimTC.dta", clear

* Base qui synthétise les résultats des estimations sur 3 digits, en intégrant en plus les variables observées

keep if year==`year'
keep if mode=="`mode'"

gen prix_trsp = prix_caf/prix_fob -1
gen termeAetI = terme_A+terme_I-1
gen termeiceberg = terme_iceberg -1

local type prix_trsp termeAetI termeiceberg

foreach i of local type {
	gen ln`i' = log(`i')
}
	


local type prix_trsp termeAetI termeiceberg lnprix_trsp lntermeAetI lntermeiceberg
keep `type' year mode val

foreach x in `type' {

	quietly sum `x'  [fweight= val], det
	generate `x'_mp = r(mean)
	generate `x'_med = r(p50)
	generate `x'_et = r(sd)
	generate `x'_min = r(min)
	generate `x'_max = r(max)

	
	quietly sum `x', det
	generate `x'_uwm = r(mean)
	generate `x'_uwmed = r(p50)
	
}

keep if _n ==1


save "$dir/results/describe_db_`year'_`mode'", replace 


end

******************************
*** Lancer le programme

set more off
local mode ves air

foreach x in `mode' {

	*foreach z in `year' {
		foreach z of num 1974(1)2013 {
		
		
		stats_des `z' `x'
		
	
	}
}



** Compiler les résultats sur toutes les années

cd $dir/results/

* Première année 1974


set more off
local mode ves air


foreach x in `mode' {

	use describe_db_1974_`x', clear
	
	
	save compil_describedb_`x', replace
	erase describe_db_1974_`x'.dta
	
}

* Les années ultérieures


foreach x in `mode' {

	foreach z of num 1975(1)2013 {
	
		use compil_describedb_`x', clear
		append using describe_db_`z'_`x'
		
		save compil_describedb_`x', replace
		erase describe_db_`z'_`x'.dta
	
	}

}


** Exploiter la base de données

* Pour 3 digits
local mode ves air


foreach x in `mode' {
	use compil_describedb_`x', clear
	
	display "Mode de transport = `x'" 
	
		foreach  y of varlist prix_trsp* termeAetI* termeiceberg* lnprix_trsp* lntermeAetI* lntermeiceberg* {
		
		quietly sum `y'
		generate `y'_meanperiod = r(mean)
		
		
		}
	
	save compil_describedb_`x', replace
	
	
}


use compil_describedb_ves, clear

*edit mode *_mp_meanperiod *_med_meanperiod *uwm_meanperiod *uwmed_meanperiod in 1
edit mode prix_trsp_med_meanperiod termeAetI_med_meanperiod termeiceberg_med_meanperiod in 1

edit mode year lnprix_trsp_uwm lntermeiceberg_uwm  lntermeAetI_uwm

*use compil_describedb_ves, clear
*edit mode *_mp_meanperiod  *_med_meanperiod *uwm_meanperiod *uwmed_meanperiod in 1


**********************************************************************************
****  Sur les estimations en 4 digits, on est obligé de repartir de hummels_tra
**********************************************************************************

capture program drop stats_des_4digits
program stats_des_4digits
args year mode


use "$dir/data/hummels_tra.dta", clear

* Base de départ des estimations

keep if year==`year'
keep if mode=="`mode'"

rename sitc2 product
replace product = substr(product,1,4)



display "Nombre avant bas et haut " _N

bys product: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys product: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 

sum prix_trsp  [fweight=`mode'_val], det
generate prix_trsp_mp = r(mean)
generate prix_trsp_med = r(p50)
generate prix_trsp_et=r(sd)	
generate prix_trsp_min = r(min)
generate prix_trsp_max=r(max)	

keep year mode prix_trsp_*
keep if _n==1

save "$dir/results/describe_db_`year'_`mode'_4digits", replace 

end




*** Lancer le programme

set more off
local mode ves air

foreach x in `mode' {

	*foreach z in `year' {
		foreach z of num 1974(1)2013 {
		
		
		stats_des_4digits `z' `x'
		
	
	}
}

** *******************************************
** Compiler les résultats sur toutes les années

cd $dir/results/

* Première année 1974

set more off
local mode ves air


foreach x in `mode' {

	use describe_db_1974_`x'_4digits, clear
	
	
	save compil_describedb_`x'_4digits, replace
	erase describe_db_1974_`x'_4digits.dta
	
}

* Les années ultérieures
foreach x in `mode' {

	foreach z of num 1975(1)2013 {
	
		use compil_describedb_`x'_4digits, clear
		append using describe_db_`z'_`x'_4digits
		
		save compil_describedb_`x'_4digits, replace
		erase describe_db_`z'_`x'_4digits.dta
	
	}

}


** Exploiter la base de données

local mode ves air


foreach x in `mode' {
	use compil_describedb_`x'_4digits, clear
	
	display "Mode de transport = `x'" 
	
		foreach  y of varlist prix_trsp*  {
		
		quietly sum `y'
		generate `y'_meanperiod = r(mean)
		
		
		}
	
	save compil_describedb_`x'_4digits, replace
	
	
}


use compil_describedb_ves_4digits, clear
edit mode prix_trsp_mp_meanperiod prix_trsp_med_meanperiod  in 1

use compil_describedb_air_4digits, clear
edit mode prix_trsp_mp_meanperiod prix_trsp_med_meanperiod  in 1



