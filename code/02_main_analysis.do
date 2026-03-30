*=============================================================
* Missing Fire Horse Women — Main Replication Analysis
* Author: David Ernst
*
* Purpose:
*   Produces all figures and tables that appear in the main text
*   and appendix of "Missing Fire Horse Women" (JDE submission).
*   Uses LEVELS specification: outcome = infant deaths (count).
*
* Source:  fire_horse_an_did.do (Parts II onwards)
*
* Input:  did_clean_merge.dta  (built by 01_build_dataset.do)
*
* Required packages (install via ssc install <name>):
*   reghdfe, xtevent, honestdid, pretrends, esttab, coefplot
*
* Outputs (all saved to $output, names match firehorse.tex):
*   Figures
*     firehorse_did_honest_mbar.pdf           HonestDiD panel (a)
*     firehorse_did_honest_noeffect.pdf       HonestDiD panel (b)
*     firehorse_did_honest_average.pdf        HonestDiD panel (c)
*     firehorse_did_honest_upper.pdf          HonestDiD panel (d)
*     firehorse_did_xtevent_main.pdf          Fig 2  (main event study)
*     firehorse_did_xtevent_wiggle.pdf        Appendix B3
*     firehorse_did_xtevent_nocities.pdf      Table B1 col II
*     firehorse_did_xtevent_nodecjan.pdf      Table B1 col III
*     firehorse_did_didregress_accident.pdf   Fig 7 (infanticide test)
*     firehorse_did_xtevent_hospital_all_dot.pdf   Fig 8a
*     firehorse_did_xtevent_hospital_adj.pdf       Fig 8b
*     firehorse_did_xtevent_hospital_all_fetal_dot.pdf  Fig 9a
*     firehorse_did_xtevent_hospital_fetal_adj.pdf      Fig 9b
*     firehorse_did_xtevent_hospital_inf_fet_DDD.pdf    Fig 10
*   Tables
*     firehorse_did_reg.tex           Table B1
*     firehorse_did_hospital_reg1.tex Table B3
*     firehorse_did_hospital_reg2.tex Table B4
*=============================================================

clear all
set more off

*--------------------------------------------------------------
* Directory globals — set by 00_master.do; fallback for
* standalone use (edit root path here if running this file directly)
*--------------------------------------------------------------
if "$root" == "" {
	global root   "SET_PATH_HERE"   // <- set this to your local replication_package folder
	global data   "$root/data"
	global temp   "$root/temp"
	global output "$root/output"
	global code   "$root/code"
	cap mkdir "$output"
	cap mkdir "$temp"
}


*==============================================================
* SECTION 1: HonestDiD — sensitivity of β_1966 to parallel
*   trends violations (Rambachan & Roth 2023 + pretrends pkg)
*   Source: fire_horse_an_did.do lines 678–746
*==============================================================

use "$data/did_clean_merge", clear
keep  if prefecture_id!=0 & prefecture_id<50 & year>1962 & year<1969
collapse (first) time (sum) inf_birth, by(year prefecture_id female)

gen treated_gen_inf = 0
replace treated_gen_inf = 1 if female==1
gen did_gen_inf = time*treated_gen_inf

*--- Define Dyear treatment variable (female=1 gets year, else 1965)
gen yearexp2 = 1966 if female == 1
gen byte D = (yearexp2 == 1966)
gen `:type year' Dyear = cond(D, year, 1965)

*--- (a) Sensitivity analysis: M-bar plot
reghdfe inf_birth b1965.Dyear, absorb(female year prefecture_id) cluster(prefecture_id) noconstant
honestdid, pre(1/3) post(4/6) mvec(0(0.5)2)
local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, cached coefplot `plotopts'
	graph export "$output/firehorse_did_honest_mbar.pdf", replace

