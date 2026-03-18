# YouTube Trending Videos Analytics (R)

This project is an end-to-end analytics pipeline for public Kaggle YouTube Trending datasets.  
It ingests raw CSV/ZIP files, cleans and standardizes the data, generates trend and engagement analytics, builds visualizations, and renders a final HTML report.

## Project Description

The pipeline focuses on three main analysis goals:
- **Category trend growth** across weekly windows
- **Engagement behavior** using views, likes, and comments
- **Outlier detection** with IQR and Z-score methods

The project does **not** require the YouTube API. It uses only public CSV data.

## Data Input

Place dataset files in one of the following locations:
- `data/raw/` for extracted CSV files like `USvideos.csv`, `INvideos.csv`, etc.
- `data/incoming/` for Kaggle ZIP files (auto-imported during run)

`run_project.R` automatically imports ZIP data from `data/incoming/` into `data/raw/` before analysis.

## How It Works

Running the project executes this workflow:
1. Import Kaggle ZIP (if present)
2. Install/load required R packages
3. Clean and normalize source data
4. Compute analytics and generate visuals
5. Render Quarto HTML report

## Run the Project

From project root (R console):

```r
source("run_project.R")
```

From terminal:

```bash
Rscript run_project.R
```

Windows one-click launcher:

```bat
run_project_windows.bat
```

Launcher options:

```bat
run_project_windows.bat --no-open --no-pause
```

Create Desktop shortcut (one-time):

```powershell
powershell -ExecutionPolicy Bypass -File .\create_desktop_shortcut.ps1
```

## Outputs

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
- `youtube_trending_report.html`

## Metrics and Methods

- **Engagement rate**: `(likes + comment_count) / views`
- **Outlier rules**:
  - IQR threshold: `1.5 × IQR`
  - Z-score threshold: `|z| >= 3` within each category

## Dependencies

R packages are installed automatically when missing. Core packages include:
- `tidyverse`, `lubridate`, `janitor`, `scales`
- `gganimate`, `gifski`, `glue`, `patchwork`

For report rendering, use either:
- R package: `quarto` (`install.packages("quarto")`)
- or Quarto CLI: https://quarto.org
