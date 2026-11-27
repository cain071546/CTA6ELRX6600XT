# Streaming / host-memory work plan — 2026-11-26

## Evidence rules

- `[M]` measured run: run ID plus full log path.
- `[S]` source-confirmed mechanism with `file:line`.
- `[H]` hypothesis or inferred counter direction; not a measurement.
- `[X]` no source/build/process change made.
- Any memory series states the nominal cadence, sample count, and measured gap range.

## Current baseline and invariants

- `[M]` `8gb16-series-s`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb16-series-s.log`.
  - Memory series: nominal copystat cadence about 5 s; 106 samples, 105 gaps; min/median/max gaps `4.892886 / 5.523047 / 15.15085 s`.
  - Final: `16,633 MB` private, `4,282 MB` working, `763 MB` PC free, `5,435 MB` left to commit; `65/106` samples above `16,384 MB`, maximum `16,937 MB`.
  - Final host-copy split: `4,053 MB` host copies of title memory, including `3,240 MB` in `788` windows outside buffers; `52 MB` texture staging; `1,614 MB` host textures.
  - Pipeline-wait series: one value per copystat statistics window; 106 windows, 44 nonzero; min/median/p90/p99/max `0 / 0 / 501.6 / 569.7 / 899.6 ms`; sum `12,223.1 ms`; `2,590` shader-translated lines.
- `[S]` “private” is `PROCESS_MEMORY_COUNTERS.PagefileUsage`; “working” is `WorkingSetSize`: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\copystat.rs:569-583`.
- `[S]` Pressure bands are selected below `3 GiB` physical / `4 GiB` commit and recover above `5 / 6 GiB`: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\residency.rs:124-130`, `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\residency.rs:171-191`. The baseline is already in High pressure by physical free.
- Invariants unchanged: no `VICTORY_KEEP_FREED=0`, no `VICTORY_CARD_ROOM_FOR_TARGETS_MB` below `3072`, keep `VICTORY_LIBRARY_LOCK=1`, no SM 6.6 relaxation, keep Agility SDK `1.614.1`.

## Windows memory compression

- `[S]` At `2026-11-26T17:50:47.0649099-08:00`, the protected `Memory Compression` process existed as PID `2708` with working set `360,140,800` bytes. `Get-MMAgent` returned access denied because the shell is not elevated, so this is process-level evidence that compression is active, not an elevated boolean query.

## Console memory exposure

- [S] Series S is `--console series-s`; Series X is the CLI default. The title-facing memory values are set in `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\console.rs:6-26`: Series S reports `(0 GPU-optimal, 7,776 MiB standard)`; Series X reports `(10 GiB GPU-optimal, 3.5 GiB standard)`. `C:\users\mrgre\victory-7900XTX\apps\victory\src\main.rs:156-158` sets `default_value_t = Console::SeriesX`.
- [S] `7,776 MiB` is `7.59375 GiB`; the source calls it the published console-mode figure: `console.rs:16-21`.
- [S] Those values reach the title through the emulated DXGI adapter description: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\dxgi.rs:152-164`, where `dedicated_video_memory = gpu_optimal` and `shared_system_memory = standard`. They are not a measurement of the physical RX 6600 XT or PC RAM.
- [S] `XMemGetWorkingSetStatistics` reports `title_limit = gpu_optimal + standard - transferred`, and `title_used` is the whole process's `PagefileUsage`, including layer memory: `C:\users\mrgre\victory-7900XTX\crates\victory-hle\src\modules\xmem.rs:1932-1956`. The source explicitly notes this makes a title that budgets streaming from those figures believe it is far over its limit: `xmem.rs:1939-1946`.
- [S] `XMemTransferMemory` may only subtract from the standard portion: `xmem.rs:1963-1982`.
- [S] `VICTORY_PROFILE=low-vram` does not change console selection or title-reported memory. Its preset contains only texture staging, idle-texture keep, target reservation, by-address card cap, and library serialization defaults: `C:\users\mrgre\victory-7900XTX\apps\victory\src\profile.rs:19-36`. `README.md:52-54` states that console constants change what the title is told about memory, not the physical card or RAM.
- [S] `scripts\play.ps1` does not pass `--console`; our measured runs add `--console series-s` through the temporary launcher. The title therefore sees Series S memory constants in all current A/B runs: `C:\users\mrgre\victory-7900XTX\scripts\play.ps1:22,48`.
- [X] A read-only source audit produced these findings; no source, build, process, or benchmark state changed.

## PC-port memory practices compared with this layer

- `[H]` Claude’s PC-port summary is general-practice context supplied by the user, not evidence about this title or this fork. It is recorded here only where local source confirms a local equivalent.
- `[S]` The console/PC split matches the earlier audit: Series S is reported as `(0 GPU-optimal, 7,776 MiB standard)` and Series X/default as `(10 GiB, 3.5 GiB)`: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\console.rs:6-26`. Those are title-facing values through DXGI: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\dxgi.rs:152-164`. The physical adapter’s own/shared budgets are queried separately: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\host.rs:9695-9733`.
- `[S]` The layer bridges the two pools with host copies of title buffers, updated from title memory and written back for declared shader writes: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:1-11`, `shadow.rs:148-163`. That is why “just keep GPU-only resources in VRAM” cannot be applied globally to an unmodified title.
- `[S]` Residency/budget work already exists: DXGI budget queries (`host.rs:9695-9733`), texture-copy budget and pressure gate (`C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\resource.rs:1779-1800`), `VICTORY_TEXTURE_ROOM_PERCENT` (`resource.rs:1868-1883`), VRAM-pressure idle eviction (`host.rs:157-223`), and host-RAM admission bands (`C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\residency.rs:1-12`). `[H]` These match the general pattern, but they are present controls, not a new A/B variable.
- `[S]` Mip-level residency exists in bounded form: `VICTORY_LEVELS_ON_DEMAND=1` makes eligible title textures reserved/tiled and gives tiles to levels at staging/upload time: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\tiles.rs:16-50`, `tiles.rs:74-105`. `[S]` The held-level rule is title-memory mapped/span based, not sampled/camera-distance based: `tiles.rs:28-35`.
- `[S]` Sampler feedback is not an implemented streaming policy here. Only a mip-region field in the newer resource description and recorded vtable slots were found: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\resource.rs:853-860`, `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\replay\record.rs:988-1000`. `[H]` A feedback-driven loader would be a source change and a separate branch.
- `[S]` DirectStorage here is console-HLE, not PC DirectStorage-to-VRAM/GPU decompression: requests are inflated with zlib/BCPack and written to destination addresses or physical pages by CPU workers: `C:\users\mrgre\victory-7900XTX\crates\victory-hle\src\modules\dstorage.rs:1-18`. Formats decode in software: `C:\users\mrgre\victory-7900XTX\crates\victory-formats\src\lib.rs:6`, `bcpack.rs:2`.
- `[S]` CPU-writable card memory is implemented through `D3D12_HEAP_TYPE_GPU_UPLOAD`, but only after `D3D12_FEATURE_D3D12_OPTIONS16.GPUUploadHeapSupported` succeeds: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\host.rs:9840-9875`. `[S]` `VICTORY_SEND_BAR=1` uses it for sends but defaults off because filling costs the submitting thread more: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\host\send.rs:132-142`. `[S]` `VICTORY_WINDOWS_BAR_MB` also uses it for windows and defaults to `0`: `shadow.rs:483-499`. `[H]` A registry ReBAR value is therefore not the decisive local check; the feature query is.
- `[S]` Writer-direction classification and copying only needed ranges is already present for card-side buffers: card copy plus CPU staging, dirty ranges up before submission, declared shader-write ranges compared by 64 KiB pieces and merged back: `shadow.rs:148-163`. `[S]` Kept snapshots remain off by default because undeclared shader writes can be missed or misattributed: `shadow.rs:2654-2672`.
- `[H]` Claude’s “borrow” list maps conservatively: writer classification and directional sync are already local (`shadow.rs:148-163`); eviction and texture budgets are local (`resource.rs:1779-1883`, `host.rs:157-223`); dropped/stale host copies are covered by the queued env A/B chain, not by removing mirrors globally; sampler feedback and DirectStorage/GPU decompression require separate source experiments.
- `[X]` This comparison was read-only. No source, build, driver, registry, process, or active benchmark state was changed; `8gb21-20m-baseline` remains untouched.

