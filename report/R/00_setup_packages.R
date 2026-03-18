required_packages <- c(
  "tidyverse",
  "lubridate",
  "janitor",
  "scales",
  "gganimate",
  "gifski",
  "glue",
  "patchwork"
)

ensure_writable_library <- function() {
  default_lib <- .libPaths()[1]

  if (file.access(default_lib, mode = 2) == 0) {
    return(invisible(default_lib))
  }

  user_lib <- Sys.getenv("R_LIBS_USER")
  if (!nzchar(user_lib)) {
    user_lib <- file.path(path.expand("~"), "R", "win-library", paste0(R.version$major, ".", strsplit(R.version$minor, "\\.")[[1]][1]))
  }

  if (!dir.exists(user_lib)) {
    dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
  }

  .libPaths(c(user_lib, .libPaths()))
  message("Using user library: ", user_lib)
  invisible(user_lib)
}

install_if_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
  if (length(missing) > 0) {
    message("Installing missing packages: ", paste(missing, collapse = ", "))
    target_lib <- .libPaths()[1]
    lock_dirs <- list.files(target_lib, pattern = "^00LOCK", full.names = TRUE)
    if (length(lock_dirs) > 0) {
      unlink(lock_dirs, recursive = TRUE, force = TRUE)
    }

    install_ok <- TRUE
    tryCatch(
      install.packages(missing, repos = "https://cloud.r-project.org", lib = target_lib),
      error = function(e) {
        install_ok <<- FALSE
        msg <- conditionMessage(e)
        if (grepl("failed to lock directory", msg, ignore.case = TRUE)) {
          lock_dirs_retry <- list.files(target_lib, pattern = "^00LOCK", full.names = TRUE)
          if (length(lock_dirs_retry) > 0) {
            unlink(lock_dirs_retry, recursive = TRUE, force = TRUE)
          }
          message("Detected lock error. Removed stale lock directories and retrying install once...")
          install.packages(missing, repos = "https://cloud.r-project.org", lib = target_lib)
          install_ok <<- TRUE
        } else {
          stop(e)
        }
      }
    )

    if (!install_ok) {
      stop("Package installation failed. Please rerun after checking internet access and library permissions.")
    }
  }
}

ensure_writable_library()
install_if_missing(required_packages)
invisible(lapply(required_packages, library, character.only = TRUE))

message("All required packages are ready.")
