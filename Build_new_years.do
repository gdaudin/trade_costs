
***** Programme Pour intégrer les années qui ne sont pas dans Hummels
***** Réponse au référé 1



*version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
	global dir_data ~/Documents/Recherche/2013 -- Trade Costs -- local/data
	global dir_external_data ~/Documents/Recherche/2013 -- Trade Costs -- local/external_data
	global dir_temp ~/Downloads/temp_stata
}



** Juillet 2020: Lise, je mets tout sur mon OneDrive

/* Fixe Lise A FAIRE */
if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost_nonpartage\database
	global dir_data \\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\database
	global dir_external_data ????
	global dir_temp ????
}


/* Dell portable Lise Lise */
if "`c(hostname)'" =="LAB0271A" {
	global dir "C:\Users\Ipatureau\Dropbox\trade_cost\JEGeo"
	global dir_data "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data"
	global dir_external_data "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data"
	/* To update for two new files within "data"
	- New_years file with original Census data + countrycodes_use.txt +
	- Hummels_JEP_data that includes hummels_tra + country_codes_v2.dta*/ 
	global dir_temp "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
}



capture progam drop From_Zip_to_Stata
program From_Zip_to_Stata
args year


****************Step 1 Passer les donées de .txt dans la base

global base IMDBR0512 IMDBR0612 IMDBR0712 IMDBR0812 IMDBR0912 IMDBR1012 IMDBR1112 IMDBR1212 IMDBR1312

local base = "IMDB"+substr("`year'",3,2)+"12"
if `year' >= 2002 & `year' <= 2012 local base = "IMDBR"+substr("`year'",3,2)+"12"
if `year' == 2000 | `year' == 2001 local base = "IMHDBR"+"`year'"


clear
cd "$dir_external_data/New_years"
capture mkdir folder_`year'
cd "$dir_external_data/New_years/folder_`year'"
unzipfile ../`base'.zip, replace
local file `base'
if `year'== 2012 | `year' <= 2001 | `year'>=2014  local file IMP_DETL

if `year' >=2002  infix str10	commodity 1-10 str6	cty_code 11-14 str2	cty_subco 15-16 str2	dist_entry 	17-18 str2	dist_unlad 	19-20 str2	rate_prov	21-22 int	year 23-26 int	month 	27-28 /*
*/ str15 cards_mo 29-43 double	con_qy1_mo 	44-58 double con_qy2_mo 59-73 double con_val_mo 74-88 double	dut_val_mo 	89-103 double	cal_dut_mo 	104-118 double	con_cha_mo 	119-133 /*
*/double con_cif_mo 134-148 double	gen_qy1_mo 	149-163 double	gen_qy2_mo 164-178 double gen_val_mo 179-193 double	gen_cha_mo 	194-208 double	gen_cif_mo 	209-223 double	air_val_mo 	224-238 /*
*/double air_wgt_mo 239-253 double	air_cha_mo 	254-268 double	ves_val_mo 	269-283 double	ves_wgt_mo 	284-298 double	ves_cha_mo 	299-313 double	cnt_val_mo 	314-328 double	cnt_wgt_mo 	329-343 /*
*/ double cnt_cha_mo 344-358 double	cards_yr 359-373 double	con_qy1_yr 	374-388 double	con_qy2_yr 	389-403 double	con_val_yr 	404-418 double	dut_val_yr 	419-433 double	cal_dut_yr 	434-448 /*
*/ double con_cha_yr 449-463 double con_cif_yr 464-478 double	gen_qy1_yr 	479-493 double	gen_qy2_yr 	494-508 double	gen_val_yr 	509-523 double	gen_cha_yr 	524-538 double	gen_cif_yr 	539-553 /*
*/ double	air_val_yr 	554-568 double	air_wgt_yr 	569-583 double	air_cha_yr 	584-598 double	ves_val_yr 	599-613 double	ves_wgt_yr 	614-628 double	ves_cha_yr 	629-643 double	cnt_val_yr 	644-658 /*
*/ double	cnt_wgt_yr 	659-673 double	cnt_cha_yr 	674-688  using `file'.txt

if `year' <= 2001 import dbase `file'.dbf
rename *,lower

compress

capture erase `file'.txt

cd "$dir_external_data/New_years"
capture noisily rmdir folder_`year'
capture noisily rename stat_month month
capture noisily destring(month), replace                 

**Vérification pour les mois puis nettoyage
* tab month
assert month==12
drop *_mo
drop month
**

capture noisily generate gen_cif_yr=gen_val_yr+gen_cha_yr

if `year' >= 2001 assert gen_cif_yr==gen_val_yr+gen_cha_yr
*Cela montre que les "charges", ce sont les coûts de transport
*Ne marche pas pour 1998 ni 1999


/*Choses fausses
assert gen_cha_yr==ves_cha_yr+air_cha_yr+cnt_cha_yr
assert gen_cha_yr==ves_cha_yr+air_cha_yr
assert dut_val_yr == 0 | dut_val_yr==con_val_yr
assert abs(gen_cha_yr-ves_cha_yr-air_cha_yr)<= 0.5*gen_cha_yr
assert abs(gen_cha_yr-ves_cha_yr-air_cha_yr)<= 0.01*gen_cha_yr
C’est normal, parce que (15 de https://www.census.gov/foreign-trade/guide/sec2.html) 
The data for "all methods of transportation" include exports and general imports by vessel, air, truck, rail, air mail, parcel post, and other methods of transportation.
The data for vessel and air exports and general imports represent waterborne and airborne shipments only (merchandise actually leaving or arriving in the United States aboard a vessel or an aircraft).
*/



* renommer les variables
/*
drop  cards_mo con_qy1_mo con_qy2_mo con_val_mo dut_val_mo cal_dut_mo con_cha_mo con_cif_mo gen_* 
drop air_val_mo air_wgt_mo air_cha_mo ves_val_mo ves_wgt_mo ves_cha_mo cnt_val_mo cnt_wgt_mo cnt_cha_mo
drop cty_subco dist_unlad rate_prov month cal_dut_yr cards_yr
*/

rename cty_code country 
rename commodity hs
rename cal_dut_yr duty 
label var hs "Anciennement commodity"
label var duty "Anciennement cal_dut_yr"
label var country "Anciennement cty_code"
rename *_yr *
capture gen year = `year'

