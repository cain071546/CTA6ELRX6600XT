# Repo ref check and integration gate — 2026-11-26T19:58:47.3424930-08:00

## Scope

`[X]` User requested another pass over eight repositories: `DexNom/VIctory`, `stellarr-studio/kelvaroq`, `zibawaa/rtx-5070ti-water`, `avatarmanz/VIctory-7900XTX`, `Belobug/VIctory-Belobug-AMD`, `ZigZagBoi1/ScarlettPort`, `readmet3xt-lab/foxhound`, `PastiiJay/klbf-lab`.

`[X]` Method: `git ls-remote <url> HEAD refs/heads/*` for every repo, then fetch/ref/log comparison in read-only temp mirrors. No game `.exe` launch, no rebuild, no source edit, no driver/registry change, and no `H:\report.txt` access. The user pause remains in force: prepare/integrate only; explicit approval is still required before a run and, if a source change is made, before rebuilding because the diagnostics build hash is a hard guard.

`[S]` Prior six-repo refs are recorded in `C:\Users\mrgre\AppData\Local\Temp\opencode\streaming-plan-20261126.md:232-243`. `[X]` This check adds `ScarlettPort`, `foxhound`, and `klbf-lab` to the same ref-ledger format.

## Current refs

| Repo | Current `HEAD` | Current default branch | Comparison |
|---|---|---|---|
| `DexNom/VIctory` | `8114ff779b5e1c7112b87476753dc8d0992ed97c` | `main` same | unchanged from recorded ref |
| `stellarr-studio/kelvaroq` | `e062a82e04853bbcae281d166980e0a9b65c975a` | `main` same | unchanged from recorded ref |
| `zibawaa/rtx-5070ti-water` | `d9e957a616566530b04f8bb2dab464497e13c5e7` | `main` same | unchanged from recorded ref |
| `avatarmanz/VIctory-7900XTX` | `014d52dedf837d1ac660a0bd256c4704be9eeb40` | `main` same | unchanged from recorded ref; local temp mirror was older (`126acb35`) but the documented ref already matched current |
| `Belobug/VIctory-Belobug-AMD` | `4eb6cfdf9e61cb112f1f811344ec0dd309eddd6c` | `main` `4f62c2a5e27e7beebf3e8d68f77898e43dc7b77c` | unchanged from recorded HEAD/main split; local temp mirror was older (`cd8dfc0`) |
| `ZigZagBoi1/ScarlettPort` | `f5f0ec0ec7fc189e165efb37809766588d46724d` | `main` same | **new since local temp mirror** `ba42a57e92076742b41fb073428c1aea0b46dd95`; 12 non-merge commits fetched for review |
| `readmet3xt-lab/foxhound` | `02fc18a20a1e1771374babcb44084f8de3275b96` | `main` same | fresh mirror; top commits include submission-thread work, texture queue lock work, and renderer port 1 |
| `PastiiJay/klbf-lab` | `0a8c5777fbbcab6409c142b0bc1ad7081212fac4` | `main` same | unchanged since this session's clone; branches `beta 6cce57e`, `beta-2 54a9d35`, `beta-amd 2177f15` also fetched |

## New-commit scope actually reviewed