*--- (b) Trend violation needed for null effect in 1966
reghdfe inf_birth b1965.Dyear, absorb(female year prefecture_id) cluster(prefecture_id) noconstant
pretrends power 0.99, pre(1/2) post(4/6)
matrix sigma = e(V)
matrix beta  = e(b)
matrix beta  = beta[., 1..6]
matrix sigma = sigma[1..6, 1..6]
pretrends, pre(1/2) post(4/6)  b(beta) v(sigma) slope(`r(slope)') legend(position(6) row(1)) ///
xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_honest_noeffect.pdf", replace

*--- (c) Average violation in parallel trends in 1968
reghdfe inf_birth b1965.Dyear, absorb(female year prefecture_id) cluster(prefecture_id) noconstant
pretrends power 0.109, pre(1/2) post(4/6)
matrix sigma = e(V)
matrix beta  = e(b)
matrix beta  = beta[., 1..6]
matrix sigma = sigma[1..6, 1..6]
pretrends, pre(1/2) post(4/6)  b(beta) v(sigma) slope(`r(slope)') legend(position(6) row(1)) ///
xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_honest_average.pdf", replace

*--- (d) Upper confidence bound violation in parallel trends in 1968
reghdfe inf_birth b1965.Dyear, absorb(female year prefecture_id) cluster(prefecture_id) noconstant
pretrends power 0.4, pre(1/2) post(4/6)
matrix sigma = e(V)
matrix beta  = e(b)
matrix beta  = beta[., 1..6]
matrix sigma = sigma[1..6, 1..6]
pretrends, pre(1/2) post(4/6)  b(beta) v(sigma) slope(`r(slope)') legend(position(6) row(1)) ///
xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_honest_upper.pdf", replace


*==============================================================
* SECTION 2: Main xtevent event study — LEVELS specification
*   m1 = main, m2 = excl. cities, m3 = excl. Dec/Jan,
*   m4 = 1964 base, m5 = neonatal, m6 = rural, m7 = urban
*   Source: fire_horse_an_did.do lines 2700–2955
*==============================================================

*--- Helper macro: standard xtevent panel-id setup
* Called repeatedly; each sub-section reloads data fresh to keep levels

*--------------------------------------------------------------
* m1: Main specification — all prefectures, base year 1965
*--------------------------------------------------------------
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963

gen births = .
replace births = births_male if female == 0
replace births = births_female if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth births, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year

gen did_gen_inf = time*female

eststo m1: xtevent inf_birth, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_xtevent_main.pdf", replace


*--------------------------------------------------------------
* Wiggle: least-wiggly confound path (log spec, intentional)
*   The paper's Appendix B3 uses log infant deaths for this plot.
*   Source: fire_horse_an_did.do lines 2740–2753
*--------------------------------------------------------------
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963

gen births = .
replace births = births_male if female == 0
replace births = births_female if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth births, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female

replace inf_birth = (inf_birth) * 1.16 if female == 1 & year == 1966
replace inf_birth = log(inf_birth)

xtevent inf_birth, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Event time") ///
	smpath(line, maxorder(9) maxiter(200) technique(nr 10 dfp 10)) ///
	ytitle("Coefficient") xtitle("Year") xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_xtevent_wiggle.pdf", replace


*--------------------------------------------------------------
* m2: Exclude major cities (Tokyo=13, Osaka=27, Nagoya=23)
*--------------------------------------------------------------
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963

gen births = .
replace births = births_male if female == 0
replace births = births_female if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth births, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female

eststo m2: xtevent inf_birth ///
	if prefecture_id != 13 & prefecture_id != 23 & prefecture_id != 27 ///
	, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_xtevent_nocities.pdf", replace


*--------------------------------------------------------------
* m4: Use 1964 as base period (norm(-2))
*--------------------------------------------------------------
* (uses the same collapsed data still in memory from m2 prep;
*  reload to be safe)
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female

eststo m4: xtevent inf_birth, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id) norm(-2)


*--------------------------------------------------------------
* m3: Exclude December and January months
*--------------------------------------------------------------
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963
drop if month2 == 1 | month2 == 12

gen births = .
replace births = births_male if female == 0
replace births = births_female if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth births, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female

eststo m3: xtevent inf_birth, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_xtevent_nodecjan.pdf", replace


*--------------------------------------------------------------
* m5: Neonatal deaths (below 4 weeks of age)
*--------------------------------------------------------------
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963

gen inf_neo = .
replace inf_neo = infant_neo4_tot_m if female==0
replace inf_neo = infant_neo4_tot_f if female==1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth inf_neo, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female

replace inf_neo = inf_neo/12
replace inf_neo =  . if year == 1968

eststo m5: xtevent inf_neo, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 0) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)


*--------------------------------------------------------------
* m6 and m7: Rural and Urban infant deaths
*--------------------------------------------------------------
use "$data/did_clean_merge", clear
drop if year>1968 | year<1963

gen inf_birth_rural = .
replace inf_birth_rural = infant_tot_m_rural if female == 0
replace inf_birth_rural = infant_tot_f_rural if female == 1

gen inf_birth_urban = .
replace inf_birth_urban = infant_tot_m_urban if female == 0
replace inf_birth_urban = infant_tot_f_urban if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (sum) inf_birth inf_birth_rural inf_birth_urban, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female

replace inf_birth_rural = inf_birth_rural/12
replace inf_birth_urban = inf_birth_urban/12
replace inf_birth_rural =  . if year == 1968
replace inf_birth_urban =  . if year == 1968

eststo m6: xtevent inf_birth_rural, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 0) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)

eststo m7: xtevent inf_birth_urban, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 0) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)


*==============================================================
* SECTION 3: Infanticide falsification test
*   Restricts to causes of death classifiable as deliberate
*   infanticide (external causes, see Appendix C Table C1).
*   Source: fire_horse_an_did.do lines 2900–2933
*==============================================================

use "$data/did_clean_merge", clear

keep  if prefecture_id!=0 & prefecture_id<50 & year>1962 & year<1968
collapse (first) time gender2 infant_cause* (sum) inf_birth, by(year prefecture_id female)

gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year

gen did_gen_inf = time*female

foreach y of varlist infant_cause* {
	replace `y' = 0 if `y'==.
}

gen accident = infant_causeE

eststo accident: xtevent accident, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 0) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967+")
	graph export "$output/firehorse_did_didregress_accident.pdf", replace


