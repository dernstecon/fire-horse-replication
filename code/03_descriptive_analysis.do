*=============================================================
* Missing Fire Horse Women — Descriptive & Auxiliary Figures
* Author: David Ernst
*
* Purpose:
*   Produces descriptive and robustness figures that appear in the
*   paper but are not part of the main event-study pipeline.
*   All sections use did_clean_merge.dta as the only input.
*
* Input:  $data/did_clean_merge.dta
*         $data/maternal_statistics1964.dta  (prefecture names)
*
* Required packages: reghdfe, coefplot, esttab (estout)
*
* Outputs (all saved to $output):
*   firehorse_sex_ratio_monthly.pdf      Fig A3 — sex ratio at birth
*   firehorse_ddd_birthyeardeath.pdf     Fig 5  — DDD birth year
*   firehorse_did_reg_DDDbirth.tex       Table B2 — DDD regression
*   prefecture_descriptive1.tex          Table A1 — prefecture stats (I)
*   prefecture_descriptive2.tex          Table A2 — prefecture stats (II)
*   firehorse_did_prefecture_graph.pdf   Fig 4a — prefecture effects
*   firehorse_did_prefecture_birthdrop.pdf  Fig 4b — vs birth drop
*   firehorse_did_urban_rural.pdf        Fig B1 — urban vs rural
*   firehorse_did_didregress_oneyear.pdf Fig B2 — one-year-old deaths
*
* NOTE: firehorse_did_prefecture_map.pdf (Fig 4c) requires the
*       prefecture shapefile and is distributed as a pre-generated
*       static file in output/. It is not reproduced here.
*
* NOTE: The following descriptive figures (Figs A1, A2, A4-A8) are
*       also distributed as pre-generated static files. The code that
*       produced them is not available in this replication package:
*         firehorse_births_mf.pdf
*         firehorse_pregnancies.pdf
*         firehorse_abortion_ratio.pdf  firehorse_abortion_agecohort.pdf
*         firehorse_births_yoy_birth_map.pdf
*         firehorse_births_agecohort.pdf  firehorse_births_firstborn.pdf
*         firehorse_infant_abs.pdf        firehorse_infant_rate.pdf
*         firehorse_infant_neo_abs.pdf    firehorse_infant_neo_rate.pdf
*=============================================================

clear all
set more off

*-------------------------------------------------------------
* Paths — set by 00_master.do; fallback for standalone use
*-------------------------------------------------------------
if "$root" == "" {
	global root   "SET_PATH_HERE"
	global data   "$root/data"
	global temp   "$root/temp"
	global output "$root/output"
	cap mkdir "$output"
	cap mkdir "$temp"
}


*==============================================================
* SECTION 1: Sex ratio at birth by month, 1965 vs 1966
*   Source: firehorse_additional_figs.do
*==============================================================

use "$data/did_clean_merge", clear

keep if year == 1965 | year == 1966
keep if prefecture_id > 0 & prefecture_id < 48

collapse (first) births_male births_female, by(year month2)

gen sex_ratio = 100 * births_female / (births_male + births_female)
label variable sex_ratio "Female share of births (%)"
label variable month2    "Month"

