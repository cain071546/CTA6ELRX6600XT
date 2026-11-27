param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$Log
)

$ErrorActionPreference = 'Stop'
$ansi = [string][char]27 + '\[[0-9;]*m'
$lines = @(Get-Content -LiteralPath $Log | ForEach-Object { $_ -replace $ansi, '' })
$waits = @()
foreach ($line in $lines) {
    $m = [regex]::Match($line, '([0-9]+(?:\.[0-9]+)?)\s*ms waiting for pipelines')
    if ($m.Success) { $waits += [double]::Parse($m.Groups[1].Value, [cultureinfo]::InvariantCulture) }
}
$sorted = @($waits | Sort-Object)
$q = { param([double[]]$values, [double]$fraction)
    if ($values.Count -eq 0) { return 0.0 }
    $index = [int][Math]::Floor(($values.Count - 1) * $fraction)
    return $values[$index]
}
$nonzero = @($waits | Where-Object { $_ -gt 0 })
$translated = @($lines | Select-String -Pattern 'shader translated' -SimpleMatch).Count

[pscustomobject]@{
    RunId = $RunId
    Log = $Log
    WindowCount = $waits.Count
    NonzeroWindowCount = $nonzero.Count
    MaxWaitMs = if ($sorted.Count -gt 0) { $sorted[-1] } else { 0.0 }
    MedianWaitMs = & $q $sorted 0.50
    P90WaitMs = & $q $sorted 0.90
    P99WaitMs = & $q $sorted 0.99
    SumWaitMs = [Math]::Round((($waits | Measure-Object -Sum).Sum), 3)
    ShaderTranslatedLines = $translated
}
