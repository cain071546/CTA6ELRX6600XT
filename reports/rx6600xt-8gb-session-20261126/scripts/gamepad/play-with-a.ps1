param(
    [Parameter(Mandatory)][string]$Exe,
    [switch]$Safe,
    [switch]$RayTracing,
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [ValidateSet('default', 'low-vram')][string]$Profile = 'default',
    [hashtable]$More = @{},
    [int]$AfterSeconds = 20
)

$helper = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\press-a.dll'
$play = 'C:\users\mrgre\victory-7900XTX\scripts\play.ps1'
if (-not (Test-Path -LiteralPath $helper)) { throw "No gamepad helper: $helper" }
if (-not (Test-Path -LiteralPath $play)) { throw "No launcher: $play" }

$press = Start-Job -ArgumentList $helper, $AfterSeconds -ScriptBlock {
    param($helper, $after)
    Start-Sleep -Seconds $after
    & dotnet $helper 0 250
}

$launch = @{ Exe = $Exe; Build = $Build; Profile = $Profile; More = $More }
if ($Safe) { $launch.Safe = $true }
if ($RayTracing) { $launch.RayTracing = $true }

try {
    & $play @launch
}
finally {
    if ($press) {
        Wait-Job $press -Timeout 2 | Out-Null
        $output = Receive-Job $press -ErrorAction SilentlyContinue
        if ($output) { Write-Host "gamepad: $output" }
        Stop-Job $press -ErrorAction SilentlyContinue
        Remove-Job $press -Force -ErrorAction SilentlyContinue
    }
}
