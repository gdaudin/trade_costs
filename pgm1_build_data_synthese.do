***********************************
** TRADE COSTS: ICEBERG, ADDITIVE, or BOTH?

** Avril 2015

************************************************************************
** PGM 1 : construction de la base de données - COMPLETE, de 1974 à 2013
************************************************************************

*** Attention, on part de la base de données fournies par Hummels sur son site
*** http://www.krannert.purdue.edu/faculty/hummelsd/research/jep/data.html ***

** Partant des importations US en hs10, hummels.dta = agrégé au niveau 5 digits (sitc2)

version 12

* sur le serveur
*cd "C:\Echange\trade_costs\database\hummels_db"
*sur mon ordi old
*cd "E:\Lise\BQR_Lille\data\USdata_use"

*sur mon nouvel ordi
cd "C:\Echange\trade_costs\database\hummels_db"

* sur le fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database"

clear all
set more off

*----------------------------------------------------------
**** STEP 1 - START FROM HUMMELS.dta, 1974-2004 
*----------------------------------------------------------


use "C:\Lise\trade_costs\Hummels\database\raw_data\hummels.dta", clear

/*
* A faire une fois pour toutes
drop _merge
save "C:\Lise\trade_costs\Hummels\database\raw_data\hummels.dta", replace
*/

********Special Hummels******
capture drop iso_d
generate iso_d="USA"



merge m:1 iso2 using country_codes_v2
drop if _merge==2
drop _merge

rename yr year
tostring year, replace

rename iso3 iso_o

replace iso_o="SVN" if name=="Slovenia"
replace iso_o="MMR" if name=="Burma (Myanmar)"
replace iso_o="ZAR" if name =="Congo, Democratic Republic of th"

* On enlève si non renseigné pour le pays d'origine
drop if iso_o==""

*On enlève les territoires français d'Antarctique
drop if iso_o=="ATF"


merge m:1 iso_o iso_d using dist_cepii
drop if _merge==2
drop _merge


**Il faut séparer les air et les vessels
generate mode="ves"

save temp, replace

replace mode="air"
append using temp


generate prix_fob=.
generate prix_caf=.
generate prix_trsp=.
generate prix_trsp2=.

