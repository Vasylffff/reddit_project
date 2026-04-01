param(
    [string]$TaskName = "REdit Free Collection"
)

$ErrorActionPreference = "Stop"

& schtasks.exe /Delete /TN $TaskName /F
if ($LASTEXITCODE -ne 0) { throw "schtasks.exe failed with exit code $LASTEXITCODE" }

Write-Host "Task '$TaskName' removed."
