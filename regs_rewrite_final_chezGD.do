
****Ceci est la régression d'Hummels pour enlever l'effet de composition réécrit pour correspondre à ce que nous faisons.
****Et en fait, c'est très bizarre.
/*  uses sitcreallysmall_allyears to calculate average freight rates by year */
clear
set more off
capture log close
set mem 2000m

*global DIR c:\david\decline\finaldata\regs/

*use ${DIR}sitcreallysmall_allyears

use "/Users/guillaumedaudin/dropbox/2013 -- trade_cost -- dropbox/data/Hummels_JEP_data/Table2_Figure5_6/sitcreallysmall_allyears.dta"


drop if substr(sitc2,1,1)=="9"

gen manuflag =  real(substr(sitc2,1,1))> 5  

ren yr year
sort year


*merge year using ${DIR}fuelprices
*keep if year >=1974
*drop _merge

/*  merge with dist, container, gdp data */

sort ctry year
*merge ctry year using ${DIR}cleangdp
*keep if year >= 1974
*drop _merge

sort ctry year
*merge ctry year using ${DIR}container70_2003
*keep if year >= 1974
*drop _merge

sort ctry 
*merge ctry using ${DIR}newusmindist
*drop _merge du
*ren mindist dist


/* deflate data */

*ren crude vfuel
*ren jet  afuel

*foreach var of varlist *val *cha *fuel duty {
*replace `var' = `var' / gdpdefl
*}

*replace ves_wgt = ves_wgt/2.2  if year <=1988
*replace air_wgt = air_wgt/2.2  if year <=1988

gen afw = air_cha / air_wgt
gen vfw = ves_cha / ves_wgt
gen afv = air_cha / air_val
gen vfv = ves_cha / ves_val
gen awv = air_wgt / air_val
gen vwv = ves_wgt / ves_val
gen tar = 1+ duty/con_val
gen aval = air_val
gen vval = ves_val


egen atrade = sum(aval), by(ctry year)
egen vtrade = sum(vval), by(ctry year)
*gen cont = teu/vtrade


/* clean up out of bound observations */

gen airflag = (air_val > 0) & (awv > 100 | afv > 2)
gen vesflag = (ves_val > 0) & vfv > 1
drop if airflag == 1
drop if vesflag == 1
drop airflag vesflag



/* take logs */

foreach var of varlist aval vval afw vfw afv vfv awv vwv /*afuel vfuel dist gdp cont*/ atrade vtrade {
replace `var' = ln(`var')
}


/* generates year dummies, then renames them meaningfully */

tab year, gen(y)
global ct 1

while $ct <=31 {
global nct = $ct + 1973
ren y$ct  y$nct

global ct = $ct + 1
}

gen trend = year - 1973
*gen dt = dist * trend
*save temp, replace

egen ii = group(sitc2 ctry)
destring(sitc2), gen(s2)

*save temp1, replace

/*  first simple regressions */

* log using regs_rewrite_final.log, replace


iis ii
tis year




/* generate output for main figure */
xtreg afv awv y1975-y2004, fe
predict afvhat


xtreg vfv vwv y1975-y2004, fe
predict vfvhat

/*

/* table regressions */

xtreg vfv vwv vfuel cont, fe
xtreg vfv vwv vfuel , fe


/* redo with sitc2 fixed effects */
iis s2
tis year


xtreg vfv vwv vfuel cont dist, fe
xtreg vfv vwv vfuel dist, fe

xtreg afv awv afuel dist, fe

xtreg afv awv afuel dist trend dt, fe

*/

/* collapse data down to something useful */

foreach var of varlist afvhat vfvhat afv vfv {
replace `var' = exp(`var')
}

gen achahat = afvhat*air_val
gen vchahat = vfvhat*ves_val

collapse (mean) afvhat vfvhat afv vfv (sum) air_val ves_val air_cha ves_cha achahat vchahat, by(year)

gen afv_wgt = air_cha/air_val
gen vfv_wgt = ves_cha / ves_val

*gen afvhat_wgt = achahat / air_val
*gen vfvhat_wgt = vchahat / ves_val

/*  afv and vfv are original data,  average freight

afv_wgt is weighted average freight

afvhat and vfvhat are estimated freight rates, mean values by year

afvhat_wgt... are value weighted averages of the estimates


*/
 graph twoway (line vfv_wgt year) (line vfvhat year)


*save predictedrates, replace

log close


*/



