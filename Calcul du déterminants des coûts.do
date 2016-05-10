*** Pgm pour extraire la variable Vk de la Maritime Trnasport Costs database


**  traitement_mtc.do

*** GD LP Dec 23/12/2106


version 12

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767


if ("`c(hostname)'" =="MacBook-Pro-Lysandre.local") global dir ~/dropbox/trade_cost



if ("`c(hostname)'" =="LAB0271A") 	global dir C:\Users\lpatureau\Dropbox\trade_cost


if ("`c(hostname)'" =="lise-HP") global dir C:\Users\lise\Dropbox\trade_cost



