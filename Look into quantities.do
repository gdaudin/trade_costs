
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


program import_hs_qy1
args year


if `year'==2018 | `year'==2019 {
	import delimited "$dir_external_data/Quantity/hts_`year'_basic_csv.csv", ///
		bindquote(strict) varnames(1) encoding(UTF-8) clear
} 

if `year'==2017 {
	import delimited "$dir_external_data/Quantity/hts_`year'_preliminary_csv.csv", ///
		bindquote(strict) varnames(1) encoding(UTF-8) clear
} 

if `year'==2016 {
	import delimited "$dir_external_data/Quantity/hts_`year'_basic_delimited.csv", ///
		bindquote(strict) varnames(1) encoding(UTF-8) clear
} 

if `year'==2015 {
	import delimited "$dir_external_data/Quantity/`year'_htsa_basic_delimited_0.txt", ///
		parselocale(fr_FR) stringcols(2 4) bindquote(nobind) clear encoding(UTF-8)
}

if `year'==2014 {
	import delimited "$dir_external_data/Quantity/`year'_hts_delimited_0.txt", ///
		parselocale(fr_FR) stringcols(2 4) bindquote(nobind) clear encoding(UTF-8)
}  

if `year'<=2013 {
	import delimited "$dir_external_data/Quantity/`year'_hts_delimited.txt", ///
		parselocale(fr_FR) stringcols(2 4) bindquote(nobind) clear encoding(UTF-8)
}  

if `year'==2011 | `year'==2010 {
	rename v1 htsno
	rename v2 statsuffix
	rename v6 unitofquantity
	drop if unitofquantity==""
}


if `year'==2009 {
	rename v1 htsno
	rename v2 statsuffix
	rename v4 unitofquantity
	drop if unitofquantity==""
	replace unitofquantity="doz. kg" if unitofquantity=="doz.kg"
	replace unitofquantity="m2 kg" if unitofquantity=="m2kg"
	replace unitofquantity="No. kg" if unitofquantity=="No.kg"
	replace unitofquantity="doz.pr. kg" if unitofquantity=="doz.pr.kg"
}

tab unitofquantity, sort

if `year'>=2016 {

	keep htsnumber unitofquantity
	drop if unitofquantity==""
	
	replace unitofquantity=subinstr(unitofquantity,"[","",.)
	replace unitofquantity=subinstr(unitofquantity,"]","",.)
	replace unitofquantity=subinstr(unitofquantity,`"""',"",.)
	replace unitofquantity=subinstr(unitofquantity,`"."',"",.) 
	
	generate unit_qy2=substr(unitofquantity,strpos(unitofquantity,`","')+1,.) if strpos(unitofquantity,`","')!=0
	
	replace unitofquantity=substr(unitofquantity,1,strpos(unitofquantity,`","')-1) if strpos(unitofquantity,`","')!=0
		
}


if `year'<=2015 {
	generate htsnumber = htsno+statsuffix
	
	generate unit_qy2=substr(unitofquantity,strpos(unitofquantity,`" "')+1,.) if strpos(unitofquantity,`" "')!=0
	
	replace unitofquantity=substr(unitofquantity,1,strpos(unitofquantity,`" "')-1) if strpos(unitofquantity,`" "')!=0
		
}

if `year'==2015 drop if v3=="text"

replace htsnumber=subinstr(htsnumber,`"."',"",.) 

rename unitofquantity unit_qy1
replace unit_qy1=trim(unit_qy1)

rename htsnumber hs
 
compress hs

 

keep if strlen(hs)==10
duplicates tag hs, generate(flag)
*br if flag==1 

keep hs unit_qy1
bys hs unit_qy1: drop if _n>=2

duplicates tag unit_qy1 hs , generate(flag)
assert flag==0
drop flag
replace unit_qy1="kg" if unit_qy1=="kg." | unit_qy1=="Kg"
replace unit_qy1="doz." if unit_qy1=="doz" | unit_qy1=="Doz" | unit_qy1=="Doz."
replace unit_qy1="X" if unit_qy1=="X." | unit_qy1=="Doz" | unit_qy1=="Doz."
replace unit_qy1="No." if unit_qy1=="No" | unit_qy1=="No.."
replace unit_qy1="m3" if unit_qy1=="M3" | unit_qy1=="m3." | unit_qy1=="m³"
replace unit_qy1="doz.pr." if unit_qy1=="doz.pr"
replace unit_qy1="pcs" if unit_qy1=="pcs."
replace unit_qy1="thousands" if unit_qy1=="thousand" | unit_qy1=="Thousand"
replace unit_qy1="gross" if unit_qy1=="Gross"
replace unit_qy1="X" if unit_qy1=="x"
replace unit_qy1="prs." if unit_qy1=="prs"
replace unit_qy1="m2" if unit_qy1=="m²"

save "$dir_data/Quantity/hs_qy1_`year'.dta", replace

end

****----------------

*import_hs_qy1 2009
*blif


foreach year of numlist 2009(1)2019 {
	import_hs_qy1 `year'
}


blif



use "$dir_data/hs_qy1.dta", clear
merge 1:m hs using "$dir_data/base_hs10_1997.dta"  
tabulate unit_qy1, sort

collapse (sum) con_val, by (unit_qy1)
egen total = total(con_val)
gen perc = con_val/total
format perc %9.2f
br

******Tout cela montre que les mesures en kilogrammes sont minoritaires (1/4-1/3)
 

