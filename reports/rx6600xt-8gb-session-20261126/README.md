# RX 6600 XT 8 GB session archive — 2026-11-26

`[X]` Durable copy of the temporary session artifacts, saved so the planned page-file reboot cannot lose them. No source code was changed by this archive; the diagnostic binary remains `26E124D8F539B09B730753B73392FD487E5B0CC73AADFE507DD82A40970A4740` and the required gamepad wrapper remains `9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7`.

## Contents

- `state/CURRENT-STATE.md` — single entry point: hard invariants, run protocol, results, pause/reboot gate, next actions.
- `state/evidence-ledger-20261126.md` — measured component profiles, claim ledger, ranked backlog, and all eight-repo candidate shortlists.
- `state/streaming-plan-20261126.md` — consolidated streaming evidence and eight-repo watch.
- `state/repo-ref-check-20261126.md` — eight-repo ref comparison.
- `state/memory-switch-inventory.md` — 349-switch local inventory.
- `state/sampler-feedback-experiment-prompt.md` — held sampler-feedback experiment.
- `dark-integration/` — read-only validation logs for the audited `b56d271` selective integration and its `8gb36` A/B.
- `analysis/component-*.txt` — read-only component-profile outputs for `8gb30`, `8gb31`, `8gb32`, `8gb34`, `8gb35`, `8gb36`.
- `analysis/fps-*.json` — read-only frame-rate series for those runs.
- `logs/victory-8gb*.log` and marker files — preserved full logs and cap/monitor markers.
- `scripts/` — read-only analyzers, 5-minute cap, wrapper/temporary launcher, gamepad helper, and the launch/invoke scripts for `8gb30`–`8gb36`.

## Run summary

| Run | Result | Full log | Marker |
|---|---|---|---|
| `8gb30-minimal-stable` | Pass, 5-minute cap, 0 failure markers | `logs/victory-8gb30-minimal-stable.log` | `logs/8gb30-minimal-stable-stop-marker.txt` |
| `8gb31-deep-inplace` | Pass, 5-minute cap, 0 failure markers | `logs/victory-8gb31-deep-inplace.log` | `logs/8gb31-deep-inplace-stop-marker.txt` |
| `8gb32-port-constants` | Pass, 5-minute cap, 0 failure markers | `logs/victory-8gb32-port-constants.log` | `logs/8gb32-port-constants-stop-marker.txt` |
| `8gb34-agility620` | Pass, 5-minute cap, 0 markers; empty host library at startup | `logs/victory-8gb34-agility620.log` | `logs/8gb34-agility620-stop-marker.txt` |
| `8gb35-agility620-warmlib` | Pass, 5-minute cap, 0 markers; populated host library | `logs/victory-8gb35-agility620-warmlib.log` | `logs/8gb35-agility620-warmlib-stop-marker.txt` |
| `8gb36-b56d271-defer` | Pass, 5-minute cap, 0 markers; mixed tails, not promoted | `logs/victory-8gb36-b56d271-defer.log` | `logs/8gb36-b56d271-defer-stop-marker.txt` |

`[H]` `8gb31-deep-inplace` has the best measured 5-minute tail profile; `8gb32-port-constants` improved commit headroom and cumulative card/upload buffer creation but worsened frame-time tails in its run. `8gb35` removed the empty-library artifact; `8gb36` improved p90 and most component/memory tails but had one late 2,506.1 ms frame that worsened p99. `[X]` None of these is proof of the old ~11.5-minute failure point. `[S]` GPU timing sections are absent from all logs; no visual check was performed.

## Selective Dark integration

`[X]` Only the six audited `b56d271` runtime hunks from `darksidexc/Dark-Victory-RX6600-I714700KF-VI` were applied to the active fork and committed as `3dd97a9` (`Integrate b56d271 upload deferral/retry hunks`), then pushed to `cain/main`. All three victory profiles were rebuilt successfully under `BelowNormal` priority; diag SHA-256 changed from `15D934F2...` to `F472D6BC...`, so the runnable diag binary contains the hunks. After explicit user approval, one duration-matched 5-minute A/B (`8gb36-b56d271-defer`) completed with 0 failure markers: p90 frame time improved to `339.1 ms` and final private/working set fell to `17,079 / 5,780 MB`, but a single late `2,506.1 ms` frame made p99/max worse than `8gb35`; the patch is not promoted over `8gb31` or `8gb35`. No warm on the new binary, visual change, FFX/framegen/RT work, or wholesale merge was performed. `dc1a0c7` and `d6dd31b` remain held; all visual/script/test-hygiene and watch-indexing work remains rejected. `[S]` Details and validation logs are recorded in `state/CURRENT-STATE.md`, `state/evidence-ledger-20261126.md`, and `dark-integration/`.

## Reboot gate

`[X]` No further `.exe` launch until explicitly approved after the reboot. Before any post-reboot run, recheck:

1. Page-file allocation reflects the user's 64 GB change.
2. Wrapper hash `9B12E201...` and diagnostics build hash `26E124D8...` are unchanged.
3. No scoped `victory.exe` / `game_scarlett_master.exe` processes are running.
4. Logs/markers from any new run use a fresh run ID and fresh named cache.

`[X]` `H:\report.txt` was not touched. Only the audited six-hunk `b56d271` selective integration was applied at `3dd97a9`, rebuilt into diag `F472D6BC...`, and measured once in `8gb36`; it remains unpromoted. All other fork candidates remain rebuild-gated in `state/evidence-ledger-20261126.md`.
