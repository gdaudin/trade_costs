
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

cd "$dir_external_data/New_years"

****************Step 1 Passer les donées de .txt dans la base

global base IMDBR0512 IMDBR0612 IMDBR0712 IMDBR0812 IMDBR0912 IMDBR1012 IMDBR1112 IMDBR1212 IMDBR1312


foreach x in $base {
	clear
	unzipfile `x'.zip, replace
	local file `x'
	if "`x'"== "IMDBR1212" local file IMP_DETL
	infix str10	commodity 1-10 str6	cty_code 11-14 str2	cty_subco 15-16 str2	dist_entry 	17-18 str2	dist_unlad 	19-20 str2	rate_prov	21-22 int	year 23-26 int	month 	27-28 /*
	*/ str15 cards_mo 29-43 double	con_qy1_mo 	44-58 double con_qy2_mo 59-73 double con_val_mo 74-88 double	dut_val_mo 	89-103 double	cal_dut_mo 	104-118 double	con_cha_mo 	119-133 /*
	*/double con_cif_mo 134-148 double	gen_qy1_mo 	149-163 double	gen_qy2_mo 164-178 double gen_val_mo 179-193 double	gen_cha_mo 	194-208 double	gen_cif_mo 	209-223 double	air_val_mo 	224-238 /*
	*/double air_wgt_mo 239-253 double	air_cha_mo 	254-268 double	ves_val_mo 	269-283 double	ves_wgt_mo 	284-298 double	ves_cha_mo 	299-313 double	cnt_val_mo 	314-328 double	cnt_wgt_mo 	329-343 /*
	*/ double cnt_cha_mo 344-358 double	cards_yr 359-373 double	con_qy1_yr 	374-388 double	con_qy2_yr 	389-403 double	con_val_yr 	404-418 double	dut_val_yr 	419-433 double	cal_dut_yr 	434-448 /*
	*/ double con_cha_yr 449-463 double con_cif_yr 464-478 double	gen_qy1_yr 	479-493 double	gen_qy2_yr 	494-508 double	gen_val_yr 	509-523 double	gen_cha_yr 	524-538 double	gen_cif_yr 	539-553 /*
	*/ double	air_val_yr 	554-568 double	air_wgt_yr 	569-583 double	air_cha_yr 	584-598 double	ves_val_yr 	599-613 double	ves_wgt_yr 	614-628 double	ves_cha_yr 	629-643 double	cnt_val_yr 	644-658 /*
	*/ double	cnt_wgt_yr 	659-673 double	cnt_cha_yr 	674-688  using `file'.txt
	
	compress
	
	erase `file'.txt
	
	** Nettoyer a minima

	* renommer les variables
	drop  cards_mo con_qy1_mo con_qy2_mo con_val_mo dut_val_mo cal_dut_mo con_cha_mo con_cif_mo gen_* 
	drop air_val_mo air_wgt_mo air_cha_mo ves_val_mo ves_wgt_mo ves_cha_mo cnt_val_mo cnt_wgt_mo cnt_cha_mo
	drop cty_subco dist_unlad rate_prov month cal_dut_yr cards_yr
	
	rename cty_code country 
	rename commodity hs
	rename dut_val_yr duty 
	rename *_yr *
	
	save "$dir_temp/new_`x'.dta", replace
}

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


use base_new_years.dta, clear
sort country
merge m:1 country using $dir_temp/temp.dta
drop if _merge==2
drop _merge


save base_new_years.dta, replace
erase $dir_temp/temp.dta

** Ajouter code iso3

use base_new_years, clear

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

save base_new_years.dta, replace

******************************************************************************
*** STEP 2.3: Introduire éuqlivalence HS10 - SITC2 (la clé de classification dans hummels_tra)
******************************************************************************

** Les nouvelles années sont codées en HTS (Harmonized Tariff System): variable hs
** Les 6 premiers chiffres de "hs" sont en fait les mêmes que la classification HS6

** On garde les 6 premiers chiffres, on convertit ensuite en sitc Rev2

use base_new_years.dta, clear

gen hs6=substr(hs,1,6)


save base_new_years, replace

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

save hs_sitc2, replace

** Merge avec base

use base_new_years, clear
merge m:1 hs6 using hs_sitc2

count if _merge==1
egen _=group(hs6) if _merge==1
sum _
drop _


drop if _merge==2
drop _merge

label var hs6 "HS6 classification (2002 version)"
label var sitc2 "SITC, Rev.2, 5 digit"

save base_new_years.dta, replace
zipfile base_new_years.dta,saving(base_new_years.zip, replace) 
erase base_new_years.dta


