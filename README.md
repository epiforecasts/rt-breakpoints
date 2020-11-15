# Estimate Rt using breakpoints with EpiNow2

This code estimates time-varying R using breakpoints. We include two types of breakpoint estimates: one with a single breakpoint where specified; and another with a 7-day random walk until a breakpoint is specified.

This codebase is intended for use by Epiforecasts running estimates of Rt from Covid-19 cases, admissions, and deaths, in Wales and Nothern Ireland. However code can be adapted for use on other datasets.

The sequence of scripts needed to run Rt estimates and generate a report is listed in `update.R`.

### Running on individual datasets
To run this outside of Epiforecasts, these scripts need the following edits.

1.	`run-rt-breakpoint.R` is the main script for running Rt estimates. To run this you will need to:
   
 * Install `EpiNow2` development version from github (line 3)

 * Edit the file path to your own data (line 46)

 * Clean and format the data before running estimates (lines 46-56). This should result in a long format dataframe with columns `date`, `region`, `cases`, `admissions`, `deaths`.

 * Keep or edit line 60, which keeps only the last 6 weeks of data with which to estimate Rt

 *	Remove or edit line 63, which keeps only some regions in the data (as our dataset included more regions than those more than just the regions with firebreaks)

 * Specify date(s) of breakpoints (lines 66-70, line 133, and line 136). Here we have specified separate breakpoints for each region.
   

 2.	`format-rt.R` cleans and formats the Rt estimates for plotting.
 
 *	Edit breakpoint date(s) (lines 4-5)
   
 
 3.	`breakpoint-effects.R` formats the estimates of breakpoint effects. No changes needed.
  

 4.	`format-data.R` cleans and formats the raw data for plotting.

  *	Edit file path to data (line 3)

  *	Clean and format data (lines 6-16). This should result in a dataframe with columns `date`, `region`, `cases`, `admissions`, `deaths`, and `breakpoint`. The `breakpoint` column should be 1 on the date of the breakpoint and 0 on all other dates.
   

 5.	`generic-report.Rmd` - generate the report using R Markdown: edit text as needed
