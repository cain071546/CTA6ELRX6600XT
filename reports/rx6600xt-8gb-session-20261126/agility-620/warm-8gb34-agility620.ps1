$ErrorActionPreference = 'Continue'
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = 'BelowNormal'

$repo = 'C:\users\mrgre\victory-7900XTX'
$victory = Join-Path $repo 'target\diag\victory.exe'
$expectedBuildHash = '15D934F2905336A2E0E0C661AA01790D1A9FB91CA21E063D1A8C74D86A8AF699'
$warmSource = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb18-book'
$cache = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb34-agility620'
$log = 'C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb34-agility620-warm.log'
$summary = 'C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb34-agility620-warm-summary.txt'

if (-not (Test-Path -LiteralPath $victory)) { throw "No build: $victory" }
if ((Get-FileHash -LiteralPath $victory -Algorithm SHA256).Hash -ne $expectedBuildHash) {
    throw 'Diagnostics build hash changed; warm aborted.'
}
if (-not (Test-Path -LiteralPath (Join-Path $warmSource 'pipelines\known-pipelines.bin'))) {
    throw "Warm source book is missing: $warmSource"
}
if (-not (Test-Path -LiteralPath (Join-Path $warmSource 'pipelines\early-pipelines.txt'))) {
    throw "Warm source early list is missing: $warmSource"
}

if (-not (Test-Path -LiteralPath $cache)) {
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
}
foreach ($name in @('known-pipelines.bin', 'known-shaders.bin', 'early-pipelines.txt')) {
    $dest = Join-Path $cache "pipelines\$name"
    if (-not (Test-Path -LiteralPath $dest)) {
        Copy-Item -LiteralPath (Join-Path $warmSource "pipelines\$name") -Destination $dest -Force
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $cache 'pipelines\known-pipelines.bin'))) {
    throw 'Warm cache known-pipelines.bin is missing after copy.'
}

# Force all used pipelines to be made under SDK 620 rather than trusting 614 lists/blobs.
foreach ($name in @('warm-done.txt', 'warm-bad.txt', 'slow-pipelines.txt', 'host-pipelines.bin', 'host-pipelines.next')) {
    $path = Join-Path $cache "pipelines\$name"
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }

$env:VICTORY_CACHE_DIR = $cache
Set-Location -LiteralPath $repo
& $victory warm --used --jobs 2 2>&1 | Tee-Object -FilePath $log
$exitCode = $LASTEXITCODE

$doneFile = Join-Path $cache 'pipelines\warm-done.txt'
$badFile = Join-Path $cache 'pipelines\warm-bad.txt'
$sdkFile = Join-Path $cache 'pipelines\agility-sdk.txt'
$doneLines = if (Test-Path -LiteralPath $doneFile) { @(Get-Content -LiteralPath $doneFile).Count } else { 0 }
$badLines = if (Test-Path -LiteralPath $badFile) { @(Get-Content -LiteralPath $badFile).Count } else { 0 }
$sdk = if (Test-Path -LiteralPath $sdkFile) { (Get-Content -LiteralPath $sdkFile -Raw).Trim() } else { '(missing)' }
Set-Content -LiteralPath $summary -Encoding UTF8 -Value @(
    "warm --used --jobs 2 finished at $(Get-Date -Format o) with exit code $exitCode.",
    "process_priority=BelowNormal",
    "cache: $cache",
    "build_sha256: $expectedBuildHash",
    "agility-sdk.txt: $sdk",
    "warm-done.txt lines: $doneLines",
    "warm-bad.txt lines: $badLines",
    "log: $log"
)
if ($exitCode -ne 0) { throw "warm --used exited $exitCode; see $log" }
