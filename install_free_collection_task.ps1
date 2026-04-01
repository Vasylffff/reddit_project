param(
    [string]$TaskName         = "REdit Free Collection",
    [int]$StartMinuteOffset   = 0,
    [int]$IntervalHours       = 1
)

$ErrorActionPreference = "Stop"

if ($StartMinuteOffset -lt 0 -or $StartMinuteOffset -gt 59) {
    throw "StartMinuteOffset must be between 0 and 59."
}
if ($IntervalHours -lt 1 -or $IntervalHours -gt 24) {
    throw "IntervalHours must be between 1 and 24."
}

$projectRoot   = (Resolve-Path $PSScriptRoot).Path
$runnerScript  = Join-Path $projectRoot "run_free_collection_window.ps1"
$tempDir       = Join-Path $projectRoot ".tmp"
$xmlPath       = Join-Path $tempDir "redit_free_collection_task.xml"

if (-not (Test-Path $runnerScript)) {
    throw "Runner script not found: $runnerScript"
}

$nextRun       = (Get-Date).AddHours(1)
$startTime     = Get-Date -Year $nextRun.Year -Month $nextRun.Month -Day $nextRun.Day -Hour $nextRun.Hour -Minute $StartMinuteOffset -Second 0
$userName      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$startBoundary = $startTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
$intervalIso   = "PT$($IntervalHours)H"
$taskArguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "{0}"' -f $runnerScript

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$([System.DateTime]::Now.ToString("s"))</Date>
    <Author>$userName</Author>
    <Description>Runs collect_reddit_free.py on a schedule — no API key required.</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$startBoundary</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
      <Repetition>
        <Interval>$intervalIso</Interval>
        <Duration>P1D</Duration>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$([System.Security.SecurityElement]::Escape($userName))</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT55M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>$([System.Security.SecurityElement]::Escape($taskArguments))</Arguments>
      <WorkingDirectory>$([System.Security.SecurityElement]::Escape($projectRoot))</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

$xml | Set-Content -Path $xmlPath -Encoding Unicode

Write-Host "Creating task '$TaskName' for user $userName"
Write-Host "Runs every $IntervalHours hour(s), starting at minute :$($StartMinuteOffset.ToString('D2'))"
Write-Host "Runner script: $runnerScript"

& schtasks.exe /Create /TN $TaskName /XML $xmlPath /F
if ($LASTEXITCODE -ne 0) { throw "schtasks.exe failed with exit code $LASTEXITCODE" }

& schtasks.exe /Query /TN $TaskName /FO LIST /V
if ($LASTEXITCODE -ne 0) { throw "Task registration verification failed." }

Write-Host ""
Write-Host "Task installed successfully."
Write-Host "Run it right now with:"
Write-Host ('  schtasks /Run /TN "{0}"' -f $TaskName)
