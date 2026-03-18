source("report/R/00_import_kaggle_zip.R")

import_kaggle_zip()

source("report/R/01_load_and_clean.R")
source("report/R/02_analytics_and_visuals.R")
source("report/R/03_render_report.R")

render_report("report/youtube_trending_report.qmd")

message("Project run complete.")
