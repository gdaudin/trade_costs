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


cd "C:\Echange\trade_costs\results"


capture log close
log using ident_duplicates, replace

local mode air ves

forvalues z = 1974(1)2013 {

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
duplicates report iso_o-year

*duplicates tag iso_o-year, gen(tag)

*br if tag==1

dis "détecter les pbs sur iso2"
dis "Nb of Duplicates by iso_o-year + iso2 "
duplicates report iso_o-year iso2

dis "détecter les pbs sur iso_d "
dis "Nb of Duplicates by iso_o, product-year"
duplicates report iso_o product-year

dis "Nb of Duplicates "
duplicates report 

dis "***-----------------------------***" 

}


}



log close


************************************************
**** Revenir à la base de départ ****

* sur le serveur
use "C:\Echange\trade_costs\database\hummels_tra.dta", clear

duplicates report

** pas de pb
** ouf

************************************************

*** Eliminer le pb sur les blouk

** Quand duplicates lié à pb sur iso2
** vessel, 2008, 2010, 2011, 2012
** air, 2008, 2010, 2011, 2012


cd "C:\Echange\trade_costs\results"

set more off

** pour vessel
local year 2008 2010 2011 2012
local mode air ves

foreach z in `year' {
foreach x in `mode' {


local z 2008
local x air
use blouk_`z'_sitc2_3_`x', clear


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

save blouk_`z'_sitc2_3_`x', replace

}
}



** Pour pbs sur iso_d
** air en 2008 et 2011


set more off

cd "C:\Echange\trade_costs\results"

local year 2008 2011

foreach x in `year' {

use blouk_`x'_sitc2_3_air, clear


#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr



sort iso_o product prix_fob
count

duplicates report iso_o product-year 
duplicates tag iso_o product-year, gen(tag)

drop if tag==1 & iso_d==""

drop tag
duplicates report

save blouk_`x'_sitc2_3_air, replace

}



***************************
** Pour les autres années
** Certaines observations sont strictement identiques

** air
local year 1983 1988 1992 1993 1995 2002 2004 2005 2006 2007 2008 2009 2013 2011


foreach z in `year' {
use blouk_`z'_sitc2_3_air, clear


#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr



sort iso_o product prix_fob
count

duplicates report 
duplicates drop


save blouk_`z'_sitc2_3_air, replace


}



** vessel
local year 1986 1988 1997 2000 2002 2003 2011


foreach z in `year' {
use blouk_`z'_sitc2_3_ves, clear


#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr



sort iso_o product prix_fob
count

duplicates report 
duplicates drop


save blouk_`z'_sitc2_3_ves, replace


}

*** Check
*** On en profite pour remplacer du nb d'obs, qui n'a pas été corrigé dans le blouk initia

set more off

cd "C:\Echange\trade_costs\results"

capture log close

log using ident_duplicates_check, replace

dis "Vérification des pbs de duplicates après nettoyage des bases"

local mode air ves

forvalues z = 1974(1)2013 {

foreach x in `mode'{

use blouk_`z'_sitc2_3_`x', clear

drop nbr_obs
gen nbr_obs = _N


* s'assurer que les variables sont rangées dans le même ordre

#delimit ;
order iso_o iso_d product prix_fob prix_caf prix_trsp2 prix_trsp lprix_trsp2 country con_qy1 con_qy2 con_val ves_val air_val con_cha ves_cha air_cha
	air_wgt ves_wgt con_cif_yr duty rec year name iso2 mode;

#delimit cr

dis "For year = "
dis year

dis "And for transport mode "
dis mode

dis "Recherche de duplicates lies à iso2"
duplicates report iso_o-year


dis "Recherche de duplicates lies à iso_d"
duplicates report iso_o product-name

dis "Recherche de duplicates purs"
duplicates report


save blouk_`z'_sitc2_3_`x', replace

}
}

log close


* ----------------------------------------------------------------------------* 
*** Bug 2. Pb sur fusion bases blouk et blouk_nlI sur 2010 et 2011, en vessel
* ----------------------------------------------------------------------------* 

cd "C:\Echange\trade_costs\results"
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



* ----------------------------------------------------------------------------* 
*** Bug 3. Au moment d'extraire les résultats, certaines stats s'ont pas été calculées à l'issue des blouk

clear
set more off

* Pour air, à partir de 2008, manque terme_nlI_med, idem pour terme I et A (sauf en 2003)
* Faire une boucle

*forvalues z = 2007(-1)2004 {
forvalues z = 2002(-1)1974 {


use blouk_`z'_sitc2_3_air, clear

sum terme_iceberg  [fweight= air_val], det 	
generate terme_nlI_med = r(p50)


sum terme_A  [fweight= air_val], det 	
generate terme_A_med = r(p50)

sum terme_I  [fweight= air_val], det 	
generate terme_I_med = r(p50)

save blouk_`z'_sitc2_3_air, replace

}