*--------------------------------------------------------------
* Table B1: Event Study Regression Coefficients
*   Columns I–VII: main, no-cities, no-dec/jan, 1964-base,
*                  neonatal, rural, urban
*   Source: fire_horse_an_did.do lines 2939–2955
*--------------------------------------------------------------
esttab m1 m2 m3 m4 m5 m6 m7 ///
using "$output/firehorse_did_reg.tex", replace ///
s(r2 F N , ///
label("R2"  "F" "N" ) fmt(%9.2f %9.2f %9.0f)) ///
mtitle("I" "II" "III" "IV" "V" "VI" "VII") ///
p ///
nonumbers ///
nonote ///
nostar ///
drop("_k_eq_m1") ///
coeflab( ///
_k_eq_m3 "1963" ///
_k_eq_m2 "1964"	///
_k_eq_p0 "1966"	///
_k_eq_p1 "1967"	///
_k_eq_p2 "1968"	///
)


*==============================================================
* SECTION 4: Hospitalization DiD — Infant mortality
*   Outcome: at-home infant deaths (female) vs. at-institution
*            infant deaths (male), by prefecture × year
*   Source: fire_horse_an_did.do lines 2963–3154
*==============================================================

use "$data/did_clean_merge", clear

replace inf_death_midwife       = 0 if inf_death_midwife       == . & year>1962 & year < 1969
replace inf_death_midwife_rural = 0 if inf_death_midwife_rural == . & year>1962 & year < 1969
replace inf_death_midwife_urban = 0 if inf_death_midwife_urban == . & year>1962 & year < 1969

gen did_gen_inf = time*female

gen hospital_home_inf = 0
replace hospital_home_inf = inf_death_hospital + inf_death_clinic + inf_death_midwife if female == 0
replace hospital_home_inf = inf_death_home if female == 1

drop if year>1968 | year<1963

gen births = .
replace births = births_male if female == 0
replace births = births_female if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (mean) hospital_home_inf births, by(year prefecture_id female)
gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female


*--- Raw event study (not in main paper, used for context)
xtevent hospital_home_inf, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_xtevent_hospital_all.pdf", replace


