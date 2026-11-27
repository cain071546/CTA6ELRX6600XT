$ErrorActionPreference = 'Stop'
$runId = '8gb32-port-constants'
$repo = 'C:\users\mrgre\victory-7900XTX'
$exe = 'C:\users\mrgre\downloads\gta6\game_scarlett_master.exe'
$victory = Join-Path $repo 'target\diag\victory.exe'
$wrapper = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1'
$wrapperBackup = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1.bak-8gb26'
$tempLauncher = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-series-s.ps1'
$monitor = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cap-5min.ps1'
$invoke = 'C:\Users\mrgre\AppData\Local\Temp\opencode\invoke-8gb32-port-constants.ps1'
$cache = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb32-port-constants'
$warmCache = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb18-book'
$log = 'C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb32-port-constants.log'
$startMarker = 'C:\Users\mrgre\AppData\Local\Temp\opencode\8gb32-port-constants-start-marker.txt'
$expectedBuildHash = '26E124D8F539B09B730753B73392FD487E5B0CC73AADFE507DD82A40970A4740'
$expectedWrapperHash = '9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7'

function Get-ScopedVictory {
    @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -eq 'victory.exe' -and
        $_.CommandLine -like "*$exe*" -and
        $_.CommandLine -match '--console\s+series-s'
    })
}

if (Get-ScopedVictory) { throw "A scoped victory.exe for $exe is already running; launch aborted." }
if ((Get-FileHash -LiteralPath $victory -Algorithm SHA256).Hash -ne $expectedBuildHash) { throw 'Diagnostics build hash changed; launch aborted.' }
if ((Get-FileHash -LiteralPath $wrapper -Algorithm SHA256).Hash -ne $expectedWrapperHash) { throw 'Required wrapper hash changed; launch aborted.' }
if (-not (Test-Path -LiteralPath $tempLauncher)) { throw "No temp Series S launcher: $tempLauncher" }

$knownBook = Join-Path $warmCache 'pipelines\known-pipelines.bin'
$doneBook = Join-Path $warmCache 'pipelines\warm-done.txt'
if (-not (Test-Path -LiteralPath $knownBook)) { throw "Warm pipeline book is missing: $knownBook" }
if (-not (Test-Path -LiteralPath $doneBook)) { throw "Warm done list is missing: $doneBook" }
if (@(Get-Content -LiteralPath $doneBook).Count -eq 0) { throw "Warm done list is empty: $doneBook" }
if (Test-Path -LiteralPath $cache) {
    if (@(Get-ChildItem -LiteralPath $cache -Force -ErrorAction SilentlyContinue).Count -gt 0) {
        throw "Measured cache directory is not empty: $cache"
    }
} else {
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
}
Copy-Item -Path (Join-Path $warmCache '*') -Destination $cache -Recurse -Force
if (-not (Test-Path -LiteralPath (Join-Path $cache 'pipelines\known-pipelines.bin'))) {
    throw 'Warm pipeline book was not copied into the measured cache; launch aborted.'
}
Copy-Item -LiteralPath $wrapper -Destination $wrapperBackup -Force

$started = Get-Date -Format o
$launcherPid = 0
$consoleSeen = $false
try {
    $text = Get-Content -Raw -LiteralPath $wrapper
    $old = "`$play = 'C:\users\mrgre\victory-7900XTX\scripts\play.ps1'"
    $new = "`$play = '$tempLauncher'"
    if (-not $text.Contains($old)) { throw 'Wrapper launcher line not found; launch aborted.' }
    Set-Content -LiteralPath $wrapper -Encoding UTF8 -Value ($text.Replace($old, $new).TrimEnd())

    $launcher = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', "`"$invoke`""
    ) -WindowStyle Hidden -PassThru
    $launcherPid = [int]$launcher.Id

    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 500
        if (Get-ScopedVictory) { $consoleSeen = $true; break }
    }
    if (-not $consoleSeen) { throw 'victory.exe with --console series-s was not seen within 10 s; launch aborted.' }
}
finally {
    Copy-Item -LiteralPath $wrapperBackup -Destination $wrapper -Force
    if ((Get-FileHash -LiteralPath $wrapper -Algorithm SHA256).Hash -ne $expectedWrapperHash) {
        throw 'Wrapper restore failed; do not launch again until it is fixed.'
    }
}

Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', "`"$monitor`"",
    '-RunId', "`"$runId`"", '-Log', "`"$log`"", '-Exe', "`"$exe`"", '-Cache', "`"$cache`"",
    '-LauncherPid', "$launcherPid", '-StartedAt', "`"$started`""
) -WindowStyle Hidden | Out-Null

Set-Content -LiteralPath $startMarker -Encoding UTF8 -Value @(
    "$runId launched at $started; hidden window; prepared during the pause after 8gb31-deep-inplace completed and launched only after explicit user approval. Base is exactly the passed 8gb30-minimal-stable setting set; this run adds only VICTORY_PORT_CONSTANTS=1 and VICTORY_CARD_BUFFERS_MIN_KB=64. It targets the 174 MB constants ring's host copy and the default bounded card-buffer path without the failed VICTORY_CARD_BUFFERS_MB=256 cap. Same warmed pipeline state copied from cache-8gb18-book; required wrapper with temporary Series S launcher; console flag confirmed before wrapper restore; hidden launcher PID $launcherPid; build hash $expectedBuildHash; wrapper restored byte-identical $expectedWrapperHash. 5-minute cap; failure-marker count from the 1-minute read-only monitor is the go/no-go for stability."
)
