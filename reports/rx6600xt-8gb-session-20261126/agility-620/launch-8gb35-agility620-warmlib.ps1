$ErrorActionPreference = 'Stop'
$runId = '8gb35-agility620-warmlib'
$repo = 'C:\users\mrgre\victory-7900XTX'
$exe = 'C:\users\mrgre\downloads\gta6\game_scarlett_master.exe'
$victory = Join-Path $repo 'target\diag\victory.exe'
$wrapper = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1'
$wrapperBackup = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1.bak-8gb35'
$tempLauncher = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-series-s.ps1'
$monitor = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cap-5min.ps1'
$invoke = 'C:\Users\mrgre\AppData\Local\Temp\opencode\invoke-8gb35-agility620-warmlib.ps1'
$cache = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb35-agility620-warmlib'
$log = 'C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb35-agility620-warmlib.log'
$startMarker = 'C:\Users\mrgre\AppData\Local\Temp\opencode\8gb35-agility620-warmlib-start-marker.txt'
$expectedBuildHash = '15D934F2905336A2E0E0C661AA01790D1A9FB91CA21E063D1A8C74D86A8AF699'
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
if (Test-Path -LiteralPath $log) { throw "Run log already exists; launch aborted: $log" }
if (Test-Path -LiteralPath $startMarker) { throw "Start marker already exists; launch aborted: $startMarker" }

$knownBook = Join-Path $cache 'pipelines\known-pipelines.bin'
$doneBook = Join-Path $cache 'pipelines\warm-done.txt'
$badBook = Join-Path $cache 'pipelines\warm-bad.txt'
$sdkMarker = Join-Path $cache 'pipelines\agility-sdk.txt'
$hostLib = Join-Path $cache 'pipelines\host-pipelines.bin'
if (-not (Test-Path -LiteralPath $knownBook)) { throw "Warm pipeline book is missing: $knownBook" }
if (-not (Test-Path -LiteralPath $doneBook)) { throw "Warm done list is missing: $doneBook" }
if (@(Get-Content -LiteralPath $doneBook).Count -eq 0) { throw "Warm done list is empty: $doneBook" }
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
    "$runId launched at $started; hidden window; prepared after explicit user approval to stage the corrected Agility SDK 1.620.2 run. Base is exactly the 8gb34-agility620 setting set, including title-side FSR4 by default and no VICTORY_FSR toggle. Fresh cache cache-8gb35-agility620-warmlib preserves the populated host-pipelines.bin from cache-8gb34-agility620 (SHA-256 $expectedHostLibHash, 302946 bytes, written during 8gb34) instead of deleting it; agility-sdk.txt=620, warm-done.txt has 2245 lines, warm-bad.txt empty. Required wrapper with temporary Series S launcher; console flag confirmed before wrapper restore; hidden launcher PID $launcherPid; diagnostics build hash $expectedBuildHash; wrapper restored byte-identical $expectedWrapperHash. 5-minute cap; failure-marker count from the 1-minute read-only monitor is the go/no-go for stability."
)