save "$dir_data/base_`year'.dta", replace

/*
** Compiler les années à partir de 2005 en une même base
** Start in 2005
use "$dir_temp/new_IMDBR0512.dta", clear

save "$dir_data/base_new_years.dta", replace

global for_merge IMDBR0612 IMDBR0712 IMDBR0812 IMDBR0912 IMDBR1012 IMDBR1112 IMDBR1212 IMDBR1312

foreach x in $for_merge { 
 

use "$dir_data/base_new_years", clear

append using "$dir_temp/new_`x'.dta"

save "$dir_data/base_new_years", replace

}


foreach x in $for_merge {
	erase "$dir_temp/new_`x'.dta"
}

*/

** Step 1.2 Ajout variables pays origine
******************************************************

** convertir le code pays en iso2 -iso3
** Les données du US Census sont au départ en code à 4 chiffres
** Conversion en iso2 via Schedule C (see US census foreign trade website)

cd "$dir_data"
 
clear 
insheet using "$dir_external_data/countrycodes_use.txt", delimiter(";") 

rename isocode iso2
rename code country
tostring country, replace
sort country
save $dir_temp/temp.dta, replace


use base_`year'.dta, clear
sort country
merge m:1 country using $dir_temp/temp.dta
drop if _merge==2
drop _merge


save base_`year'.dta, replace
erase $dir_temp/temp.dta

** Ajouter code iso3

use base_`year'.dta, clear

* Ajouter la variable iso_d pour merge ensuite sur les variables de gravité
capture drop iso_d
generate iso_d="USA"


*merge m:1 iso2 using "E:\Lise\BQR_Lille\data\USdata_raw\country_codes_v2.dta"
merge m:1 iso2 using "$dir_external_data/Hummels_JEP_data/country_codes_v2.dta"
drop if _merge==2

drop _merge

** on enlève si code pays origine pas renseigné
drop if iso2==""

*rename yr year
tostring year, replace

rename iso3 iso_o


replace iso_o="SVN" if name=="Slovenia"
replace iso_o="MMR" if name=="Burma (Myanmar)"
replace iso_o="ZAR" if name =="Congo, Democratic Republic of th"

drop if iso_o==""
*On enlève les territoires français d'Antarctique.
drop if iso_o=="ATF"

label var iso2 "ISO 2 country code (origin)"
label var iso_d "Importing country (iso3)"
label var iso_o "Exporting country (iso3)"

save base_`year'.dta, replace

******************************************************************************
*** STEP 2.3: Introduire éuqlivalence HS10 - SITC2 (la clé de classification dans hummels_tra)
******************************************************************************

** Les nouvelles années sont codées en HTS (Harmonized Tariff System): variable hs
** Les 6 premiers chiffres de "hs" sont en fait les mêmes que la classification HS6

** On garde les 6 premiers chiffres, on convertit ensuite en sitc Rev2

use base_`year'.dta, clear

gen hs6=substr(hs,1,6)


save base_`year', replace

clear

** Table de conversion HS6 - SITC2 (HS6 version 2002)
infix str6 hs2002 1-6 str sitc2 9-13 using "$dir_external_data/HS2002_SITC2.txt"
drop if _n==1

gen t0 = "0"
gen tt0 = "00"
gen tt = length(sitc2)
tab tt


egen sitc2_1 = concat(sitc2 t0) if length(sitc2)==4
egen sitc2_2 = concat(sitc2 tt0) if length(sitc2)==3

replace sitc2=sitc2_1 if length(sitc2)==4
replace sitc2=sitc2_2 if length(sitc2)==3

drop tt
gen tt= length(sitc2)
tab tt

drop tt0 t0 sitc2_1 sitc2_2 tt
rename hs2002 hs6
duplicates report hs6

save hs2002_sitc2, replace

** Merge avec base

use base_`year', clear
merge m:1 hs6 using hs2002_sitc2

count if _merge==1
egen _=group(hs6) if _merge==1
sum _
drop _


drop if _merge==2
drop _merge

label var hs6 "HS6 classification (2002 version)"
label var sitc2 "SITC, Rev.2, 5 digit"

save base_`year'.dta, replace
zipfile base_`year'.dta,saving(base_`year'.zip, replace) 
erase base_`year'.dta



end

*2000 ? *2001 ?


foreach year of numlist 2014(1)2019 {
	From_Zip_to_Stata `year'	
} 



/*

foreach year of numlist 1998 1999 2002(1)2004 {
	From_Zip_to_Stata `year'	
} 



foreach year of numlist 2005(1)2013 {
	From_Zip_to_Stata `year'	
} 