## Remote tiered-budget A/B triage

- `[X]` Claude asked about the “10-minute loop: staging, then card buffers, then landing memory; record working set, hard-fault proxies and fps.” It is **not runnable as written**: current protocol is 20-minute duration-matched runs, and `8gb21-20m-baseline` was already active when this was reviewed.
- `[S]` `VICTORY_TEXTURE_STAGE_MB` exists, but it is read inside the by-index texture path (`heap_textures`): `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\draw.rs:2257-2275`. Current A/B settings include `VICTORY_HEAP_TEXTURES=0` (`draw.rs:2257-2260`), so changing staging alone would be a no-op; enabling heap textures with it would change two variables and re-enter a known stability tradeoff.
- `[M]` `VICTORY_TEXTURE_STAGE_MB=64` was already tested and rejected in `8gb8-stage64`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb8-stage64.log`. It is not repeated in the 20-minute chain.
- `[S]` `VICTORY_CARD_BUFFERS_MB` exists and overrides the card-side buffer cap; the local default is `16 / 512 MiB` for a `<= 12 GiB` VRAM budget: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:169-216`, `shadow.rs:5736-5742`. `256` is a valid one-variable candidate, but it caps VRAM-side copies, not a direct host-RAM control.
- `[S]` No `VICTORY_QUEUE2_LANDING_MB` definition was found in the local tree. The nearest landing control is `VICTORY_LAND_THREADS`, a thread count, not a byte budget: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\land.rs:50-56`. Landing memory is therefore a source-expiry question, not a configuration A/B here.
- `[S]` Working set and private bytes remain available from the copystat series: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\copystat.rs:569-583`. FPS is in the host frame lines; `[M]` a new read-only parser was tested on `8gb19-prewarm`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb19-prewarm.log`: 107 fps samples / 106 gaps, min/median/max gaps `5.035262 / 5.528776 / 12.488393 s`.
- `[H]` The named `Hard Faults/sec` counter remains unavailable locally. `Page Reads/sec` and `Pages Input/sec` are mixed proxies only.
- `[X]` Prepared but not launched: `C:\Users\mrgre\AppData\Local\Temp\opencode\invoke-8gb23-20m-card-buffers256.ps1`, `launch-8gb23-20m-card-buffers256.ps1`, `collect-page-proxies.ps1`, and `analyze-fps.ps1`; all parse-checked. The card-buffers run is queued behind `8gb21-20m-baseline` and `8gb22-20m-window-budget`, not inserted ahead of them.

## Trimming already present locally

- `[S]` Pipeline-library page trimming already exists and is active by default: after `10 s` without a pipeline load and according to `ram_idle_ms(available_physical_ram())`, it `VirtualUnlock`s the mapped library view on its own thread; `VICTORY_LIBRARY_TRIM=0` disables it: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\pipeline\library.rs:386-424`. The once-per-second sweep calls it: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\host.rs:556-569`.
- `[S]` `VICTORY_LIBRARY_LOCK=1` is a separate library-call serialization switch, not a trim disable: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\pipeline\library.rs:24`, `library.rs:454-458`, `library.rs:586`.
- `[S]` Low-RAM upload/storage release already exists: with `VICTORY_RESIDENCY=1`, the same sweep asks `residency::pressured()` and then drops spare scratch chunks, send upload blocks, landed card-step pools, kept snapshots, idle lists, and thin-list backs: `host.rs:556-565`. Pressure is entered at `<= 3 GiB` physical free or `<= 4 GiB` commit, recovered above `5 / 6 GiB`: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\residency.rs:124-130`.
- `[S]` Individual release paths: `send::trim()` drops the spare upload block pool (`host\send.rs:178-181`), spare scratch chunks are freed under pressure (`host.rs:2107-2125`), and card-step owned lists are drained down to two (`host\card_steps.rs:605-616`).
- `[X]` Current A/B settings already include `VICTORY_RESIDENCY=1` and `VICTORY_RESIDENCY_LIMITED=1`; this is not a new candidate. No source, build, process, or benchmark state changed while reviewing it.

## 8gb21-20m-baseline failure (blocks further A/B)

- `[M]` `8gb21-20m-baseline`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb21-20m-baseline.log`, marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb21-20m-baseline-stop-marker.txt`: 20-minute cap reached `18:39:38`, crash monitor ended `18:40:40`, **15 failure-marker hits**. The game/victory PIDs were already gone at cap time; the process died early, not at the cap.
- `[M]` First failure at log line 125811, timestamp `2026-11-27T02:31:08Z` (~11.5 min in): `a host command list did not close (0x8007000E)` repeated 5x, then 10 `VIctory: host GPU failure` lines. This is `ID3D12GraphicsCommandList::Close()` failing on the host list (`host.rs:6531-6535`), **not** a texture-residency or page-file failure.
- `[M]` Preceding line: `new card memory waited for until it is mapped 295200 times, 94224.8 ms, longest 764.3 ms`. Final memory: private `18,204 MB`, working `5,276 MB`, PC-free `438 MB`, commit-left `5,254 MB`, host copies `4,856` alive / `5,474 MB`, windows `4,668 MB`, host textures `1,727 MB`; `109/123` samples above `16,384 MB`. Memory series: 123 samples / 122 gaps, `5.018710 / 5.503305 / 13.185822 s`. Pipeline wait: 123 windows, 42 nonzero, median `0`, p90 `13.1`, p99 `443.1`, max `496.9`, sum `2,824.3 ms`.
- `[X]` `8gb24-20m-window-budget-1024` (aggressive `VICTORY_WINDOW_BUDGET_MB=1024`) was prepared and parse-checked but **not launched**. There is no stable duration-matched baseline to compare against, and a window-memory cap does not address a command-list `Close()` allocator failure. Hold until the baseline failure is resolved.

## Concurrent diagnostic and source-experiment work

- `[M]` `8gb25-debug-close-oom` launched hidden at `2026-11-26T18:48:38.6588472-08:00`; full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb25-debug-close-oom.log`; start marker `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb25-debug-close-oom-start-marker.txt`; hidden launcher PID `14360`. This is a DIAGNOSTIC, not an A/B: `8gb21` settings with the single added variable `VICTORY_D3D12_DEBUG=1`, capped at 900 s (`15-minute`) to reach the ~11.5 min first-failure point with margin. Required wrapper used with temporary Series S launcher, console flag confirmed before byte-identical restore; warmed cache copied from `cache-8gb18-book`; build hash and wrapper hash verified.
- `[S]` `VICTORY_D3D12_DEBUG` is read on diagnostics builds at `crates\victory-gpu\src\host.rs:976-993`; with no info queue the build warns to install Graphics Tools (`host.rs:1081`). `C:\Windows\System32\D3D12SDKLayers.dll` is present (`4,827,136` bytes, `2026-11-26T03:50:00`).
- `[M]` `8gb25-debug-close-oom` completed: cap reached `19:03:42`, monitor ended `19:04:44`, **16 failure-marker hits**. Debug layer named the command: `ID3D12CommandList::SetComputeRootSignature: SetDescriptorHeaps must be called to bind a sampler descriptor before setting a root signature with D3D12_ROOT_SIGNATURE_FLAG_SAMPLER_HEAP_DIRECTLY_INDEXED flag` (`id=1419`, `severity=1`, log lines 199758-199809). The `0x8007000E` from `Close()` is a validation symptom, **not** host-memory exhaustion.
- `[S]` Fix is already in source as a dormant switch: `VICTORY_FALLBACK_HEAPS=1` binds a one-slot fallback view/sampler heap where the title set none (`host.rs:384-387`, `draw.rs:1548-1588`, `host.rs:6366-6390`). `[X]` Not yet run; must be validated with 0 failure markers before any stability claim. Gate in `sampler-feedback-experiment-prompt.md` stays closed until then.
- `[X]` The read-only subagent finished drafting `C:\Users\mrgre\AppData\Local\Temp\opencode\sampler-feedback-experiment-prompt.md`. It did not edit source, build, launch a process, or touch `H:\report.txt`; no local source/build/process change from that work.
- `[S]` Its findings: sampler feedback is stub-only (`resource.rs:853-860`, `resource.rs:2998-3004`, `replay\record.rs:986-1002`); no feedback heap, UAV, readback, shader write, or HLE call exists. `D3D12_FEATURE_D3D12_OPTIONS7` is queried at `host.rs:4140-4171` but only `MeshShaderTier` is consumed; `SamplerFeedbackTier` is never read, so RX 6600 XT tier is unknown-to-be-measured. Existing sampled hint is descriptor-level (`draw.rs:2355-2365` `UsedResource`), not texel-level. The draft has a hard gate on the `Close()` OOM, four phases, and explicit black-surface/next-frame-fault traps (`tiles.rs:36-40`, `memory.rs:25-31`, `descriptor\host.rs:2274-2288`).
- `[X]` `8gb24-20m-window-budget-1024` remains prepared but not launched; `8gb22-20m-window-budget` also remains unlaunched.

