*************************************************
*
* 
*************************************************

version 14.2


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



********************************************************************
*** Faire un programme qui calcule l'écart cif-fob observé / prédit*** 

capture program drop calc_trend
program calc_trend
	args precis mode 
	*ex : calc_trend 3 air

use "$dir/results/3_models/table_`precis'_`mode'.dta", clear

replace terme_nlI_mp = terme_nlI_mp-1
replace terme_I_mp = terme_I_mp-1
generate terme_IetA_mp = terme_I_mp+terme_A_mp
local var_liste terme_nlI terme_nlA terme_A terme_I terme_IetA
gen year_num = real(year)

foreach var of local var_liste {
	gen ln_var = ln(`var'_mp)
	quietly regress ln_var year_num
	matrix e=e(b)
	local redu = round(e[1,1],0.001)
	display "Le trend pour `var' pour `mode' en précision `precis' sur la période 1974-2013 est `redu'"
	quietly regress ln_var year_num if year_num>=1980
	matrix e=e(b)
	local redu = round(e[1,1],0.001)
	display "Le trend pour `var' pour `mode' en précision `precis' sur la période 1980-2013 est `redu'"
	drop ln_var
}


end

calc_trend 3 air
calc_trend 3 ves 