foreach i in air ves {
	replace prix_fob = `i'_val/`i'_wgt if mode=="`i'"
	replace prix_caf = (`i'_val+`i'_cha)/`i'_wgt if mode=="`i'"
	replace prix_trsp=(prix_caf-prix_fob)/prix_fob if mode=="`i'"
	replace prix_trsp2=prix_caf/prix_fob
	label variable prix_trsp "(prix_caf-prix_fob)/prix_fob"
}

drop if prix_fob==.

erase temp.dta
destring year, replace
save hummels_tra.dta, replace 

*----------------------------------------------------------
*** STEP 2 - ADD NEW YEARS - AT FIRST, 2005-2006-2008-2010-2011-2012-2013
*----------------------------------------------------------


*cd "E:\Jerome\Papier_Lise_Guillaume\2014"
*cd "E:\Lise\BQR_Lille\data\USdata_raw"
*cd "C:\Echange\trade_costs\database\hummels_db"

*cd "C:\Lise\trade_costs\Hummels\database\raw_data"


cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\trade_cost\database\rawdata" 
******************************************************
** STEP 2.1.: Constituer la base hummels_addyears
******************************************************


set more off
** STEP 1: CONSTITUER BASE ADDITIONAL YEARS: 2005, 2006, 2008, 2010 à 2013
** MANQUE 2009 
 
local base IMDBR0512 IMDBR0612 IMDBR0612 IMDBR0812 IMDBR1012 IMDBR1112 IMDBR1212 IMDBR1312
 
* Ajout 2007 et 2009 : plus loin
local base IMDBR0912
 
foreach x in `base' {
clear
infix str10	commodity 1-10 str6	cty_code 11-14 str2	cty_subco 15-16 str2	dist_entry 	17-18 str2	dist_unlad 	19-20 str2	rate_prov	21-22 int	year 23-26 int	month 	27-28 /*
*/ str15 cards_mo 29-43 double	con_qy1_mo 	44-58 double con_qy2_mo 59-73 double con_val_mo 74-88 double	dut_val_mo 	89-103 double	cal_dut_mo 	104-118 double	con_cha_mo 	119-133 /*
*/double con_cif_mo 134-148 double	gen_qy1_mo 	149-163 double	gen_qy2_mo 164-178 double gen_val_mo 179-193 double	gen_cha_mo 	194-208 double	gen_cif_mo 	209-223 double	air_val_mo 	224-238 /*
*/double air_wgt_mo 239-253 double	air_cha_mo 	254-268 double	ves_val_mo 	269-283 double	ves_wgt_mo 	284-298 double	ves_cha_mo 	299-313 double	cnt_val_mo 	314-328 double	cnt_wgt_mo 	329-343 /*
*/ double cnt_cha_mo 344-358 double	cards_yr 359-373 double	con_qy1_yr 	374-388 double	con_qy2_yr 	389-403 double	con_val_yr 	404-418 double	dut_val_yr 	419-433 double	cal_dut_yr 	434-448 /*
*/ double con_cha_yr 449-463 double con_cif_yr 464-478 double	gen_qy1_yr 	479-493 double	gen_qy2_yr 	494-508 double	gen_val_yr 	509-523 double	gen_cha_yr 	524-538 double	gen_cif_yr 	539-553 /*
*/ double	air_val_yr 	554-568 double	air_wgt_yr 	569-583 double	air_cha_yr 	584-598 double	ves_val_yr 	599-613 double	ves_wgt_yr 	614-628 double	ves_cha_yr 	629-643 double	cnt_val_yr 	644-658 /*
*/ double	cnt_wgt_yr 	659-673 double	cnt_cha_yr 	674-688  using `x'.txt

compress
save new_`x', replace

** Nettoyer a minima

use new_`x', clear

* renommer les variables
drop  cards_mo con_qy1_mo con_qy2_mo con_val_mo dut_val_mo cal_dut_mo con_cha_mo con_cif_mo gen_* 
drop air_val_mo air_wgt_mo air_cha_mo ves_val_mo ves_wgt_mo ves_cha_mo cnt_val_mo cnt_wgt_mo cnt_cha_mo
drop cnt_* cty_subco dist_unlad dist_entry rate_prov month cal_dut_yr cards_yr

rename cty_code country 
rename commodity hs
rename con_qy1_yr con_qy1
rename con_qy2_yr con_qy2 
rename con_val_yr con_val 
rename ves_val_yr ves_val
rename air_val_yr air_val
rename con_cha_yr con_cha
rename ves_cha_yr ves_cha
rename air_cha_yr air_cha
rename air_wgt_yr air_wgt
rename ves_wgt_yr ves_wgt
rename dut_val_yr duty 


save new_`x', replace
}

** Compiler les années 2006, 2008, 2010, 11, 12 et 13


** Start in 2005
use new_IMDBR0512, clear

save "C:\Lise\trade_costs\Hummels\database\hummels_addyears", replace

foreach x in new_IMDBR0612 new_IMDBR0812 new_IMDBR1012 new_IMDBR1112 new_IMDBR1212 new_IMDBR1312 {

use "C:\Lise\trade_costs\Hummels\database\hummels_addyears", clear
append using `x'

save "C:\Lise\trade_costs\Hummels\database\hummels_addyears", replace

}

foreach x in `base' {
erase new_`x'.dta 
}



******************************************************
** STEP 2.2.: Ajout variables pays origine
******************************************************

** convertir le code pays en iso2 -iso3
** Les données du US Census sont au départ en code à 4 chiffres
** Conversion en iso2 via Schedule C (see US census foreign trade website)

*cd "C:\Lise\trade_costs\Hummels\database"
cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database"

clear 
insheet using countrycodes_use.txt, delimiter(";") 

rename isocode iso2
rename code country
tostring country, replace
sort country
save temp, replace

use hummels_addyears, clear
sort country
merge m:1 country using temp
drop if _merge==2
drop _merge


save hummels_addyears, replace
erase temp.dta

** Ajouter code iso3

use hummels_addyears, clear

* Ajouter la variable iso_d pour merge ensuite sur les variables de gravité
capture drop iso_d
generate iso_d="USA"


*merge m:1 iso2 using "E:\Lise\BQR_Lille\data\USdata_raw\country_codes_v2.dta"
merge m:1 iso2 using country_codes_v2
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


save hummels_addyears, replace

******************************************************************************
*** STEP 2.3: Passer de HS10 à SITC2 (la clé de classification dans hummels_tra)
******************************************************************************

** Les nouvelles années sont codées en HTS (Harmonized Tariff System): variable hs
** Les 6 premiers chiffres de "hs" sont en fait les mêmes que la classification HS6

** On garde les 6 premiers chiffres, on convertit ensuite en sitc Rev2
** On fait un collapse par sitc rev2/year/pays d'origine


use hummels_addyears, clear