## Architecture note assessment

- `[X]` User supplied a general crate/architecture overview and asked whether it helps. Mostly orientation; no new runnable knob. Three locally confirmed points are useful:
- `[S]` Shaders are translated when host pipelines are made, not only by pre-conversion: `crates\victory-gpu\src\pipeline\host.rs:372-375,472,492`. This confirms the warmed book is a warm-up only; the pipeline-wait series remains the right measure.
- `[S]` `crates\victory-shader\src\resource.rs:1-12,176-199` already traces every descriptor/scalar address to its root parameter, including waterfall loops and non-uniform per-lane heap indices. This is a better instrumentation site for a descriptor-level "sampled" signal than host slot bookkeeping alone; added to the sampler-feedback prompt Phase 1.
- `[S]` Title path-taking imports are rewritten onto a virtual drive via `crates\victory-hle\src\modules\files.rs:1-9,147,186`; combined with the CPU-decode DirectStorage HLE already audited, any "page from SSD" behavior is title-driven. The layer cannot invent a separate asset stream; it can only choose what it keeps.
- `[S]` `crates\victory-game\src` contains only `lib.rs` and `sgd5.rs`, i.e. title-specific hooks are thin. A camera/world signal would belong there, not in `victory-gpu`; still a separate source experiment.

## 7900 XTX findings assessment (user-supplied 2026-11-23..25 notes)

