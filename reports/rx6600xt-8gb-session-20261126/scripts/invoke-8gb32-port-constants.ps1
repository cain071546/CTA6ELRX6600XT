$ErrorActionPreference = 'Continue'
$runId = '8gb32-port-constants'
$repo = 'C:\users\mrgre\victory-7900XTX'
$exe = 'C:\users\mrgre\downloads\gta6\game_scarlett_master.exe'
$wrapper = 'C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1'
$cache = 'C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb32-port-constants'
$log = 'C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb32-port-constants.log'

Set-Location -LiteralPath $repo
& $wrapper -Exe $exe -Profile low-vram -Build diag -More @{
    VICTORY_CACHE_DIR = $cache
    VICTORY_LEVELS_ON_DEMAND = '1'
    VICTORY_RESIDENCY = '1'
    VICTORY_RESIDENCY_LIMITED = '1'
    VICTORY_TEXTURE_ROOM_PERCENT = '60'
    VICTORY_TEXTURE_BUDGET_MB = '1792'
    VICTORY_TEXTURE_MAX = '256'
    VICTORY_THIN_THREADS = '5'
    VICTORY_CARD_AWAKE = '0'
    VICTORY_HEAP_TEXTURES = '0'
    VICTORY_FALLBACK_HEAPS = '1'
    VICTORY_MEMORY_CATEGORIES = '1'
    VICTORY_PORT_CONSTANTS = '1'
    VICTORY_CARD_BUFFERS_MIN_KB = '64'
} -AfterSeconds 20 2>&1 | Tee-Object -FilePath $log