gen hs6=substr(hs,1,6)


save hummels_addyears, replace

clear

** Table de conversion HS6 - SITC2 (HS6 version 2002)
infix str6 hs2002 1-6 str sitc2 9-13 using HS2002_SITC2.txt
drop if _n==1
save hs_sitc2, replace

use hs_sitc2, clear
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

use hummels_addyears, clear
merge m:1 hs6 using hs_sitc2

count if _merge==1
egen _=group(hs6) if _merge==1
sum _
drop _
* 69,005 obs, 10 hs6 sans équivalent sitc2
* Que faire?
drop if _merge==2
drop _merge

label var hs6 "HS6 classification (2002 version)"
label var sitc2 "SITC, Rev.2, 5 digit"

save hummels_addyears, replace

** Faire un collapse par year/country o/sitc2

use hummels_addyears, clear

collapse(sum) con_qy1 con_qy2 con_val duty con_cha con_cif_yr air_val air_wgt air_cha ves_val ves_wgt ves_cha, by (iso_o year sitc2)
count if sitc2==""
*422 obs sans code sitc2, on drop

drop if sitc2==""
count
* pour 2005 et 2006, 130,311 obs supplémentaires

egen _ =group(iso_o)
sum _
drop _
* 213 pays origine
egen _ = group(sitc2)
sum _
drop _
* 1735 sitc2 (5 digits)

save hummels_addyears, replace

******************************************************************************
*** STEP 2.4: Ajouter les variables de gravité, pays destination
******************************************************************************
use hummels_addyears, clear

* remettre code iso2, parti dans le collapse
rename iso_o iso3
merge m:1 iso3 using country_codes_v2
drop if _merge==2
drop _merge

rename iso3 iso_o

capture drop iso_d
generate iso_d="USA"

*merge m:1 iso_o iso_d using "E:\Lise\BQR_Lille\data\USdata_raw\dist_cepii.dta"
merge m:1 iso_o iso_d using dist_cepii
drop if _merge==2
drop _merge

label var iso2 "ISO 2 country code (origin)"
label var iso_d "Importing country (iso3)"
label var iso_o "Exporting country (iso3)"


******************************************************************************
*** STEP 2.5: Construire l'écart prix cif/fob
******************************************************************************

** Attention, comme pour la base hummels, on le fait au niveau agrégé (5 digits)

**Il faut séparer les air et les vessels
** Attention, ce n'est pas "l'un ou l'autre"
** Il peut y avoir des observations qui utilisent à la fois air et ves
** On calcule un écart cif/fob pour chaque mode de transport

generate mode="ves"
save temp, replace

replace mode="air"
append using temp


generate prix_fob=.
generate prix_caf=.
generate prix_trsp=.
generate prix_trsp2=.