- `[X]` User supplied a 24 GB / 64 GB / Series X performance retrospective and asked, in context, what helps here. Most frame-time work does not transfer to 8 GB / 16 GB; four items do.
- `[S]` `VICTORY_MEMORY_CATEGORIES=1` prints a per-memory-line field breakdown from values already collected (`copystat.rs:615-619`, `copystat.rs:1021-1043`) — cheap enough for every 5-minute run. Added to prepared `8gb27`/`8gb28`.
- `[S]` `VICTORY_MEMORY_MAP=<n>` walks the address space every n memory lines (n=60 default, ~5 min; `0` disables); a walk costs 0.6-0.9 s on its own thread and can hold other memory calls (`copystat.rs:597-613`, `copystat.rs:643-656`). At this machine's 18.0 GB private the same kind of walk attributed 4.6 GB to title heaps, 2.6 GB to process heap segments, 2.7 GB to 707 4 MiB windows and 0.46 GB to the pipeline library file (`copystat.rs:647-652`). This matters: the window knobs address ~2.7 GB, while title heaps and process heap segments are larger. `VICTORY_MEMORY_MAP=6` is reserved for one diagnostic run, not every run.
- `[S]` `VICTORY_CARD_BUFFERS_MIN_KB=64` puts every title buffer on the card, bounded here by `VICTORY_CARD_BUFFERS_MB=256` (`shadow.rs:210-236`); unmeasured on the 24 GB machine, so it is a candidate here. Added to prepared `8gb28`.
- `[S]` `VICTORY_TEXTURE_BACK` defaults to the four water formats so CPU physics can read shader-written textures; disabling it sank boats in every run on the 24 GB machine (`texback.rs:1-20`). Keep it on; not an occupancy knob.
- `[S]` `VICTORY_INDIRECT_REST=0` is the outdoor-flicker experiment (`indirect.rs:298-303`, `indirect.rs:2592`); stability/walkability, not memory. Held for a later run if flicker appears.
- `[S]` Explicitly not worth repeating here: `VICTORY_SHADER_OPT=127` (no gain on AMD), sixteen map threads (fewer mapped pages not more, longer frames), wave size/FMA/fast-reciprocal/barrier tweaks (0.1 ms), and native console shader code. `VICTORY_SHOW_AFTER=1` is already set in the Series S launcher (`play-series-s.ps1:21`).

## 8gb29 result

- `[M]` `8gb29-recover-windows`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb29-recover-windows.log`, marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb29-recover-windows-stop-marker.txt`: cap `19:31:54`, monitor `19:32:56`, **2 failure-marker hits**. Failure at log lines 34395-34399, `2026-11-27T03:28:23Z`: `no host list for a prelude (0x8007000E)` then `no host list for a state prelude`. No `Close()` validation error and no `no shared buffer` line this time.
- `[M]` Memory series: nominal 5 s, **16 samples**, one 8 s gap (`03:27:35` to `03:27:43`); final private / in-memory / PC-free / commit-left `17,415 / 7,038 / 645 / 5,564 MB`; host copies `4,853` / `5,375 MB`, windows `1,066` / `4,568 MB`, grid 4096 KiB, card buffers `7,005` / `854 MB`. The copy count returned to the `8gb21` level, so the window knobs were not the cause.
- `[H]` The remaining differences from the known-good `8gb19` set were `VICTORY_WINDOW_BUDGET_MB=2048`, `VICTORY_CARD_BUFFERS_MB=256`, `VICTORY_FALLBACK_HEAPS=1` and `VICTORY_MEMORY_CATEGORIES=1`; the card-buffer cap is the likeliest source of extra host-side memory. `[X]` Launched `8gb30-minimal-stable` at `19:34:10.0594115-08:00` with only `VICTORY_FALLBACK_HEAPS=1` and `VICTORY_MEMORY_CATEGORIES=1` added to the retained set. Full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb30-minimal-stable.log`, marker `8gb30-minimal-stable-stop-marker.txt`, 5-minute cap.

## 8gb30 result and the comparative-report backlog

- `[M]` `8gb30-minimal-stable`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb30-minimal-stable.log`, marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb30-minimal-stable-stop-marker.txt`: cap reached `2026-11-26T19:39:13.0412245-08:00`, monitor ended `19:40:15.6236501-08:00`, **0 failure-marker hits**; later scoped check found no processes left. Settings: retained `8gb19` base + only `VICTORY_FALLBACK_HEAPS=1` and `VICTORY_MEMORY_CATEGORIES=1`.
- `[M]` Memory series: nominal 5 s, **53 samples / 52 gaps**, gaps `5.043256 / 5.465956 / 9.342467 s`; final private / in-memory / PC-free / commit-left `16,869 / 4,782 / 1,114 / 6,273 MB`; host copies `4,737` alive / `4,226 MB`, windows `829` / `3,420 MB`, staging `118` / `51 MB`, host textures `1,100` / `1,625 MB`. `[H]` `VICTORY_FALLBACK_HEAPS=1` is validated for this 5-minute run; `8gb30` is the new 5-minute stability baseline. It does not prove the 20-minute failure point: `8gb21` first failed at ~11.5 min under the older config.
- `[M]` Component series, **53 samples** at one stats-window cadence (~5 s): present → first list median/p90/p99 `17.6 / 32.0 / 148.7 ms`; last submit → present `17.6 / 32.3 / 87.6 ms`; CPU all-thread median `892 ms user + 152 ms kernel/frame`; refresh volume median `15,589.6 MB/frame`; page faults median `27,288/frame`; watch time median `12.23 ms/frame`; pipeline wait p90/p99/sum `20.7 / 140.0 / 757.7 ms`. `[X]` Parsed by `analyze-component-profile.ps1`; no source/build/process change.
- `[X]` User supplied a seven-fork comparative engineering report. It is research evidence, not a local A/B. Recorded in `C:\Users\mrgre\AppData\Local\Temp\opencode\evidence-ledger-20261126.md` with a claim ledger and ranked backlog. Local priority is unchanged: stability gate first, then memory/sync work measured by the component series; fork FPS numbers are not combined.
- `[S]` The tree has waits-by-work and per-list GPU timing (`copystat.rs:1405-1466`, `host.rs:1892-1897`), but those lines are absent from every current log (`8gb19`, `8gb21`, `8gb26`, `8gb29`, `8gb30`: 0 matches). `[X]` GPU execution time remains unmeasured until a build producing those lines is used.
- `[X]` `8gb31-deep-inplace` launched at `19:41:24.4106734-08:00` with exact `8gb30` base + `VICTORY_INPLACE=1` / `VICTORY_INPLACE_MB=256`; full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb31-deep-inplace.log`, marker `8gb31-deep-inplace-stop-marker.txt`, 5-minute cap. `8gb32-port-constants` is prepared and parse-checked from `8gb30` (+ `VICTORY_PORT_CONSTANTS=1`, `VICTORY_CARD_BUFFERS_MIN_KB=64`) but held. `[X]` User then instructed: prepare the next run and pause; no further launch without explicit approval. Old `8gb27`/`8gb28` scripts are superseded because they still contain the failed window/card cap settings.

