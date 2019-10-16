

*version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767




if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/2013 -- trade_cost -- dropbox/JEGeo
	global dir_db ~/Documents/Recherche/2013 -- Trade Costs -- local/data
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\lpatureau\Dropbox\trade_cost\data
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost\JEGeo
	global dir_db C:\Users\lpatureau\Dropbox\trade_cost\data /* pour aller chercher la base de données au départ */ 
}


*cd $dir

capture log using "`c(current_time)' `c(current_date)'"

set more off


*----------------------------------------------------------
*** START FROM NEW YEARS 2005-2013
*----------------------------------------------------------

*****************************************************************
*** STEP 1: BUILD THE DATASET ***********************************
*****************************************************************



capture program drop build_database
program build_database

cd "$dir_db/New_years"


** STEP 1: CONSTITUER BASE ADDITIONAL YEARS: 2005, 2006, 2008, 2010 à 2013
********************************************************************************

** Step 1.1. Partir des nouvelles années en HS 10 **
** Garder le port d'entrée
 
local base IMDBR0512 IMDBR0612 IMDBR0712 IMDBR0812 IMDBR0912 IMDBR1012 IMDBR1112 IMDBR1212 IMDBR1312 
 
foreach x in `base' {
clear
quietly infix str10	commodity 1-10 str6	cty_code 11-14 str2	cty_subco 15-16 str2	dist_entry 	17-18 str2	dist_unlad 	19-20 str2	rate_prov	21-22 int	year 23-26 int	month 	27-28 /*
*/ str15 cards_mo 29-43 double	con_qy1_mo 	44-58 double con_qy2_mo 59-73 double con_val_mo 74-88 double	dut_val_mo 	89-103 double	cal_dut_mo 	104-118 double	con_cha_mo 	119-133 /*
*/double con_cif_mo 134-148 double	gen_qy1_mo 	149-163 double	gen_qy2_mo 164-178 double gen_val_mo 179-193 double	gen_cha_mo 	194-208 double	gen_cif_mo 	209-223 double	air_val_mo 	224-238 /*
*/double air_wgt_mo 239-253 double	air_cha_mo 	254-268 double	ves_val_mo 	269-283 double	ves_wgt_mo 	284-298 double	ves_cha_mo 	299-313 double	cnt_val_mo 	314-328 double	cnt_wgt_mo 	329-343 /*
*/ double cnt_cha_mo 344-358 double	cards_yr 359-373 double	con_qy1_yr 	374-388 double	con_qy2_yr 	389-403 double	con_val_yr 	404-418 double	dut_val_yr 	419-433 double	cal_dut_yr 	434-448 /*
*/ double con_cha_yr 449-463 double con_cif_yr 464-478 double	gen_qy1_yr 	479-493 double	gen_qy2_yr 	494-508 double	gen_val_yr 	509-523 double	gen_cha_yr 	524-538 double	gen_cif_yr 	539-553 /*
*/ double	air_val_yr 	554-568 double	air_wgt_yr 	569-583 double	air_cha_yr 	584-598 double	ves_val_yr 	599-613 double	ves_wgt_yr 	614-628 double	ves_cha_yr 	629-643 double	cnt_val_yr 	644-658 /*
*/ double	cnt_wgt_yr 	659-673 double	cnt_cha_yr 	674-688  using `x'.txt

quietly compress

generat test=0
replace test=1 if (air_val_mo !=0 &  (ves_val_mo !=0 | cnt_val_mo !=0)) | (ves_val_mo !=0 & cnt_val_mo !=0)

display "`x'"
tab test


save new_`x', replace

gen value=air_val_mo+ves_val_mo
collapse (sum) value, by(test)
egen val_tot = total(value)
gen percentage_value = value/val_tot
list



}

end



build_database

end log
