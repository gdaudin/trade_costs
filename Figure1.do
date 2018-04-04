<<<<<<< HEAD
use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\trade_cost\resultats_finaux\estimTC.dta" , clear
=======


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/Dropbox/trade_cost
	global dirgit ~/Documents/Recherche/Trade Costs/trade_costs_github/trade_costs
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

if "`c(hostname)'" =="LABP112" {
    global dir C:\Users\lpatureau\Dropbox\trade_cost
}

use "$dir/resultats_finaux/estimTC.dta" , clear
>>>>>>> 76f4a6da89bc69c663e87828f07028581571ffaa

sort mode year
replace terme_I = terme_I-1
g terme_I_w= terme_I*val
g terme_A_w= terme_A*val


collapse (sum) terme_A_w terme_I_w val, by(year mode)

drop if year==1989 & mode=="air"

g terme_A = terme_A_w/val*100
g terme_I = terme_I_w/val*100

g tot_costs_estimated= terme_A+terme_I

replace mode = "(a) Air" if mode=="air"
replace mode = "(b) Ves" if mode=="ves"



<<<<<<< HEAD
twoway (line tot_costs_estimated year) (lfit tot_costs_estimated year), ytitle(In %) yscale(range(0 12)) ylabel(0 (3) 12) xtitle(Year) xscale(range(1972 2013)) xlabel(1973 1980 (10) 2000 2013) by(, legend(off)) by(mode)

graph export "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\trade_cost\Figure1.eps", as(eps) replace
=======
twoway (line tot_costs_estimated year) (lfit tot_costs_estimated year), ///
			ytitle("In % of fas price") yscale(range(0 12)) ylabel(0 (3) 12) xtitle(Year) ///
			xscale(range(1973 2013)) xlabel(1974 1980 (10) 2000 2013) by(mode,  note("1989 is ommited for air") legend(off))

graph export "$dirgit/redaction/Figure1_Trend_of_total_TC_by_mode.pdf", as(pdf) replace
>>>>>>> 76f4a6da89bc69c663e87828f07028581571ffaa
