library(ospsuiteCpp)
library(ospsuite)
library(tictoc)

sim_files <- list.files("sims", pattern = ".pkml", full.names = TRUE) |>
  rev()
sim_files <- sim_files
benchmark_file <- "benchmark_cpp.csv"
wd <- getwd()

param_path <- c("Voriconazole-CYP2C19-Bhara et al 2011|kcat")
param_vals <- c(2)
observer_path <- "Organism|PeripheralVenousBlood|Voriconazole|Plasma (Peripheral Venous Blood)"

for (sim in sim_files) {
  simulation <- loadSimulation(sim)
  clearOutputs(simulation)
  addOutputs(c(observer_path), simulation = simulation)

  run_id <- floor(runif(1, min = 0, max = 1000))
  run_name <- paste0("run_", run_id)

  sim_batch_opts <- SimulationBatchOptions$new(
    variableParameters = param_path
  )

  exportSimulationCpp(simulation, sim_batch_opts, run_name, wd)
  cpp_path <- file.path(wd, paste0(run_name, ".cpp"))
  out_path <- file.path(wd)
  compileSimulationCpp(cpp_path, outputPath = out_path)

  sim_compiled <- SimulationCompiled$new(run_name)

  tic(msg = "Simulation time (Cpp)")
  res_compiled <- sim_compiled$run(parameter = param_vals)
  x <- toc()

  tic(msg = "Simulation time (ospsuite batch)")
  res <- runSimulations(simulation)
  y <- toc()

  df <- data.frame(
    sim = sim,
    time_cpp = unname(x$toc),
    time_osp = unname(y$toc)
  ) |>
    write.table(append = TRUE, file = benchmark_file, row.names = FALSE, col.names = FALSE)
}
