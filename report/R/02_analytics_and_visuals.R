source("report/R/00_setup_packages.R")

clean_path <- "data/processed/trending_clean.csv"
if (!file.exists(clean_path)) {
  stop("Clean dataset not found. Run R/01_load_and_clean.R first.")
}

df <- readr::read_csv(clean_path, show_col_types = FALSE) |>
  dplyr::mutate(
    trending_date = as.Date(trending_date),
    category_id = as.factor(category_id),
    week = lubridate::floor_date(trending_date, unit = "week", week_start = 1),
    weekday = lubridate::wday(trending_date, label = TRUE, week_start = 1)
  )

# 1) Category growth analytics -------------------------------------------------
weekly_category <- df |>
  dplyr::group_by(week, category_id) |>
  dplyr::summarise(
    trending_count = dplyr::n(),
    mean_engagement = mean(engagement_rate, na.rm = TRUE),
    .groups = "drop"
  )

category_growth <- weekly_category |>
  dplyr::group_by(category_id) |>
  dplyr::arrange(week, .by_group = TRUE) |>
  dplyr::mutate(
    previous_count = dplyr::lag(trending_count),
    growth_rate = dplyr::if_else(!is.na(previous_count) & previous_count > 0,
                                 (trending_count - previous_count) / previous_count,
                                 NA_real_)
  ) |>
  dplyr::ungroup()

category_growth_summary <- category_growth |>
  dplyr::group_by(category_id) |>
  dplyr::summarise(
    avg_weekly_count = mean(trending_count, na.rm = TRUE),
    median_growth_rate = median(growth_rate, na.rm = TRUE),
    max_growth_rate = max(growth_rate, na.rm = TRUE),
    min_growth_rate = min(growth_rate, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(avg_weekly_count))

readr::write_csv(category_growth, "outputs/tables/category_growth_weekly.csv")
readr::write_csv(category_growth_summary, "outputs/tables/category_growth_summary.csv")

# 2) Engagement analytics + outliers ------------------------------------------
engagement_summary <- df |>
  dplyr::group_by(category_id) |>
  dplyr::summarise(
    videos = dplyr::n(),
    median_views = median(views, na.rm = TRUE),
    avg_engagement_rate = mean(engagement_rate, na.rm = TRUE),
    p95_engagement_rate = stats::quantile(engagement_rate, 0.95, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(avg_engagement_rate))

outliers <- df |>
  dplyr::group_by(category_id) |>
  dplyr::mutate(
    z_engagement = as.numeric(scale(engagement_rate)),
    q1 = stats::quantile(engagement_rate, 0.25, na.rm = TRUE),
    q3 = stats::quantile(engagement_rate, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    outlier_iqr = engagement_rate > (q3 + 1.5 * iqr) | engagement_rate < (q1 - 1.5 * iqr),
    outlier_z = abs(z_engagement) >= 3
  ) |>
  dplyr::ungroup() |>
  dplyr::filter(outlier_iqr | outlier_z) |>
  dplyr::arrange(dplyr::desc(engagement_rate)) |>
  dplyr::select(trending_date, region, category_id, video_id, title, channel_title, views, likes, comment_count, engagement_rate, z_engagement, outlier_iqr, outlier_z)

readr::write_csv(engagement_summary, "outputs/tables/engagement_summary.csv")
readr::write_csv(outliers, "outputs/tables/engagement_outliers.csv")

# 3) Visuals ------------------------------------------------------------------

# 3a) Animated rank chart (gganimate): weekly top categories by trending_count
rank_data <- weekly_category |>
  dplyr::group_by(week) |>
  dplyr::mutate(rank = dense_rank(desc(trending_count))) |>
  dplyr::ungroup() |>
  dplyr::filter(rank <= 10)

p_rank <- ggplot2::ggplot(
  rank_data,
  ggplot2::aes(x = -rank, y = trending_count, fill = category_id)
) +
  ggplot2::geom_col(show.legend = FALSE, width = 0.8) +
  ggplot2::geom_text(
    ggplot2::aes(label = category_id),
    hjust = 1.15,
    color = "white",
    size = 3.3
  ) +
  ggplot2::coord_flip(clip = "off") +
  ggplot2::scale_x_continuous(
    breaks = -1:-10,
    labels = 1:10,
    expand = c(0, 0)
  ) +
  ggplot2::scale_y_continuous(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
  ggplot2::labs(
    title = "Top Trending Categories by Week",
    subtitle = "Week: {frame_time}",
    x = "Rank (1 = highest)",
    y = "Trending video count"
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(plot.margin = ggplot2::margin(5.5, 50, 5.5, 5.5)) +
  gganimate::transition_time(week) +
  gganimate::ease_aes("cubic-in-out")

anim <- gganimate::animate(
  p_rank,
  nframes = max(60, dplyr::n_distinct(rank_data$week) * 2),
  fps = 12,
  width = 900,
  height = 550,
  renderer = gganimate::gifski_renderer(loop = TRUE)
)

gganimate::anim_save("outputs/figures/category_rank_animation.gif", animation = anim)

# 3b) Engagement scatter
scatter_sample <- df |>
  dplyr::filter(is.finite(engagement_rate), is.finite(views), views > 0, engagement_rate >= 0) |>
  dplyr::sample_n(size = min(8000, dplyr::n()), replace = FALSE)

p_scatter <- ggplot2::ggplot(scatter_sample, ggplot2::aes(x = views, y = engagement_rate, color = category_id)) +
  ggplot2::geom_point(alpha = 0.5, size = 1.4) +
  ggplot2::scale_x_log10(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.01)) +
  ggplot2::labs(
    title = "Engagement Rate vs Views",
    subtitle = "Each point is a trending video observation",
    x = "Views (log scale)",
    y = "Engagement rate = (likes + comments) / views",
    color = "Category"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave("outputs/figures/engagement_scatter.png", p_scatter, width = 10, height = 6, dpi = 150)

# 3c) Category heatmap (weekday × category)
heatmap_data <- df |>
  dplyr::group_by(weekday, category_id) |>
  dplyr::summarise(
    avg_engagement = mean(engagement_rate, na.rm = TRUE),
    n = dplyr::n(),
    .groups = "drop"
  )

p_heatmap <- ggplot2::ggplot(heatmap_data, ggplot2::aes(x = weekday, y = category_id, fill = avg_engagement)) +
  ggplot2::geom_tile() +
  ggplot2::scale_fill_viridis_c(labels = scales::percent_format(accuracy = 0.01), option = "C") +
  ggplot2::labs(
    title = "Category Engagement Heatmap",
    subtitle = "Average engagement rate by weekday and category",
    x = "Weekday",
    y = "Category",
    fill = "Avg engagement"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave("outputs/figures/category_engagement_heatmap.png", p_heatmap, width = 10, height = 7, dpi = 150)

message("Analytics and visuals completed. Check outputs/tables and outputs/figures.")