## GPU residency journal assessment (user-supplied 2026-11-25 journal)

- `[X]` User supplied a residency/OOM bug journal from another fork and another PC (RTX 5090 / 32 GB). Its failure class matches `8gb26`: `E_OUTOFMEMORY 0x8007000E` on small D3D12 allocations, followed by Rust aborts. Their repair was to back off pool growth for 500 ms after a failed block creation, interrupt the texture sweep on allocation refusal, and defer prefetch at low commit. No code was ported.
- `[S]` Local equivalents already exist: `residency::allocation_error` sets a 500 ms upload retry on `E_OUTOFMEMORY` (`residency.rs:35-44`), pool rest is 2500 ms (`pool.rs:83-84`), and emergency throttling on refused texture uploads is documented at `residency.rs:12,172`.
- `[S]` The local call sites of `allocation_error` are `host.rs:8844`, `pool.rs:690`, `resource.rs:2651` — **not** the `no host list for a prelude` path (`host.rs:4218-4235`) or the `no shared buffer` path (`host.rs:9831-9837`), which are the two warnings that immediately preceded `8gb26`'s death. `[H]` Extending the 500 ms backoff to those two allocation sites may stop the cascade; held as a candidate source patch until `8gb29` reports.
- `[S]` `VICTORY_INDIRECT_REST=0` is defaulted in that fork to stop one oversized indirect record zeroing later draws; locally it defaults on (`indirect.rs:298-303,2592`). `[X]` Held for a stability run, not added to `8gb29`. `VICTORY_AMBIENT_AIR=1.5` (local default unset, `ambient.rs:106-110`) is visual-only and held.

## 8gb26 result and recovery

- `[M]` `8gb26-aggressive-pools`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb26-aggressive-pools.log`, marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb26-aggressive-pools-stop-marker.txt`: cap reached `2026-11-26T19:25:12.7787461-08:00`, monitor ended `19:26:15.0345266-08:00`, **6 failure-marker hits**. First failure at log lines 32808-32822, timestamp `2026-11-27T03:21:41Z`: `no host list for a prelude (0x8007000E)`, `no shared buffer (0x8007000E, size=2621440)`, then `a host command list did not close ... 0x8007000E` and `no host list for a state prelude`. This is allocation exhaustion, not the sampler-heap validation found by `8gb25`.
- `[M]` Memory series: nominal 5 s, **15 samples**, one 14 s gap (`03:20:52` to `03:21:06`); final private / in-memory / PC-free / commit-left `17,267 / 3,190 / 375 / 5,729 MB`. Final host copies `6,734` alive / `5,579 MB`, windows `2,928` / `4,621 MB`, shared buffers `8,602` / `5,880 MB`, own allocations `1,317 MB` in `1,159,501` blocks (`1,140,508` under 4 KiB). `[M]` `8gb21` ended at `18,204 / 5,276 / 438 / 5,254 MB` with `4,856` host copies and `4,668 MB` windows; the finer grid therefore raised copy count about 39 % without reducing window bytes.
- `[H]` `VICTORY_WINDOW_KB=1024` plus `VICTORY_WINDOW_TAILS=1` multiplied small host buffers/copies and exhausted physical RAM; `VICTORY_FALLBACK_HEAPS=1` could not help an allocation failure. `[X]` Reverted those two settings and launched `8gb29-recover-windows` at `19:26:49.9727469-08:00`, keeping `VICTORY_FALLBACK_HEAPS=1`, `VICTORY_WINDOW_BUDGET_MB=2048`, `VICTORY_CARD_BUFFERS_MB=256` and adding `VICTORY_MEMORY_CATEGORIES=1`; default 4 MiB grid restored. Full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb29-recover-windows.log`, marker `8gb29-recover-windows-stop-marker.txt`, 5-minute cap.

## fxceless README assessment (user-supplied fork README, 2026-11-25)

- `[X]` User supplied the fxceless README kept in this repo. Its headline state (2.5-4 fps, RTX 4070 12 GB / 32 GB, Series X) is another PC and not our measurement. The card/streaming switches named there are worth checking; all of the ones that matter are **already at their "new" defaults locally**, so nothing was added to a run.
- `[S]` `VICTORY_CARD_ROOM_FOR_BUFFERS` is **on** locally unless set to `0` (`shadow.rs:255-284`), unlike the README's "off by default" for that fork. `[S]` `VICTORY_FULL_CARD_PASS` is on unless `0` (`draw.rs:745-755`); `VICTORY_VIEW_GUARD` is on unless `0` (`watch.rs:1978-1993`); `VICTORY_DSTORAGE_RETRIES` defaults to 12 (`dstorage.rs:1662-1666`); `VICTORY_WIDE_REFRESH` is on by default (`host.rs:7814-7829`); `VICTORY_SHADER_OPT` runs every pass when unset (`emit\mod.rs:208-223,306`); `VICTORY_PIPELINE_WAIT_MS` defaults to 500 (`pipeline\make.rs:128`); `VICTORY_LEVELS_ON_DEMAND=1` is already in our run settings.
- `[S]` `VICTORY_GPU_TIMING=1` (`host.rs:1892-1897`) timestamps each list and reports slow commands, useful if a future run is bounded by command cost rather than occupancy. `VICTORY_STACKS` (`stacks.rs:1-40`) is a diagnostic for where threads sit. Neither changes memory; both are held.
- `[S]` `VICTORY_WINDOW_MAX` only limits the displayed window, not the console render resolution or swap-chain buffers; it is not a VRAM knob.

## Ray-tracing notes assessment (user-supplied 2026-11-25 notes)

- `[X]` User supplied the ray-tracing/BVH retrospective. It is mostly not actionable for the current 8 GB / 16 GB memory work, but it removes two candidates and confirms one setting.
- `[M]` In `8gb21-20m-baseline`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb21-20m-baseline.log`, the `title memory by address` line (e.g. lines 26532-26536, 10 s cadence, 63 lines in that run) reads: 6 pages (0 MB) in 1 arena, 3 copies, 18 dispatches reading per frame, 0 building, 0.0 pages faulting, 0.0 turned down, 0 results brought back. `[S]` So `VICTORY_MEMORY_CARD_MB` (default 4096, `shadow.rs:5464-5484`) has essentially nothing to cap here; lowering it is not a memory win. `[S]` `VICTORY_UPLOAD_LOW=0` would put upload blocks above 2^40 where translated reads see zeros (`upload.rs:1-14,40-42`), and `VICTORY_LENT_HEAP=0` drops dispatches without a heap (`descriptor.rs:755-765`); both defaults stay.
- `[S]` `VICTORY_BVH_BUILDER=1` is off locally (`pipeline.rs:272-273,348`) and costs ~40 ms of card time plus VRAM on the 24 GB machine; it is not part of the memory/streaming push. Its overlap/fault gaps are open upstream problems.
- `[S]` `VICTORY_AMBIENT=0.8` is already set by the Series S launcher (`play-series-s.ps1:21`); the ambient stand-in is active and is not a new experiment. `[S]` `VICTORY_MEMORY_DUMP`, `VICTORY_BVH_TRACE`, `VICTORY_BVH_SIZES_WAIT`, `VICTORY_BVH_BOUNDS`, `VICTORY_BVH_FENCES`, `VICTORY_BVH_QUARANTINE` only matter with the builder; not used.

