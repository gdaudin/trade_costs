
if "`c(username)'" =="guillaumedaudin" {
	global dir_baseline_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results/baseline"
	global dir_referee1 "~/Documents/Recherche/2013 -- Trade Costs -- local/results/referee1"
	global dir "~/Documents/Recherche/2013 -- Trade Costs -- local"
	global dir_comparaison "~/Documents/Recherche/2013 -- Trade Costs -- local/results/comparaisons_various"
	global dir_temp ~/Downloads/temp_stata
	global dir_results "~/Documents/Recherche/2013 -- Trade Costs -- local/results"
	global dir_redaction  "~/Répertoires Git/trade_costs_git/redaction/JEGeo/revision_JEGeo/revised_article"
	global dir_git  "~/Répertoires Git/trade_costs_git/"
	
	
}


*** Juillet 2020: Lise, tout sur mon OneDrive


/* Fixe Lise P112*/
if "`c(hostname)'" =="LAB0271A" {
	 

	* baseline results sur hummels_tra dans son intégralité
    global dir_baseline_results "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\baseline"
	
		
	* résultats selon méthode référé 1
	global dir_referee1 "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	
	* stocker la comparaison des résultats
	global dir_comparaison "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\comparaison_baseline_referee1"
	
	/* Il me manque pour faire méthode 2 en IV 
	- IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta
	- IV_ref1_y/results_estimTC_`year'_sitc2_3_`mode'.dta
	
	*/
	
	global dir_temp "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
	global dir "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_results "C:\Users\lpatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results"
	 
	 
	 
	}

/* Nouveau portable Lise */
if "`c(hostname)'" =="MSOP112C" {

	* baseline results sur hummels_tra dans son intégralité
    global dir_baseline_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\baseline"
		
	* résultats selon méthode référé 1
	global dir_referee1 "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1"
	
	* stocker la comparaison des résultats
	global dir_comparaison "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results\referee1\comparaison_baseline_referee1"
	
	/* Il me manque pour faire méthode 2 en IV 
	- IV_referee1_panel/results_estimTC_`year'_sitc2_3_`mode'.dta
	- IV_ref1_y/results_estimTC_`year'_sitc2_3_`mode'.dta
	
	*/
	
	global dir_temp "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\temp"
	global dir "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs"
	global dir_results "C:\Users\Ipatureau\OneDrive - Université Paris-Dauphine\Université Paris-Dauphine\trade_costs\results"
	}



set more off






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
				title("`mode'") name("`mode'", replace) ///
				scheme(s1mono)
					
	}
	
	graph combine air ves, rows(1) scheme(s1mono)


end



use "$dir/data/hummels_tra.dta", clear

gen sector = substr(sitc2,1,3)

decompo_var	
		
graph export "$dir_results/Decomposition_variance/Décomposition de la variance à la mimine_brut.png", replace	

keep year mode sd_tot-share_var_inter_secteur


export delimited 	"$dir_results/Decomposition_variance/Décomposition de la variance à la mimine_brut.csv", replace

use "$dir/data/hummels_tra.dta", clear

gen sector = substr(sitc2,1,3)

bys sector: egen c_95_prix_trsp2 = pctile(prix_trsp2),p(95)
bys sector: egen c_05_prix_trsp2 = pctile(prix_trsp2),p(05)
drop if prix_trsp2 < c_05_prix_trsp2 | prix_trsp2 > c_95_prix_trsp2 

decompo_var	

graph export "$dir_results/Decomposition_variance/Décomposition de la variance à la mimine_ss_val_ext.png", replace	
graph export "$dir_redaction/Décomposition de la variance à la mimine_ss_val_ext.png"

keep year mode sd_tot-share_var_inter_secteur


export delimited 	"$dir_results/Decomposition_variance/Décomposition de la variance à la mimine_ss_val_ext.csv", replace








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
