# Run breakpoint estimates
# Uses Epinow 2 v1.3
# remotes::install_github("epiforecasts/EpiNow2")

# Packages -----------------------------------------------------------------
library(EpiNow2)
library(data.table)
library(future)
# install.packages("EpiNow2")


# Delays -----------------------------------------------------------
# Update
# source(here::here("delays", "public-linelist-delays.R"))

# Fixed
generation_time <- readRDS(here::here("delays", "data", "generation_time.rds"))
incubation_period <- readRDS(here::here("delays", "data", "incubation_period.rds"))

# Deaths delay
deaths_delay <- readRDS(here::here("delays", "data", "cocin_onset_to_death_delay.rds"))

# Cases delay
cases_delay <- readRDS(here::here("delays", "data", "public_onset_to_report_delay.rds"))


# get public data ----------------------------------------------------------------
# # # Public data
# # Set up query
# structure <- list("date", "areaName", 
#                   "newDeaths28DaysByDeathDate",
#                   "newCasesBySpecimenDate", 
#                   "newAdmissions")
# names(structure) <- structure
# areaType <- list("nation" = "areaType=nation")
# 
# # Get data
# raw <- ukcovid19::get_data(filters = areaType, structure = structure)
# # clean
# data <- data.table::as.data.table(raw)
# old <- unlist(structure)
# new <- c("date", "region", "deaths_death",  "cases_test", "cases_hosp")
# data <- data.table::setnames(data, old, new)


# get private data --------------------------------------------------------
raw <- readRDS("~/covid19_uk_forecast_data/data/processed/latest_data.rds")
# raw <- readRDS(path.expand(file.path("C:", "Users", "kaths", "Github", "covid19_uk_forecast_data", "data", "processed", "latest_data.rds")))

raw$value_desc <- NULL
data <- raw[raw$type == "Data" ,]
data <- tidyr::pivot_wider(data, values_from = "value", names_from = "value_type")
data$type <- NULL
data <- data[,c("value_date", "geography", "death_inc_line", "hospital_inc", "reported_cases")]
colnames(data) <- c("date", "region", "deaths", "admissions", "cases")


# Format data -------------------------------------------------------------

data <- as.data.table(data)

# Set date sequence to start from some weeks before the firebreak
data$date <- lubridate::ymd(data$date)
data <- data[, .SD[date >= "2020-09-28"], by = region]

# Keep regions
data <- data[region %in% c("Wales", "Northern Ireland")]


# Set breakpoints ---------------------------------------------------------
all_dates <- unique(data$date)
breakpoints <- list("firebreak" = list("n_ireland" = list("start" = as.Date("2020-10-16"),
                                                          "end" = as.Date("2020-11-20")),
                                       "wales" = list("start" = as.Date("2020-10-24"),
                                                      "end" = as.Date("2020-11-09"))))

# # Add multiple breakpoints, weekly on Sundays, for random walk
sundays <- all_dates[weekdays(all_dates)=="Sunday"]

breakpoints$random_walk_firebreak <- list("n_ireland" = c(sundays[sundays <= (breakpoints$firebreak$n_ireland$start - 6)], 
                                                          breakpoints$firebreak$n_ireland$start,
                                                          breakpoints$firebreak$n_ireland$end),
                                          "wales" = c(sundays[sundays <= (breakpoints$firebreak$wales$start - 6)], 
                                                      breakpoints$firebreak$wales$start,
                                                      breakpoints$firebreak$wales$end))

# Rt estimate -------------------------------------------------------------

# Get function for Rts
source(here::here("rt-breakpoint-epinow2-1.3.R"))

# Set up cores -----------------------------------------------------
setup_future <- function(jobs) {
  if (!interactive()) {
    ## If running as a script enable this
    options(future.fork.enable = TRUE)
  }
  plan(tweak(multiprocess, workers = min(future::availableCores(), jobs)),
       gc = TRUE, earlySignal = TRUE)
  jobs <- max(1, round(future::availableCores() / jobs, 0))
  return(jobs)
}
no_cores <- setup_future(length(unique(data$region)))



