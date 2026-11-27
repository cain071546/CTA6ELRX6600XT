param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$Log
)

$ErrorActionPreference = 'Stop'
$ansi = [string][char]27 + '\[[0-9;]*m'
$stamp = '^\d{4}-\d{2}-\d{2}T'
$lines = @(Get-Content -LiteralPath $Log | ForEach-Object { $_ -replace $ansi, '' })

function Get-LastGroup {
    param([Parameter(Mandatory)][string]$Pattern)
    $start = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i].Contains($Pattern)) { $start = $i; break }
    }
    if ($start -lt 0) { return @() }
    $end = $start + 1
    while ($end -lt $lines.Count -and $lines[$end] -notmatch $stamp) { $end++ }
    return @($lines[$start..($end - 1)])
}

function Get-Quantile {
    param([double[]]$Values, [double]$Fraction)
    if ($Values.Count -eq 0) { return 0.0 }
    $sorted = @($Values | Sort-Object)
    $index = [int][Math]::Floor(($sorted.Count - 1) * $Fraction)
    return $sorted[$index]
}

function Show-Series {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Pattern)
    $values = @()
    foreach ($line in $lines) {
        $m = [regex]::Match($line, $Pattern)
        if ($m.Success) {
            $values += [double]::Parse($m.Groups[1].Value, [cultureinfo]::InvariantCulture)
        }
    }
    if ($values.Count -eq 0) {
        "$($Name)_SERIES samples=0"
        return
    }
    $sum = ($values | Measure-Object -Sum).Sum
    "$($Name)_SERIES samples=$($values.Count) cadence=stats-window~5s median=$([Math]::Round((Get-Quantile $values 0.50), 3)) p90=$([Math]::Round((Get-Quantile $values 0.90), 3)) p99=$([Math]::Round((Get-Quantile $values 0.99), 3)) max=$([Math]::Round((Get-Quantile $values 1.0), 3)) sum=$([Math]::Round($sum, 3))"
}

$times = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    $m = [regex]::Match($lines[$i], '^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z)\b.*memory: [0-9.]+ MB private')
    if ($m.Success) {
        $times += [DateTimeOffset]::Parse($m.Groups[1].Value, [cultureinfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal)
    }
}
$gaps = @()
for ($i = 1; $i -lt $times.Count; $i++) {
    $gaps += [double]($times[$i] - $times[$i - 1]).TotalSeconds
}

$failPatterns = @('VIctory: host GPU failure', '0x887A0005', '0x887A0007', '0x8007000E', '0x80070057')
$failures = @($lines | Select-String -Pattern $failPatterns -SimpleMatch)

"RUN $RunId"
"LOG $Log"
"LINES $($lines.Count)"
"FAILURE_MARKER_HITS $($failures.Count)"
"MEMORY_SERIES samples=$($times.Count) gaps=$($gaps.Count) cadence=nominal-5s gap_min=$([Math]::Round((Get-Quantile $gaps 0.0), 6)) gap_median=$([Math]::Round((Get-Quantile $gaps 0.5), 6)) gap_max=$([Math]::Round((Get-Quantile $gaps 1.0), 6))"

Show-Series 'PRESENT_TO_FIRST_LIST_MS' 'after a present ([0-9.]+) ms until the first list call'
Show-Series 'LAST_SUBMIT_TO_PRESENT_MS' '([0-9.]+) ms from the last'
Show-Series 'LIST_RESET_MS' 'lists reset in ([0-9.]+) ms'
Show-Series 'PIPELINE_WAIT_MS' '([0-9.]+) ms waiting for pipelines'
Show-Series 'CPU_USER_MS_ALL_THREADS' 'process ran ([0-9.]+) ms user'
Show-Series 'CPU_KERNEL_MS_ALL_THREADS' 'process ran [0-9.]+ ms user \+ ([0-9.]+) ms kernel'
Show-Series 'HOST_LIST_MAKE_MS' 'host lists made ([0-9.]+) ms'
Show-Series 'REFRESH_MB_PER_FRAME' 'refreshes ([0-9.]+) MB'
Show-Series 'WATCH_MS_PER_FRAME' 'watches ([0-9.]+) ms'
Show-Series 'PAGE_FAULTS_PER_FRAME' '([0-9]+) page faults'
Show-Series 'BACK_SCAN_MS_PER_FRAME' '([0-9.]+) ms finding [0-9]+ pieces that differ'
Show-Series 'SNAPSHOT_MS_PER_FRAME' 'snapshots ([0-9.]+) ms'
Show-Series 'COMPARE_BACK_MB_PER_FRAME' '([0-9.]+) MB compared back'

foreach ($section in @(
    'copies per frame:',
    'recording per frame',
    'frame account per frame:',
    'waiting for the card per frame:',
    "the card's time by what ran:",
    "the card's time by list (timing run), per frame,",
    'copied whole (memory not watched):',
    'INFO victory_gpu::copystat: memory: ',
    'memory by category'
)) {
    "LAST_GROUP [$section]"
    $group = @(Get-LastGroup $section)
    if ($group.Count -eq 0) { 'NONE' } else { $group | ForEach-Object { $_ } }
}
