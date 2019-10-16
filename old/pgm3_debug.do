**** Septembre 2015

*** DEBUGER LES PRBS - A faire une fois pour toutes ***********************


clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


* ----------------------------------------------------------------------------* 
**** Bug 1. On se rend compte de pbs sur les années récentes
**** Liés à iso2 notamment
**** Il y a des duplicates en 2012 par exemple, alors qu'il ne devrait pas
* ----------------------------------------------------------------------------* 

** Step 1 : Faire une boucle pour identifier les pbs dans les blouk

** Avril 2°16: On reprend sur les nouvelles années de 2005 à 2013

*cd "C:\Echange\trade_costs\results"



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/results/New_years
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost\results\New_years
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost\results\New_years
}

cd $dir


capture log close
log using ident_duplicates, replace

local mode air ves

*forvalues z = 1974(1)2013 {
forvalues z = 2005(1)2013 {

foreach x in `mode'{


use blouk_`z'_sitc2_3_`x', clear

* s'assurer que les variables sont rangées dans le même ordre

#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr

dis "For year = "
dis year

dis "And for transport mode "
dis mode

dis "Nb of Duplicates by iso_o-year"
duplicates report 





dis "***-----------------------------***" 

save blouk_`z'_sitc2_3_`x', replace

}


}


************************************************
**** Revenir à la base de départ ****

/*
* sur le serveur
use "C:\Echange\trade_costs\database\hummels_tra.dta", clear

duplicates report

** pas de pb
** en fait, dans hummels_tra, sitc2 est en 5 digits

** Dans le programme 2, on le réduit à 3 (ou 4) digits
** On trouve alors des duplicates, ce sont exactement les mêmes flux qui avant étaient deux produits différents (en 5 digits)
** qui deviennent strictement identiques ensuite

** Donc ensuite on les retrouve dans le blouk
** Mais fondamentalement ce sont deux observations différentes, donc pas de raison de droper les duplicates

*/

***

/*
* ----------------------------------------------------------------------------* 
*** Bug 2. Pb sur fusion bases blouk et blouk_nlI sur 2010 et 2011, en vessel
* ----------------------------------------------------------------------------* 

cd $dir
set more off

* Pour 2010
***************************************
use blouk_nlI_2010_sitc2_3_ves, clear

tab iso2
count
** On a aussi le pb sur iso2 en 2010 sur blouk_nlI
** Traiter le pb sur iso2

#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr


sort iso_o product prix_fob
count

duplicates report iso_o-year 
duplicates tag iso_o-year, gen(tag)

drop if tag==1 & iso2==""

drop tag
duplicates report

save blouk_nlI_2010_sitc2_3_ves, replace


*** Faire le merge ensuite
use blouk_nlI_2010_sitc2_3_ves, clear


keep iso_o-mode prix* predict* converge* rc* terme* blink* Rp2* nbr* coef* ecart_type* aic* logL* 
sort iso_o-mode 

save temp, replace

use blouk_2010_sitc2_3_ves, clear


sort iso_o-mode 

merge 1:1 iso_o-mode using temp
count

keep if _merge==3
drop _merge

save blouk_2010_sitc2_3_ves, replace

erase temp.dta



** Pour 2011
****************************************
use blouk_nlI_2011_sitc2_3_ves, clear

tab iso2
count
** Le pb ne vient pas que de iso2 

duplicates report
duplicates tag, gen(tag)

br if tag==1
duplicates drop
br if tag==1
drop tag

** Vérifier aussi le pb sur iso2

#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr


sort iso_o product prix_fob
count

duplicates report iso_o-year 
duplicates tag iso_o-year, gen(tag)

drop if tag==1 & iso2==""

drop tag
duplicates report

save blouk_nlI_2011_sitc2_3_ves, replace


*** Faire le merge ensuite

use blouk_nlI_2011_sitc2_3_ves, clear

keep iso_o-mode prix* predict* converge* rc* terme* blink* Rp2* nbr* coef* ecart_type* aic* logL* 
sort iso_o-mode 

save temp, replace

use blouk_2011_sitc2_3_ves, clear
count

sort iso_o-mode 

merge 1:1 iso_o-mode using temp


keep if _merge==3
drop _merge

save blouk_2011_sitc2_3_ves, replace

erase temp.dta


*/

* ----------------------------------------------------------------------------* 
*** Bug 3. Au moment d'extraire les résultats, certaines stats s'ont pas été calculées à l'issue des blouk

clear
set more off

* Pour air, à partir de 2008, manque terme_nlI_med, idem pour terme I et A (sauf en 2003)
* Faire une boucle

* 3 digits

*forvalues z = 2007(-1)2004 {
forvalues z = 2005(1)2013 {


use blouk_`z'_sitc2_3_air, clear

sum terme_iceberg  [fweight= air_val], det 	
generate terme_nlI_med = r(p50)


sum terme_A  [fweight= air_val], det 	
generate terme_A_med = r(p50)

sum terme_I  [fweight= air_val], det 	
generate terme_I_med = r(p50)

save blouk_`z'_sitc2_3_air, replace

}

log close
