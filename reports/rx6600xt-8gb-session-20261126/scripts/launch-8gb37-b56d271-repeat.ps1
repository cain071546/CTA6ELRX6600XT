$ErrorActionPreference = 'Stop'
$runId = '8gb37-b56d271-repeat'
$repo = 'C:\users\mrgre\victory-7900XTX'
$exe = 'C:\users\mrgre\downloads\gta6\game_scarlett_master.exe'
$victory = Join-Path $repo 'target\diag\victory.exe'
$wrapper = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1'
$wrapperBackup = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1.bak-8gb37'
$tempLauncher = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-series-s.ps1'
$monitor = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cap-5min.ps1'
$invoke = 'C:\Users\mrgre\AppData\Local\Temp\opencode\invoke-8gb37-b56d271-repeat.ps1'
$cache = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb37-b56d271-repeat'
$log = 'C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb37-b56d271-repeat.log'
$startMarker = 'C:\Users\mrgre\AppData\Local\Temp\opencode\8gb37-b56d271-repeat-start-marker.txt'
$stopMarker = 'C:\Users\mrgre\AppData\Local\Temp\opencode\8gb37-b56d271-repeat-stop-marker.txt'
$expectedBuildHash = 'F472D6BCEE923407BB20F6DCCF106732D25154D7481F8F01B476635A7A08A083'
$expectedWrapperHash = '9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7'
$expectedHostLibHash = '71C4E00585A842203B25A7ABB8C34FC14D9B2A3EEC560A15995CDD6CDF8DE211'

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
if (-not (Test-Path -LiteralPath $cache)) { throw "Fresh run cache is missing: $cache" }
if (Test-Path -LiteralPath $log) { throw "Run log already exists; launch aborted: $log" }
if (Test-Path -LiteralPath $startMarker) { throw "Start marker already exists; launch aborted: $startMarker" }
if (Test-Path -LiteralPath $stopMarker) { throw "Stop marker already exists; launch aborted: $stopMarker" }

$knownBook = Join-Path $cache 'pipelines\known-pipelines.bin'
$doneBook = Join-Path $cache 'pipelines\warm-done.txt'
$badBook = Join-Path $cache 'pipelines\warm-bad.txt'
$sdkMarker = Join-Path $cache 'pipelines\agility-sdk.txt'
$hostLib = Join-Path $cache 'pipelines\host-pipelines.bin'
if (-not (Test-Path -LiteralPath $knownBook)) { throw "Warm pipeline book is missing: $knownBook" }
if (-not (Test-Path -LiteralPath $doneBook)) { throw "Warm done list is missing: $doneBook" }
if (@(Get-Content -LiteralPath $doneBook).Count -ne 2245) { throw "Warm done list is not 2245 lines: $doneBook" }
if (-not (Test-Path -LiteralPath $sdkMarker) -or (Get-Content -LiteralPath $sdkMarker -Raw).Trim() -ne '620') {
    throw "Warm cache is not marked for Agility SDK 620: $sdkMarker"
}
if ((Test-Path -LiteralPath $badBook) -and @(Get-Content -LiteralPath $badBook).Count -gt 0) {
    throw "Warm cache has bad pipelines; launch aborted: $badBook"
}
if (-not (Test-Path -LiteralPath $hostLib)) { throw "Populated host pipeline library is missing: $hostLib" }
if ((Get-Item -LiteralPath $hostLib).Length -le 0) { throw "Host pipeline library is empty: $hostLib" }
if ((Get-FileHash -LiteralPath $hostLib -Algorithm SHA256).Hash -ne $expectedHostLibHash) {
    throw 'Host pipeline library hash changed; launch aborted.'
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
    "$runId launched at $started; hidden window; repeat of 8gb36-b56d271-defer with settings line-for-line identical and no source change. Purpose: test whether the single late 2506.1 ms frame was reproducible under another 5-minute vs 5-minute run. Fresh cache cache-8gb37-b56d271-repeat is an exact copy of cache-8gb34-agility620, the same starting state used by 8gb36: host-pipelines.bin SHA-256 $expectedHostLibHash (302946 bytes), agility-sdk.txt=620, warm-done.txt 2245 lines, warm-bad.txt empty. Diagnostics build hash $expectedBuildHash still contains the six audited b56d271 hunks; 8gb36 used the same hash. VICTORY_MEMORY_CATEGORIES=1, title-side FSR4 by default, no VICTORY_FSR toggle, and no excluded knobs. Required wrapper with temporary Series S launcher; console flag confirmed before wrapper restore; hidden launcher PID $launcherPid; wrapper restored byte-identical $expectedWrapperHash. 5-minute cap; failure-marker count from the 1-minute read-only monitor is the go/no-go for stability."
)
