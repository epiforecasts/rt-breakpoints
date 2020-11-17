library("dplyr")

# Check BP effect sizes
vars <- c("cases", "admissions", "deaths")
models <- c("breakpoint-only",
            "breakpoint-with-rw") #,
regions <- c("Wales", "Northern Ireland")

# Get summary
regions_fn <- function(model, var, region){
  estimates <-
    readRDS(here::here(model, var, "region", region, Sys.Date()-1,
                       "summarised_estimates.rds"))
  estimates$region <- region
  estimates$source <- var
  estimates$model <- model
  estimates <- estimates[estimates$variable == "breakpoints",]
  return(estimates)
  }

m <- list()

for (model in models) {
  for (var in vars) {
    for (region in regions) {
      m[[length(m) + 1]] <-
        regions_fn(model = model, var = var, region = region)
    }
  }
}

summary <- dplyr::bind_rows(m) %>%
  dplyr::mutate(dplyr::across(median:upper_90, exp))


# Summarise effects -------------------------------------------------------

# For random walk breakpoints,
#   if firebreak has not ended, get max strat
#   else get max strat -1 if lockdown has ended
breakpoints <- readRDS(paste0(Sys.Date(), "/breakpoints.rds"))
# Assuming breakpoints have end dates, strat will be length of RW - 1
ni_strat <- length(breakpoints[["random_walk_firebreak"]][["n_ireland"]]) - 1
wales_strat <- length(breakpoints[["random_walk_firebreak"]][["wales"]]) - 1


effects <- summary %>%
  dplyr::group_by(region, model) %>%
  dplyr::filter((model == "breakpoint-only" & strat == 1) | 
                  (model == "breakpoint-with-rw" & region == "Northern Ireland" & strat == ni_strat) |
                  (model == "breakpoint-with-rw" & region == "Wales" & strat == wales_strat)) %>%
  dplyr::select(-c(variable, type, strat, date, mean, sd, lower_20:upper_20)) %>%
  dplyr::mutate(region = factor(region,
                                levels = c("Wales", "Northern Ireland"),
                                ordered = TRUE),
                model = factor(model,
                                levels = c("breakpoint-only", "breakpoint-with-rw"),
                               labels = c("Single breakpoint", "Random walk + breakpoint"),
                                ordered = TRUE)) %>%
  dplyr::ungroup()

readr::write_csv(effects,
                 here::here(Sys.Date(),
                            "breakpoint-effects.csv"))