# Run Rt with single breakpoint  ---------------------------------------------------------
# Add breakpoints
# set data with single bp
data_firebreak <- data[, breakpoint := data.table::fifelse( # NI
  ((region == "Northern Ireland" &
     date %in% breakpoints$firebreak$n_ireland) | 
    # Wales
    (region == "Wales" & 
       date %in% breakpoints$firebreak$wales)),
  1, 0)]

# # Set root for saving estimates
save_loc <- "breakpoint-only/"
# # Cases
cases <- run_rt_breakpoint(data = data_firebreak,
                           type = "breakpoint",
                           truncate = 0,
                           count_variable = "cases",
                           reporting_delay = cases_delay,
                           generation_time = generation_time,
                           incubation_period = incubation_period,
                           save_loc = save_loc,
                           no_cores = no_cores)
# Admissions
adm <- run_rt_breakpoint(data = data_firebreak,
                         type = "breakpoint",
                         truncate = 0,
                         count_variable = "admissions",
                         reporting_delay = cases_delay,
                         generation_time = generation_time,
                         incubation_period = incubation_period,
                         save_loc = save_loc,
                         no_cores = no_cores)
# Deaths
deaths <- run_rt_breakpoint(data = data_firebreak,
                            type = "breakpoint",
                            truncate = 0,
                            count_variable = "deaths",
                            reporting_delay = deaths_delay,
                            generation_time = generation_time,
                            incubation_period = incubation_period,
                            save_loc = save_loc,
                            no_cores = no_cores)


# Run Rt with RW ------------------------------------------------------------------
# Add BPs
data_rw_firebreak <- data[, breakpoint := data.table::fifelse( # NI
  ((region == "Northern Ireland" &
     date %in% breakpoints$random_walk_firebreak$n_ireland) | 
    # Wales
    (region == "Wales" & 
       date %in% breakpoints$random_walk_firebreak$wales)),
  1, 0)]

# Save dir
save_loc <- "breakpoint-with-rw/"

# Cases
cases <- run_rt_breakpoint(data = data_rw_firebreak,
                           type = "breakpoint",
                           truncate = 0,
                           count_variable = "cases",
                           reporting_delay = cases_delay,
                           generation_time = generation_time,
                           incubation_period = incubation_period,
                           save_loc = save_loc,
                           no_cores = no_cores)
# Admissions
adm <- run_rt_breakpoint(data = data_rw_firebreak,
                         type = "breakpoint",
                         truncate = 0,
                         count_variable = "admissions",
                         reporting_delay = cases_delay,
                         generation_time = generation_time,
                         incubation_period = incubation_period,
                         save_loc = save_loc,
                         no_cores = no_cores)
# Deaths
deaths <- run_rt_breakpoint(data = data_rw_firebreak,
                            type = "breakpoint",
                            truncate = 0,
                            count_variable = "deaths",
                            reporting_delay = deaths_delay,
                            generation_time = generation_time,
                            incubation_period = incubation_period,
                            save_loc = save_loc,
                            no_cores = no_cores)


# GP + 1 breakpoint ---------------------------------------------------------
# # Set root for saving estimates
# save_loc <- "rt-estimate/estimate-break/gp-only/"
# cases <- run_rt_breakpoint(data = data,
#                            type = "gp",
#                            truncate = 0,
#                             count_variable = "cases",
#                            reporting_delay = cases_delay,
#                            generation_time = generation_time,
#                            incubation_period = incubation_period,
#                            save_loc = save_loc,
#                            no_cores = no_cores)
# #Admissions
# adm <- run_rt_breakpoint(data = data,
#                          type = "gp",
#                          truncate = 0,
#                          count_variable = "admissions",
#                          reporting_delay = cases_delay,
#                          generation_time = generation_time,
#                          incubation_period = incubation_period,
#                          save_loc = save_loc,
#                          no_cores = no_cores)
# # Deaths
# deaths <- run_rt_breakpoint(data = data,
#                   type = "gp",
#                   truncate = 0,
#                   count_variable = "deaths",
#                   reporting_delay = deaths_delay,
#                   generation_time = generation_time,
#                   incubation_period = incubation_period,
#                   save_loc = save_loc,
#                   no_cores = no_cores)
