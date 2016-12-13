
if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

cd $dir

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767

use "$dir/data/hummels_tra.dta", clear

encode iso_o, gen(iso_o_num)
encode sitc2, gen(sitc2_num)
gen iso_sitc = iso_o+sitc2
egen iso_sitc_num = group(iso_sitc)

xtreg prix_trsp  if year==1974, i(sitc2_num)
local rho_sitc=e(rho)
xtreg prix_trsp  if year==1974, i(iso_o_num)
local rho_iso=e(rho)
xtreg prix_trsp  if year==1974, i(iso_sitc_num)
local rho_iso_sitc=e(rho)

matrix ana_var = (1974,`rho_sitc',`rho_iso',`rho_iso_sitc')

mat colnames ana_var = year product_variance country_variance product_country_variance

foreach y of num 1975(1)2013 {
	xtreg prix_trsp  if year==`y', i(sitc2_num)
	local rho_sitc=e(rho)
	xtreg prix_trsp  if year==`y', i(iso_o_num)
	local rho_iso=e(rho)
	xtreg prix_trsp  if year==`y', i(iso_sitc_num)
	local rho_iso_sitc=e(rho)
	
	matrix A = (`y',`rho_sitc',`rho_iso',`rho_iso_sitc')
	matrix ana_var = ana_var \ A
}
	



	
matrix list ana_var

clear

svmat ana_var, names (col)

twoway (line  product_variance year) (line  country_variance year) (line  product_country_variance year), ///
	legend(label(1 "Share of between product variance") label(2 "Share of between country variance") label(3 "Share of between product x country variance") ///
	rows(3))
	
graph export 
