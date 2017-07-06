

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

cd $dir/results/

use $dir/data/Hummels_tra, clear

rename sitc2 sector

gen prim_manuf = "manuf"
replace prim_manuf="prim" if substr(sector,1,1)=="0" | substr(sector,1,1)=="1" /// 
	| substr(sector,1,1)=="2" | substr(sector,1,1)=="3" | substr(sector,1,1)=="4" /// 
	| substr(sector,1,3)=="667" | substr(sector,1,2)=="68"
	
drop if substr(sector,1,1)=="9"
	
collapse (sum) ves_val air_val, by(year prim_manuf)

reshape wide ves_val air_val, i(year) j(prim_manuf) string 

gen share_prim_ves = ves_valprim / (ves_valprim + ves_valmanuf)
gen share_prim_air = air_valprim / (air_valprim + air_valmanuf)

twoway (line share_prim_ves year) (line share_prim_air year,lpattern(shortdash)), ///
	legend( label(1 "Share of primary trade in the value of total vessel imports") ///
			label(2 "Share of primary trade in the value of total air imports") rows(2))
			
graph export "$dir/resultats_finaux/Share_of_primary.pdf", replace
