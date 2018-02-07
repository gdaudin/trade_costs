

version 15.1

clear all
*set mem 800m
set matsize 8000
set more off
set maxvar 32767



if "`c(username)'" =="guillaumedaudin" {
	global dir ~/dropbox/trade_cost
}


if "`c(hostname)'" =="LAB0271A" {
	global dir C:\Users\lpatureau\Dropbox\trade_cost
}


if "`c(hostname)'" =="lise-HP" {
	global dir C:\Users\lise\Dropbox\trade_cost
}

cd $dir

capture log using "`c(current_time)' `c(current_date)'"


use "$dir/results/estimTC.dta", clear

gen beta =(terme_I-1)/(terme_A+terme_I-1)
*Si on prend le TC observé, cela ne marche pas !!

histogram beta if year==2000 & mode=="ves", kdensity