## 5-minute run protocol (newest; supersedes the 20-minute protocol for future runs)

- `[X]` User instruction at `2026-11-26T18:5x-08:00`: **limit future runs to 5 minutes.** All runs launched after this point use a 300 s cap. Duration matching is now 5-minute vs 5-minute; the earlier 20-minute protocol and all `8gb2x-20m-*` prepared scripts are superseded, not to be launched as-is.
- `[X]` `C:\Users\mrgre\AppData\Local\Temp\opencode\cap-5min.ps1` was prepared and parse-checked: `capSeconds = 300`, accurate `5-minute cap` / `before the 5-minute cap` marker text, scoped termination, natural-exit vs cap distinction, preserved named marker, and the same 1-minute read-only crash monitor and failure patterns.
- `[X]` The already-launched `8gb25-debug-close-oom` is **not** a future run: it stays at its 900 s diagnostic cap. Its purpose is to reach the ~11.5 min `Close()` failure; a 5-minute cap could not reproduce it. No script, process, or marker for that active run was changed.
- `[X]` Consequence to report on every future result: `[M]` `8gb21-20m-baseline` first failed at ~11.5 min, which a 5-minute run would not see. A 5-minute run with `0` failure markers is **not** evidence of 20-minute stability. `8gb21` is not duration-matched to future 5-minute runs; a fresh 5-minute baseline at retained settings is required before any 5-minute A/B.
- `[X]` User directed a cleanup/streamline pass and a shift away from strict one-variable A/B toward aggressive combined memory/streaming work. `C:\Users\mrgre\AppData\Local\Temp\opencode\CURRENT-STATE.md` is the new single entry point; 17 pre-21 `.ps1` launch/invoke scripts were moved to `archive-pre21\` (nothing deleted). All logs, markers, caches, and analyzers remain in place. Hard invariants in `CURRENT-STATE.md` §2 remain in force.
- `[X]` A read-only subagent is inventorying every memory/streaming `VICTORY_*` switch into `memory-switch-inventory.md` to build the aggressive combined candidate set.

## Pipeline prewarm status

- `[M]` `8gb18-book` recording run, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb18-book.log`, cap marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb18-book-stop-marker.txt`.
  - Cap reached `2026-11-26T18:01:44.1940799-08:00`; crash monitor ended `2026-11-26T18:02:46.9638806-08:00`; failure-marker hits `0`.
  - Memory series: nominal copystat cadence about 5 s; 108 samples, 107 gaps; min/median/max gaps `0.851704 / 5.411787 / 14.485977 s`.
  - Final: `16,363 MB` private, `3,991 MB` working, `2,115 MB` PC free, `5,685 MB` left to commit; `48/108` samples above `16,384 MB`.
  - Pipeline-wait series: one value per copystat statistics window; 108 windows, 38 nonzero; median/p90/p99/max `0 / 500.7 / 567.7 / 660.4 ms`; sum `10,933 ms`; `2,572` shader-translated lines. This was the recording run, not the warmed measured run.
  - It created `C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb18-book\pipelines\known-pipelines.bin`, `50,325,870` bytes, plus `early-pipelines.txt` and `host-pipelines.bin`.
- `[M]` `warm --used`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb18-warm.log`, summary `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb18-warm-summary.txt`: finished `2026-11-26T18:03:37.9861914-08:00`, exit code `0`; `83,580` pipelines known, fingerprint `c8cb246cebff481a`, `2,245` used pipelines made in `11 s` with `0` refused and `0` crashed; ms each median `9.3`, p90 `24.6`, p99 `460.0`, most `706`. `warm-done.txt` has `2,245` lines and `warm-bad.txt` has `0`.
- `[X]` The first warm attempt stopped on a Windows PowerShell native-stderr handling issue before doing work. The wrapper script was changed from `$ErrorActionPreference='Stop'` to `'Continue'`; no project source, build, driver, or benchmark setting was changed.
- `[M]` `8gb19-prewarm` launched at `2026-11-26T18:04:02.6219209-08:00`, hidden window, with the warmed cache copied into `C:\Users\mrgre\AppData\Local\Temp\opencode\cache-8gb19-prewarm`; `--console series-s` confirmed before wrapper restore; wrapper hash restored byte-identical. Full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb19-prewarm.log`. Awaiting cap.
- `[X]` User reported at `2026-11-26T18:15:11.1407786-08:00` that the last run was good. Interpreted as positive subjective walkability/stability evidence for `8gb19-prewarm`; it does not replace the cap marker or log-based A/B evidence, and it made no setting, source, build, or process change.
- `[M]` `8gb19-prewarm` cap marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb19-prewarm-stop-marker.txt`: cap reached `2026-11-26T18:14:04.2286303-08:00`; 1-minute read-only crash monitor ended `2026-11-26T18:15:07.7269099-08:00`; failure-marker hits `0`. The marker recorded `scoped processes remaining: 1`; a later scoped check found no `victory.exe`, `game_scarlett_master.exe`, Series S launcher, or cap-monitor process left. Build hash `26E124D8F539B09B730753B73392FD487E5B0CC73AADFE507DD82A40970A4740` and wrapper hash `9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7` remained unchanged.
- `[M]` `8gb19-prewarm` memory series: nominal copystat cadence about 5 s; 107 samples, 106 gaps; min/median/max gaps `5.035311 / 5.52225 / 12.486116 s`. Final: `18,210 MB` private, `4,413 MB` working, `390 MB` PC free, `4,770 MB` left to commit; `91/107` samples above `16,384 MB`; private min/max `6,725 / 18,210 MB`.
- `[M]` `8gb19-prewarm` final host-copy split: `5,067 MB` host copies of title memory, `4,092 MB` in windows, `55 MB` texture staging, `1,709 MB` host textures. Versus `8gb16-series-s`: private `+1,577 MB`, working `+131 MB`, PC free `-373 MB`, commit left `-665 MB`, host copies `+1,014 MB`, windows `+852 MB`, staging `+3 MB`, host textures `+95 MB`; samples above `16,384 MB` rose from `65/106` to `91/107`.
- `[M]` `8gb19-prewarm` pipeline-wait series: one value per copystat statistics window; 107 windows, 34 nonzero; median/p90/p99/max `0 / 23.1 / 462.2 / 1,583.5 ms`; sum `4,645.4 ms`; `2,809` shader-translated lines. Baseline `8gb16-series-s` series was one value per copystat statistics window; 106 windows, 44 nonzero; median/p90/p99/max `0 / 501.6 / 569.7 / 899.6 ms`; sum `12,223.1 ms`; `2,590` shader-translated lines.
- Decision: **retain `8gb19-prewarm` as the walkability/stability and pipeline-wait baseline**, using the warmed pipeline state for future A/Bs; the user report and `0` failure markers support stability, and p90/p99/sum pipeline wait improved. It is **not** retained as a RAM improvement: private bytes and every reported host-copy category rose, so the memory regression must be carried forward into the 20-minute baseline.

