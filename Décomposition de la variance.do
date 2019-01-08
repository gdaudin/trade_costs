
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
cd $dir

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767






capture program drop decompo_var
program decompo_var


	egen sd_tot=sd(prix_trsp), by(year mode)
	gen var_tot=sd_tot^2
	
	

	foreach dim in pays produit secteur {
	
		if "`dim'"=="pays"    egen sd_intra_`dim'=sd(prix_trsp), by(year mode iso_o)
		if "`dim'"=="produit" egen sd_intra_`dim'=sd(prix_trsp), by(year mode sitc2)
		if "`dim'"=="secteur" egen sd_intra_`dim'=sd(prix_trsp), by(year mode sector)
		
		gen var_intra_`dim'=sd_intra_`dim'^2
		egen var_intra_`dim'_moy=mean(var_intra_`dim'), by(year mode)
		gen share_var_inter_`dim' = 1-var_intra_`dim'_moy/var_tot
	}
			
	
	bys year mode: keep if _n==1
	
	foreach mode in air ves {
	
	if "`mode'"== "air" local title_graph  "Air"
	if "`mode'"== "ves" local title_graph  "Ves"
	
		twoway (line  share_var_inter_produit year) (line  share_var_inter_secteur year) (line  share_var_inter_pays year) /*(line  product_country_variance year)*/ ///
				if mode=="`mode'", ///
				legend(label(1 "Share of between-product variance") label(3 "Share of between-country variance") label(2 "Share of between-sector variance")  /*label(3 "Share of between product x country variance")*/ ///
				rows(3)) ///
				title("`mode'") name("`mode'", replace)
					
	}
	
	graph combine air ves, rows(2)	


end




use "$dir/database/hummels_tra.dta", clear

gen sector = substr(sitc2,1,3)

decompo_var	
		
graph export "$dir/results/Décomposition de la variance/Décomposition de la variance à la mimine_brut.png", replace	

keep year mode sd_tot-share_var_inter_secteur


export delimited 	"$dir/results/Décomposition de la variance/Décomposition de la variance à la mimine_brut.csv", replace

use "$dir/database/hummels_tra.dta", clear

gen sector = substr(sitc2,1,3)

bys sector: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys sector: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 

decompo_var	

graph export "$dir/results/Décomposition de la variance/Décomposition de la variance à la mimine_ss_val_ext.png", replace	

keep year mode sd_tot-share_var_inter_secteur


export delimited 	"$dir/results/Décomposition de la variance/Décomposition de la variance à la mimine_ss_val_ext.csv", replace








/*Décidemment, je n'arrive pas à réconcilier les différentes méthodes.... :(

*******Test

use "$dir/data/hummels_tra.dta", clear
encode iso_o, gen(iso_o_num)
encode sitc2, gen(sitc2_num)
areg prix_trsp  if mode=="ves" & year==1974, absorb(sitc2_num)


		




**Méthode xtreg

foreach mode in air ves {
	
	use "$dir/data/hummels_tra.dta", clear
	keep if mode=="`mode'"
		
	encode iso_o, gen(iso_o_num)
	encode sitc2, gen(sitc2_num)
	gen iso_sitc = iso_o+sitc2
	egen iso_sitc_num = group(iso_sitc)
	
	xtreg prix_trsp  if year==1974, i(sitc2_num)
	local rho_sitc=e(rho)
	xtreg prix_trsp  if year==1974, i(iso_o_num)
	local rho_iso=e(rho)
	capture xtreg prix_trsp  if year==1974, i(iso_sitc_num)
	local rho_iso_sitc=e(rho)
	
	matrix ana_var = (1974,`rho_sitc',`rho_iso',`rho_iso_sitc')
	
	mat colnames ana_var = year product_variance country_variance product_country_variance
	
	foreach y of num 1975(1)2013 {
		xtreg prix_trsp  if year==`y', i(sitc2_num)
		local rho_sitc=e(rho)
		xtreg prix_trsp  if year==`y', i(iso_o_num)
		local rho_iso=e(rho)
		capture xtreg prix_trsp  if year==`y', i(iso_sitc_num)
		local rho_iso_sitc=e(rho)
		
		matrix A = (`y',`rho_sitc',`rho_iso',`rho_iso_sitc')
		matrix ana_var = ana_var \ A
	}
		
	matrix list ana_var

	clear
	
	svmat ana_var, names (col)
	
	twoway (line  product_variance year) (line  country_variance year) /*(line  product_country_variance year)*/, ///
		legend(label(1 "Share of between product variance") label(2 "Share of between country variance") /*label(3 "Share of between product x country variance")*/ ///
		rows(2)) ///
		title("`mode'") name("`mode'", replace)
		
	gen mode = "`mode'"
	save "$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg_`mode'.dta", replace
		
	
}

use "$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg_air.dta", clear
append using "$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg_ves.dta", replace
erase "$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg_air.dta"
erase "$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg_ves.dta"


	
graph combine air ves, rows(2)
graph export "$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg.png", replace

export delimited 	"$dir/results/Décomposition de la variance/Décomposition de la variance à la xtreg.csv", replace
