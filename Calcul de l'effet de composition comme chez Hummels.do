
**À partir de regs_rewrite_final.do + figure5_6 chez Hummels
**Qui est là : /Users/guillaumedaudin/dropbox/2013 -- trade_cost -- dropbox/data/Hummels_JEP_data/Table2_Figure5_6

version 15

/*  uses sitcreallysmall_allyears to calculate average freight rates by year */
clear
set more off
capture log close
*set mem 2000m

*global DIR c:\david\decline\finaldata\regs/
cd "~/dropbox/2013 -- trade_cost -- dropbox"


*use ${DIR}sitcreallysmall_allyears

use   "~/dropbox/2013 -- trade_cost -- dropbox/data/hummels_tra.dta"
rename iso2 ctry

drop if substr(sitc2,1,1)=="9"

*cgen manuflag =  real(substr(sitc2,1,1))> 5  

*ren yr year
sort year
/*

merge year using ${DIR}fuelprices
keep if year >=1974
drop _merge

/*  merge with dist, container, gdp data */

sort ctry year
merge ctry year using ${DIR}cleangdp
keep if year >= 1974
drop _merge

sort ctry year
merge ctry year using ${DIR}container70_2003
keep if year >= 1974
drop _merge

sort ctry 
merge ctry using ${DIR}newusmindist
drop _merge du
ren mindist dist


/* deflate data */

ren crude vfuel
ren jet  afuel

foreach var of varlist *val *cha *fuel duty {
replace `var' = `var' / gdpdefl
}

*/

replace ves_wgt = ves_wgt/2.2  if year <=1988
replace air_wgt = air_wgt/2.2  if year <=1988

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

foreach var of varlist aval vval afw vfw afv vfv awv vwv /*afuel vfuel*/ dist /* gdp cont*/ atrade vtrade {
replace `var' = ln(`var')
}


/* generates year dummies, then renames them meaningfully */

tab year, gen(y)
global ct 1

while $ct <=40 {
global nct = $ct + 1973
ren y$ct  y$nct

global ct = $ct + 1
}

gen trend = year - 1973
gen dt = dist * trend
save temp, replace

egen ii = group(sitc2 ctry)
destring(sitc2), gen(s2)

save temp1, replace

/*  first simple regressions */

*log using regs_rewrite_final.log, replace


iis ii
tis year


/* generate output for main figure */
xtreg afv awv y1975-y2013, fe


predict afvhat


xtreg vfv vwv y1975-y2013, fe
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

gen afvhat_wgt = achahat / air_val
gen vfvhat_wgt = vchahat / ves_val

/*  afv and vfv are original data,  average freight

afv_wgt is weighted average freight

afvhat and vfvhat are estimated freight rates, mean values by year

afvhat_wgt... are value weighted averages of the estimates


*/

save predictedrates, replace

*log close


*/


clear
use predictedrates
tsset year, yearly 

label var afvhat  "Fitted ad-valorem rate"
label var vfvhat  "Fitted ad-valorem rate"
label var afv_wgt "Expenditure/import value"
label var vfv_wgt "Expenditure/import value"

tsline afvhat afv_wgt  , ytitle("% of value shipped") /*title("Figure 5 -- Ad-valorem Air Freight")*/ clpattern(solid longdash) xlabel("1974,1984,1994,2004,2014")
quietly capture graph save resultats_finaux/figure5_comme_hummels.gph, replace
quietly capture graph export resultats_finaux/figure5_comme_hummels.pdf, replace

tsline vfvhat vfv_wgt   , ytitle("% of value shipped") /*title("Figure 6 -- Ad-valorem Ocean Freight")*/ clpattern(solid longdash) xlabel("1974,1984,1994,2004,2014")

quietly capture graph save resultats_finaux/figure6_comme_hummels.gph, replace
quietly capture graph export resultats_finaux/figure6_comme_hummels.pdf, replace


********En base 100 en 1974


sort year
gen afvhat_index = (afvhat/afvhat[1])*100 
gen vfvhat_index = (vfvhat/vfvhat[1])*100 
gen afv_wgt_index = (afv_wgt/afv_wgt[1])*100
gen vfv_wgt_index = (vfv_wgt/vfv_wgt[1])*100




label var afvhat_index  "Fitted ad-valorem rate, 100 in 1974"
label var vfvhat_index  "Fitted ad-valorem rate, 100 in 1974"
label var afv_wgt_index "Expenditure/import value, 100 in 1974"
label var vfv_wgt_index "Expenditure/import value, 100 in 1974"

twoway (line  afvhat_index year,  clpattern(solid) color(navy)) ///
	   (line  afv_wgt_index year, clpattern( longdash) color(sienna)  ) ///
	   (lfit  afvhat_index year, clpattern(solid) color(navy) ) ///
	   (lfit  afv_wgt_index year, clpattern( longdash) color(sienna)) ///
	   , /* ytitle("% of value shipped") title("Figure 5 -- Ad-valorem Air Freight")*/ xlabel("1974,1984,1994,2004,2014") legend(stack order (1 2))
quietly capture graph save resultats_finaux/figure5_comme_hummels_base100.gph, replace
quietly capture graph export resultats_finaux/figure5_comme_hummels_base100.pdf, replace

twoway (line  vfvhat_index year,  clpattern(solid) color(navy)) ///
	   (line  vfv_wgt_index year, clpattern( longdash) color(sienna) ) ///
	   (lfit  vfvhat_index year, clpattern(solid) color(navy) ) ///
	   (lfit  vfv_wgt_index year, clpattern( longdash) color(sienna)  ) ///  
	   , /*ytitle("% of value shipped") title("Figure 6 -- Ad-valorem Ocean Freight")*/ xlabel("1974,1984,1994,2004,2014") legend(stack order(1 2))

	   
	   
	   
quietly capture graph save resultats_finaux/figure6_comme_hummels_base100.gph, replace
quietly capture graph export resultats_finaux/figure6_comme_hummels_base100.pdf, replace


 save "/Users/guillaumedaudin/Documents/Recherche/2013 -- Trade Costs -- local/results/effet_composition_hummels.dta", replace


if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
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



save "$dir/results/effet_composition_hummels.dta", replace




erase temp.dta
erase temp1.dta
erase predictedrates.dta


