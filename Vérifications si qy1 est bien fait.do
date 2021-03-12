

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


use "$dir_data/hummels_tra", clear
keep if year==2019
egen com_total = total(con_val)
tab com_total
bys sitc2 iso_o year : drop if _N==2
egen com_total_réduit = total(con_val)
tab com_total_réduit




	
******

use "$dir_data/base_hs10_2019.dta" , clear

egen com_total = total(con_val)
tab com_total

duplicates report hs iso_o dist_entry dist_unlad rate_prov /*je crois que c’est l’unité qui est bien là...)
