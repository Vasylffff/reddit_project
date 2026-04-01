param(
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$resolvedProjectRoot = (Resolve-Path $ProjectRoot).Path
$pythonPath = Join-Path $resolvedProjectRoot ".venv\Scripts\python.exe"
$schedulerScript = Join-Path $resolvedProjectRoot "run_free_collection_schedule.py"
$historyScript = Join-Path $resolvedProjectRoot "build_reddit_history.py"
$freePoolBuilderScript = Join-Path $resolvedProjectRoot "build_free_tracking_pool.py"
$freePoolPath = Join-Path $resolvedProjectRoot "data\tracking\free_observation_pool_latest.csv"
$freeTrackingScript = Join-Path $resolvedProjectRoot "collect_reddit_free.py"
$predictionScript = Join-Path $resolvedProjectRoot "build_prediction_dataset.py"
$naiveForecastScript = Join-Path $resolvedProjectRoot "build_naive_forecast.py"
$naiveForecastEvaluationScript = Join-Path $resolvedProjectRoot "evaluate_naive_forecast.py"
$caseStudyScript = Join-Path $resolvedProjectRoot "build_post_case_studies.py"
$validationScript = Join-Path $resolvedProjectRoot "validate_history_data.py"
$sqliteExportScript = Join-Path $resolvedProjectRoot "export_history_to_sqlite.py"
$logDir = Join-Path $resolvedProjectRoot "logs\collection_schedule"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runStartedAt = Get-Date
$logPath = Join-Path $logDir "$timestamp.log"
$mutexName = "Global\REditCollectionScheduleMutex"
$trackedCommentLimit = 5

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-CollectionLog {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Lines
    )

    @($Lines | ForEach-Object { [string]$_ }) | Set-Content -Path $logPath -Encoding UTF8
}

function Append-CollectionLog {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Lines
    )

    @($Lines | ForEach-Object { [string]$_ }) | Add-Content -Path $logPath -Encoding UTF8
}

function Start-CollectionPopup {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Icon = "Information",
        [int]$TimeoutSeconds = 20
    )
    return
}

$mutex = [System.Threading.Mutex]::new($false, $mutexName)
$hasLock = $false

