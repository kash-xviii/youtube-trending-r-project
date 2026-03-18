source("report/R/00_setup_packages.R")

read_trending_files <- function(raw_dir = "data/raw") {
  csv_files <- list.files(raw_dir, pattern = "videos\\.csv$", full.names = TRUE, ignore.case = TRUE)

  if (length(csv_files) == 0) {
    csv_files <- list.files(raw_dir, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  }

  if (length(csv_files) == 0) {
    stop("No CSV files found in data/raw. Place Kaggle YouTube trending dataset CSV files there.")
  }

  read_one <- function(path) {
    region <- basename(path) |>
      stringr::str_remove("videos\\.csv$") |>
      stringr::str_replace("_+$", "") |>
      stringr::str_to_upper()

    suppressMessages(
      readr::read_csv(path, show_col_types = FALSE)
    ) |>
      janitor::clean_names() |>
      dplyr::mutate(region = region)
  }

  dplyr::bind_rows(lapply(csv_files, read_one))
}

safe_parse_datetime <- function(x) {
  parsed <- suppressWarnings(lubridate::ymd_hms(x, tz = "UTC", quiet = TRUE))
  missing_idx <- is.na(parsed)
  if (any(missing_idx)) {
    parsed[missing_idx] <- suppressWarnings(lubridate::ymd_hm(x[missing_idx], tz = "UTC", quiet = TRUE))
  }
  missing_idx <- is.na(parsed)
  if (any(missing_idx)) {
    parsed[missing_idx] <- suppressWarnings(lubridate::ymd(x[missing_idx], tz = "UTC", quiet = TRUE))
  }
  parsed
}

normalize_schema <- function(raw_df) {
  pick_first_existing <- function(df, candidates) {
    matched <- candidates[candidates %in% names(df)]
    if (length(matched) == 0) return(NULL)
    df[[matched[1]]]
  }

  if (!"publish_time" %in% names(raw_df)) {
    publish_time_candidate <- pick_first_existing(raw_df, c("published_at", "publish_date", "published_time", "video_publish_time"))
    if (!is.null(publish_time_candidate)) raw_df$publish_time <- publish_time_candidate
  }

  if (!"trending_date" %in% names(raw_df)) {
    trending_date_candidate <- pick_first_existing(raw_df, c("date", "trending_day", "trending_datetime"))
    if (!is.null(trending_date_candidate)) raw_df$trending_date <- trending_date_candidate
  }

  if (!"channel_title" %in% names(raw_df)) {
    channel_candidate <- pick_first_existing(raw_df, c("channel_name", "channel"))
    if (!is.null(channel_candidate)) raw_df$channel_title <- channel_candidate
  }

  if (!"video_id" %in% names(raw_df)) {
    video_candidate <- pick_first_existing(raw_df, c("id", "videoid"))
    if (!is.null(video_candidate)) raw_df$video_id <- video_candidate
  }

  if (!"category_id" %in% names(raw_df)) {
    category_candidate <- pick_first_existing(raw_df, c("category", "categoryid"))
    if (!is.null(category_candidate)) raw_df$category_id <- category_candidate
  }

  if (!"likes" %in% names(raw_df)) {
    likes_candidate <- pick_first_existing(raw_df, c("like_count", "likecount"))
    if (!is.null(likes_candidate)) raw_df$likes <- likes_candidate
  }

  if (!"comment_count" %in% names(raw_df)) {
    comments_candidate <- pick_first_existing(raw_df, c("comments", "commentcount"))
    if (!is.null(comments_candidate)) raw_df$comment_count <- comments_candidate
  }

  if (!"dislikes" %in% names(raw_df)) {
    dislikes_candidate <- pick_first_existing(raw_df, c("dislike_count", "dislikecount"))
    if (!is.null(dislikes_candidate)) raw_df$dislikes <- dislikes_candidate
  }

  if (!"title" %in% names(raw_df)) {
    title_candidate <- pick_first_existing(raw_df, c("video_title", "name"))
    if (!is.null(title_candidate)) raw_df$title <- title_candidate
  }

  if (!"region" %in% names(raw_df)) {
    region_candidate <- pick_first_existing(raw_df, c("country", "location"))
    if (!is.null(region_candidate)) raw_df$region <- region_candidate
  }

  raw_df
}

prepare_trending_data <- function(raw_df) {
  raw_df <- normalize_schema(raw_df)

  needed <- c("video_id", "trending_date", "category_id", "title", "channel_title", "publish_time", "views", "likes", "region")
  missing_cols <- setdiff(needed, names(raw_df))

  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  if (!"comment_count" %in% names(raw_df)) raw_df$comment_count <- NA_real_
  if (!"dislikes" %in% names(raw_df)) raw_df$dislikes <- NA_real_

  trending_date_parsed <- suppressWarnings(lubridate::ymd(raw_df$trending_date, quiet = TRUE))
  two_digit_idx <- is.na(trending_date_parsed)
  if (any(two_digit_idx)) {
    trending_date_parsed[two_digit_idx] <- suppressWarnings(lubridate::dmy(raw_df$trending_date[two_digit_idx], quiet = TRUE))
  }

  cleaned <- raw_df |>
    dplyr::mutate(
      trending_date = trending_date_parsed,
      publish_time = safe_parse_datetime(publish_time),
      views = as.numeric(views),
      likes = as.numeric(likes),
      dislikes = as.numeric(dislikes),
      comment_count = as.numeric(comment_count),
      likes = dplyr::coalesce(likes, 0),
      comment_count = dplyr::coalesce(comment_count, 0),
      category_id = as.character(category_id),
      engagement_rate = dplyr::if_else(views > 0, (likes + comment_count) / views, NA_real_),
      like_rate = dplyr::if_else(views > 0, likes / views, NA_real_),
      dislike_rate = dplyr::if_else(views > 0, dislikes / views, NA_real_),
      comment_rate = dplyr::if_else(views > 0, comment_count / views, NA_real_),
      publish_lag_hours = as.numeric(difftime(trending_date, as.Date(publish_time), units = "hours"))
    ) |>
    dplyr::filter(!is.na(trending_date), !is.na(category_id), !is.na(views)) |>
    dplyr::arrange(trending_date)

  cleaned
}

save_clean_data <- function(df, out_path = "data/processed/trending_clean.csv") {
  readr::write_csv(df, out_path)
  message("Saved cleaned data to: ", out_path)
}

raw <- read_trending_files("data/raw")
clean <- prepare_trending_data(raw)
save_clean_data(clean)

message(glue::glue("Rows loaded: {nrow(clean)} | Categories: {dplyr::n_distinct(clean$category_id)} | Regions: {dplyr::n_distinct(clean$region)}"))