*--- Trend imputation: linear (x=1) and quadratic (x=2)
xtevent hospital_home_inf, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)

matrix coefficient = e(b)
matrix list coefficient

forvalues x = 1/2 {
preserve
clear
set obs 6
gen year = 1963 + _n - 1
gen x = cond(_n == 1, -2, cond(_n == 2, -1, cond(_n == 3, 0, cond(_n == 4, 1, cond(_n == 5, 2, 3)))))
gen trend = cond(_n == 3, 0, .)
replace trend = coefficient[1,1] if year == 1963
replace trend = coefficient[1,2] if year == 1964
replace trend = coefficient[1,5] if year == 1968
gen x2 = x^`x'
reg trend x x2
predict fitted_trend
list year x trend fitted_trend if missing(trend)
replace trend = fitted_trend if year == 1966
replace trend = fitted_trend if year == 1967
mkmat trend, matrix(trend_`x')
restore
}

matrix list trend_2

gen trend_n = cond(_n == 1, -3, cond(_n == 2, -2, cond(_n == 3, -1, cond(_n == 4, 0, cond(_n == 5, 1, cond(_n == 6, 2, .))))))
svmat trend_1
svmat trend_2

label define trend_1 0 "linear" 1 "linear"
gen trend_1_label = cond(_n == 1, -3, cond(_n == 2, -2, cond(_n == 3, -1, cond(_n == 4, 0, cond(_n == 5, 1, cond(_n == 6, 2, .))))))
label values trend_1_label trend_1
label define trend_2 0 "squared" 1 "squared"
gen trend_2_label = cond(_n == 1, -3, cond(_n == 2, -2, cond(_n == 3, -1, cond(_n == 4, 0, cond(_n == 5, 1, cond(_n == 6, 2, .))))))
label values trend_2_label trend_2


*--- Plot with extrapolated trend dots
eststo hospital1: xtevent hospital_home_inf, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+") ///
	addplots(scatter trend_11 trend_n if trend_n == 0 | trend_n == 1 | trend_n == 0.4, ///
	msize(2) color(red) symbol(triangle_hollow)  mlabel(trend_1_label) mlabc(red)  || ///
	scatter trend_21 trend_n if trend_n == 0 | trend_n == 1, ///
	msize(2) color(green) symbol(diamond_hollow)  mlabel(trend_2_label) mlabc(green))
	graph export "$output/firehorse_did_xtevent_hospital_all_dot.pdf", replace