foreach i in air ves {
	replace prix_fob = `i'_val/`i'_wgt if mode=="`i'"
	replace prix_caf = (`i'_val+`i'_cha)/`i'_wgt if mode=="`i'"
	replace prix_trsp=(prix_caf-prix_fob)/prix_fob if mode=="`i'"
	replace prix_trsp2=prix_caf/prix_fob
	label variable prix_trsp "(prix_caf-prix_fob)/prix_fob"
}


** De cette façon là, prix_fob est missing pour l'observation par mode "air" si tout le transport se fait par "ves"
** Et réciproquement


drop if prix_fob==.

erase temp.dta
destring year, replace

save hummels_addyears, replace

***************************************************
*** STEP 2.6: ADD to the whole database
***************************************************

use hummels_tra, clear

append using hummels_addyears

save hummels_tra, replace

** Attention aux anciennes versions de stata si sous Stata13
saveold hummels_tra, replace

 
*erase hummels_addyears.dta


*----------------------------------------------------------
*** STEP 3 - ADD NEW YEARS "au compte gouttes" - 2007, puis 2009
*----------------------------------------------------------



cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database\rawdata"



set more off
** STEP 1: CONSTITUER BASE pour 2007, puis 2009
** Juillet 2015: MANQUE 2009 
 
* Juin 2015 : on fait le travail pour 2007
*local base IMDBR0712
 
local base IMDBR0712 IMDBR0912
 
foreach x in `base' {
clear
infix str10	commodity 1-10 str6	cty_code 11-14 str2	cty_subco 15-16 str2	dist_entry 	17-18 str2	dist_unlad 	19-20 str2	rate_prov	21-22 int	year 23-26 int	month 	27-28 /*
*/ str15 cards_mo 29-43 double	con_qy1_mo 	44-58 double con_qy2_mo 59-73 double con_val_mo 74-88 double	dut_val_mo 	89-103 double	cal_dut_mo 	104-118 double	con_cha_mo 	119-133 /*
*/double con_cif_mo 134-148 double	gen_qy1_mo 	149-163 double	gen_qy2_mo 164-178 double gen_val_mo 179-193 double	gen_cha_mo 	194-208 double	gen_cif_mo 	209-223 double	air_val_mo 	224-238 /*
*/double air_wgt_mo 239-253 double	air_cha_mo 	254-268 double	ves_val_mo 	269-283 double	ves_wgt_mo 	284-298 double	ves_cha_mo 	299-313 double	cnt_val_mo 	314-328 double	cnt_wgt_mo 	329-343 /*
*/ double cnt_cha_mo 344-358 double	cards_yr 359-373 double	con_qy1_yr 	374-388 double	con_qy2_yr 	389-403 double	con_val_yr 	404-418 double	dut_val_yr 	419-433 double	cal_dut_yr 	434-448 /*
*/ double con_cha_yr 449-463 double con_cif_yr 464-478 double	gen_qy1_yr 	479-493 double	gen_qy2_yr 	494-508 double	gen_val_yr 	509-523 double	gen_cha_yr 	524-538 double	gen_cif_yr 	539-553 /*
*/ double	air_val_yr 	554-568 double	air_wgt_yr 	569-583 double	air_cha_yr 	584-598 double	ves_val_yr 	599-613 double	ves_wgt_yr 	614-628 double	ves_cha_yr 	629-643 double	cnt_val_yr 	644-658 /*
*/ double	cnt_wgt_yr 	659-673 double	cnt_cha_yr 	674-688  using `x'.txt

compress
save new_`x', replace

** Nettoyer a minima

use new_`x', clear

* renommer les variables
drop  cards_mo con_qy1_mo con_qy2_mo con_val_mo dut_val_mo cal_dut_mo con_cha_mo con_cif_mo gen_* 
drop air_val_mo air_wgt_mo air_cha_mo ves_val_mo ves_wgt_mo ves_cha_mo cnt_val_mo cnt_wgt_mo cnt_cha_mo
drop cnt_* cty_subco dist_unlad dist_entry rate_prov month cal_dut_yr cards_yr

rename cty_code country 
rename commodity hs
rename con_qy1_yr con_qy1
rename con_qy2_yr con_qy2 
rename con_val_yr con_val 
rename ves_val_yr ves_val
rename air_val_yr air_val
rename con_cha_yr con_cha
rename ves_cha_yr ves_cha
rename air_cha_yr air_cha
rename air_wgt_yr air_wgt
rename ves_wgt_yr ves_wgt
rename dut_val_yr duty 


save new_`x', replace
}

***************************************************************************
* Guillaume dira que c'est sous-optimal et avec raison 
* mais on recommence le travail des étapes 2.2 à 2.6 sur la base année 2009
***************************************************************************
 
local base IMDBR0712 IMDBR0912
 
foreach x in `base' {

use "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database\rawdata\new_IMDBR0912"

save "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database\new_IMDBR0912", replace

******************************************************
** STEP 3.2: Ajout variables pays origine
******************************************************

** convertir le code pays en iso2 -iso3
** Les données du US Census sont au départ en code à 4 chiffres
** Conversion en iso2 via Schedule C (see US census foreign trade website)

*cd "C:\Lise\trade_costs\Hummels\database"
cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database"

clear 
insheet using countrycodes_use.txt, delimiter(";") 

rename isocode iso2
rename code country
tostring country, replace
sort country
save temp, replace

use new_`x', clear
sort country
merge m:1 country using temp
drop if _merge==2
drop _merge


save new_`x', replace
erase temp.dta

** Ajouter code iso3

use new_`x', clear

* Ajouter la variable iso_d pour merge ensuite sur les variables de gravité
capture drop iso_d
generate iso_d="USA"


*merge m:1 iso2 using "E:\Lise\BQR_Lille\data\USdata_raw\country_codes_v2.dta"
merge m:1 iso2 using country_codes_v2
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


save new_`x', replace

******************************************************************************
*** STEP 3.3: Passer de HS10 à SITC2 (la clé de classification dans hummels_tra)
******************************************************************************

** Les nouvelles années sont codées en HTS (Harmonized Tariff System): variable hs
** Les 6 premiers chiffres de "hs" sont en fait les mêmes que la classification HS6

** On garde les 6 premiers chiffres, on convertit ensuite en sitc Rev2
** On fait un collapse par sitc rev2/year/pays d'origine


use new_`x', clear

gen hs6=substr(hs,1,6)


save new_`x', replace

clear

** Table de conversion HS6 - SITC2 (HS6 version 2002)
infix str6 hs2002 1-6 str sitc2 9-13 using HS2002_SITC2.txt
drop if _n==1
save hs_sitc2, replace

use hs_sitc2, clear
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

use new_`x', clear
merge m:1 hs6 using hs_sitc2

count if _merge==1
egen _=group(hs6) if _merge==1
sum _
drop _
* 69,005 obs, 10 hs6 sans équivalent sitc2
* Que faire?
drop if _merge==2
drop _merge

label var hs6 "HS6 classification (2002 version)"
label var sitc2 "SITC, Rev.2, 5 digit"

save new_`x', replace

** Faire un collapse par year/country o/sitc2

use new_`x', clear

collapse(sum) con_qy1 con_qy2 con_val duty con_cha con_cif_yr air_val air_wgt air_cha ves_val ves_wgt ves_cha, by (iso_o year sitc2)
count if sitc2==""
*422 obs sans code sitc2, on drop

drop if sitc2==""
count
* 

egen _ =group(iso_o)
sum _
drop _
* 

egen _ = group(sitc2)
sum _
drop _
* 

save new_`x', replace

******************************************************************************
*** STEP 3.4: Ajouter les variables de gravité, pays destination
******************************************************************************
use new_`x', clear

* remettre code iso2, parti dans le collapse
rename iso_o iso3
merge m:1 iso3 using country_codes_v2
drop if _merge==2
drop _merge

rename iso3 iso_o

capture drop iso_d
generate iso_d="USA"

*merge m:1 iso_o iso_d using "E:\Lise\BQR_Lille\data\USdata_raw\dist_cepii.dta"
merge m:1 iso_o iso_d using dist_cepii
drop if _merge==2
drop _merge

label var iso2 "ISO 2 country code (origin)"
label var iso_d "Importing country (iso3)"
label var iso_o "Exporting country (iso3)"


******************************************************************************
*** STEP 3.5: Construire l'écart prix cif/fob
******************************************************************************

** Attention, comme pour la base hummels, on le fait au niveau agrégé (5 digits)

**Il faut séparer les air et les vessels
** Attention, ce n'est pas "l'un ou l'autre"
** Il peut y avoir des observations qui utilisent à la fois air et ves
** On calcule un écart cif/fob pour chaque mode de transport

generate mode="ves"
save temp, replace

replace mode="air"
append using temp


generate prix_fob=.
generate prix_caf=.
generate prix_trsp=.
generate prix_trsp2=.

foreach i in air ves {
	replace prix_fob = `i'_val/`i'_wgt if mode=="`i'"
	replace prix_caf = (`i'_val+`i'_cha)/`i'_wgt if mode=="`i'"
	replace prix_trsp=(prix_caf-prix_fob)/prix_fob if mode=="`i'"
	replace prix_trsp2=prix_caf/prix_fob
	label variable prix_trsp "(prix_caf-prix_fob)/prix_fob"
}


** De cette façon là, prix_fob est missing pour l'observation par mode "air" si tout le transport se fait par "ves"
** Et réciproquement


drop if prix_fob==.

erase temp.dta
destring year, replace

save new_`x', replace

***************************************************
*** STEP 3.6: ADD to the whole database
***************************************************

*** sur le serveur directement
cd "C:\Echange\trade_costs\database"

use hummels_tra, clear

append using new_`x'

save hummels_tra, replace

** Attention aux anciennes versions de stata si sous Stata13
saveold hummels_tra, replace

erase new_`x'.dta
*erase hummels_addyears.dta


************************************************************************
*** 29 mai 2015

*** Rétablir bug dans années récentes il n'y a pas les variables de gravité
*************************************************************************

* sur le fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\database"

* sur le serveur
cd "C:\Echange\trade_costs\database"

clear all
set more off



use hummels_tra, clear

* On enlève les variables de gravité et on recommence le merge
capture drop iso_d
generate iso_d="USA"

tab year

drop contig-distwces


*merge m:1 iso_o iso_d using "E:\Lise\BQR_Lille\data\USdata_raw\dist_cepii.dta"
merge m:1 iso_o iso_d using dist_cepii
drop if _merge==2
drop _merge

label var iso2 "ISO 2 country code (origin)"
label var iso_d "Importing country (iso3)"
label var iso_o "Exporting country (iso3)"


save hummels_tra, replace

}
