*************************************************
* Programme 5 : Programme pour constuire la bdd permettant ensuite d'estimer les déterminants des TC
*NB : il y a un programme sur le serveur pour rapatrier les données pertinentes à partir des blouks
*************************************************

version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



* sur mon laptop
*cd "C:\Lise\trade_costs\Hummels\resultats\new"
* sur le serveur
*cd "C:\Echange\trade_costs\results"
***Je change le working directory en quelque chose que nous pouvons utiliser tous les deux
*cd ~/dropbox/trade_cost/results

*** ne marche pas donc je personnalise
cd "C:\Users\lpatureau\Dropbox\trade_cost\results"


use estimTC_bycountry.dta, clear

*merge m:1 name year using "~/dropbox/trade_cost/data/DoingBusiness_exportscosts.dta"

*merge m:1 year using "~/dropbox/trade_cost/data/oil/oil prices, BP energy outlook.dta"

* Ajouter la variable "export cost formality"
merge m:1 name year using "C:\Users\lpatureau\Dropbox\trade_cost\data\DoingBusiness_exportscosts.dta"


/*
** pb avec cette version de stata, ai le message d'erreur suivant

dta too modern
    File C:\Users\lpatureau\Dropbox\trade_cost\data\DoingBusiness_exportscosts.dta is from a more recent version of Stata.  Type update query to
    determine whether a free update of Stata is available, and browse http://www.stata.com/ to determine if a new version is available.
r(610);


*/

** te laisse faire...