try {
    $hasLock = $mutex.WaitOne(0, $false)
    if (-not $hasLock) {
        $message = "Another Reddit collection schedule run is already active. This run was skipped."
        Write-CollectionLog -Lines @(
            "Started: $($runStartedAt.ToString('o'))"
            "Project root: $resolvedProjectRoot"
            ""
            $message
        )
        Start-CollectionPopup -Title "REdit Collection Schedule" -Message $message -Icon Information -TimeoutSeconds 10
        exit 0
    }

    if (-not (Test-Path $pythonPath)) {
        throw "Virtual environment interpreter not found: $pythonPath"
    }

    if (-not (Test-Path $schedulerScript)) {
        throw "Free scheduler script not found: $schedulerScript"
    }

    Set-Location $resolvedProjectRoot
    $scheduledHourLabel = Get-Date -Format "HH"
    Write-CollectionLog -Lines @(
        "Started: $($runStartedAt.ToString('o'))"
        "Project root: $resolvedProjectRoot"
        "Python: $pythonPath"
        "Mode: free-only automatic collection"
        ""
        "Run in progress..."
    )

    $collectorOutput = & $pythonPath $schedulerScript 2>&1
    $collectorExitCode = $LASTEXITCODE
    $collectorText = ($collectorOutput | Out-String).Trim()
    Append-CollectionLog -Lines @("", "Free discovery exit code: $collectorExitCode")

    $historyExitCode = $null
    $historyText = ""
    if (Test-Path $historyScript) {
        $historyOutput = & $pythonPath $historyScript 2>&1
        $historyExitCode = $LASTEXITCODE
        $historyText = ($historyOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "History refresh exit code: $historyExitCode")
    }

    $freePoolBuildExitCode = $null
    $freePoolBuildText = ""
    if ((($historyExitCode -eq $null) -or $historyExitCode -eq 0) -and (Test-Path $freePoolBuilderScript)) {
        $freePoolBuildOutput = & $pythonPath $freePoolBuilderScript `
            --source "data/history/reddit/latest_post_status.csv" `
            --output $freePoolPath `
            --max-posts 1000 `
            --per-subreddit-limit 250 2>&1
        $freePoolBuildExitCode = $LASTEXITCODE
        $freePoolBuildText = ($freePoolBuildOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Free observation pool build exit code: $freePoolBuildExitCode")
    }

    $freePoolFetchExitCode = $null
    $freePoolFetchText = ""
    if (($freePoolBuildExitCode -eq 0) -and (Test-Path $freeTrackingScript) -and (Test-Path $freePoolPath)) {
        $freePoolFetchOutput = & $pythonPath $freeTrackingScript `
            --post-urls-file $freePoolPath `
            --comment-limit-per-post $trackedCommentLimit `
            --output-format reddit_json `
            --output-dir "data/raw/reddit_json" `
            --schedule-name "free_tracking_pool" `
            --cadence-label "hourly" `
            --scheduled-hour $scheduledHourLabel 2>&1
        $freePoolFetchExitCode = $LASTEXITCODE
        $freePoolFetchText = ($freePoolFetchOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Free observation pool fetch exit code: $freePoolFetchExitCode")
    }

    $postPoolHistoryExitCode = $null
    $postPoolHistoryText = ""
    if (($freePoolFetchExitCode -ne $null) -and (Test-Path $historyScript)) {
        $postPoolHistoryOutput = & $pythonPath $historyScript 2>&1
        $postPoolHistoryExitCode = $LASTEXITCODE
        $postPoolHistoryText = ($postPoolHistoryOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Post-pool history refresh exit code: $postPoolHistoryExitCode")
    }

    $predictionExitCode = $null
    $predictionText = ""
    if ((($historyExitCode -eq $null) -or $historyExitCode -eq 0) -and (Test-Path $predictionScript)) {
        $predictionOutput = & $pythonPath $predictionScript 2>&1
        $predictionExitCode = $LASTEXITCODE
        $predictionText = ($predictionOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Prediction dataset exit code: $predictionExitCode")
    }

    $naiveForecastExitCode = $null
    $naiveForecastText = ""
    if ((($predictionExitCode -eq $null) -or $predictionExitCode -eq 0) -and (Test-Path $naiveForecastScript)) {
        $naiveForecastOutput = & $pythonPath $naiveForecastScript 2>&1
        $naiveForecastExitCode = $LASTEXITCODE
        $naiveForecastText = ($naiveForecastOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Naive forecast exit code: $naiveForecastExitCode")
    }

    $naiveForecastEvaluationExitCode = $null
    $naiveForecastEvaluationText = ""
    if ((($naiveForecastExitCode -eq $null) -or $naiveForecastExitCode -eq 0) -and (Test-Path $naiveForecastEvaluationScript)) {
        $naiveForecastEvaluationOutput = & $pythonPath $naiveForecastEvaluationScript 2>&1
        $naiveForecastEvaluationExitCode = $LASTEXITCODE
        $naiveForecastEvaluationText = ($naiveForecastEvaluationOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Naive forecast evaluation exit code: $naiveForecastEvaluationExitCode")
    }

    $caseStudyExitCode = $null
    $caseStudyText = ""
    if ((($naiveForecastEvaluationExitCode -eq $null) -or $naiveForecastEvaluationExitCode -eq 0) -and (Test-Path $caseStudyScript)) {
        $caseStudyOutput = & $pythonPath $caseStudyScript 2>&1
        $caseStudyExitCode = $LASTEXITCODE
        $caseStudyText = ($caseStudyOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Case-study builder exit code: $caseStudyExitCode")
    }

    $validationExitCode = $null
    $validationText = ""
    if ((($caseStudyExitCode -eq $null) -or $caseStudyExitCode -eq 0) -and (Test-Path $validationScript)) {
        $validationOutput = & $pythonPath $validationScript 2>&1
        $validationExitCode = $LASTEXITCODE
        $validationText = ($validationOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "Validation exit code: $validationExitCode")
    }

    $sqliteExitCode = $null
    $sqliteText = ""
    if ((($validationExitCode -eq $null) -or $validationExitCode -eq 0) -and (Test-Path $sqliteExportScript)) {
        $sqliteOutput = & $pythonPath $sqliteExportScript 2>&1
        $sqliteExitCode = $LASTEXITCODE
        $sqliteText = ($sqliteOutput | Out-String).Trim()
        Append-CollectionLog -Lines @("", "SQLite export exit code: $sqliteExitCode")
    }

    $exitCode = if (
        $collectorExitCode -eq 0 -and
        (($historyExitCode -eq $null) -or $historyExitCode -eq 0) -and
        (($freePoolBuildExitCode -eq $null) -or $freePoolBuildExitCode -eq 0) -and
        (($postPoolHistoryExitCode -eq $null) -or $postPoolHistoryExitCode -eq 0) -and
        (($predictionExitCode -eq $null) -or $predictionExitCode -eq 0) -and
        (($naiveForecastExitCode -eq $null) -or $naiveForecastExitCode -eq 0) -and
        (($naiveForecastEvaluationExitCode -eq $null) -or $naiveForecastEvaluationExitCode -eq 0) -and
        (($caseStudyExitCode -eq $null) -or $caseStudyExitCode -eq 0) -and
        (($validationExitCode -eq $null) -or $validationExitCode -eq 0) -and
        (($sqliteExitCode -eq $null) -or $sqliteExitCode -eq 0)
    ) { 0 } else { 1 }
    $outputSections = @()
    if ($collectorText) {
        $outputSections += "Free discovery output:"
        $outputSections += $collectorText
    }
    if ($historyExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "History refresh exit code: $historyExitCode"
        if ($historyText) {
            $outputSections += $historyText
        }
    }
    if ($freePoolBuildExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Free observation pool build exit code: $freePoolBuildExitCode"
        if ($freePoolBuildText) {
            $outputSections += $freePoolBuildText
        }
    }
    if ($freePoolFetchExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Free observation pool fetch exit code: $freePoolFetchExitCode"
        if ($freePoolFetchText) {
            $outputSections += $freePoolFetchText
        }
    }
    if ($postPoolHistoryExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Post-pool history refresh exit code: $postPoolHistoryExitCode"
        if ($postPoolHistoryText) {
            $outputSections += $postPoolHistoryText
        }
    }
    if ($freePoolFetchExitCode -ne $null -and $freePoolFetchExitCode -ne 0) {
        $outputSections += ""
        $outputSections += "Free observation pool fetch warning: continuing without this optional refresh."
    }
    if ($predictionExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Prediction dataset exit code: $predictionExitCode"
        if ($predictionText) {
            $outputSections += $predictionText
        }
    }
    if ($naiveForecastExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Naive forecast exit code: $naiveForecastExitCode"
        if ($naiveForecastText) {
            $outputSections += $naiveForecastText
        }
    }
    if ($naiveForecastEvaluationExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Naive forecast evaluation exit code: $naiveForecastEvaluationExitCode"
        if ($naiveForecastEvaluationText) {
            $outputSections += $naiveForecastEvaluationText
        }
    }
    if ($caseStudyExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Case-study builder exit code: $caseStudyExitCode"
        if ($caseStudyText) {
            $outputSections += $caseStudyText
        }
    }
    if ($validationExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "Validation exit code: $validationExitCode"
        if ($validationText) {
            $outputSections += $validationText
        }
    }
    if ($sqliteExitCode -ne $null) {
        $outputSections += ""
        $outputSections += "SQLite export exit code: $sqliteExitCode"
        if ($sqliteText) {
            $outputSections += $sqliteText
        }
    }
    $outputText = ($outputSections | Out-String).Trim()

    $logLines = @(
        ""
        "Completed: $(Get-Date -Format o)"
        "Started: $($runStartedAt.ToString('o'))"
        "Project root: $resolvedProjectRoot"
        "Python: $pythonPath"
        "Collector exit code: $collectorExitCode"
        "History exit code: $historyExitCode"
        "Free observation pool build exit code: $freePoolBuildExitCode"
        "Free observation pool fetch exit code: $freePoolFetchExitCode"
        "Post-pool history exit code: $postPoolHistoryExitCode"
        "Actor tracking: disabled"
        "Prediction dataset exit code: $predictionExitCode"
        "Naive forecast exit code: $naiveForecastExitCode"
        "Naive forecast evaluation exit code: $naiveForecastEvaluationExitCode"
        "Case-study builder exit code: $caseStudyExitCode"
        "Validation exit code: $validationExitCode"
        "SQLite export exit code: $sqliteExitCode"
        "Combined exit code: $exitCode"
        ""
        $outputText
    )
    Append-CollectionLog -Lines $logLines

    if (-not $outputText) {
        $outputText = "The schedule runner completed without console output."
    }

    if ($exitCode -eq 0) {
        $summary = "Collection schedule finished successfully.`n`n$outputText`n`nLog: $logPath"
        $icon = "Information"
        $timeoutSeconds = 20
    } else {
        $summary = "Collection schedule failed.`n`n$outputText`n`nLog: $logPath"
        $icon = "Error"
        $timeoutSeconds = 45
    }

    Start-CollectionPopup `
        -Title "REdit Collection Schedule" `
        -Message $summary `
        -Icon $icon `
        -TimeoutSeconds $timeoutSeconds

    exit $exitCode
}
catch {
    $message = "Collection schedule crashed.`n`n$($_.Exception.Message)`n`nLog: $logPath"
    Append-CollectionLog -Lines @(
        ""
        "Crashed: $(Get-Date -Format o)"
        "Started: $($runStartedAt.ToString('o'))"
        "Project root: $resolvedProjectRoot"
        ""
        $_ | Out-String
    )

    Start-CollectionPopup -Title "REdit Collection Schedule" -Message $message -Icon Error -TimeoutSeconds 60
    exit 1
}
finally {
    if ($hasLock) {
        $mutex.ReleaseMutex() | Out-Null
    }
    $mutex.Dispose()
}
