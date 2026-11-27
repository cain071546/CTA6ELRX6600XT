param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$Log
)

$ErrorActionPreference = 'Stop'
$ansi = [string][char]27 + '\[[0-9;]*m'
$clean = @(Get-Content -LiteralPath $Log | ForEach-Object { $_ -replace $ansi, '' })
$rows = [System.Collections.Generic.List[object]]::new()
foreach ($line in $clean) {
    $stamp = [regex]::Match($line, '^(\d{4}-\d{2}-\d{2}T[0-9:.]+Z)')
    $fps = [regex]::Match($line, '([0-9]+\.[0-9]+) fps,\s*([0-9]+\.[0-9]+) ms/frame')
    if (-not ($stamp.Success -and $fps.Success)) { continue }
    $rows.Add([pscustomobject]@{
        At = [datetime]::Parse($stamp.Groups[1].Value, [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
        Fps = [double]$fps.Groups[1].Value
        FrameMs = [double]$fps.Groups[2].Value
    })
}
$gapValues = @()
for ($i = 1; $i -lt $rows.Count; $i++) {
    $gapValues += ($rows[$i].At - $rows[$i - 1].At).TotalSeconds
}
$gaps = @($gapValues | Sort-Object)
$sortedFps = @($rows | ForEach-Object { $_.Fps } | Sort-Object)
$sortedMs = @($rows | ForEach-Object { $_.FrameMs } | Sort-Object)
function Pct([object[]]$sorted, [double]$p) {
    if ($sorted.Count -eq 0) { return $null }
    $index = [int][Math]::Ceiling(($p / 100.0) * $sorted.Count) - 1
    if ($index -lt 0) { $index = 0 }
    if ($index -ge $sorted.Count) { $index = $sorted.Count - 1 }
    return $sorted[$index]
}
[pscustomobject]@{
    RunId = $RunId
    Log = $Log
    SampleCount = $rows.Count
    GapCount = $gaps.Count
    MinGapS = if ($gaps.Count -gt 0) { [math]::Round($gaps[0], 6) } else { $null }
    MedianGapS = if ($gaps.Count -gt 0) { [math]::Round($gaps[[int][Math]::Floor(($gaps.Count - 1) / 2)], 6) } else { $null }
    MaxGapS = if ($gaps.Count -gt 0) { [math]::Round($gaps[$gaps.Count - 1], 6) } else { $null }
    MeanFps = if ($rows.Count -gt 0) { [math]::Round((($rows | Measure-Object -Property Fps -Average).Average), 3) } else { $null }
    MedianFps = Pct $sortedFps 50
    P90Fps = Pct $sortedFps 90
    P99Fps = Pct $sortedFps 99
    MinFps = if ($rows.Count -gt 0) { [math]::Round($sortedFps[0], 3) } else { $null }
    MaxFps = if ($rows.Count -gt 0) { [math]::Round($sortedFps[$sortedFps.Count - 1], 3) } else { $null }
    MedianFrameMs = Pct $sortedMs 50
    P90FrameMs = Pct $sortedMs 90
    P99FrameMs = Pct $sortedMs 99
    MaxFrameMs = if ($rows.Count -gt 0) { [math]::Round($sortedMs[$sortedMs.Count - 1], 3) } else { $null }
}
