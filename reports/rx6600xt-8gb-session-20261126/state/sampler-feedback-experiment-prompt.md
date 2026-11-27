# Paste-ready agent prompt: sampler-feedback / world-visible texture streaming (source experiment)

> **Document status (read before pasting):** This file is a **proposed prompt only**, drafted by a read-only research subagent. No source, build, process, driver, registry, benchmark, or report state was changed by the drafter. It must not be treated as authorization to edit, build, launch, or benchmark. The hard gate in §2 remains in force.

---

You are a subagent continuing the 8 GB VRAM / 16 GB RAM compatibility work on `C:\users\mrgre\victory-7900XTX` (Rust/D3D12 Xbox Series S compatibility layer). Target GPU: RX 6600 XT 8 GB VRAM / 16 GB system RAM. Priority order: **walkability/stability first, then VRAM/RAM occupancy**.

## 1. Objective and scope

User objective, verbatim intent: **“stream only the assets we need to render the game world while paging the rest from the ssd.”**

This task is a **source experiment**: build the missing **camera/world-visible texture signal** using **D3D12 sampler feedback** (“which texels were actually read”) so a future loader/pager can prefer what the rendered world samples and page out the rest. It is **NOT an env-knob A/B run**. Do not add it to, or mix it with, the existing `8gb2x` environment-knob chain. Draw-distance / camera-proximate / frustum-culling work is a **separate source experiment**; do not combine it with this one or with the env A/B chain in a single run.

What already exists (do not re-implement or treat as missing):

- 64 KiB page demand-paging with shader fault feedback: `crates\victory-gpu\src\memory.rs:1-27` (faults read back once a frame, “only helps the next frame” at `memory.rs:25-31`).
- Mip-level tiles on demand: `crates\victory-gpu\src\tiles.rs:1-50`, gated by `VICTORY_LEVELS_ON_DEMAND=1` (`tiles.rs:74-105`); which levels are held is decided by title-memory mapping at `crates\victory-gpu\src\texture.rs:1163-1195`, `texture.rs:1497-1513`.
- Speculative texture prefetch gated on RAM/commit pressure: `crates\victory-gpu\src\residency.rs:1-12`, `residency.rs:75-114`, `residency.rs:181-191`.
- Cache/idle trimming under pressure: `crates\victory-gpu\src\host.rs:556-571`.
- What is missing: a **sampled/world-visible texture signal** and a loader policy that uses it. `crates\victory-gpu\src\resource.rs:853-860` only mentions sampler feedback in a resource-description comment; there is **no camera/frustum/culling instrumentation** and **no sampler-feedback allocator, view, readback, or policy** anywhere in the tree.

## 2. HARD GATE — no source promotion or rebuild until the Close() OOM is diagnosed and resolved

`8gb21-20m-baseline` **FAILED** at ~11.5 min with 15 failure markers: `a host command list did not close (0x8007000E)` then `VIctory: host GPU failure`. Source: `crates\victory-gpu\src\host.rs:6531-6535` (`ID3D12GraphicsCommandList::Close()` on a host list). This is a **command-list/allocator failure, not texture residency**.

