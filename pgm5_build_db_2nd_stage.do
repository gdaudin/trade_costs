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
cd ~/dropbox/trade_cost/results


use estimTC_bycountry.dta, clear

merge m:1 name year using "~/dropbox/trade_cost/data/DoingBusiness_exportscosts.dta"

merge m:1 year using "~/dropbox/trade_cost/data/oil/oil prices, BP energy outlook.dta"




