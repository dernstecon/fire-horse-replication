Replication Package: "Missing Fire Horse Women"
David Ernst, Kyoto University

This package replicates all figures and tables in "Missing Fire Horse Women."


REQUIREMENTS
------------
Software: Stata 16 or later

Stata packages (install once before running):
  ssc install reghdfe
  ssc install xtevent
  ssc install honestdid
  ssc install pretrends
  ssc install estout      (provides esttab)
  ssc install coefplot
  ssc install spmap       (required for birth drop map)


HOW TO RUN
----------
1. Open code/00_master.do and set the root path at the top:

     global root  "C:/path/to/replication_package"

2. Run 00_master.do. All figures (.pdf) and tables (.tex) are written
   to output/. Runtime: approximately 20-30 minutes.


DIRECTORY STRUCTURE
-------------------
replication_package/
  code/
    00_master.do               <- run this
    02_main_analysis.do        <- main event-study figures & tables
    03_descriptive_analysis.do <- descriptive & auxiliary figures
    04_descriptive_births.do   <- birth/infant/abortion descriptives
  data/
    did_clean_merge.dta        <- analysis dataset (pre-built)
    maternal_statistics1964.dta
    vital_summary.dta          <- national vital statistics summary
    table_33.dta               <- monthly infant/neonatal deaths
    table_4.dta                <- monthly births by prefecture/sex
    table_6_trim.dta           <- births by maternal age cohort
    table_50_trim.dta          <- national abortions by age cohort
    prefecture_shape/          <- prefecture map coordinate files
  output/
    [pipeline outputs]         <- created when you run 00_master.do
    [static files]             <- pre-generated; see list below


DATA
----
data/did_clean_merge.dta is a balanced prefecture x year x month x sex
panel covering all 47 Japanese prefectures, years 1963-1968
(6,768 observations). Variables include monthly infant deaths by sex,
live births, fetal deaths by place of death, neonatal deaths, abortion
counts, urban/rural splits, and infant deaths by cause of death.
Source: Japanese Annual Vital Statistics Reports (jinko dotai tokei).

data/vital_summary.dta contains national and prefecture-level annual
vital statistics for Japan, 1899-1998. Used for descriptive figures.

data/table_33.dta, table_4.dta, table_6_trim.dta, table_50_trim.dta
are source tables used directly by 04_descriptive_births.do.


OUTPUTS CREATED BY RUNNING THE CODE
-------------------------------------
From 02_main_analysis.do:
  firehorse_did_honest_mbar.pdf              Fig 3 - HonestDiD panel (a)
  firehorse_did_honest_noeffect.pdf          Fig 3 - panel (b)
  firehorse_did_honest_average.pdf           Fig 3 - panel (c)
  firehorse_did_honest_upper.pdf             Fig 3 - panel (d)
  firehorse_did_xtevent_main.pdf             Fig 2 - main event study
  firehorse_did_xtevent_wiggle.pdf           Fig B3 - least-wiggly path
  firehorse_did_didregress_accident.pdf      Fig 7 - infanticide test
  firehorse_did_xtevent_hospital_all_dot.pdf Fig 8a
  firehorse_did_xtevent_hospital_adj.pdf     Fig 8b
  firehorse_did_xtevent_hospital_all_fetal_dot.pdf  Fig 9a
  firehorse_did_xtevent_hospital_fetal_adj.pdf      Fig 9b
  firehorse_did_xtevent_hospital_inf_fet_DDD.pdf    Fig 10
  firehorse_did_reg.tex                      Table B1
  firehorse_did_hospital_reg1.tex            Table B3
  firehorse_did_hospital_reg2.tex            Table B4

From 03_descriptive_analysis.do:
  firehorse_sex_ratio_monthly.pdf            Fig A3 - sex ratio
  firehorse_ddd_birthyeardeath.pdf           Fig 5  - DDD birth year
  firehorse_did_reg_DDDbirth.tex             Table B2 - DDD regression
  prefecture_descriptive1.tex                Table A1 - prefecture stats
  prefecture_descriptive2.tex                Table A2 - prefecture stats
  firehorse_did_prefecture_graph.pdf         Fig 4a - prefecture effects
  firehorse_did_prefecture_birthdrop.pdf     Fig 4b - vs birth drop
  firehorse_did_urban_rural.pdf              Fig B1 - urban vs rural
  firehorse_did_didregress_oneyear.pdf       Fig B2 - one-year-old deaths

From 04_descriptive_births.do:
  firehorse_births_mf.pdf                    Fig A1 - male/female births
  firehorse_births_firstborn.pdf             Fig A  - first-born share
  firehorse_pregnancies.pdf                  Fig A  - total pregnancies
  firehorse_abortion_ratio.pdf               Fig A  - abortion/birth ratio
  firehorse_infant_abs.pdf                   Fig A  - infant deaths (abs.)
  firehorse_infant_rate.pdf                  Fig A  - infant mortality rate
  firehorse_infant_neo_abs.pdf               Fig A  - neonatal deaths (abs.)
  firehorse_infant_neo_rate.pdf              Fig A  - neonatal mortality rate
  firehorse_births_agecohort.pdf             Fig A  - births by age cohort
  firehorse_abortion_agecohort.pdf           Fig A  - abortions by age cohort
  firehorse_births_yoy_birth_map.pdf         Fig A1 - birth drop map


PRE-GENERATED STATIC FILES (in output/)
-----------------------------------------
The following files are included pre-generated and cannot be reproduced
by the current code (they require raw data not distributed here):

  firehorse_did_prefecture_map.pdf   (requires raw prefecture shapefile + spmap)
  firehorse_birth_manipulation.png   (external image)
  vital_statistics_example.pdf       (external image)
