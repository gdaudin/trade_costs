*version 12


** -------------------------------------------------------------
** Programme pour extraire les résultats de l'estimation Etape 1

** Valeur des coûts de transport
** issus de l'estimation v10, barre à 5% au départ

** 	Septembre 2015 
** -------------------------------------------------------------

clear all
set mem 700m
*set matsize 8000
set more off
*set maxvar 32767


** Programme pour sortir les résultats
capture program drop get_table

program get_table
args year class preci mode

dis "year = " `year'
*dis "classification = " `class'
dis "\# digits= " `preci'
dis "mode = `mode'"

use blouk_`year'_`class'_`preci'_`mode'.dta, clear


* nb obs = variable nbr_obs
* nb de pays dans l'estimation

egen _ = group(iso_o)
sum _
gen nbr_iso_o = r(max)

drop _

* nd de produits
egen _ = group(product)
sum _
gen nbr_prod = r(max)

drop _



dis "******************************"
dis "Estimation NL avec iceberg trade costs ONLY"
sum Rp2_nlI 


dis "Terme iceberg: distribution (moyenne pondérée par `mode'_val)"
sum terme_iceberg  [iweight=`mode'_val]


dis "Terme iceberg: distribution (sans moyenne pondérée)"
sum terme_iceberg

gen terme_nlI_min = r(min)
gen terme_nlI_max = r(max)

dis "******************************"
dis "Estimation non-linéaire"
dis "******************************"

sum Rp2_nl  



dis "Terme A: distribution (moyenne pondérée par `mode'_val)"
sum terme_A  [iweight=`mode'_val]


gen terme_A_min = r(min)
gen terme_A_max = r(max)

dis "Terme A: distribution (sans moyenne pondérée)"
sum terme_A

** nb: on a la valeur moyenne et l'écart-type dans terme_A_mp et terme_A_et resp.

dis "Terme I: distribution (moyenne pondérée par `mode'_val)"
sum terme_I  [iweight=`mode'_val]



dis "Terme I: distribution (sans moyenne pondérée)"
sum terme_I

gen terme_I_min=r(min)
gen terme_I_max=r(max)


# delimit ;
keep nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min terme_A_max terme_I_mp 
	terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nl Rp2_nlI aic_nl aic_nlI logL_nl logL_nlI;

# delimit cr

keep if _n==1



*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace

** Ajouter informations : Année, mode, degré de classification


gen mode = "`mode'"

gen digits = "`preci'_digits"
gen year = "`year'"

order year digits mode nbr_obs nbr_iso_o nbr_prod terme_nlI_mp terme_nlI_med terme_nlI_et terme_nlI_min terme_nlI_max terme_A_mp terme_A_med terme_A_et terme_A_min /*
*/ terme_A_max terme_I_mp terme_I_med terme_I_et terme_I_min terme_I_max Rp2_nlI Rp2_nl aic_nlI aic_nl logL_nlI logL_nl

*save "E:\Lise\BQR_Lille\Hummels\resultats\results_estim_`year'_`class'_`preci'_`mode'", replace
save results_estim_`year'_`class'_`preci'_`mode', replace


end

***********************************
**** SORTIR LES RESULTATS *********

*capture log close
*log using get_table, replace

*** 3 digits, all years ***


* sur le serveur
*cd "C:\Echange\trade_costs\results"

* sur fixe Dauphine
*cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\resultats\results_v10\vessel_3d"

** Fait sur le serveur 28/08/2015

set more off
local mode ves
local preci 3

* pour test
/*
local z 2013
local x sitc2

get_table `z' `x' `preci' `mode'
*/


foreach x in `mode' {

foreach k in `preci' {

*forvalues z = 2013(-1)2012 {
*forvalues z = 2009(-1)2007 {
forvalues z = 2005(-1)1974 {

** Pb sur 2011 et 2010 pour résultats iceberg only
** Pb sur 2006 pas de blouk

*local year = `z'

*capture log close
*log using results_`z'_`k'_`x', replace

get_table `z' sitc2 `preci' `mode'

*log close

}

}
}



***************************************
*** Step 2 - compiler en une même base
***************************************


* sur le serveur
cd "C:\Echange\trade_costs\results"

* sur fixe Dauphine
cd "\\filer.windows.dauphine.fr\home\l\lpatureau\My_Work\Lise\Trade_costs\resultats\raw_results_v10\vessel_3d"

* ---------------------------------
*** Pour 3 digits ***
* ---------------------------------

local preci 3

foreach x in ves {
use results_estim_1974_prod5_sect`preci'_`x', clear


save table_`preci'_`x', replace

}

** Ajouter ensuite les autres années
** Attention à ce stade (28/08/2015) on n'a pas 2006, 2010 et 2011
set more off
local preci 3

#delimit ;
local year 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 
	1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2007 2008 2009 2012 2013 ;

#delimit cr

foreach x in ves {

foreach k in `preci' {

*forvalues z = 1975(1)2006 {
* pb 2002

foreach z in `year' {

use table_`k'_`x', clear
append using results_estim_`z'_prod5_sect`k'_`x'

save table_`k'_`x', replace

}
}
}

** Exporter en excel

local preci 3

foreach x in ves {

foreach k in `preci' {

use table_`k'_`x'
export excel using table_`k'_`x', replace firstrow(varlabels)

}
}


***************************************************
** Suite aux pbs sur 2006, 2010 et 2011 en vessel
** On compile ces trois bases
***************************************************

local preci 3

foreach x in ves {
use results_estim_2006_prod5_sect`preci'_`x', clear


save table_`preci'_`x'_bis, replace

}

** Ajouter ensuite les autres années
** Attention à ce stade (28/08/2015) on n'a pas 2006, 2010 et 2011
set more off
local preci 3


local year 2010 2011

foreach x in ves {

foreach k in `preci' {

*forvalues z = 1975(1)2006 {
* pb 2002

foreach z in `year' {

use table_`k'_`x'_bis, clear
append using results_estim_`z'_prod5_sect`k'_`x'

save table_`k'_`x'_bis, replace

}
}
}

** Exporter en excel

local preci 3

foreach x in ves {

foreach k in `preci' {

use table_`k'_`x'_bis
export excel using table_`k'_`x'_bis, replace firstrow(varlabels)

}
}