twoway ///
  (connected sex_ratio month2 if year == 1965, ///
    lcolor(navy) mcolor(navy) msymbol(circle) lpattern(solid) ///
    legend(label(1 "1965 (unaffected year)"))) ///
  (connected sex_ratio month2 if year == 1966, ///
    lcolor(cranberry) mcolor(cranberry) msymbol(square) lpattern(dash) ///
    legend(label(2 "1966 (Fire Horse year)"))) , ///
  xlabel(1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" ///
         7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec", angle(45)) ///
  ylabel(48 49 50 51 52) ///
  ytitle("Female share of births (%)") xtitle("") ///
  legend(position(6) row(1))
	graph export "$output/firehorse_sex_ratio_monthly.pdf", replace


*==============================================================
* SECTION 2: DDD — death by birth year vs. death by calendar year
*   Source: fire_horse_an_did.do lines 797–865
*==============================================================

use "$data/did_clean_merge", clear
keep if prefecture_id < 50 & year > 1962 & year < 1969

*--- Save national (prefecture_id==0) bthyear_inf to temp ---
preserve
use "$data/did_clean_merge", clear
drop if year < 1963 | year > 1968
keep if prefecture_id == 0
keep bthyear_inf time prefecture_id female year month2
gen identifier = 1
save "$temp/birthyearDDD", replace
restore

*--- Append and construct DDD outcome ---
append using "$temp/birthyearDDD"
keep if prefecture_id == 0

replace identifier = 0 if identifier == .

gen inf_birthdate_DDD = .
replace inf_birthdate_DDD = bthyear_inf             if identifier == 1
replace inf_birthdate_DDD = inf_birth - bthyear_inf if identifier == 0

*--- Estimate (reghdfe for event-study plot) ---
eststo ddd_birthyear: reghdfe inf_birthdate_DDD identifier##female##b1965.year, ///
  absorb(female##identifier year female#year identifier#year) ///
  noconstant vce(cluster month2)

coefplot, vertical yline(0) ciopts(recast(rcap)) ///
  ytitle("Estimate and 95% Conf. Int.") ///
  omitted baselevels ///
  keep(1.identifier#1.female#1963.year 1.identifier#1.female#1964.year ///
       1.identifier#1.female#1965.year 1.identifier#1.female#1966.year ///
       1.identifier#1.female#1967.year 1.identifier#1.female#1968.year) ///
  coeflabels( ///
    1.identifier#1.female#1963.year = "1963" ///
    1.identifier#1.female#1964.year = "1964" ///
    1.identifier#1.female#1965.year = "1965" ///
    1.identifier#1.female#1966.year = "1966" ///
    1.identifier#1.female#1967.year = "1967" ///
    1.identifier#1.female#1968.year = "1968")
	graph export "$output/firehorse_ddd_birthyeardeath.pdf", replace

*--- Regression table ---
esttab ddd_birthyear ///
using "$output/firehorse_did_reg_DDDbirth.tex", replace ///
s(r2 F N, label("R2" "F" "N") fmt(%9.2f %9.2f %9.0f)) ///
mtitle("I") ///
p nonumbers nostar ///
keep("1.identifier#1.female#1963.year" ///
     "1.identifier#1.female#1964.year" ///
     "1.identifier#1.female#1966.year" ///
     "1.identifier#1.female#1967.year" ///
     "1.identifier#1.female#1968.year") ///
coeflab( ///
  1.identifier#1.female#1963.year "1963" ///
  1.identifier#1.female#1964.year "1964" ///
  1.identifier#1.female#1965.year "1965" ///
  1.identifier#1.female#1966.year "1966" ///
  1.identifier#1.female#1967.year "1967" ///
  1.identifier#1.female#1968.year "1968")


*==============================================================
* SECTION 3: Prefecture descriptive statistics tables
*   Source: fire_horse_an_did.do lines 1050–1154
*==============================================================

use "$data/did_clean_merge", clear

*--- Define storage matrices ---
matrix prefecture_descriptive1 = J(47, 6, .)
matrix colnames prefecture_descriptive1 = ///
  "Population (in thousand)" "Population Density" "Urban Share (\%)" ///
  "Births tot" "Birth/Population" "Female Births/All Births"

matrix prefecture_descriptive2 = J(47, 4, .)
matrix colnames prefecture_descriptive2 = ///
  "Infant mortality tot" "Infant mortality/All Births" ///
  "Female Inf. Mort./Male Inf Mort. 1966" "Female Inf. Mort./Male Inf Mort. 1965"

*--- Get prefecture names as row names ---
preserve
keep if year == 1966
collapse (first) Prefecture (sum) inf_birth, by(prefecture_id)
sort prefecture_id
replace Prefecture = "Japan" if Prefecture == ""
mkmat inf_birth, matrix(prefecture_names) rownames(Prefecture)
restore
local prefecture_names : rowfullnames prefecture_names

matrix rownames prefecture_descriptive1 = `prefecture_names'
matrix rownames prefecture_descriptive2 = `prefecture_names'

*--- Fill matrices prefecture by prefecture ---
forvalue j = 0/46 {

	gen pop_total2 = pop_total / 1000
	replace pop_total2 = round(pop_total2, 1.0)
	sum pop_total2 if prefecture_id == `j' & year == 1965 & month2 == 1 & female == 1
	matrix prefecture_descriptive1[`j'+1, 1] = r(mean)
	drop pop_total2

	gen pop_density_1965 = pop_total / area_tot
	replace pop_density_1965 = round(pop_density_1965, 0.01)
	sum pop_density_1965 if prefecture_id == `j' & year == 1965
	matrix prefecture_descriptive1[`j'+1, 2] = r(mean)
	drop pop_density_1965

	gen urban_share_1965 = (pop_total_urban / pop_total) * 100
	replace urban_share_1965 = round(urban_share_1965, 0.01)
	sum urban_share_1965 if prefecture_id == `j' & year == 1965 & month2 == 1 & female == 1
	matrix prefecture_descriptive1[`j'+1, 3] = r(mean)
	drop urban_share_1965

	sum births_total if prefecture_id == `j' & year == 1964
	matrix prefecture_descriptive1[`j'+1, 4] = r(mean)

	gen birth_ratio = births_total / pop_total
	replace birth_ratio = round(birth_ratio, 0.001)
	sum birth_ratio if prefecture_id == `j' & year == 1964 & month2 == 1 & female == 1
	matrix prefecture_descriptive1[`j'+1, 5] = r(mean)
	drop birth_ratio

	gen births_female_ratio = (births_female / births_total) * 100
	replace births_female_ratio = round(births_female_ratio, 0.01)
	sum births_female_ratio if prefecture_id == `j' & year == 1964 & month2 == 1 & female == 1
	matrix prefecture_descriptive1[`j'+1, 6] = r(mean)
	drop births_female_ratio

	gen infant_mortality = death_0_m + death_0_f
	sum infant_mortality if prefecture_id == `j' & year == 1964
	matrix prefecture_descriptive2[`j'+1, 1] = r(mean)

	gen infant_mortality_rate = infant_mortality / births_total
	sum infant_mortality_rate if prefecture_id == `j' & year == 1964
	matrix prefecture_descriptive2[`j'+1, 2] = r(mean)
	drop infant_mortality_rate

	gen gendered_inf_ratio = (death_0_f / infant_mortality) * 100
	sum gendered_inf_ratio if prefecture_id == `j' & year == 1964
	matrix prefecture_descriptive2[`j'+1, 3] = r(mean)
	sum gendered_inf_ratio if prefecture_id == `j' & year == 1965
	matrix prefecture_descriptive2[`j'+1, 4] = r(mean)
	drop infant_mortality gendered_inf_ratio
}

esttab matrix(prefecture_descriptive1) ///
  using "$output/prefecture_descriptive1.tex", replace ///
  nomtitle nonote noobs

esttab matrix(prefecture_descriptive2) ///
  using "$output/prefecture_descriptive2.tex", replace ///
  nomtitle nonote noobs


*==============================================================
* SECTION 4: Prefecture-level treatment effects scatter plots
*   Source: fire_horse_an_did.do lines 1289–1389
*   NOTE: map figure (prefecture_map.pdf) omitted — requires
*         prefecture shapefile not included in this package.
*==============================================================

use "$data/did_clean_merge", clear

gen did_gen_inf = time * female

*--- Run by-prefecture DiD and store results in matrix ---
matrix gendered_inf_death = J(47, 8, .)

forvalue j = 1/47 {

	*--- cap: some prefectures have insufficient variation; skip gracefully ---
	cap didregress (DiD_inf_0year) (did_gen_inf) ///
	  if prefecture_id != 0 & prefecture_id < 50 & month2 == 1 ///
	  & year > 1962 & year < 1967 & prefecture_id == `j', ///
	  group(female) time(year) vce(cluster prefecture_id)

	if _rc == 0 {
		matrix gendered_inf_death[`j', 1] = r(table)[1, 1]
	}
	else {
		matrix gendered_inf_death[`j', 1] = .
	}

	sum death_0_f if prefecture_id == `j' & year > 1965 & year < 1967
	matrix gendered_inf_death[`j', 2] = r(mean)
	matrix gendered_inf_death[`j', 3] = (gendered_inf_death[`j', 1] / gendered_inf_death[`j', 2]) * 100

	sum births_female if prefecture_id == `j' & year > 1965 & year < 1967
	matrix gendered_inf_death[`j', 4] = r(mean)

	cap sum adherents_buddh if prefecture_id == `j' & year == 1966
	matrix gendered_inf_death[`j', 5] = r(mean)

	sum prefecture_id if prefecture_id == `j'
	matrix gendered_inf_death[`j', 6] = r(mean)

	sum _ID if prefecture_id == `j'
	matrix gendered_inf_death[`j', 7] = r(mean)

	sum birthdrop2 if prefecture_id == `j'
	matrix gendered_inf_death[`j', 8] = r(mean)
}

*--- Convert matrix to dataset ---
clear
svmat gendered_inf_death

rename gendered_inf_death1 excess_inf_female
rename gendered_inf_death2 infant_female_tot
rename gendered_inf_death3 excess_inf_female_pct
rename gendered_inf_death4 female_births
rename gendered_inf_death5 buddh_rate
rename gendered_inf_death6 prefecture_id
rename gendered_inf_death7 _ID
rename gendered_inf_death8 birthdrop

*--- Ensure prefecture_id is integer for merge ---
recast int prefecture_id

label variable excess_inf_female     "Excess female infant mortality"
label variable infant_female_tot     "Female infant deaths"
label variable excess_inf_female_pct "Excess female infant mortality percent"
label variable female_births         "Female births"
label variable birthdrop             "Year over year birth change"

*--- Merge prefecture names ---
merge 1:1 prefecture_id using "$data/maternal_statistics1964"

*--- Scatter: effect vs percent effect ---
scatter excess_inf_female_pct excess_inf_female ///
  if prefecture_id != 47, ms(Oh) mlabel(Prefecture) xline(24, lcolor(red))
	graph export "$output/firehorse_did_prefecture_graph.pdf", replace

*--- Scatter: percent effect vs birth drop ---
scatter excess_inf_female_pct birthdrop ///
  if prefecture_id != 47, ms(Oh) mlabel(Prefecture) ///
  ytitle("Excess female infant mortality percent") || ///
lfit excess_inf_female_pct birthdrop ///
  if prefecture_id != 47, legend(position(6) row(1))
	graph export "$output/firehorse_did_prefecture_birthdrop.pdf", replace


*==============================================================
* SECTION 5: Urban vs. rural infant mortality event study
*   Source: fire_horse_an_did.do lines 1598–1645
*==============================================================

use "$data/did_clean_merge", clear
keep if prefecture_id != 0 & prefecture_id < 50 & year > 1962 & year < 1969

gen inf_birth_rural = .
replace inf_birth_rural = infant_tot_m_rural if female == 0
replace inf_birth_rural = infant_tot_f_rural if female == 1

gen inf_birth_urban = .
replace inf_birth_urban = infant_tot_m_urban if female == 0
replace inf_birth_urban = infant_tot_f_urban if female == 1

reghdfe inf_birth_rural female##b1965.year, ///
  absorb(female year) vce(cluster prefecture_id) noconstant
eststo g1

reghdfe inf_birth_urban female##b1965.year, ///
  absorb(female year) vce(cluster prefecture_id) noconstant
eststo g2

coefplot ///
  (g1, label(Rural)  offset(-0.1) ciopts(recast(rcap))) ///
  (g2, label(Urban)  offset( 0.1) ciopts(recast(rcap))), ///
  vertical yline(0) ciopts(recast(rcap)) ///
  ytitle("Estimate and 95% Conf. Int.") ///
  omitted baselevels ///
  keep(1.female#1963.year 1.female#1964.year 1.female#1965.year ///
       1.female#1966.year 1.female#1967.year 1.female#1968.year) ///
  coeflabels( ///
    1.female#1963.year = "1963" ///
    1.female#1964.year = "1964" ///
    1.female#1965.year = "1965" ///
    1.female#1966.year = "1966" ///
    1.female#1967.year = "1967" ///
    1.female#1968.year = "1968")
	graph export "$output/firehorse_did_urban_rural.pdf", replace


*==============================================================
* SECTION 6: Mortality of one-year-olds — placebo check
*   Source: fire_horse_an_did.do lines 1982–2005
*==============================================================

use "$data/did_clean_merge", clear

gen did_gen_inf = time * female

gen DDD_mf_1 = .
replace DDD_mf_1 = death_1_f if female == 1
replace DDD_mf_1 = death_1_m if female == 0

didregress (DDD_mf_1) (did_gen_inf) ///
  if prefecture_id != 0 & prefecture_id < 50 & month2 == 1 ///
  & year > 1962 & year < 1969, ///
  group(female) time(year) vce(cluster prefecture_id)

estat grangerplot, title("") ytitle("Estimate and 95% Conf. Int.")
	graph export "$output/firehorse_did_didregress_oneyear.pdf", replace


di "=== 03_descriptive_analysis.do complete. All outputs saved to $output ==="