*--- Generate trend-adjusted outcomes
gen hospital_home_inf_adj_1 = .
forvalues k = 1/6 {
	replace hospital_home_inf_adj_1 = hospital_home_inf - trend_1[`k',1] if year == 1962 + `k' & female==1
}
replace hospital_home_inf_adj_1 = hospital_home_inf if female==0

gen hospital_home_inf_adj_2 = .
forvalues k = 1/6 {
	replace hospital_home_inf_adj_2 = hospital_home_inf - trend_2[`k',1] if year == 1962 + `k' & female==1
}
replace hospital_home_inf_adj_2 = hospital_home_inf if female==0


*--- Adjusted coefficient plot
eststo hospital1: reghdfe hospital_home_inf female##b1965.year, ///
	absorb(female year) vce(cluster prefecture_id) noconstant

eststo hospital2: reghdfe hospital_home_inf_adj_1 female##b1965.year, ///
	absorb(female year) vce(cluster prefecture_id) noconstant
eststo g1

eststo hospital3: reghdfe hospital_home_inf_adj_2 female##b1965.year, ///
	absorb(female year) vce(cluster prefecture_id) noconstant
eststo g2

coefplot ///
	(g1, label(linear) msize(1.5) symbol(triangle_hollow) color(red) offset(-0.1) ciopts(recast(rcap)lcolor(red))) ///
	(g2, label(squared) symbol(diamond_hollow) color(green) offset(0.1) ciopts(recast(rcap)lcolor(green))), ///
	vertical yline(0) ciopts(recast(rcap)) ytitle("Estimate and 95% Conf. Int.") ///
	omitted baselevels ///
	legend(position(6) row(1)) ///
	keep( 1.female#1963.year 1.female#1964.year 1.female#1965.year ///
	 1.female#1966.year 1.female#1967.year 1.female#1968.year) ///
	coeflabels( ///
	1.female#1963.year = "1963+" ///
	1.female#1964.year = "1964" ///
	1.female#1965.year = "1965" ///
	1.female#1966.year = "1966" ///
	1.female#1967.year = "1967" ///
	1.female#1968.year = "1968+")
	graph export "$output/firehorse_did_xtevent_hospital_adj.pdf", replace


*--- Save adjusted infant data for DDD (Section 6)
preserve
keep hospital_home_inf_adj_1 hospital_home_inf_adj_2 time prefecture_id female year
gen identifier = 1
save "$temp/hospital_gender_fetal_DDD", replace
restore


*==============================================================
* SECTION 5: Hospitalization DiD — Fetal (spontaneous) mortality
*   Outcome: at-home spontaneous fetal deaths (used as the
*            cohort-effect control in the DDD).
*   Source: fire_horse_an_did.do lines 3163–3354
*==============================================================

use "$data/did_clean_merge", clear

gen did_gen_inf = time*female
gen hospital_home_fet = 0
replace hospital_home_fet = fetal_hos_sp + fetal_clin_sp + fetal_mid_sp if female == 0
replace hospital_home_fet = fetal_home_sp if female == 1

drop if year>1968 | year<1963

gen births = .
replace births = births_male if female == 0
replace births = births_female if female == 1

drop if prefecture_id==0
drop if prefecture_id>47
collapse (first) time gender2 fetal_sp (mean) hospital_home_fet births death_0_f _ID, by(year prefecture_id female)

gen prefec_month_gender2 = string(prefecture_id) + "_" + gender2
encode prefec_month_gender2, gen(prefec_month_gender)
sort year prefec_month_gender
xtset  prefec_month_gender year
gen did_gen_inf = time*female


*--- Raw event study
xtevent hospital_home_fet, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+")
	graph export "$output/firehorse_did_xtevent_hospital_fetal_all.pdf", replace


*--- Trend imputation for fetal: use 1963, 1964, 1967, 1968
*   (1967 also imputed since fetal effect should not extend past 1966)
xtevent hospital_home_fet, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)

matrix coefficient = e(b)
matrix list coefficient

forvalues x = 1/2 {
preserve
clear
set obs 6
gen year = 1963 + _n - 1
gen x = cond(_n == 1, -2, cond(_n == 2, -1, cond(_n == 3, 0, cond(_n == 4, 1, cond(_n == 5, 2, 3)))))
gen trend = cond(_n == 3, 0, .)
replace trend = coefficient[1,1] if year == 1963
replace trend = coefficient[1,2] if year == 1964
replace trend = coefficient[1,4] if year == 1967
replace trend = coefficient[1,5] if year == 1968
gen x2 = x^`x'
reg trend x x2 if year != 1963
predict fitted_trend
list year x trend fitted_trend if missing(trend)
replace trend = fitted_trend if year == 1966
mkmat trend, matrix(trend_`x')
restore
}

matrix list trend_2

gen trend_n = cond(_n == 1, -3, cond(_n == 2, -2, cond(_n == 3, -1, cond(_n == 4, 0, cond(_n == 5, 1, cond(_n == 6, 2, .))))))
svmat trend_1
svmat trend_2

label define trend_1 0 "linear" 1 "linear"
gen trend_1_label = cond(_n == 1, -3, cond(_n == 2, -2, cond(_n == 3, -1, cond(_n == 4, 0, cond(_n == 5, 1, cond(_n == 6, 2, .))))))
label values trend_1_label trend_1
label define trend_2 0 "squared" 1 "squared"
gen trend_2_label = cond(_n == 1, -3, cond(_n == 2, -2, cond(_n == 3, -1, cond(_n == 4, 0, cond(_n == 5, 1, cond(_n == 6, 2, .))))))
label values trend_2_label trend_2


*--- Plot with trend dots (only 1966 imputed for fetal)
xtevent hospital_home_fet, panelvar(prefec_month_gender) timevar(year) policyvar(did_gen_inf) ///
	window(-2 1) impute(nuchange) reghdfe addabsorb(prefecture_id female year) vce(cluster prefecture_id)
xteventplot, ytitle("Coefficient") xtitle("Year") ///
	xlabel(-3 "1963+" -2 "1964" -1 "1965" 0 "1966" 1 "1967" 2 "1968+") ///
	addplots(scatter trend_11 trend_n if trend_n == 0, ///
	msize(2) color(red) symbol(triangle_hollow)  mlabel(trend_1_label) mlabc(red)  || ///
	scatter trend_21 trend_n if trend_n == 0, ///
	msize(2) color(green) symbol(diamond_hollow)  mlabel(trend_2_label) mlabc(green))
	graph export "$output/firehorse_did_xtevent_hospital_all_fetal_dot.pdf", replace


*--- Generate trend-adjusted fetal outcomes
gen hospital_home_fet_adj_1 = .
forvalues k = 1/6 {
	replace hospital_home_fet_adj_1 = hospital_home_fet - trend_1[`k',1] if year == 1962 + `k' & female==1
}
replace hospital_home_fet_adj_1 = hospital_home_fet if female==0

gen hospital_home_fet_adj_2 = .
forvalues k = 1/6 {
	replace hospital_home_fet_adj_2 = hospital_home_fet - trend_2[`k',1] if year == 1962 + `k' & female==1
}
replace hospital_home_fet_adj_2 = hospital_home_fet if female==0


*--- Adjusted fetal coefficient plot
eststo hospital4: reghdfe hospital_home_fet female##b1965.year, ///
	absorb(female year) vce(cluster prefecture_id) noconstant

eststo hospital5: reghdfe hospital_home_fet_adj_1 female##b1965.year, ///
	absorb(female year) vce(cluster prefecture_id) noconstant
eststo g1

eststo hospital6: reghdfe hospital_home_fet_adj_2 female##b1965.year, ///
	absorb(female year) vce(cluster prefecture_id) noconstant
eststo g2

coefplot ///
	(g1, label(linear) msize(1.5) symbol(triangle_hollow) color(red) offset(-0.1) ciopts(recast(rcap)lcolor(red))) ///
	(g2, label(squared) symbol(diamond_hollow) color(green) offset(0.1) ciopts(recast(rcap)lcolor(green))), ///
	vertical yline(0) ciopts(recast(rcap)) ytitle("Estimate and 95% Conf. Int.") ///
	omitted baselevels ///
	legend(position(6) row(1)) ///
	keep( 1.female#1963.year 1.female#1964.year 1.female#1965.year ///
	 1.female#1966.year 1.female#1967.year 1.female#1968.year) ///
	coeflabels( ///
	1.female#1963.year = "1963+" ///
	1.female#1964.year = "1964" ///
	1.female#1965.year = "1965" ///
	1.female#1966.year = "1966" ///
	1.female#1967.year = "1967" ///
	1.female#1968.year = "1968+")
	graph export "$output/firehorse_did_xtevent_hospital_fetal_adj.pdf", replace


*==============================================================
* SECTION 6: Sex-selective neglect DDD
*   Combines infant + fetal hospital data to isolate the
*   sex-selective component φ_1966 = π_1966 − ω_1966 × τ_1966
*   Scaling factor 0.3149076 from ratio of fetal to infant deaths.
*   Source: fire_horse_an_did.do lines 3360–3454
*==============================================================

append using "$temp/hospital_gender_fetal_DDD"
replace identifier = 0 if identifier == .

*--- DDD variable construction (linear and quadratic)
gen gen_inf_fet_DDD_1 = .
replace  gen_inf_fet_DDD_1 = hospital_home_fet_adj_1 * 0.3149076 if identifier == 0
replace  gen_inf_fet_DDD_1 = hospital_home_inf_adj_1             if identifier == 1

gen gen_inf_fet_DDD_2 = .
replace  gen_inf_fet_DDD_2 = hospital_home_fet_adj_2 * 0.3149076 if identifier == 0
replace  gen_inf_fet_DDD_2 = hospital_home_inf_adj_2              if identifier == 1


*--- DDD event-study regressions
eststo hospital7: reghdfe gen_inf_fet_DDD_1 identifier##female##b1965.year ///
	if year>1962 & year<1969, ///
	absorb(female##identifier year female#year identifier#year) noconstant vce(cluster prefecture_id)
matrix list e(b)
eststo g1

eststo hospital8: reghdfe gen_inf_fet_DDD_2 identifier##female##b1965.year ///
	if year>1962 & year<1969, ///
	absorb(female##identifier year female#year identifier#year) noconstant vce(cluster prefecture_id)
matrix list e(b)
eststo g2


*--- DDD coefficient plot
coefplot ///
	(g1, label(linear) msize(1.5) symbol(triangle_hollow) color(red) offset(-0.1) ciopts(recast(rcap)lcolor(red))) ///
	(g2, label(squared) symbol(diamond_hollow) color(green) offset(0.1) ciopts(recast(rcap)lcolor(green))), ///
	vertical yline(0) ciopts(recast(rcap)) ytitle("Estimate and 95% Conf. Int.") ///
	omitted baselevels ///
	legend(position(6) row(1)) ///
	keep( 1.identifier#1.female#1963.year 1.identifier#1.female#1964.year ///
	1.identifier#1.female#1965.year 1.identifier#1.female#1966.year ///
	 1.identifier#1.female#1967.year 1.identifier#1.female#1968.year) ///
	coeflabels( ///
	1.identifier#1.female#1963.year = "1963+" ///
	1.identifier#1.female#1964.year = "1964" ///
	1.identifier#1.female#1965.year = "1965" ///
	1.identifier#1.female#1966.year = "1966" ///
	1.identifier#1.female#1967.year = "1967" ///
	1.identifier#1.female#1968.year = "1968+")
	graph export "$output/firehorse_did_xtevent_hospital_inf_fet_DDD.pdf", replace


*--------------------------------------------------------------
* Table B3: Hospital regression coefficients (infant + fetal)
*   Columns I–III: raw infant, linear-adj infant, quad-adj infant
*   Columns IV–VI: raw fetal,  linear-adj fetal,  quad-adj fetal
*   Source: fire_horse_an_did.do lines 3416–3431
*--------------------------------------------------------------
esttab hospital1 hospital2 hospital3 ///
hospital4 hospital5 hospital6  ///
using "$output/firehorse_did_hospital_reg1.tex", replace ///
s(r2 F N , ///
fmt(%9.2f %9.2f %9.0f)) ///
mtitle("I" "II" "III" "IV" "V" "VI" ) ///
p ///
nonumbers nonote ///
nostar ///
keep(1.female#1963.year 1.female#1964.year  ///
 1.female#1966.year 1.female#1967.year 1.female#1968.year) ///
coeflab(1.female#1963.year "1963"  ///
1.female#1964.year "1964"  ///
1.female#1966.year "1966"  ///
1.female#1967.year "1967"  ///
1.female#1968.year "1968"   )


*--------------------------------------------------------------
* Table B4: DDD regression (sex-selective neglect)
*   Columns I–II: linear-adj DDD, quadratic-adj DDD
*   Source: fire_horse_an_did.do lines 3437–3454
*--------------------------------------------------------------
esttab hospital7 hospital8 ///
using "$output/firehorse_did_hospital_reg2.tex", replace ///
s(r2 F N , ///
fmt(%9.2f %9.2f %9.0f)) ///
mtitle("I" "II") ///
p ///
nonumbers nonote ///
nostar ///
keep(1.identifier#1.female#1963.year  1.identifier#1.female#1964.year ///
1.identifier#1.female#1966.year 1.identifier#1.female#1967.year ///
1.identifier#1.female#1968.year) ///
coeflab( ///
1.identifier#1.female#1963.year "1963" ///
1.identifier#1.female#1964.year "1964" ///
1.identifier#1.female#1965.year "1965" ///
1.identifier#1.female#1966.year "1966" ///
1.identifier#1.female#1967.year "1967" ///
1.identifier#1.female#1968.year "1968")


di "=== 02_main_analysis.do complete. All outputs saved to $output ==="
