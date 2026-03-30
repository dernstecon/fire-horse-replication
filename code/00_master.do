*=============================================================
* Missing Fire Horse Women — Replication Master File
* Author: David Ernst
*
* Purpose:
*   Runs the full analysis pipeline in the correct sequence.
*   All outputs (figures, tables) are saved to output/.
*
* Directory structure (replication package root):
*   ├── code/              ← this file and all do-files
*   ├── data/              ← provided datasets (see DATA section below)
*   ├── output/            ← created automatically; all outputs
*   └── temp/              ← created automatically; scratch files
*
* Data provided:
*   data/did_clean_merge.dta    — prefecture × year × month × sex
*                                  panel, years 1963–1968
*   data/maternal_statistics1964.dta — prefecture names/demographics
*   data/vital_summary.dta      — national vital statistics (1899–1998)
*   data/table_33.dta           — monthly infant/neonatal deaths
*   data/table_4.dta            — monthly births by prefecture/sex
*   data/table_6_trim.dta       — births by maternal age cohort
*   data/table_50_trim.dta      — national abortions by age cohort
*   data/prefecture_shape/      — prefecture map coordinate files
*
* Required Stata packages (install once via ssc install <name>):
*   reghdfe   — high-dimensional fixed effects
*   xtevent   — event-study estimator
*   honestdid — Rambachan & Roth (2023) sensitivity analysis
*   pretrends — pre-trends power calculations
*   esttab    — regression tables (part of estout)
*   coefplot  — coefficient plots
*   spmap     — prefecture map (for birth drop map figure)
*
* Pipeline:
*   02_main_analysis.do        — main event-study figures & tables
*   03_descriptive_analysis.do — descriptive & auxiliary figures
*   04_descriptive_births.do   — birth/infant/abortion descriptives
*=============================================================

clear all
set more off

*-------------------------------------------------------------
* Global paths — edit only this ONE line when moving the project
*   Set root to the absolute path of the replication package
*   (the folder containing code/, data/, output/)
*-------------------------------------------------------------
global root    "SET_PATH_HERE"   // <- set this to your local replication_package folder

global data    "$root/data"
global temp    "$root/temp"
global output  "$root/output"
global code    "$root/code"

cap mkdir "$output"
cap mkdir "$temp"


*-------------------------------------------------------------
* Step 1: Main analysis
*   Produces all figures and tables in Ernst (2025).
*   Outcome: infant deaths (count levels).
*   Outputs: firehorse_did_*.pdf  firehorse_did_*.tex
*-------------------------------------------------------------
do "$code/02_main_analysis.do"


*-------------------------------------------------------------
* Step 2: Descriptive and auxiliary figures
*   Produces: sex ratio, DDD birth year, prefecture tables,
*             prefecture scatter plots, urban/rural, one-year-old
*   NOTE: prefecture_map.pdf (requires shapefile) stays pre-generated.
*-------------------------------------------------------------
do "$code/03_descriptive_analysis.do"


*-------------------------------------------------------------
* Step 3: Births and vital statistics descriptives
*   Produces: births/infant/abortion descriptive figures
*   using national vital_summary.dta and source tables
*   NOTE: requires spmap package for the birth drop map
*         (ssc install spmap)
*-------------------------------------------------------------
do "$code/04_descriptive_births.do"


di "=== Replication complete. Outputs saved to $output ==="
