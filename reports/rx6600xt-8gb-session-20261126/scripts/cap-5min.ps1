param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$Log,
    [Parameter(Mandatory)][string]$Exe,
    [Parameter(Mandatory)][string]$Cache,
    [Parameter(Mandatory)][int]$LauncherPid,
    [Parameter(Mandatory)][string]$StartedAt
)

$ErrorActionPreference = 'Continue'
$capSeconds = 300
$capLabel = '5-minute cap'
$stopMarker = Join-Path (Split-Path -Parent $Log) "$RunId-stop-marker.txt"
$deadline = [datetime]::Parse($StartedAt).AddSeconds($capSeconds)
$seenVictory = $false
$victoryPid = $null

function Get-ScopedVictory {
    $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    @($all | Where-Object {
        $_.Name -eq 'victory.exe' -and
        $_.CommandLine -like "*$Exe*" -and
        $_.CommandLine -match '--console\s+series-s'
    })
}

function Get-DescendantIds {
    param([int]$RootPid)
    $all = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $ids = [System.Collections.Generic.List[int]]::new()
    $ids.Add($RootPid)
    do {
        $added = 0
        foreach ($p in $all) {
            if ($ids.Contains([int]$p.ParentProcessId) -and -not $ids.Contains([int]$p.ProcessId)) {
                $ids.Add([int]$p.ProcessId)
                $added++
            }
        }
    } while ($added -gt 0)
    @($ids | Where-Object { $_ -ne $RootPid })
}

while ((Get-Date) -lt $deadline) {
    $v = Get-ScopedVictory
    if ($v.Count -gt 0) {
        $seenVictory = $true
        $victoryPid = [int]$v[0].ProcessId
    } elseif ($seenVictory) {
        $at = Get-Date -Format o
        Set-Content -LiteralPath $stopMarker -Encoding UTF8 -Value @(
            "$RunId natural exit detected at $at; victory.exe PID $victoryPid was gone before the $capLabel; no scoped termination performed."
        )
        break
    }
    Start-Sleep -Seconds 5
}

if ((Get-Date) -ge $deadline -and -not (Test-Path -LiteralPath $stopMarker)) {
    $at = Get-Date -Format o
    $v = Get-ScopedVictory
    $victoryIds = @($v | ForEach-Object { [int]$_.ProcessId })
    $children = if ($victoryIds.Count -gt 0) { @(Get-DescendantIds -RootPid $victoryIds[0]) } else { @() }
    $gameIds = @($children | Where-Object {
        $p = Get-CimInstance Win32_Process -Filter "ProcessId=$_" -ErrorAction SilentlyContinue
        $p -and $p.Name -eq 'game_scarlett_master.exe'
    })
    $targets = @($children + $victoryIds + @($LauncherPid) | Where-Object { $_ -gt 0 } | Select-Object -Unique)

    foreach ($id in @($children + $victoryIds)) {
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
    }
    Stop-Process -Id $LauncherPid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $remaining = @($targets | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
    Set-Content -LiteralPath $stopMarker -Encoding UTF8 -Value @(
        "$RunId $capLabel reached at $at; terminated game PID(s) $($gameIds -join ','); victory.exe PID(s) $($victoryIds -join ','); launcher PID(s) $LauncherPid; scoped processes remaining: $($remaining.Count)."
    )
}

$watchEnd = (Get-Date).AddSeconds(60)
while ((Get-Date) -lt $watchEnd) {
    Start-Sleep -Seconds 5
}

$patterns = @('VIctory: host GPU failure', '0x887A0005', '0x887A0007', '0x8007000E', '0x80070057')
$hits = @()
if (Test-Path -LiteralPath $Log) {
    $hits = @(Select-String -LiteralPath $Log -Pattern $patterns -SimpleMatch -ErrorAction SilentlyContinue)
}
Add-Content -LiteralPath $stopMarker -Encoding UTF8 -Value @(
    "$RunId 1-minute read-only crash monitor ended at $(Get-Date -Format o); failure-marker hits: $($hits.Count)."
)