## Ranked streaming candidates

All effects on private bytes are `[H]` direction only unless measured by an A/B. Stability and walkability outrank private-byte gains.

1. `VICTORY_WINDOW_BUDGET_MB=2048` — prepared as `8gb20-window-budget`.
   - `[S]` Optional cap and Watch/High-only application: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:2940-2951`, `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:3002-3017`.
   - `[S]` Source records loose windows growing from `648 windows / 2.8 GB` to `974 / 4.3 GB`; eviction only when held by no list, slot, or comparison: `shadow.rs:2983-2986`, `shadow.rs:3026-3047`, `shadow.rs:3055-3060`.
   - `[H]` Private down; recopy churn may regress frame time and present wait.
2. `VICTORY_WINDOW_KB=1024`.
   - `[S]` `803` windows held `3.3 GB` while asked ranges lay within `1.6 GB`; a 1 MiB grid is the conservative first step: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:5320-5346`, `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:5517-5557`.
   - `[H]` Private down, but more windows can invert the gain through duplicate buffers; check `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\copystat.rs:1010-1019`.
3. `VICTORY_TEXTURE_AWAY_MS=0`.
   - `[S]` Nulls the host slot when title memory unmaps so the copy can be let go: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\descriptor\host.rs:2269-2272`.
   - `[H]` Private down; `[S]` default `3000 ms` was chosen after `0.3-2 s` black faces/books/posters/sleeves, so reject on visual regression: `descriptor\host.rs:2274-2279`.
4. `VICTORY_PORT_CONSTANTS=1`.
   - `[S]` Off by default; targets a `174 MB` constants ring with a host copy, `17 MB/frame` sent up and about `6,000` fills/frame; in-place path has no host copy, send, fetch or compare: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\port.rs:1-36`, `port.rs:71-79`, `port.rs:315-317`.
   - `[H]` Private down; `[S]` pages stay locked and the path assumes CPU fills/read-backs do not need in-flight shader writes: `port.rs:46-51`, `port.rs:67-69`, `port.rs:237-239`.
5. `VICTORY_INPLACE=1` with `VICTORY_INPLACE_MB=256`.
   - `[S]` Level 1 opens private committed title memory as a host heap so a window is not copied; default cap is `4096 MB` and opening locks pages: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\inplace.rs:65-97`, `shadow.rs:5564-5568`.
   - `[H]` Private down; physical free may fall because pages are locked. Level 2 is incompatible with late wait, so only level 1 is considered: `inplace.rs:76-86`.
6. `VICTORY_WINDOW_TAILS=1` only after rank 2 is kept.
   - `[S]` Of `782` windows, `513` had no length, holding `2,052 MB` while only `1,988 MB` was ever copied; tail slack is capped near `192 KiB`: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\shadow.rs:5355-5382`, `shadow.rs:5546-5548`.
   - `[H]` Private down only for unsized prefixes; a later lower ask can replace an older buffer.
7. Rebuild-required promotion: make a bounded window budget a limited-RAM default.
   - `[S]` Change `shadow.rs:2943-2951` to default to a bounded value when `crate::residency::limited_host_ram()` is true, while keeping Watch/High-only application at `shadow.rs:3002-3017`; current low-vram defaults have no such value: `C:\users\mrgre\victory-7900XTX\apps\victory\src\profile.rs:19-36`.
   - Promote only after the env A/B clears stability, p90/p99, present wait, and copy-count checks.

Explicitly not selected now: `VICTORY_TEXTURE_STORE`, `VICTORY_KEEP_SNAPSHOTS=1`, `VICTORY_WINDOWS_OWN=1`, `VICTORY_LIBRARY_MAP=0`, `VICTORY_CARD_BUFFERS=0`, `VICTORY_TEXTURE_POOL=0`, `VICTORY_SCRATCH_POOL=0`, `VICTORY_LIST_POOL=0`, `VICTORY_BURY_LAG=0`, and other paths that keep more bytes, depend on the disabled by-index pass, or sit in known device-loss territory.

## Draw distance and camera-proximate texture focus

