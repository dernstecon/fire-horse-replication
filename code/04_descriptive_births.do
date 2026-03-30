*=============================================================
* Missing Fire Horse Women — Births and Vital Statistics Descriptives
* Author: David Ernst
*
* Purpose:
*   Produces descriptive figures on births, infant/neonatal mortality,
*   abortion, and pregnancies using national vital statistics summary
*   data and the prefecture-level source tables.
*
* Inputs (all in $data):
*   vital_summary.dta             <- national + prefecture vital stats
*   prefecture_shape/             <- prefecture map coordinate files
*   table_33.dta                  <- monthly infant/neonatal deaths
*   table_4.dta                   <- monthly births by prefecture/sex
*   table_6_trim.dta              <- births by maternal age cohort
*   table_50_trim.dta             <- national abortions by age cohort
*
* Outputs (saved to $output):
*   firehorse_births_mf.pdf           Fig A1 - male/female births
*   firehorse_births_agecohort.pdf    Fig A  - births by age cohort
*   firehorse_births_firstborn.pdf    Fig A  - firstborn share
*   firehorse_pregnancies.pdf         Fig A  - total pregnancies
*   firehorse_abortion_ratio.pdf      Fig A  - abortion/birth ratio
*   firehorse_abortion_agecohort.pdf  Fig A  - abortions by age cohort
*   firehorse_infant_abs.pdf          Fig A  - infant deaths (absolute)
*   firehorse_infant_rate.pdf         Fig A  - infant mortality rate
*   firehorse_infant_neo_abs.pdf      Fig A  - neonatal deaths (absolute)
*   firehorse_infant_neo_rate.pdf     Fig A  - neonatal mortality rate
*   firehorse_births_yoy_birth_map.pdf Fig A1 - birth drop map
*=============================================================

*--- Standalone path (overridden by 00_master.do when run as part of pipeline)
if "$root" == "" {
	global root    "SET_PATH_HERE"
	global data    "$root/data"
	global temp    "$root/temp"
	global output  "$root/output"
}

cap mkdir "$output"
cap mkdir "$temp"


*==============================================================
* SECTION 1: National vital statistics figures
*   Source: vital_summary.dta (Japan national totals, 1960–1970)
*   Produces: births_mf, births_firstborn, pregnancies,
*             abortion_ratio, infant_abs, infant_rate
*==============================================================

use "$data/vital_summary", clear

*--- Keep only Japan national rows with years in analysis window
keep if name == "Japan" & year >= 1960 & year <= 1970

*--- Generate derived variables
gen male_infd_rate  = infantdeathmale  / birthsmale   * 1000
gen female_infd_rate = infantdeathfemale / birthsfemale * 1000
label variable male_infd_rate   "Male infant mortality (per 1,000 births)"
label variable female_infd_rate "Female infant mortality (per 1,000 births)"

gen abortionrate = abortion / births
label variable abortionrate "Abortion/birth ratio"

gen pregnancy_tot = births + abortion
label variable pregnancy_tot "Total pregnancies (births + abortions)"

gen firstbornrate = firstborn / births
label variable firstbornrate "First-born share of births"

label variable birthsmale   "Male births"
label variable birthsfemale "Female births"
label variable infantdeathmale   "Male infant deaths"
label variable infantdeathfemale "Female infant deaths"

