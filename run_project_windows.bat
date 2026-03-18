@echo off
setlocal enabledelayedexpansion

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

set "NO_PAUSE=0"
set "NO_OPEN=0"
for %%A in (%*) do (
  if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
  if /I "%%~A"=="--no-open" set "NO_OPEN=1"
)

set "R_SCRIPT="

for /f "delims=" %%I in ('where Rscript 2^>nul') do (
  set "R_SCRIPT=%%I"
  goto :found_rscript
)

for /f "delims=" %%I in ('dir /b /ad "C:\Program Files\R\R-*" 2^>nul ^| sort /r') do (
  if exist "C:\Program Files\R\%%I\bin\x64\Rscript.exe" (
    set "R_SCRIPT=C:\Program Files\R\%%I\bin\x64\Rscript.exe"
    goto :found_rscript
  )
  if exist "C:\Program Files\R\%%I\bin\Rscript.exe" (
    set "R_SCRIPT=C:\Program Files\R\%%I\bin\Rscript.exe"
    goto :found_rscript
  )
)

echo [ERROR] Rscript not found.
echo Install R from https://cran.r-project.org/bin/windows/base/
echo and run this launcher again.
if "%NO_PAUSE%"=="0" pause
exit /b 1

:found_rscript
echo [INFO] Using Rscript: %R_SCRIPT%
pushd "%PROJECT_DIR%"
"%R_SCRIPT%" run_project.R
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
  echo [ERROR] Project run failed with exit code %EXIT_CODE%.
  if "%NO_PAUSE%"=="0" pause
  exit /b %EXIT_CODE%
)

if "%NO_OPEN%"=="0" (
  set "REPORT_PATH=%PROJECT_DIR%\report\youtube_trending_report.html"
  if exist "%REPORT_PATH%" (
    start "" "%REPORT_PATH%"
    echo [INFO] Opened report: %REPORT_PATH%
  ) else (
    echo [WARN] Report not found at: %REPORT_PATH%
  )
)

echo [INFO] Project run complete.
if "%NO_PAUSE%"=="0" pause
exit /b 0