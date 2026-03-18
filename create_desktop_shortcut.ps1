param(
  [string]$ShortcutName = "Run YouTube Trending Report.lnk"
)

$projectDir = $PSScriptRoot
$launcherPath = Join-Path $projectDir "run_project_windows.bat"

if (-not (Test-Path $launcherPath)) {
  throw "Launcher not found: $launcherPath"
}

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath $ShortcutName

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcherPath
$shortcut.WorkingDirectory = $projectDir
$shortcut.Description = "Run YouTube trending analytics pipeline and open the report"
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,174"
$shortcut.Save()

Write-Host "Created shortcut:" $shortcutPath