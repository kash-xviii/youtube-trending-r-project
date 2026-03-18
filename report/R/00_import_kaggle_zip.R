import_kaggle_zip <- function(
  zip_path = NULL,
  incoming_dir = "data/incoming",
  raw_dir = "data/raw"
) {
  if (!dir.exists(raw_dir)) {
    dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!is.null(zip_path) && !file.exists(zip_path)) {
    stop("ZIP file not found: ", zip_path)
  }

  if (is.null(zip_path)) {
    zip_candidates <- list.files(incoming_dir, pattern = "\\.zip$", full.names = TRUE, ignore.case = TRUE)
    if (length(zip_candidates) == 0) {
      message("No ZIP found in data/incoming. Skipping import step.")
      return(invisible(FALSE))
    }
    zip_info <- file.info(zip_candidates)
    zip_path <- rownames(zip_info)[which.max(zip_info$mtime)]
  }

  temp_extract <- tempfile(pattern = "kaggle_zip_")
  dir.create(temp_extract, recursive = TRUE, showWarnings = FALSE)

  utils::unzip(zipfile = zip_path, exdir = temp_extract)

  csv_files <- list.files(temp_extract, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)

  if (length(csv_files) == 0) {
    unlink(temp_extract, recursive = TRUE, force = TRUE)
    stop("No CSV files found inside ZIP: ", zip_path)
  }

  out_files <- file.path(raw_dir, basename(csv_files))
  copied <- file.copy(from = csv_files, to = out_files, overwrite = TRUE)

  unlink(temp_extract, recursive = TRUE, force = TRUE)

  if (!all(copied)) {
    warning("Some CSV files could not be copied to data/raw.")
  }

  message("Imported ", sum(copied), " CSV file(s) into data/raw from ZIP: ", basename(zip_path))
  invisible(TRUE)
}
