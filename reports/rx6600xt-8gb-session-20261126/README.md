# RX 6600 XT 8 GB session archive — 2026-11-26

`[X]` Durable copy of the temporary session artifacts, saved so the planned page-file reboot cannot lose them. The current diagnostics build is `94267660E81A098750A7B78725B1C60A1B3C8DCBD6855D83E7B1F4AB4F71D188` (commits `588ef12` + `874da36`); the pre-hotness build `F472D6BC...` is preserved at `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-diag-F472D6BC-pre-hotness.exe`. The required gamepad wrapper remains `9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7`.

## Contents

- `state/CURRENT-STATE.md` — single entry point: hard invariants, run protocol, results, pause/reboot gate, next actions.
- `state/evidence-ledger-20261126.md` — measured component profiles, claim ledger, ranked backlog, and all eight-repo candidate shortlists.
- `state/streaming-plan-20261126.md` — consolidated streaming evidence and eight-repo watch.
- `state/repo-ref-check-20261126.md` — eight-repo ref comparison.
- `state/memory-switch-inventory.md` — 349-switch local inventory.
- `state/sampler-feedback-experiment-prompt.md` — held sampler-feedback experiment.
- `dark-integration/` — read-only validation logs for the audited `b56d271` selective integration and its `8gb36`/`8gb37` A/Bs.
- `texture-hotness/` — manifest for the diagnostics-only `8gb38` hotness run.
- `analysis/component-*.txt` — read-only component-profile outputs for `8gb30`, `8gb31`, `8gb32`, `8gb34`, `8gb35`, `8gb36`, `8gb37`, `8gb38`.
- `analysis/fps-*.json` — read-only frame-rate series for those runs.
- `analysis/hotness-8gb38-texture-hotness-diag.txt` — final hotness histogram line from `8gb38`.
- `logs/victory-8gb*.log` and marker files — preserved full logs and cap/monitor markers.
- `scripts/` — read-only analyzers, 5-minute cap, wrapper/temporary launcher, gamepad helper, and the launch/invoke scripts for `8gb30`–`8gb38`.

## Run summary

| Run | Result | Full log | Marker |
|---|---|---|---|
| `8gb30-minimal-stable` | Pass, 5-minute cap, 0 failure markers | `logs/victory-8gb30-minimal-stable.log` | `logs/8gb30-minimal-stable-stop-marker.txt` |
| `8gb31-deep-inplace` | Pass, 5-minute cap, 0 failure markers | `logs/victory-8gb31-deep-inplace.log` | `logs/8gb31-deep-inplace-stop-marker.txt` |
| `8gb32-port-constants` | Pass, 5-minute cap, 0 failure markers | `logs/victory-8gb32-port-constants.log` | `logs/8gb32-port-constants-stop-marker.txt` |
| `8gb34-agility620` | Pass, 5-minute cap, 0 markers; empty host library at startup | `logs/victory-8gb34-agility620.log` | `logs/8gb34-agility620-stop-marker.txt` |
| `8gb35-agility620-warmlib` | Pass, 5-minute cap, 0 markers; populated host library | `logs/victory-8gb35-agility620-warmlib.log` | `logs/8gb35-agility620-warmlib-stop-marker.txt` |
| `8gb36-b56d271-defer` | Pass, 5-minute cap, 0 markers; mixed tails, not promoted | `logs/victory-8gb36-b56d271-defer.log` | `logs/8gb36-b56d271-defer-stop-marker.txt` |
| `8gb37-b56d271-repeat` | Pass, 5-minute cap, 0 markers; one 8,079.4 ms frame, not promoted | `logs/victory-8gb37-b56d271-repeat.log` | `logs/8gb37-b56d271-repeat-stop-marker.txt` |
| `8gb38-texture-hotness-diag` | Pass, 5-minute cap, 0 markers; best mean/p99 FPS, mixed tails, not promoted | `logs/victory-8gb38-texture-hotness-diag.log` | `logs/8gb38-texture-hotness-diag-stop-marker.txt` |

`[H]` `8gb31-deep-inplace` still has the best measured 5-minute tail profile. `8gb37` repeated `8gb36` settings and produced `0` failure markers but an `8,079.4 ms` p99/max frame. `8gb38` added diagnostics-only hotness counters and reached the best mean FPS (`9.100`) and p99 FPS (`30.7`), but its p90/max frame times (`464.9 / 3,847.3 ms`) are worse than `8gb31`; no promotion. `[X]` None of these is proof of the old ~11.5-minute failure point. `[S]` GPU timing sections are absent from all logs; no visual check was performed.

## Selective Dark integration

`[X]` Only the six audited `b56d271` runtime hunks from `darksidexc/Dark-Victory-RX6600-I714700KF-VI` were applied to the active fork and committed as `3dd97a9` (`Integrate b56d271 upload deferral/retry hunks`), then pushed to `cain/main`. All three victory profiles were rebuilt successfully under `BelowNormal` priority; diag SHA-256 changed from `15D934F2...` to `F472D6BC...`, so the runnable diag binary contains the hunks. After explicit user approval, one duration-matched 5-minute A/B (`8gb36-b56d271-defer`) completed with 0 failure markers: p90 frame time improved to `339.1 ms` and final private/working set fell to `17,079 / 5,780 MB`, but a single late `2,506.1 ms` frame made p99/max worse than `8gb35`; the patch is not promoted over `8gb31` or `8gb35`. No warm on the new binary, visual change, FFX/framegen/RT work, or wholesale merge was performed. `dc1a0c7` and `d6dd31b` remain held; all visual/script/test-hygiene and watch-indexing work remains rejected. `[S]` Details and validation logs are recorded in `state/CURRENT-STATE.md`, `state/evidence-ledger-20261126.md`, and `dark-integration/`.

## Reboot gate

`[X]` No further `.exe` launch until explicitly approved after the reboot. Before any post-reboot run, recheck:

1. Page-file allocation reflects the user's 64 GB change.
2. Wrapper hash `9B12E201...` and diagnostics build hash `94267660...` are unchanged (or the replacement hash is explicitly recorded before a launch).
3. No scoped `victory.exe` / `game_scarlett_master.exe` processes are running.
4. Logs/markers from any new run use a fresh run ID and fresh named cache.

`[X]` `H:\report.txt` was not touched. Only the audited six-hunk `b56d271` selective integration was applied at `3dd97a9`, rebuilt into diag `F472D6BC...`, and measured in `8gb36`/`8gb37`; it remains unpromoted. Diagnostics-only hotness counters were then added at `588ef12` and a formatting fix at `874da36`; `8gb38` used the `94267660...` build and remains diagnostics-only. All other fork candidates remain rebuild-gated in `state/evidence-ledger-20261126.md`.