- `[S]` The renderer does not currently expose a draw-distance or player/camera-radius setting. The title's own culling programs (`tree`, `tree_imposter`, `grass`, `prop`, `slod`, and others) are only counted for the walls trace: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\draw.rs:3296-3316`.
- `[S]` Camera motion is used only by diagnostics that compare presented frames; it is not a texture-streaming priority input: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\popwatch.rs:1-15`.
- `[S]` The indirect path clamps and budgets the title's own records; it does not select records by world distance: `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\indirect.rs:45-68`.
- `[S]` The nearest existing texture controls are temporal, descriptor, or memory-address based, not world-space: `VICTORY_TEXTURE_LOOK_MS` at `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\draw.rs:4652-4663`, `VICTORY_TEXTURE_HOT` at `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\texture.rs:112-131`, `VICTORY_UPLOAD_AHEAD` at `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\texture\ahead.rs:1-46`, and `VICTORY_TEXTURE_AWAY_MS` at `C:\users\mrgre\victory-7900XTX\crates\victory-gpu\src\descriptor\host.rs:2269-2284`.
- `[S]` The low-VRAM preset has no distance or focus variable: `C:\users\mrgre\victory-7900XTX\apps\victory\src\profile.rs:17-36`.
- `[H]` A real “immediate vicinity” policy needs new instrumentation that maps requested textures to world/camera position or to the title's culling output, then prioritizes or drops by distance. That is a source change and a separate experiment branch, not a safe env-only one-variable A/B.
- `[X]` No draw-distance or camera-focus source change was made during the active run.

## 20-minute run protocol

- `[X]` User-requested protocol change: starting with the next measured run after `8gb19-prewarm`, the cap is 20 minutes, not 10 minutes.
- `[X]` `C:\Users\mrgre\AppData\Local\Temp\opencode\cap-20min.ps1` was prepared and parse-checked. It uses `1200` cap seconds and writes accurate `20-minute cap` / `before the 20-minute cap` stop-marker text. It keeps the 1-minute read-only crash monitor and the same failure-marker patterns.
- `[X]` `8gb19-prewarm` stays a 10-minute run. Its result is not duration-matched to later 20-minute runs; after retain/reject, the next step is a fresh 20-minute baseline at the retained settings, then one variable at a time at 20 minutes.
- `[X]` The prepared 10-minute `8gb20-window-budget` script is superseded by a 20-minute version and is not to be launched as-is under the new protocol.
- `[X]` User approved the recommended chain at `2026-11-26T18:19:28.5562182-08:00`: 20-minute baseline, then the ranked one-variable streaming tests. No draw-distance or duplicate-pool source work was included.
- `[X]` `cap-20min.ps1`, both 20-minute invoke scripts, and both 20-minute launch scripts parse-checked successfully before any launch.
- `[M]` `8gb21-20m-baseline` launched at `2026-11-26T18:19:36.5012155-08:00`, hidden window, at retained `8gb19-prewarm` settings with the same warmed cache; `--console series-s` confirmed before wrapper restore; wrapper hash restored byte-identical. Full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb21-20m-baseline.log`. Awaiting cap.

## Decision gate

1. `8gb19-prewarm` is complete and retained as the walkability/stability and pipeline-wait baseline, with its memory regression carried forward.
2. Finish `8gb21-20m-baseline`; it is the new duration-matched baseline for all 20-minute streaming tests.
3. Run `8gb22-20m-window-budget` at 20 minutes with only `VICTORY_WINDOW_BUDGET_MB=2048` added.
4. Continue down the ranked list one variable at a time. No source edit or rebuild until an env-level win is measured.
5. Keep draw-distance / camera-proximate texture work as a separate source experiment; do not mix it into the streaming env A/B chain.
6. Do not touch `H:\report.txt`, do not push README changes, and do not port remote code from the eight-repo watch without local evidence.

## Six-repo watch

Ref comparison at `2026-11-26T18:03Z` local time:

- `stellarr-studio/kelvaroq` `e062a82e04853bbcae281d166980e0a9b65c975a` — unchanged.
- `avatarmanz/VIctory-7900XTX` `014d52dedf837d1ac660a0bd256c4704be9eeb40` — unchanged.
- `Belobug/VIctory-Belobug-AMD` `4f62c2a5e27e7beebf3e8d68f77898e43dc7b77c` — changed from `4eb6cfdf9e61cb112f1f811344ec0dd309eddd6c`. Ref-only reading showed recent commit titles about sky-following ambient light, translated-shader clean-up passes, a placed-texture detail LOD hold, and texture census of pool/host memory. Lead context only; `[X]` no code fetched into the working tree, ported, built, or benchmarked.
- `DexNom/VIctory` `8114ff779b5e1c7112b87476753dc8d0992ed97c` — unchanged.
- `zibawaa/rtx-5070ti-water` `d9e957a616566530b04f8bb2dab464497e13c5e7` — unchanged.
- `ionestepin-dev/victory-shared-memory` `5805eea1db655b484271c6b8dd5b27228116ba87` — unchanged.

Ref comparison at `2026-11-27T02:48Z` (`2026-11-26T18:48-08:00`): five HEADs unchanged from the values above. `Belobug/VIctory-Belobug-AMD` now reports `HEAD 4eb6cfdf9e61cb112f1f811344ec0dd309eddd6c` and `refs/heads/main 4f62c2a5e27e7beebf3e8d68f77898e43dc7b77c` — the HEAD/main split flipped back from the `18:03Z` reading. Ref-only `git ls-remote`; no code fetched into the working tree, ported, built, or benchmarked.

## Eight-repo watch and pause-gate results (`2026-11-26T19:58:47.3424930-08:00`)

`[X]` Full ref ledger: `repo-ref-check-20261126.md`. Current HEADs: `DexNom 8114ff7`, `kelvaroq e062a82`, `rtx-5070ti-water d9e957a`, `avatarmanz 014d52d`, `Belobug HEAD 4eb6cfd / main 4f62c2a`, `ScarlettPort f5f0ec0`, `foxhound 02fc18a`, `klbf-lab 0a8c577`. Against the earlier recorded refs, only `ScarlettPort` advanced (`ba42a57` → `f5f0ec0`); `foxhound` was a fresh mirror; `klbf-lab` branches `beta-amd 2177f15` and `beta-2 54a9d35` were fetched and ranked. `[X]` `ionestepin-dev/victory-shared-memory` remains historical and is not part of the eight-repo set.

`[M]` `8gb31-deep-inplace` and `8gb32-port-constants` both completed under the 5-minute cap with 0 failure markers; component/FPS analyses are in `component-8gb31/32*.txt`, `fps-8gb31/32.json`, `CURRENT-STATE.md`, and `evidence-ledger-20261126.md`. `[X]` No source edit, rebuild, driver change, or `H:\report.txt` access during the pause. `[H]` `8gb31` had the best 5-minute tail profile; `8gb32` improved commit headroom and cumulative buffer creation but worsened frame-time tails. Both remain 5-minute-only evidence.

`[X]` All three fork shortlists are now in `evidence-ledger-20261126.md`: KLBF top candidates are WC copy-back skip (`e0a91ea`) and texture LRU (`0ea9755`); avatar/Belobug top rebuild-gated candidates are texture-prelude uploads (`5d6bd84`) and stack-unwind safety (`acbeb30`); ScarlettPort/foxhound top candidates are AMD mesh serialization (`6d836e8`) and queue-lock avoidance (`2ad55e6`, `abf1020`). None is config-only for the current diagnostics binary, and no candidate is active.