*--- Fig: Male and female live births (Japan, 1960–1970)
twoway (line birthsmale   year, lcolor(navy)   lwidth(medthick)) ///
       (line birthsfemale year, lcolor(maroon)  lwidth(medthick) lpattern(dash)), ///
       legend(size(*1.2) pos(6) row(1)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Live births", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_births_mf.pdf", replace

*--- Fig: First-born share (Japan, 1960–1970)
twoway (line firstbornrate year, lcolor(navy) lwidth(medthick)), ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("First-born share", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_births_firstborn.pdf", replace

*--- Fig: Total pregnancies = births + abortions (Japan, 1960–1970)
twoway (line pregnancy_tot year, lcolor(navy) lwidth(medthick)), ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Births + abortions", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_pregnancies.pdf", replace

*--- Fig: Abortion-to-birth ratio (Japan, 1960–1970)
twoway (line abortionrate year, lcolor(navy) lwidth(medthick)), ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Abortion / birth ratio", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_abortion_ratio.pdf", replace

*--- Fig: Absolute infant deaths by sex (Japan, 1960–1970)
twoway (line infantdeathmale   year, lcolor(navy)  lwidth(medthick)) ///
       (line infantdeathfemale year, lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
       legend(size(*1.2) pos(6) row(1)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Infant deaths", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_infant_abs.pdf", replace

*--- Fig: Infant mortality rate by sex (Japan, 1960–1970)
twoway (line male_infd_rate   year, lcolor(navy)  lwidth(medthick)) ///
       (line female_infd_rate year, lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
       legend(size(*1.2) pos(6) row(1)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Infant mortality rate (per 1,000)", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_infant_rate.pdf", replace


*==============================================================
* SECTION 2: Birth drop map by prefecture
*   Source: vital_summary.dta (prefecture-level births, 1965–1967)
*           prefecture_shape/jpn_admbnda_adm1_2019_coord.dta
*   Produces: births_yoy_birth_map.pdf
*==============================================================

use "$data/vital_summary", clear

*--- Keep prefecture rows with _ID (needed for shapefile merge)
keep if map_id != .
keep if year >= 1965 & year <= 1967

*--- Destring births (stored as string with spaces in some rows)
cap destring births, replace force

keep name year births map_id
reshape wide births, i(map_id) j(year)

*--- Birth drop: (avg 65+67) / 66 — higher = less drop
gen birthdrop = (births1965 + births1967) / (births1966 * 2)
format birthdrop %9.3f
label variable birthdrop "Birth drop index (avg 65+67 / 66)"

spmap birthdrop using "$data/prefecture_shape/jpn_admbnda_adm1_2019_coord", ///
	id(map_id) fcolor(Blues) legend(size(*1.3) pos(11))
graph export "$output/firehorse_births_yoy_birth_map.pdf", replace


*==============================================================
* SECTION 3: Neonatal mortality figures
*   Source: table_33.dta, table_4.dta (annual totals, by sex)
*   Produces: infant_neo_abs.pdf, infant_neo_rate.pdf
*==============================================================

use "$data/table_33", clear

*--- Keep national totals (prefecture_id == 0), drop urban/rural sub-rows
drop if urb_rural == 1 | urb_rural == 2
keep if prefecture_id == 0
keep if year >= 1960 & year <= 1970

*--- Get annual births by sex from table_4 (national total rows only)
preserve
use "$data/table_4", clear
keep if prefecture_id == 0
drop if urb_rural == 1 | urb_rural == 2
*   Keep rows that have both births_male and births_female (annual totals)
keep if births_male != . & births_female != .
keep year prefecture_id births_male births_female
duplicates drop year prefecture_id, force
save "$temp/table4_national_annual", replace
restore

*--- Merge births into neonatal data
sort year prefecture_id
merge m:1 year prefecture_id using "$temp/table4_national_annual"
drop if _merge == 2
drop _merge

*--- Neonatal mortality: 4-week deaths
gen neo4_birth_m = infant_neo4_tot_m / births_male  * 1000
gen neo4_birth_f = infant_neo4_tot_f / births_female * 1000
label variable infant_neo4_tot_m "Male neonatal deaths (4 weeks)"
label variable infant_neo4_tot_f "Female neonatal deaths (4 weeks)"
label variable neo4_birth_m      "Male neonatal mortality rate (per 1,000)"
label variable neo4_birth_f      "Female neonatal mortality rate (per 1,000)"

*--- Fig: Absolute neonatal deaths by sex (Japan, 1960–1970)
twoway (line infant_neo4_tot_m year, lcolor(navy)  lwidth(medthick)) ///
       (line infant_neo4_tot_f year, lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
       legend(size(*1.2) pos(6) row(1)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Neonatal deaths (4 weeks)", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_infant_neo_abs.pdf", replace

*--- Fig: Neonatal mortality rate by sex (Japan, 1960–1970)
twoway (line neo4_birth_m year, lcolor(navy)  lwidth(medthick)) ///
       (line neo4_birth_f year, lcolor(maroon) lwidth(medthick) lpattern(dash)), ///
       legend(size(*1.2) pos(6) row(1)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Neonatal mortality rate (per 1,000)", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_infant_neo_rate.pdf", replace


*==============================================================
* SECTION 4: Births by maternal age cohort
*   Source: table_6_trim.dta (prefecture_id == 0, national totals)
*   Produces: births_agecohort.pdf
*==============================================================

use "$data/table_6_trim", clear

*--- Keep national totals
keep if prefecture_id == 0
keep if year >= 1960 & year <= 1970

*--- Age cohort shares of total births
foreach age in 20_24 25_29 30_34 35_39 {
	gen share_`age' = birth_`age'_tot / births_total
	label variable share_`age' "Age `age'"
}

*--- Fig: Birth share by maternal age group
twoway (line share_20_24 year, lcolor(navy)   lwidth(medthick)) ///
       (line share_25_29 year, lcolor(maroon)  lwidth(medthick) lpattern(dash)) ///
       (line share_30_34 year, lcolor(forest_green) lwidth(medthick) lpattern(longdash)) ///
       (line share_35_39 year, lcolor(orange)  lwidth(medthick) lpattern(shortdash_dot)), ///
       legend(label(1 "20–24") label(2 "25–29") label(3 "30–34") label(4 "35–39") ///
              size(*1.1) pos(6) row(1)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Share of births", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_births_agecohort.pdf", replace


*==============================================================
* SECTION 5: Abortions by maternal age cohort
*   Source: table_50_trim.dta (national totals, by age group)
*   Produces: abortion_agecohort.pdf
*==============================================================

use "$data/table_50_trim", clear

*--- Keep national totals (prefecture == missing, month_gestation == 0)
keep if prefecture == . & month_gestation == 0
keep if year >= 1960 & year <= 1970

*--- Age cohort shares of total abortions
foreach age in 20 20_24 25_29 30_34 35_39 {
	cap gen share_ab_`age' = abort_`age' / abortion_tot
	cap label variable share_ab_`age' "Age `age'"
}

*--- Fig: Abortion share by maternal age group
twoway (line share_ab_20    year, lcolor(navy)   lwidth(medthick)) ///
       (line share_ab_20_24 year, lcolor(maroon)  lwidth(medthick) lpattern(dash)) ///
       (line share_ab_25_29 year, lcolor(forest_green) lwidth(medthick) lpattern(longdash)) ///
       (line share_ab_30_34 year, lcolor(orange)  lwidth(medthick) lpattern(shortdash_dot)) ///
       (line share_ab_35_39 year, lcolor(purple)  lwidth(medthick) lpattern(dot)), ///
       legend(label(1 "Under 20") label(2 "20–24") label(3 "25–29") ///
              label(4 "30–34") label(5 "35–39") ///
              size(*1.1) pos(6) row(2)) ///
       xlabel(1960(2)1970, labsize(medlarge)) ///
       ylabel(,labsize(medlarge)) ///
       xtitle("Year", size(medlarge)) ytitle("Share of abortions", size(medlarge)) ///
       xline(1966, lcolor(gray) lpattern(shortdash))
graph export "$output/firehorse_abortion_agecohort.pdf", replace


di "=== 04_descriptive_births.do complete. Outputs saved to $output ==="
