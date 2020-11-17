# Sequence to update breakpoint analysis

if (!dir.exists(here::here(Sys.Date()))) {
  dir.create(here::here(Sys.Date()))
}

# Run Rt and format
source(here::here("run-rt-breakpoint.R"))
source(here::here("format-rt-breakpoint.R"))
source(here::here("breakpoint-effects.R"))

# Format data
source(here::here("format-data.R"))

# Run report
# file.copy(here::here("generic-report.R"),
#           here::here(Sys.Date(), "report.R"))
