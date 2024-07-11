library(ospsuiteCpp)
library(ospsuite)
library(tictoc)

sim_files <- list.files("sims", pattern = ".pkml", full.names = TRUE) |>
  rev()
benchmark_file <- "benchmark_cpp.csv"

for (sim in sim_files) {
  simulation <- loadSimulation(sim)

  run_id <- floor(runif(1, min = 0, max = 1000))
  run_name <- paste0("run_", run_id)

  param_path <- c("Organism|Height")
  sim_batch_opts <- SimulationBatchOptions$new(
    variableParameters = param_path
  )

  sim_vals <- c(18)

  wd <- getwd()

  exportSimulationCpp(simulation, sim_batch_opts, run_name, wd)
  cpp_path <- file.path(wd, paste0(run_name, ".cpp"))
  out_path <- file.path(wd)
  compileSimulationCpp(cpp_path, outputPath = out_path)

  sim_compiled <- SimulationCompiled$new(run_name)

  tic(msg = "Simulation time (Cpp)")
  res <- sim_vals |>
    sapply(\(x) {
      sim_compiled$run(parameter = x)
    })
  x <- toc()

  tic(msg = "Simulation time (ospsuite batch)")
  res_batch <- runSimulations(simulation)
  y <- toc()

  df <- data.frame(
    sim = sim,
    time_cpp = unname(x$toc),
    time_osp = unname(y$toc)
  ) |>
    write.csv(append = TRUE, file = benchmark_file)
}
