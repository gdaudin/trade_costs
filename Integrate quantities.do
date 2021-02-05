
***** Programme Pour faire la relation HS10 et quantities



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

import delimited "$dir_external_data/Quantity/hts_2021_preliminary_revision_2_csv.csv", bindquote(strict) varnames(1) encoding(UTF-8)

keep htsnumber unitofquantity
drop if unitofquantity==""

replace unitofquantity=subinstr(unitofquantity,"[","",.)
replace unitofquantity=subinstr(unitofquantity,"]","",.)
replace unitofquantity=subinstr(unitofquantity,`"""',"",.)
replace unitofquantity=subinstr(unitofquantity,`"."',"",.) 
generate unit_qy2=""
replace unit_qy2=substr(unitofquantity,strpos(unitofquantity,`","')+1,.) if strpos(unitofquantity,`","')!=0

replace unitofquantity=substr(unitofquantity,1,strpos(unitofquantity,`","')-1) if 


replace htsnumber=subinstr(htsnumber,`"."',"",.) 



