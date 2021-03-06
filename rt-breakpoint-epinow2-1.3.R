library(EpiNow2, quietly = TRUE)
library(lubridate, quietly = TRUE)
library(here)
library(data.table)

# Set up running a single Rt forecast -------------------------------------
run_rt_breakpoint <- function(data, 
                              type = c("breakpoint", "gp"),
                              truncate = 3,
                              count_variable, 
                              reporting_delay,
                              save_loc,
                              no_cores,
                              generation_time,
                              incubation_period) {
  
  for(i in 1:length(count_variable)){
    
    print(paste0("Estimates for ", count_variable[i]))
    
    # Set up directories for models -------------------------------------------
    
    if(!dir.exists(here::here(save_loc, 
                              count_variable[i]))) {
      dir.create(here::here(save_loc, 
                            count_variable[i]))
    }
    
    targets <- paste0(save_loc, count_variable[i], "/region")
    summary <- paste0(save_loc, count_variable[i], "/summary")
    
    # Format for epinow2 ------------------------------------------------------
    
    data_select <- data.table::as.data.table(data)
    
    data_select <- data.table::setnames(data_select, old = count_variable[i], new = "confirm")
    
    # Include breakpoint
    data_select <- data_select[, .(date, region, confirm, breakpoint)]
    
    # truncate 5 days
    data_select <- data_select[, .SD[date <= (Sys.Date() - lubridate::days(truncate))], by = region]
    
    data.table::setorder(data_select, date)
    
    # Set up --------------------------------------------------
    
    if(type == "gp"){
      data_select$breakpoint <- NULL
      # GP 
      out <- regional_epinow(
        samples = 4000, 
        horizon = 0, 
        generation_time = generation_time,
        rt = list(prior = list(mean = 1.2, sd = 0.2),
                  future = "latest"),
        delays = list(incubation_period, reporting_delay),
        stan_args = list(warmup = 1000, 
                         cores = no_cores, 
                         control = list(adapt_delta = 0.99), 
                         chains = ifelse(no_cores <= 4, 4, no_cores)), 
        burn_in = 14, 
        non_zero_points = 2,
        max_execution_time = Inf, 
        future = FALSE,
        output = c("region", "samples", "summary", "timing"),
        reported_cases = data_select,
        target_folder = targets,
        summary_args = list(summary_dir = summary,
                            all_regions = FALSE),
        logs = save_loc)
      
      return(out)
      
    }else if(type == "breakpoint"){
      
      # Any breakpoint, no GP
      out <- regional_epinow(
        gp = NULL,
        rt = rt_opts(prior = list(mean = 1.2, sd = 0.2),
                  future = "latest"),
        horizon = 0, 
        generation_time = generation_time,
        delays = delay_opts(incubation_period, reporting_delay),
        stan = stan_opts(samples = 4000,
                         warmup = 1000, 
                         cores = no_cores, 
                         chains = ifelse(no_cores <= 4, 4, no_cores)),
        output = c("region", "samples", "summary", "timing"),
        reported_cases = data_select,
        target_folder = targets,
        summary_args = list(summary_dir = summary,
                            all_regions = FALSE),
        logs = save_loc)
      
      return(out)
    }
  }
}
