render_report <- function(report_path = "report/youtube_trending_report.qmd") {
  if (!file.exists(report_path)) {
    stop("Report file not found: ", report_path)
  }

  has_quarto_pkg <- requireNamespace("quarto", quietly = TRUE)
  has_quarto_cli <- nzchar(Sys.which("quarto"))

  if (has_quarto_pkg) {
    quarto::quarto_render(input = report_path, output_format = "html")
    message("Rendered report via quarto package.")
    return(invisible(TRUE))
  }

  if (has_quarto_cli) {
    cmd <- sprintf("quarto render %s --to html", shQuote(report_path))
    status <- system(cmd)
    if (status != 0) stop("Quarto CLI render failed with status code: ", status)
    message("Rendered report via Quarto CLI.")
    return(invisible(TRUE))
  }

  message("Quarto is not available. Install it with install.packages('quarto') or install Quarto CLI from https://quarto.org")
  invisible(FALSE)
}