The parent session launched (or is launching) a `D3D12_DEBUG=1` diagnostic repro, run ID `8gb25-debug-close-oom`, using `C:\Users\mrgre\AppData\Local\Temp\opencode\launch-8gb25-debug-close-oom.ps1`, `invoke-8gb25-debug-close-oom.ps1`, `cap-15min-debug.ps1`, log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb25-debug-close-oom.log`. Its only added variable is `VICTORY_D3D12_DEBUG=1` (`invoke-8gb25-debug-close-oom.ps1:10-22`; the switch is described at `crates\victory-gpu\src\host.rs:915-936`, `host.rs:976-1081`, `README.md:278`).

**Status update:** (a) is DONE — the debug repro `8gb25-debug-close-oom` named the command: `ID3D12CommandList::SetComputeRootSignature` without `SetDescriptorHeaps` binding a sampler heap for `D3D12_ROOT_SIGNATURE_FLAG_SAMPLER_HEAP_DIRECTLY_INDEXED` (log lines 199758-199809). The `0x8007000E` from `Close()` is a validation symptom, not memory exhaustion. The dormant fix is `VICTORY_FALLBACK_HEAPS=1` (`host.rs:384-387`, `draw.rs:1548-1588`, `host.rs:6366-6390`). (b) is **validated for a 5-minute run**: `[M]` `8gb30-minimal-stable`, full log `C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb30-minimal-stable.log`, marker `C:\Users\mrgre\AppData\Local\Temp\opencode\8gb30-minimal-stable-stop-marker.txt`, 0 failure markers. This is not proof of the old ~11.5 min failure point.

**New hold:** the user instructed at `2026-11-26T19:4x-08:00` to prepare the next run and pause. The sampler-feedback gate is cleared by `8gb30`, but no source edit, rebuild, or `.exe` launch is authorized until the user explicitly says to continue. Until then you must:

1. **Promote no source change, rebuild nothing, launch nothing.** Read-only research, log analysis, and drafting are allowed.
2. Treat `8gb21-20m-baseline` as **not a usable baseline**. There is no stable baseline at any duration. Note the newest user instruction: **future runs are capped at 5 minutes** (`cap-5min.ps1`, 300 s), so duration matching from here on is 5-minute vs 5-minute.
3. Do not interfere with any active benchmark or diagnostic run. Before any future launch, check for a scoped `victory.exe` for `C:\users\mrgre\downloads\gta6\game_scarlett_master.exe` with `--console series-s` and abort if one exists (pattern: `launch-8gb21-20m-baseline.ps1:18-29`).

## 3. Evidence and reporting rules (use these tags verbatim)

- `[M]` measured run: **run ID + full log path**. Example: `[M] 8gb21-20m-baseline, C:\Users\mrgre\AppData\Local\Temp\opencode\victory-8gb21-20m-baseline.log`.
- `[S]` source-confirmed mechanism: **`file:line`** (repo root `C:\users\mrgre\victory-7900XTX`; paths below are repo-relative).
- `[H]` hypothesis or inferred direction — explicitly **not** a measurement.
- `[X]` action/state: what you did or did not change (including “no source/build/process/driver/benchmark state changed”).
- Every series (memory, fps, pipeline wait, feedback counters) must state **nominal cadence, sample count, and measured gap min/median/max**, not just a final value. Report failure-marker hits from the stop marker.
- Never present an inferred counter direction as measured.

## 4. Experiment discipline and duration matching

- **One variable per run:** baseline → one change → compare → retain/reject → next change. Do not stack a feedback-policy change with a staging, window-budget, card-buffer, or draw-distance change.
- **5-minute duration-matched baselines only**, per the newest user instruction. `C:\Users\mrgre\AppData\Local\Temp\opencode\cap-5min.ps1` uses a 300 s cap. Prior 10-minute (`8gb19-prewarm`, `8gb18-book`) and 20-minute (`8gb21`) runs are **not** duration-matched and must not be used as the comparator. Establish a fresh, stable 5-minute baseline at retained settings **after** the hard gate clears.
- **Stability caveat:** `8gb21` first failed at ~11.5 min, which a 5-minute run cannot observe. A 5-minute run with `0` failure markers is not evidence of longer-run stability; report that limitation explicitly.
- Warmed pipeline state: copy from `cache-8gb18-book` into a fresh named cache (pattern `launch-8gb21-20m-baseline.ps1:31-46`).
- Keep this source experiment separate from the env A/B chain and from draw-distance/camera-proximate work.

## 5. Mandatory launch protocol for EVERY .exe launch (after the gate clears)

Use `C:\Users\mrgre\AppData\Local\Temp\opencode\gamepad\play-with-a.ps1` for every game/victory launch:

- `-Exe C:\users\mrgre\downloads\gta6\game_scarlett_master.exe -Profile low-vram -Build diag -More @{ ... } -AfterSeconds 20`. The wrapper presses A ~20 s after launch (`play-with-a.ps1:1-21`, helper at `gamepad\press-a.dll`).
- Launcher process must be `Start-Process ... -WindowStyle Hidden -PassThru` (pattern `launch-8gb21-20m-baseline.ps1:59-62`).
- Fresh, named cache and log per run; never reuse a populated cache or overwrite a prior log.
- Scoped termination only: descendants of the scoped `victory.exe`, the victory PID(s), and the launcher PID — never a blanket process kill (pattern `cap-5min.ps1:58-79`).
- Natural-exit vs cap marker must be recorded distinctly in **`<runId>-stop-marker.txt`** (`cap-5min.ps1:43-57`, `cap-5min.ps1:76-78`).
- Preserve all logs and markers. Use a consistent `<runId>-stop-marker.txt` for every run.
- A **1-minute read-only crash monitor** after cap/exit; it only greps the log for `VIctory: host GPU failure`, `0x887A0005`, `0x887A0007`, `0x8007000E`, `0x80070057` and appends the hit count (`cap-5min.ps1:81-93`).
- The temporary Series S launcher `gamepad\play-series-s.ps1` adds `--console series-s` (`play-series-s.ps1:32-49`). If you use the established redirect pattern, confirm `--console series-s` on the live command line **before** restoring, then restore the wrapper byte-identically and verify its hash (`launch-8gb21-20m-baseline.ps1:47-75`).
- Baseline settings to inherit from `invoke-8gb21-20m-baseline.ps1` / `invoke-8gb25-debug-close-oom.ps1:10-22` (minus `VICTORY_D3D12_DEBUG` unless diagnosing): `VICTORY_LEVELS_ON_DEMAND=1`, `VICTORY_RESIDENCY=1`, `VICTORY_RESIDENCY_LIMITED=1`, `VICTORY_TEXTURE_ROOM_PERCENT=60`, `VICTORY_TEXTURE_BUDGET_MB=1792`, `VICTORY_TEXTURE_MAX=256`, `VICTORY_THIN_THREADS=5`, `VICTORY_CARD_AWAKE=0`, `VICTORY_HEAP_TEXTURES=0`, plus `VICTORY_PROFILE=low-vram`.

## 6. Stability invariants (never violate)

- No `VICTORY_KEEP_FREED=0`; the low-vram preset deliberately does not set it (`apps\victory\src\profile.rs:33-36`). Reads past views can fault driver memory returned to the OS and lose the device.
- No `VICTORY_CARD_ROOM_FOR_TARGETS_MB` below `3072`; lowering it overcommits the 8 GB card and removed the device in the world (`apps\victory\src\profile.rs:24-28`; default and rationale `crates\victory-gpu\src\resource.rs:1818-1848`).
- Keep `VICTORY_LIBRARY_LOCK=1` (`apps\victory\src\profile.rs:31-33`); RDNA2 lost the device under parallel first-run library load/compile.
- No SM 6.6 relaxation. The mesh-shader gate is `host.rs:4140-4171`.
- Keep Agility SDK **1.614.1**, not 1.620.2.
- Keep `VICTORY_PROFILE=low-vram` / `scripts\play.ps1 -Profile low-vram` (`scripts\play.ps1:9-23`, `apps\victory\src\profile.rs:1-7`). Explicit `-More`/env values win over the preset (`apps\victory\src\profile.rs:1-7`, `scripts\play.ps1:30,40`).
- Wrapper must be restored byte-identical: hash `9B12E201B6E2A73F9B233E6284941B99FC7AE1FE1E944698F00B005AFB1A59F7`.
- Diagnostics build hash must remain `26E124D8F539B09B730753B73392FD487E5B0CC73AADFE507DD82A40970A4740` for `target\diag\victory.exe` until an explicitly authorized rebuild after the gate clears.
- Do not interfere with an active benchmark or diagnostic run.
- **`H:\report.txt` is untouched** until the recovered text and draft are verified and the user **explicitly approves replacement**.
- **Six-repo watch continues every 30 minutes**, by `git fetch` / ref-ID comparison only: `stellarr-studio/kelvaroq`, `avatarmanz/VIctory-7900XTX`, `Belobug/VIctory-Belobug-AMD`, `DexNom/VIctory`, `zibawaa/rtx-5070ti-water`, `ionestepin-dev/victory-shared-memory`. No porting from remote activity without local source/log evidence. Report ref changes as lead context only.

## 7. Source findings from the read-only audit (starting map; verify before editing)

### 7.1 Sampler feedback: only stubs/mentions, no policy

- `[S] crates\victory-gpu\src\resource.rs:853-860` — `ResourceDesc1` comment: “the newer description: the plain one, then a sampler feedback mip region (width, height, depth)”. No field is used as a loader signal.
- `[S] crates\victory-gpu\src\resource.rs:2998-3004` — `create_at_address` (Device9-11) explicitly says the `D3D12_RESOURCE_DESC1` sampler feedback region “is not needed” and passes a plain `ResourceDesc`.
- `[S] crates\victory-gpu\src\replay\record.rs:986-1002` — `device_rest` lists `ID3D12Device8_Vtbl.CreateSamplerFeedbackUnorderedAccessView` (line 997) as **not recorded**; macro at `replay\record.rs:934-941` only counts/names such calls in capture notes. There is no hook, no implementation, no call site.
- `[S]` No `WriteSamplerFeedback`, feedback heap, feedback texture, or feedback readback exists anywhere in `crates\victory-gpu\src` (repo-wide case-insensitive search found only the three sites above).
- `[S]` No sampler-feedback HLE calls in `crates\victory-hle\src`; the only “feedback” hit is unrelated force feedback at `crates\victory-hle\src\modules\gameinput.rs:992`. `d3d12x.rs` has no feedback/query-heap entry. `[H]` The title does not emit sampler-feedback work we could piggyback on; it must be host/driver-side instrumentation.

### 7.2 Feature support query — tier is unknown-to-be-measured

- `[S] crates\victory-gpu\src\host.rs:4140-4171` queries `D3D12_FEATURE_D3D12_OPTIONS7` for `MeshShaderTier` plus `D3D12_FEATURE_SHADER_MODEL`, and consumes **only** `options.MeshShaderTier` and shader model. It never reads `SamplerFeedbackTier`.
- `[S]` The struct field exists in the pinned Windows bindings: `C:\Users\mrgre\.cargo\registry\src\index.crates.io-1949cf8c6b5b557f\windows-0.62.2\src\Windows\Win32\Graphics\Direct3D12\mod.rs:2251-2254` (`SamplerFeedbackTier: D3D12_SAMPLER_FEEDBACK_TIER`); tier constants at `mod.rs:6405-6408` (not supported / 0.9 / 1.0).
- `[S]` Other feature queries are unrelated: `tiles.rs:87-97` (tiled resources tier), `tiles.rs:818-836` (test rig), `inplace.rs:865-867`, `replay\play.rs:2345` (OPTIONS12), `host\place.rs:178` (OPTIONS12), `host.rs:9851` (OPTIONS16 GPU upload heap), `pipeline\host.rs:484` (OPTIONS19), `victory-shader\src\emit\mod.rs:2017-2027` (OPTIONS7 mesh-shader test only).
- `[H]` RDNA2 / DX12 Ultimate commonly implies tier 1.0, but **there is no local measurement**. Treat RX 6600 XT `SamplerFeedbackTier` as **unknown-to-be-measured**; first instrumented run must log `options.SamplerFeedbackTier` from `host.rs:4143-4167` (or a dedicated once-only query) and `[M]` cite the log. If tier is `NOT_SUPPORTED`, stop the feedback policy and report `[X]`; do not substitute a camera heuristic silently.

### 7.3 Descriptor slots: creation, remapping, safety hold

- `[S] crates\victory-gpu\src\descriptor\host.rs:2794-2804` `make_at`; `2811-2854` `make_listed`; `2868-2878` `make_null` (null view/sampler keeps a slot safe rather than dangling).
- `[S] descriptor\host.rs:2561-2589` `texture_slot_tabled` / `tabled_in`: a table-read slot is removed from the by-index queue and the host slot is remade in place.
- `[S] descriptor\host.rs:2226-2267` `texture_views_remade` (rebuilds SRVs after tile/level changes); `2280-2288` `texture_slot_gone` with `AWAY_MS` default 3000 (`2274-2285`), chosen because instant nulling caused 0.3-2 s black faces/books/posters/sleeves.
- `[S] descriptor\host.rs:2328` `texture_slot_flip`; `2335` `texture_slot_show_after`; `2427` `texture_slots_flip`; `2022-2028` `texture_slots_room`; `2042-2067` `texture_slots_remapped` / `texture_slots_short`.

### 7.4 Levels on demand, held levels, tile remaking

- `[S] crates\victory-gpu\src\tiles.rs:16-44` rules; explicitly `tiles.rs:36-40`: “A shader must not reach a level without memory (it reads zeros: a black texture)… slots of a texture are made again when that level changes (`HostHeap::texture_views_remade`).”
- `[S] crates\victory-gpu\src\texture.rs:1163-1195` `held_levels` (title-memory-mapped/span rule, **not** sampled/camera based); `1497-1513` `detile` judges held once when filling staging.
- `[S] crates\victory-gpu\src\texture.rs:768-793` re-judgement and the ≥1 s retry when an upload left a held level without tiles; `910-933` submission-time step giving tiles before execution.
- `[S] crates\victory-gpu\src\tiles.rs:557-568` `UpdateTileMappings`; `tiles.rs:653-683` `show_from` adjusts `MostDetailedMip` / `MipLevels` / `ResourceMinLODClamp`; `tiles.rs:66-72` 11 stats; `tiles.rs:687-715` periodic status line.
- `[S] crates\victory-gpu\src\descriptor\host.rs:2216` bumps `tiles::STATS[10]` when levels-change re-uploads are forced.

### 7.5 Texture upload / staging and by-index heap path

- `[S] crates\victory-gpu\src\draw.rs:2236-2251` `heap_textures` contract; `2251-2275` `VICTORY_HEAP_TEXTURES` gate and `VICTORY_TEXTURE_STAGE_MB` / 128 MiB limited-RAM cap (note: **currently `VICTORY_HEAP_TEXTURES=0` in the measured settings**, so this path is off).
- `[S] draw.rs:2289-2318` room check, slot resets, remade views, waiting slots; `2321-2334` due slots and census counters; `2355-2365` `UsedResource` “what a table entry of a texture a shader samples says” — an existing **descriptor-level**, not texel-level, sampled hint; `2370-2403` time/byte budgets and residency prefetch cap; `2407+` per-slot work loop.
- `[S] crates\victory-gpu\src\resource.rs:1787-1816` `room`; `1836-1848` `targets_room_kept` (default 3072 MiB).

### 7.6 Residency admission and pressure trims

- `[S] crates\victory-gpu\src\residency.rs:19-23` `on()`; `40-60` `allocation_error` / `upload_refused`; `62-73` commit sampling; `75-87` reserve checks; `89-114` `admit_texture_pass` / `allow_staging_growth`; `116-122` `limited_host_ram`; `124-130` pressure bands; `132-160` `refresh` warning line; `171-179` `critical_commit`; `181-191` `prefetch_limit`.
- `[S] crates\victory-gpu\src\host.rs:556-571` once-per-second sweep trims and idle releases under pressure.

### 7.7 Existing byte counters to extend (do not invent a parallel accounting)

- `[S] crates\victory-gpu\src\copystat.rs:37-43` `TexWatched` / `TexHashed` / `TexChanged`; `90-93` `TexUploads` / `TexSkipped`; `135` `COUNTERS = 80`; `162-175` `add` / `peek` / `taken`; `1263-1302` periodic “textures … MB watched/hashed/changed” line; `1360-1383` frame-account line with texture uploads.
- `[S] crates\victory-gpu\src\resource.rs:1469-1475` `KINDS[0..7]`; `1733-1740` increments; `1797` `filled = KINDS[1] + tiles::given_total()`; `1980-2095` card-accounting line including by-level tile MB at `2094`.
- `[S] crates\victory-gpu\src\texture.rs:473` `live_staging_bytes()`; `crates\victory-gpu\src\tiles.rs:123-127` `given_total()`.

### 7.8 Where a feedback heap must be created, bound, and read back (nothing exists yet)

A sampler-feedback heap is a **readback texture used as a feedback UAV**, not a `D3D12_QUERY_HEAP_TYPE`. Local analogues for each step:

1. **Create feedback texture/heap:** `[S] crates\victory-gpu\src\resource.rs:3836-3864` creates a `D3D12_HEAP_TYPE_READBACK` committed buffer with `D3D12_RESOURCE_STATE_COPY_DEST`; `[S] crates\victory-gpu\src\host.rs:6443-6473` creates a query heap plus READBACK buffer lazily on a diagnostics host.
2. **Create the feedback UAV:** `[S] crates\victory-gpu\src\replay\record.rs:997` lists `CreateSamplerFeedbackUnorderedAccessView` as **not recorded**; it must be called on the real device for the host texture + feedback texture pair. No code does this today.
3. **Bind the descriptor heap:** `[S] crates\victory-gpu\src\draw.rs:1587`, `host.rs:1692`, `replay\play.rs:2742` show `SetDescriptorHeaps`; D3D12 permits only one CBV_SRV_UAV heap at a time, so the feedback UAV must live in the heap actually bound for the pass (or the binding must be extended deliberately). Do not add a second concurrent CBV_SRV_UAV heap.
4. **Write feedback:** requires translated-shader instrumentation (`WriteSamplerFeedback` / min-mip or full feedback map) in `crates\victory-shader\src\emit\` plus a sampler/feedback UAV binding path. No local code writes sampler feedback; treat this as the largest source step, not a config toggle.
5. **Read back:** fence-wait then `Map` the readback texture using the existing submission tracking `[S] crates\victory-gpu\src\host.rs:574-578` (`submissions()` started/finished) and `[S] host.rs:580-584` (`retire` until submissions finish); query resolve analogue `[S] host.rs:6526-6527`, `host\stamps.rs:111-148`; replay hooks `[S] replay\record.rs:976,1160-1164`.

## 8. Minimal instrumentation plan (answer the two questions before changing any eviction policy)

Question A: **“Which textures were actually sampled this frame?”** Question B: **“How many bytes could be evicted if unsampled textures were dropped?”**

Do these phases in order; each is one variable, and none may be promoted past Phase 0 until §2 clears.

**Phase 0 — read-only logging (telemetry only, no eviction, no new allocations).**
- Log `SamplerFeedbackTier` once from a `D3D12_FEATURE_DATA_D3D12_OPTIONS7` query near `host.rs:4143-4167`; report `[M]` tier value and run ID. If unsupported, stop and report `[X]`.
- Add a periodic line to the existing `resource.rs:2083-2095` card accounting (or `tiles.rs:687-715`) that reports resident host-texture bytes by category: `KINDS[1]`, `tiles::given_total()`, `texture::live_staging_bytes()`, due-slot census from `draw.rs:2331-2334`.
- Declare cadence/samples/gaps for that line like every other series.

**Phase 1 — host-side “sampled this frame” bit, no shader changes, no eviction.**
- Mark a descriptor slot sampled when a draw reads its table: extend `descriptor\host.rs:2561-2589` / `draw.rs:2355-2365` signal with a per-frame `HashSet<u32>` (or bitset) of slot indices. This is a **proxy** for sampler feedback, not texel-accurate; label `[H]` until validated against Phase 2.
- `[S]` Prefer instrumenting `crates\victory-shader\src\resource.rs:1-12,176-199` if a descriptor-level signal is chosen: it already traces every descriptor operand and scalar address back to its root parameter, including waterfall loops and non-uniform per-lane heap indices (`v_readfirstlane_b32`). That is a more complete place to record "this program read this descriptor" than host slot bookkeeping alone. Do not mix it with Phase 2 texel-accurate feedback.
- New counters (add to `copystat.rs` `C` enum and raise `COUNTERS` at `copystat.rs:135`; log in the existing `copystat.rs:1263-1302` line): `feedback_slots_sampled_frame`, `feedback_slots_resident_unsampled_frame`, `feedback_unsampled_bytes`, `feedback_unsampled_tiled_bytes`, `feedback_slot_age_frames_max`, `feedback_stale_slots_ge_2f`, `feedback_stale_slots_ge_8f`.
- Compute “could be evicted” as a **candidate** sum: resident copies whose last-sampled age exceeds the grace window **and** which are held by no live `HostList`, descriptor slot, or `Arc` (use `resource.rs:2103-2127` `let_go_idle` rules and `host.rs:580-584` retirement). Never count a texture that is bound to a pending submission as evictable (`feedback_skipped_bound`).

**Phase 2 — hardware sampler feedback capture, still no eviction.**
- Lazily create one feedback readback texture/UAV under a new diagnostic switch (e.g. `VICTORY_FEEDBACK=1`), created at the `resource.rs:3836-3864` pattern; create the feedback UAV via `CreateSamplerFeedbackUnorderedAccessView` from `replay\record.rs:997`; bind in the same CBV_SRV_UAV heap per `draw.rs:1587`; instrument shader translation to write feedback; read back after `host::submissions().1` advances (`host.rs:574-578`).
- New counters: `feedback_heap_count`, `feedback_heap_mib`, `feedback_map_wait_ms`, `feedback_texels_with_feedback`, `feedback_min_mip_histogram`, `feedback_resident_unsampled_after_readback`, `feedback_readback_mismatch_count` (host proxy vs hardware).
- Compare Phase 1 proxy against Phase 2 hardware; only then call the signal `[M]`-validated.

**Phase 3 — conservative policy, only after §2 gate + stable 5-minute baseline.**
- One variable at a time: e.g. “keep textures sampled in the last K frames, default K large, drop only via the existing `resource::let_go_idle` path” — never a new unconditional free. Reuse `residency::prefetch_limit` / `admit_texture_pass` as the admission side; reuse `descriptor\host.rs:2280-2288` away-delay pattern for the eviction side.
- Do not combine Phase 3 with `VICTORY_TEXTURE_STAGE_MB`, window budget, card-buffer cap, draw-distance, or culling changes in one run.

## 9. Safety traps (design constraints, not suggestions)

- An evicted-but-still-bound texture reads **black/zeros**: `[S] crates\victory-gpu\src\tiles.rs:36-40`; the same applies to host copies nulled too early (`descriptor\host.rs:2274-2279` documents 0.3-2 s black surfaces when `VICTORY_TEXTURE_AWAY_MS=0`).
- A shader-side fault only helps the **next** frame: `[S] crates\victory-gpu\src\memory.rs:25-31`. Do not rely on a fault to repair a same-frame miss.
- A level whose upload left it without tiles stays bad until a ≥1 s retry with card room: `[S] texture.rs:776-793`, `tiles.rs:66-72` stats `[9]`/`[10]`.
- Slots and live lists hold host copies: `[S] resource.rs:2103-2112`, `host.rs:580-584`. A candidate must be unsampled **and** unreferenced across all not-yet-finished submissions before eviction.
- Keep the 3 GiB target reserve (`resource.rs:1818-1848`); render targets are not in the texture queue and overcommit removed the device.
- Any feedback heap is extra VRAM/RAM: measure its bytes; do not let the instrumentation itself cause the `0x8007000E` class of failure again.

## 10. Measurement and decision rules

- After the hard gate clears and a new stable 5-minute baseline exists, run one variable at a time with 5-minute caps and preserved logs. Report `[M] <runId>, <full log path>` plus stop-marker text (natural exit vs cap, failure-marker hits).
- Compare: failure-marker count; walkability/visual black-surface observations; private bytes and working set (`copystat.rs:569-583` in the builder's earlier audit); PC free / commit left; host copies MB, windows MB, staging MB, host textures MB from the `resource.rs:2083-2095` accounting line; fps series; pipeline-wait series (`copystat.rs:1303-1329`); `tiles`/feedback counters. Declare cadence, sample count, and gap range for every series.
- **Retain** a phase only if: 0 failure markers; no black/stalled walkability regression; no p90/p99 pipeline-wait or present-wait regression beyond normal run variance; feedback counters actually move in the predicted direction; and RAM/VRAM occupancy does not rise from instrumentation alone.
- **Reject** and revert on: any `Close()`/`0x8007000E`/device-loss recurrence, black textures, unsupported feedback tier without a fallback decision, counters that do not separate sampled from unsampled, or an occupancy regression with no walkability/stability gain.
- After each retain/reject, state `[X]` explicitly and name the single next variable. Do not promote a policy to a default until it survives at least one full 5-minute one-variable comparison.

## 11. Standing constraints while waiting

While the user pause holds (gate cleared by `8gb30`, but no continuation approval): do read-only source/log analysis, maintain the 30-minute six-repo ref watch, and refine this plan. Do **not** edit `C:\users\mrgre\victory-7900XTX`, build, launch any `.exe`/game process, run a benchmark, or touch `H:\report.txt`. Report your state with `[X]` and the exact path of any document you write.
