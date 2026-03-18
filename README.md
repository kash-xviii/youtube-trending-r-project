# YouTube Trending Videos Analytics (No API)

This project analyzes public **Kaggle YouTube Trending CSV data** and produces:
- Category growth trends
- Engagement-rate analytics
- Outlier detection
- Visuals:
  - Animated rank chart (`gganimate`)
  - Engagement scatter plot
  - Category heatmap

## 1) Dataset

Download one or more Kaggle YouTube trending CSV files (for example: `USvideos.csv`, `GBvideos.csv`, `INvideos.csv`) and place them in:

- `data/raw/`

The script automatically reads all files ending with `videos.csv`.

### Easier option (ZIP auto-import)

You can place the Kaggle ZIP file directly in:

- `data/incoming/`

When you run `run_project.R`, the project automatically unzips and copies CSV files into `data/raw/` before analysis.

## 2) Run

From the project root:

```r
source("run_project.R")
```

or from terminal:

```bash
Rscript run_project.R
```

On Windows, you can also double-click:

```bat
run_project_windows.bat
```

After a successful run, the launcher opens `report/youtube_trending_report.html` automatically.

Optional flags:

```bat
run_project_windows.bat --no-open --no-pause
```

To create a Desktop shortcut (one-time):

```powershell
powershell -ExecutionPolicy Bypass -File .\create_desktop_shortcut.ps1
```

## 3) Outputs

### Tables (`outputs/tables`)
- `category_growth_weekly.csv`
- `category_growth_summary.csv`
- `engagement_summary.csv`
- `engagement_outliers.csv`

### Figures (`outputs/figures`)
- `category_rank_animation.gif`
- `engagement_scatter.png`
- `category_engagement_heatmap.png`

### Report (`report`)
- `youtube_trending_report.html` (rendered from `youtube_trending_report.qmd`)

## 4) Notes

- Engagement rate is defined as:
  - `(likes + comment_count) / views`
- Outliers are detected using:
  - IQR rule (1.5 × IQR)
  - Z-score threshold (`|z| >= 3`) within category
- The project uses only public CSV datasets and no YouTube API.

## 5) Quarto Report

The pipeline now renders a Quarto HTML report automatically at the end of `run_project.R`.

If Quarto package/CLI is not available, install one of these:

```r
install.packages("quarto")
```

or install Quarto CLI from:

- https://quarto.org
