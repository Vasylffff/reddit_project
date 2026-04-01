param(
    [string]$TaskName = "REdit Hourly Collection"
)

$ErrorActionPreference = "Stop"

& schtasks.exe /Delete /TN $TaskName /F

Write-Host "Removed task '$TaskName'."
