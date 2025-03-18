if (interactive() && Sys.getenv("RSTUDIO") == "1") {
  message("Scheduling FlowR addin installation...")
  later::later(function() {
    message("Installing FlowR addin...")
    try(rstudioaddinflowr:::install_node_addin(), silent = FALSE)
  }, delay = 8)  # Delays by 5 seconds to allow RStudio to fully start
}
