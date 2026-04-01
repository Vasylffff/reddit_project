param(
    [string]$TaskName = "REdit Hourly Collection",
    [int]$StartMinuteOffset = 0
)

$ErrorActionPreference = "Stop"

if ($StartMinuteOffset -lt 0 -or $StartMinuteOffset -gt 59) {
    throw "StartMinuteOffset must be between 0 and 59."
}

$projectRoot = (Resolve-Path $PSScriptRoot).Path
$runnerScript = Join-Path $projectRoot "run_collection_schedule_window.ps1"
$tempDir = Join-Path $projectRoot ".tmp"
$xmlPath = Join-Path $tempDir "redit_hourly_collection_task.xml"

if (-not (Test-Path $runnerScript)) {
    throw "Runner script not found: $runnerScript"
}

$nextRun = (Get-Date).AddHours(1)
$startTime = Get-Date -Year $nextRun.Year -Month $nextRun.Month -Day $nextRun.Day -Hour $nextRun.Hour -Minute $StartMinuteOffset -Second 0

$userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$startTimeString = $startTime.ToString("HH:mm")
$startBoundary = $startTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
$taskArguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "{0}"' -f $runnerScript

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$([System.DateTime]::Now.ToString("s"))</Date>
    <Author>$userName</Author>
    <Description>Runs the REdit collection schedule hourly with popup summaries.</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$startBoundary</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
      <Repetition>
        <Interval>PT1H</Interval>
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
Write-Host "Hourly start time: $startTimeString"
Write-Host "Runner script: $runnerScript"
Write-Host "Task XML: $xmlPath"

& schtasks.exe /Create /TN $TaskName /XML $xmlPath /F
if ($LASTEXITCODE -ne 0) {
    throw "schtasks.exe failed with exit code $LASTEXITCODE"
}

& schtasks.exe /Query /TN $TaskName /FO LIST /V
if ($LASTEXITCODE -ne 0) {
    throw "Task registration verification failed with exit code $LASTEXITCODE"
}

Write-Host ""
Write-Host "Task installed successfully."
Write-Host "Use this to run it immediately:"
Write-Host ('schtasks /Run /TN "{0}"' -f $TaskName)
