# Next A/B readiness — `8gb37-b56d271-repeat`

## Scope

`[X]` Readiness only. No game `.exe`, warm command, shader translate, rebuild, source edit, `HostPolicy` change, or FSR change was performed. `H:\report.txt` was untouched.

`[H]` Default next A/B is a repeat of `8gb36-b56d271-defer` with all settings unchanged. Rationale: `[M]` `8gb36`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb36-b56d271-defer.log`, improved p90 and most subsystem tails but had one late `2,506.1 ms` frame that worsened p99/max. A second 5-minute vs 5-minute run under the same build/settings tests whether that stall was reproducible. It is not a promotion and not a new source change.

## Preflight

- `[X]` Wrapper `C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1` SHA-256 `9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7` (required hash).
- `[X]` Diagnostics `C:\users\mrgre\victory-7900XTX\target\diag\victory.exe` SHA-256 `F472D6BCEE923407BB20F6DCCF106732D25154D7481F8F01B476635A7A08A083` (six `b56d271` hunks).
- `[X]` Page file `C:\pagefile.sys` fixed `65,536 / 65,536 MB`; commit limit `79.93 GiB`, free `63.38 GiB`.
- `[X]` GPU `AMD Radeon RX 6600 XT`, driver `32.0.21045.29003`, device ID `0x73ff`.
- `[X]` Scoped process count `0` for `victory.exe` / `game_scarlett_master.exe` / `cap-5min.ps1`; no unrelated process was touched.
- `[X]` Repo `C:\users\mrgre\victory-7900XTX` clean at `af50ec4a425ba4fdeb2bb772e2ba5bac2163a558`; local `HEAD` and `cain/main` match.

## Staged artifacts

- `[X]` Invoke `C:\Users\mrgre\AppData\Local\Temp\opencode\invoke-8gb37-b56d271-repeat.ps1`, SHA-256 `793BAA1379BA1586283007A8A36AF83090EDA5E6D11DDA7DE87F704B25850B4B`, parse errors `0`.
- `[X]` Launcher `C:\Users\mrgre\AppData\Local\Temp\opencode\launch-8gb37-b56d271-repeat.ps1`, SHA-256 `0540466B0753B2CAFA8B1AB0EEB31BA72F13A848032D8C96979D38DC4BA3B7E5`, parse errors `0`.
- `[X]` All `VICTORY_*` lines are identical to `invoke-8gb36-b56d271-defer.ps1` (`Compare-Object` returned `0` differences): includes `VICTORY_MEMORY_CATEGORIES=1`, `VICTORY_FALLBACK_HEAPS=1`, `VICTORY_PROFILE=low-vram`, `VICTORY_INPLACE=1`, `VICTORY_INPLACE_MB=256`, `VICTORY_PORT_CONSTANTS=1`, `VICTORY_CARD_BUFFERS_MIN_KB=64`; no forbidden knob, no `VICTORY_FSR`, no `VICTORY_MEMORY_MAP=6`.
- `[X]` Fresh cache `C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb37-b56d271-repeat` copied from `cache-8gb34-agility620`: `agility-sdk.txt=620`, `warm-done.txt` 2,245 lines, `warm-bad.txt` 0 lines, `host-pipelines.bin` SHA-256 `71C4E00585A842203B25A7ABB8C34FC14D9B2A3EEC560A15995CDD6CDF8DE211` (302,946 bytes), 2,612 files / 543,512,728 bytes. This is the same starting cache state used by `8gb36`.
- `[X]` Expected outputs are absent: `victory-8gb37-b56d271-repeat.log`, `8gb37-b56d271-repeat-start-marker.txt`, `8gb37-b56d271-repeat-stop-marker.txt`.
- `[X]` Protocol retained from `8gb36`: hidden launcher, required wrapper temporarily redirected to `play-series-s.ps1`, `--console series-s` confirmed before wrapper restore, A pressed ~20 s after launch, 300 s `cap-5min.ps1`, scoped termination, 1-minute read-only crash monitor, natural-exit vs cap marker, preserved named log.

## Execute gate

`[X]` Do not execute `launch-8gb37-b56d271-repeat.ps1` without explicit user approval. If approved, verify hashes and process state again immediately before launch, execute exactly once, then analyze with `analyze-component-profile.ps1`, `analyze-fps.ps1`, and `analyze-pipeline-wait.ps1`. Record every series with sample interval/count, compare only to 5-minute runs, and do not promote or change source from this run alone.

## Completion

`[X]` Explicit approval was given and the launcher was executed exactly once. `[M]` `8gb37-b56d271-repeat`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb37-b56d271-repeat.log`: 5-minute cap `2026-11-26T23:10:47.8950741-08:00`, monitor end `23:11:50.7014793-08:00`, 0 failure markers, 0 scoped processes after monitor. FPS **52 samples / 51 gaps**, median/p90/p99/max frame time `185.0 / 237.2 / 8,079.4 / 8,079.4 ms`; not promoted. The late `2,506.1 ms` stall from `8gb36` did not reproduce, but a larger `8,079.4 ms` stall did. Archive manifest: `reports\rx6600xt-8gb-session-20261126\dark-integration\8gb37-b56d271-repeat-manifest.txt`.
