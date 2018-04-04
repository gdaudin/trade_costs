use "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\trade_cost\resultats_finaux\estimTC.dta" , clear

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



twoway (line tot_costs_estimated year) (lfit tot_costs_estimated year), ytitle(In %) yscale(range(0 12)) ylabel(0 (3) 12) xtitle(Year) xscale(range(1972 2013)) xlabel(1973 1980 (10) 2000 2013) by(, legend(off)) by(mode)

graph export "C:\Users\jerome\Dropbox\Papier_Lise_Guillaume\trade_cost\Figure1.eps", as(eps) replace
