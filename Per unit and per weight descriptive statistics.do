use "/Users/guillaumedaudin/Documents/Recherche/2013 -- Trade Costs -- local/external_data/hummels.dta", clear

gen multimode = 0
replace multimode = 1 if (ves_val !=0 & ves_val!=.) & (air_val !=0 & air_val !=.) 
tab multimode

gen val = air_val + ves_val
collapse (sum) val, by(multimode)
gen n = 1
reshape wide val, i(n) j(multimode)
generate multimode = val1/(val1+val0)
list

use "/Users/guillaumedaudin/Documents/Recherche/2013 -- Trade Costs -- local/data/hummels_tra.dta", clear

gen multimode = 0
replace multimode = 1 if (ves_val !=0 & ves_val!=.) & (air_val !=0 & air_val !=.) 
tab multimode

gen val = air_val + ves_val
collapse (sum) val, by(multimode)
gen n = 1
reshape wide val, i(n) j(multimode)
generate multimode = val1/(val1+val0)
list