- `[X]` `avatarmanz` `126acb35..014d52d`: renderer ports (`PORT_GUARD`, `PORT_JOURNAL`, `PORT_CBV`, `PORT_RT`), upload-in-prelude, output/render-scale, frame-rate and earlier local-main commits. `[H]` Mostly source-visible, off-by-default work; no evidence yet that a whole port should be brought over.
- `[X]` `Belobug` `cd8dfc0..4eb6cfd`: sync/fallback counters, DXGI segment telemetry, directly-indexed-heaps diagnostics, shader size-query crash avoidance, profile/warm fixes. `[H]` Diagnostics and correctness are more relevant than input/FSR/visual commits.
- `[X]` `ScarlettPort` `ba42a57..f5f0ec0`: `f5f0ec0` raw view size handle, `6d836e8` AMD mesh pipeline serialization + mapped library, `e5faadb` loose windows under shared lock, `50a9f7c` write-watch binary search, `1e72650` fewer heap re-sets, plus launcher/readme changes.
- `[X]` `foxhound` at `02fc18a`: `f1edd66` submitting-thread work/host lists reused, `2ff3e4a` texture queue lock work, `91df493` prelude uploads, `ee3fb52` show-new-later, `185bc4c` pooled texture granularity, `9075710` constants heap in place. `[S]` `foxhound-check\README.md:126-144` names switches; local equivalents are checked by grep before any integration.
- `[X]` `klbf-lab` branches: `beta-amd` `2177f15` and `beta-2` `54a9d35` include BM-v1 bench tooling, memory/pool backoff, scoped bindless refresh, write-combining copy-back skip, RDNA2 relay default, shader compiler-crash work, and window/output switches. `[S]` `klbf-lab\README.md:165-177` claims texture queue budget/page-list/pipeline-gate/texture-sweep fixes; all require local source verification.

## Local pre-integration facts

- `[S]` `SCARLETT`/`VICTORY` fork names are not interchangeable; local switch reads are already inventoried in `C:\Users\mrgre\AppData\Local\Temp\opencode\memory-switch-inventory.md` (349 switches; A=177, B=114, C=13, D=31, E=14).
- `[S]` Existing local source already reads `VICTORY_SYNC_IN_PLACE` (`descriptor.rs:592-596`), `VICTORY_SYNC_FINE` (`descriptor.rs:615-617`), `VICTORY_SPANS_QUICK` (`descriptor\host.rs:257-261`), `VICTORY_SHOW_NEW_LATER` (`descriptor\host.rs:357-361`), and `VICTORY_PORT_CONSTANTS` (`port.rs:71-78`). These are not new gains merely because a fork README mentions them.
- `[S]` No local read exists for `VICTORY_SOFT_VIEWS`, `VICTORY_WC_NO_BACK`, `VICTORY_SKIP_WC_BACK`, `VICTORY_TEXTURE_QUEUE_MB/MS`, `VICTORY_PAGE_LIST`, `VICTORY_PIPELINE_GATE_S`, `VICTORY_SKIP_MOVIES`, `VICTORY_PORT_GUARD`, `VICTORY_PORT_JOURNAL`, `VICTORY_PORT_CBV`, or `VICTORY_PORT_RT` in the current `--include *.rs` scan. `[H]` Some are source-only and would require a rebuild; none can be activated by the current `target\diag\victory.exe`.
- `[S]` `VICTORY_TEXTURE_SWEEP` exists (`resource.rs:2125-2181`) and `VICTORY_UPLOAD_AHEAD` exists (`texture\ahead.rs:39-46`), but both are held by prior decisions; a fork mention is not local evidence to enable them.
- `[X]` The `klbf-lab` shortlist is now in `evidence-ledger-20261126.md` under "Eight-repo new-commit integration shortlist (KLBF)": 27 `beta-amd` + 88 `beta-2` fork-only commits were reduced to 10 rebuild-gated candidates; none is config-only for the current diagnostics binary. `af10390`/`8c747f5` are deprioritized because local runs already force `VICTORY_LIBRARY_LOCK=1`. The `avatar`/`Belobug` shortlist is also in that ledger: only four genuinely new avatar commits exist since the prior ref and all are RT/diagnostics work, while older fork-only texture-prelude and measurement-safety candidates remain rebuild-gated. The `ScarlettPort`/`foxhound` shortlist is complete there too: `6d836e8` AMD mesh serialization and foxhound queue-lock avoidance (`2ad55e6`, `abf1020`) rank highest, with RDNA4-only `f5f0ec0` rejected. `[X]` All eight repos are fully checked; no candidate is active or config-only for the current binary.

## Gate

`[X]` Until each candidate is confirmed present/absent in the local working tree and assigned a risk, **nothing from these repos is promoted into a run script**. `[X]` The already prepared `8gb32-port-constants` script remains the only held next run. `[H]` Low-risk config-only additions may be staged without a rebuild; source additions are integration work only and remain inactive until a separately approved rebuild updates the build-hash guard.
