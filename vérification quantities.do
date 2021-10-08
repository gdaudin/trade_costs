

if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Documents/Recherche/2013 -- Trade Costs -- local
	global dir_data ~/Documents/Recherche/2013 -- Trade Costs -- local/data
}

** Fixe Lise bureau
if "`c(hostname)'" =="LAB0271A" {
	global dir "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_data "$dir/data"
}

/* Vieux portable Lise
if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}
*/

/* Nouveau portable Lise */

if "`c(hostname)'" =="MSOP112C" {
  
	global dir C:\Lise\trade_costs
	global dir_data "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\data"
	
}
cd "$dir"

*****Ici, on vérifie la part des unimodaux dans hummels_tra (exemple 1998)
use "$dir_data/hummels_tra", clear
keep if year==1998
replace air_val=0 if mode=="ves"
replace ves_val=0 if mode=="air"

egen ves_total = total(ves_val)
egen air_total = total(air_val)
gen com_total= ves_total+air_total
tab com_total
bys sitc2 iso_o year : drop if _N==2
egen ves_total_reduit = total(ves_val)
egen air_total_reduit = total(air_val)
gen com_total_reduit= ves_total_reduit+air_total_reduit
tab com_total_reduit




	
***********Ici, on vérifie la part des unimodaux dans les nouvelles données

use "$dir_data/base_hs10_2019.dta" , clear

duplicates report hs iso_o dist_entry dist_unlad mode rate_prov /*je crois que c’est l’unité qui est bien là...) */

collapse (sum) val, by(hs iso_o dist_entry dist_unlad rate_prov mode)

bysort hs iso_o dist_entry dist_unlad rate_prov mode: drop if _N!=1
*Ce dernier test n’élimine rien



egen com_total= total(val)
tab com_total
bys hs iso_o dist_entry dist_unlad rate_prov : drop if _N==2

egen com_total_reduit= total(val)
tab com_total_reduit



*****Ici on examine le nombre d’unités dans un secteur sitc

use "$dir_data/Quantity/hs_qy1_2019.dta", clear
gen hs6= substr(hs,1,6)
merge m:1 hs6 using "$dir_data/hs2002_sitc2.dta"
keep if _merge==3
drop _merge
generate sector = substr(sitc2,1,3)
bys sector unit_qy1 : keep if _n==1
duplicates report sector

*****Ici on examine le nombre d'unités dans un secteur hs 3d

use "$dir_data/Quantity/hs_qy1_2019.dta", clear
generate sector = substr(hs,1,3)
bys sector unit_qy1 : keep if _n==1
duplicates report sector



