# VICTORY_* memory, streaming, thread, pool and telemetry switch inventory

[X] Read-only inventory. No repository file was edited, built, launched, benchmarked, or read from `H:\report.txt`; only temporary extracts under `%TEMP%\opencode` were written.
[X] Scope: all relevant `VICTORY_*` literals and environment reads in `crates\`, `apps\`, `scripts\play.ps1`, and `README.md`, plus doc-only names found in temporary fork notes.
[X] Legend: `[S] file:line` is a source-confirmed fact; `[X]` is an inventory action, grouping, risk, current state, or inference.
[X] Generic switch helpers: a value is on when set and not `0` (`crates\victory-gpu\src\switch.rs:5-16`); `toggled!` switches are on unless `0`. Each row still states the exact default/off/on semantics used by that switch.

## Groups [X]

- **A - safe to combine aggressively:** defaults, correctness fixes, stable measured settings, and telemetry/caching paths that do not by themselves violate an invariant.
- **B - stability tradeoffs needing care:** memory/VRAM sizing, residency, pool, copy, landing, thread, sync, and renderer-port behavior; test one variable at a time against the stable run.
- **C - forbidden/invariant violations:** the switch or a named value was explicitly rejected or is barred by the stable 8 GB invariants.
- **D - dormant/inert under current settings:** bench/test-only, build-generated, feature-gated, documented-but-not-read, or not active in the stable measured configuration.
- **E - nonexistent in this tree:** mentioned in other documentation only; no runtime read or definition here.

## Current state annotations [X]

[S] README.md:62-73 - stable measured command: `CACHE_DIR` fresh, `LEVELS_ON_DEMAND=1`, `RESIDENCY=1`, `RESIDENCY_LIMITED=1`, `TEXTURE_ROOM_PERCENT=60`, `TEXTURE_BUDGET_MB=1792`, `TEXTURE_MAX=256`, `THIN_THREADS=5`, `CARD_AWAKE=0`, `HEAP_TEXTURES=0`, `PROFILE=low-vram`.
[S] README.md:76-79 - reported cap: 21,152 MB private bytes, 5,738 MB working set, 765 MB physical free, 5,824 MB commit left, 5,824/7,135 MB card budget.
[S] scripts\play.ps1:17-29 - launcher defaults include `TEXTURE_NO_WAIT=1`, `RELAY=2`, `WIDE_BACK=1`, `CARD_REHASH_RUNS=1`, `JOIN_COPIES=1`, `INDIRECT_WINDOW=1`, `RELAY_COPY=1`, `CARD_STEPS=2`, `INDIRECT_BATCH=2`, `MAP_THREADS=1`, `TITLE_PRIORITIES=0`, `CARD_AWAKE=1`, `SHOW_AFTER=1`, `D3D12_DRED=light`; non-`-Safe` adds `THIN=1`, `JOIN_PARTS=8`, `UPLOAD_AHEAD=1`; `-RayTracing` adds `BVH_BUILDER=1`.
[S] scripts\play.ps1:35-45 - inherited `VICTORY_*` variables are cleared except the four path variables before launcher defaults are applied.
[S] apps\victory\src\profile.rs:19-36 - `low-vram` preset sets `TEXTURE_STAGE_MB=96`, `TEXTURE_KEEP=0`, `CARD_ROOM_FOR_TARGETS_MB=3072`, `MEMORY_CARD_MB=1024`, `LIBRARY_LOCK=1`; `KEEP_FREED` is deliberately not set to `0`.
[S] apps\victory\src\profile.rs:66-91 - explicit switches win over preset values; the preset is applied before threads start.
[S] README.md:136-144 - rejected: `ASYNC_SUBMIT=1`, `FILL_TITLE=1`, `JOIN_BARRIERS=1`, `TEXTURE_STAGE_MB=64`, `PORT_DESCRIPTORS=1`, `TEXTURE_STORE` as a RAM fix, `CARD_ROOM_FOR_TARGETS_MB < 3072`, `KEEP_FREED=0`, SM 6.6 relaxation, Agility SDK 1.620.2.
[S] README.md:177-179 - renderer ports `PORT_CONSTANTS=1`, `PORT_CONSTANTS_ORDER=0`, `PORT_DESCRIPTORS=1` were off while tested.
[S] README.md:240-273 - `low-vram` table, `TEXTURE_MAX` notes, `LIBRARY_LOCK=1` mitigation, and `HEAP_TEXTURES=0` as an explicit non-preset tradeoff.
[X] `stable=` is the effective stable measured value (launcher plus `-More` plus preset); `launcher=`/`preset=` means set by that layer only; `default/unset` means no stable override.

## Counts [X]

A=177; B=114; C=13; D=31; E=14; total=349.

## Group A [X]

| Switch | Default / off / on | Effect | Source | Risk | Current |
|---|---|---|---|---|---|
| VICTORY_ALIAS_COPY | on by default; 0 = off | VICTORY_ALIAS_COPY=0: none is found, as before; | [S] crates\victory-gpu\src\resource.rs:1521 | [X] safe | [X] default/unset |
| VICTORY_ASK_ONCE | on by default; 0 = off | Whether a submission asks the kernel once, before its first refresh, about every range its lists refresh (VICTORY_ASK_ONCE=1; off by default). | [S] crates\victory-gpu\src\watch.rs:644 | [X] safe | [X] default/unset |
| VICTORY_BAKE_EXACT | on by default; 0 = off | Whether a draw of the title's bake finds the textures it picks by index as title memory has them at that moment (VICTORY_BAKE_EXACT=0: as the pass leaves them, as before). | [S] crates\victory-gpu\src\draw.rs:198 | [X] safe | [X] default/unset |
| VICTORY_BIND_CACHE | on by default; 0 = off | VICTORY_BIND_CACHE=0 sets them every time. | [S] crates\victory-gpu\src\draw.rs:1167 | [X] safe | [X] default/unset |
| VICTORY_BOOK | on by default; 0 = off | VICTORY_BOOK=0 keeps none. What the descriptors' bits mean is AMD's (RDNA 2 and 3); on another card nothing is decoded as an address we know, and nothing is said. | [S] crates\victory-gpu\src\book.rs:77 | [X] safe | [X] default/unset |
| VICTORY_BURY_LAG | default 64 submissions (16 with limited host RAM); 0 = drop without delay | Delays release of objects and host lists by N completed submissions to avoid use-after-free faults; 0 disables the delay. | [S] crates\victory-gpu\src\host.rs:618 | [X] safe | [X] default/unset |
| VICTORY_BVH_BOUNDS | on by default; 0 = off | Whether the structure builder's accesses through its root views stay near them, and a size in a structure's header that cannot be one counts as none (VICTORY_BVH_BOUNDS=0: neither). | [S] crates\victory-shader\src\emit\mod.rs:201 | [X] safe | [X] default/unset |
| VICTORY_BVH_FENCES | on by default; 0 = off | Whether buffer atomics of the ray-tracing structure builder stand between two fences (VICTORY_BVH_FENCES=0: they do not). | [S] crates\victory-shader\src\emit\mod.rs:192 | [X] safe | [X] default/unset |
| VICTORY_CACHE_CORES | on by default; 0 = off | Whether the cores of the largest last-level cache count as the fast ones where all cores are of one class (VICTORY_CACHE_CORES=0: not). | [S] crates\victory-gpu\src\cores.rs:110 | [X] safe | [X] default/unset |
| VICTORY_CACHE_DIR | unset: LOCALAPPDATA/victory/cache; set: cache path | Overrides the cache directory (default LOCALAPPDATA/victory/cache); stable run used a fresh directory. | [S] crates\victory-core\src\config.rs:88 | [X] safe | [X] stable=fresh directory |
| VICTORY_CAPTURE_FRAMES | unset: none; set: comma-separated frame numbers | Frames listed in VICTORY_CAPTURE_FRAMES (comma-separated): saved too, and their draws traced at debug level. | [S] crates\victory-gpu\src\capture.rs:25 | [X] safe | [X] default/unset |
| VICTORY_CARD_ACCOUNTING | off by default; 1 = on | Off unless VICTORY_CARD_ACCOUNTING=1; then at the first pass that finds the card without room, and every five seconds after it. | [S] crates\victory-gpu\src\draw.rs:2177 | [X] safe | [X] default/unset |
| VICTORY_CARD_AWAKE | default/off: unset or other; on: 1; turns: turns; stable: 0 | Keeps the card's clocks up between submissions (VICTORY_CARD_AWAKE=1; off by default). | [S] crates\victory-gpu\src\host\awake.rs:66 | [X] safe | [X] stable=0 (overrides launcher 1) |
| VICTORY_CARD_BUFFERS | on by default; 0 = off | VICTORY_CARD_BUFFERS=0 keeps every copy in the PC's memory, as before. | [S] crates\victory-gpu\src\shadow.rs:166 | [X] safe | [X] default/unset |
| VICTORY_CARD_HASH_LEN | on by default; 0 = off | VICTORY_CARD_HASH_LEN=0: the whole buffer. | [S] crates\victory-gpu\src\shadow.rs:4528 | [X] safe | [X] default/unset |
| VICTORY_CARD_REHASH_RUNS | off by default; 1 = on | Whether the pieces hashed again after ranges were sent up to a copy in the card's memory are hashed in runs of pieces that touch, each piece once (VICTORY_CARD_REHASH_RUNS=1; off by default), and not in a pass per range sent up. | [S] crates\victory-gpu\src\host.rs:2294 | [X] safe | [X] launcher=1 |
| VICTORY_CARD_ROOM_FOR_BUFFERS | on by default; 0 = off | Whether the texture queue leaves room on the card for the card copies of title buffers that are not made yet (VICTORY_CARD_ROOM_FOR_BUFFERS=1; off by default). | [S] crates\victory-gpu\src\shadow.rs:284 | [X] safe | [X] default/unset |
| VICTORY_CARD_SPANS | off by default; 1 = on | Diagnostics: how long the card itself works on our submissions, by its own timestamps (VICTORY_CARD_SPANS=1). | [S] crates\victory-gpu\src\host\spans.rs:69 | [X] safe | [X] default/unset |
| VICTORY_CARD_STEPS | default 0; 1 = fill steps; 2 = title buffer copies too (launcher: 2) | Steps of a submission that read title memory flights in the air may still write, done on the card in the flights' order instead of on the CPU after a wait for them (VICTORY_CARD_STEPS, see [stage]). | [S] crates\victory-gpu\src\host\card_steps.rs:79 | [X] safe | [X] launcher=2 |
| VICTORY_CLZERO_ASK | on by default (memory answers remembered); 1 = ask Windows every time | Remembers Windows memory queries for clzero emulation; 1 asks every time and is much slower. | [S] crates\victory-loader\src\console_insn.rs:28 | [X] safe | [X] default/unset |
| VICTORY_COMMITTED_QUERY | off by default; 1 = on | Whether the two questions above and below are put to VirtualQuery, as they were (VICTORY_COMMITTED_QUERY=1). | [S] crates\victory-gpu\src\texture.rs:1704 | [X] safe | [X] default/unset |
| VICTORY_COPIES_IN_PLACE | on by default; 0 = off | The title's buffer copies, done on the card at their place in the list (VICTORY_COPIES_IN_PLACE, on by default; | [S] crates\victory-gpu\src\host\place.rs:43 | [X] safe | [X] default/unset |
| VICTORY_CUT_WAITS | on by default; 0 = off | VICTORY_CUT_WAITS=0 holds whole lists, as before. | [S] crates\victory-gpu\src\queue.rs:113 | [X] safe | [X] default/unset |
| VICTORY_D3D12_DEBUG | off by default; any nonzero/set value = on | VICTORY_D3D12_DEBUG: the debug layer, whose messages a refused pipeline's error then carries. | [S] crates\victory-shader\src\emit\host.rs:178 | [X] safe | [X] default/unset |
| VICTORY_D3D12_DRED | default off; on/light/full in diagnostics builds; launcher: light | Whether device-removed data is on (VICTORY_D3D12_DRED, diagnostics builds). | [S] crates\victory-gpu\src\host.rs:1828 | [X] safe | [X] stable=light |
| VICTORY_DECLARE_ONCE | on by default; 0 = off | See [HostList::defer_gpu_write]. | [S] crates\victory-gpu\src\host.rs:3982 | [X] safe | [X] default/unset |
| VICTORY_DEPTH_TWINS | on by default; 0 = off | VICTORY_DEPTH_TWINS=0 makes none (such views stay null), VICTORY_DEPTH_TWINS=stencil only those of formats with a stencil plane, VICTORY_DEPTH_TWINS=nodepth none for the depth planes of such formats. | [S] crates\victory-gpu\src\resource.rs:469 | [X] safe | [X] default/unset |
| VICTORY_DESC_WHY | off by default; any nonzero/set value = on | The same, of a view picked from a table or the heap at an index the program computes (the ray tracer's structure, by an index from a constant buffer): the address from the host's table by view heap slot. | [S] crates\victory-shader\src\emit\lower.rs:7069 | [X] safe | [X] default/unset |
| VICTORY_DIRECT_WRITES | on by default; 0 = off | VICTORY_DIRECT_WRITES=0 writes as before. | [S] crates\victory-gpu\src\host.rs:8683 | [X] safe | [X] default/unset |
| VICTORY_DSTORAGE_LOG | unset: off/default; set: value applies | The streaming log (VICTORY_DSTORAGE_LOG=&lt;file&gt;): a line for every request (R: queue, number, file, offset, source bytes, destination bytes, options, when enqueued, submitted, started, done, result), every status entry written (S: array, number, when enqueued, when written), the title's first look at it after (P: array, when written, when seen), every file opened (F), and each second what the title's mapping calls cost (M, xmem::map_costs). | [S] crates\victory-hle\src\modules\dstorage.rs:714 | [X] safe | [X] default/unset |
| VICTORY_DSTORAGE_TRACE | default 0 (off); 1 = batches/anomalies; 2 = every request | The streaming trace (VICTORY_DSTORAGE_TRACE): 0 or unset: off; 1: a line for every batch, and for every request whose page list, or whose pages' mapping, changed when it should not have, or whose bytes another running request writes too; 2: a line for every request. | [S] crates\victory-hle\src\modules\dstorage.rs:1056 | [X] safe | [X] default/unset |
| VICTORY_DYNAMIC_SLOTS | default up to 2^20 slots (4 x 2^18), capped by free heap slots; set overrides | Caps dynamic descriptor slots used for tables; default permits up to 4x the base 2^18 slots. | [S] crates\victory-gpu\src\descriptor\host.rs:1617 | [X] safe | [X] default/unset |
| VICTORY_EMIT_DUMP | unset: off; set: outside-repo dump folder | Dumped shaders and validator reports are game-derived (rule #1). | [S] apps\victory\src\translate.rs:247 | [X] safe | [X] default/unset |
| VICTORY_EXACT_BACK | on by default; 0 = off | Whether what shaders wrote goes into title memory run by run ([put_changed]; on by default, VICTORY_EXACT_BACK=0 writes the whole stretch from the first changed byte to the last, as before). | [S] crates\victory-gpu\src\shadow.rs:2123 | [X] safe | [X] default/unset |
| VICTORY_FAIL_DUMP | unset: off/default; set: value applies | VICTORY_FAIL_DUMP=&lt;dir&gt;: the first 3 containers of each failure reason, as the title has them (.cdxil), to work on a translator gap offline | [S] apps\victory\src\translate.rs:563 | [X] safe | [X] default/unset |
| VICTORY_FAULT_BOOK | unset: off; set: fault-book file path | Writes a binary book of guarded-view write faults to &lt;file&gt;.&lt;n&gt;.bin in diagnostics builds. | [S] crates\victory-gpu\src\faultbook.rs:87 | [X] safe | [X] default/unset |
| VICTORY_FAULT_BOOK_AT | default 150,210,270 seconds; only used with VICTORY_FAULT_BOOK | Comma-separated seconds after start from which VICTORY_FAULT_BOOK records 40 frames each; default 150,210,270. | [S] crates\victory-gpu\src\faultbook.rs:88 | [X] safe | [X] default/unset |
| VICTORY_FIRST_HALF | on by default; 0 = off | Only in the second translation of a program the first one refused for it ([with_first_half_pairs]). | [S] crates\victory-shader\src\emit\lower.rs:2079 | [X] safe | [X] default/unset |
| VICTORY_FIRSTLANE_OWN | off by default; 1 = on | the host wave holds the same, so the first lane's is the lane's own. two host waves that exchange: the console's first lane may be in the other one, unless every lane holds the same value shortcut: VICTORY_FIRSTLANE_OWN=1 takes the host wave's own first lane, exact when the value is the same in every lane of the console wave (the ray-tracing builder's scans read a sum of scalars this way, inside a loop whose exit is per console wave). | [S] crates\victory-shader\src\emit\lower.rs:9430 | [X] safe | [X] default/unset |
| VICTORY_FULL_CARD_PASS | on by default; 0 = off | Whether a pass over the textures picked by index on a full card holds back the slots that need a new host copy (VICTORY_FULL_CARD_PASS=0: no, as before: they stay due, each pass looks at the same ones again and stops at the 257th). | [S] crates\victory-gpu\src\draw.rs:755 | [X] safe | [X] default/unset |
| VICTORY_GPU_TIMING | off by default; any nonzero/set value = on | VICTORY_LATE_WAIT: 0 (off), 1, or 2 ([late_exact]). | [S] crates\victory-gpu\src\host.rs:2525 | [X] safe | [X] default/unset |
| VICTORY_HEAP_PASS_ASIDE | on by default; 0 = off | Runs the heap buffer-view pass on a helper thread while the title records; 0 does it on the recording thread. | [S] crates\victory-gpu\src\host\aside.rs:47 | [X] safe | [X] default/unset |
| VICTORY_HEAP_RECHECK | on by default; 0 = off | Whether textures picked by index are looked at again after their upload (VICTORY_HEAP_RECHECK=0: no). | [S] crates\victory-gpu\src\draw.rs:770 | [X] safe | [X] default/unset |
| VICTORY_HEAP_SPREAD | on by default; 0 = off | Whether the slots looked at again for no write are a part of them at every pass, each slot at every sixteenth (VICTORY_HEAP_SPREAD=0: all of them at every sixteenth pass, as before). | [S] crates\victory-gpu\src\draw.rs:595 | [X] safe | [X] default/unset |
| VICTORY_HEAP_SYNC | on by default; 0 = off | Whether [sync_heaps] is done (VICTORY_HEAP_SYNC=0: not). | [S] crates\victory-gpu\src\descriptor.rs:170 | [X] safe | [X] default/unset |
| VICTORY_HELPER_OWN | on by default; 0 = off | Whether a pixel shader's helper lane reads its own value where the console reads the first lane's (lower.rs first_lane); on unless VICTORY_HELPER_OWN=0. | [S] crates\victory-shader\src\emit\mod.rs:157 | [X] safe | [X] default/unset |
| VICTORY_HOST_MAX_WAVE | unset: no override; set: wave width alias; 0 = unknown width | Compatibility alias for VICTORY_HOST_WAVE used when translating for a chosen host wave width. | [S] apps\victory\src\main.rs:226 | [X] safe | [X] default/unset |
| VICTORY_HOST_RDNA | off by default; 1 = on | VICTORY_HOST_RDNA=1: as for an AMD RDNA card (VICTORY_RDNA_FLOAT). | [S] apps\victory\src\translate.rs:268 | [X] safe | [X] default/unset |
| VICTORY_HOST_WAVE | unset: device-derived wave width; set overrides; 0 = unknown; wins over alias | Overrides the emulated host wave width for translation and warm-up; wins over VICTORY_HOST_MAX_WAVE. | [S] apps\victory\src\main.rs:225 | [X] safe | [X] default/unset |
| VICTORY_IMAGE_WATCH | unset: off; set: name=hex-offset:bytes list of title image words | Diagnostics (VICTORY_IMAGE_WATCH; off by default): words of the title's image, logged once a second, for what a launch's own counters say (how much of its streaming memory it uses, whether an allocation failed) where two launches end up with different pictures. VICTORY_IMAGE_WATCH=used=98d26d8:8,failed=98d26d0:1: a name, the offset in the image (hexadecimal) and the bytes (1, 2, 4 or 8). | [S] crates\victory-hle\src\image_watch.rs:51 | [X] safe | [X] default/unset |
| VICTORY_INDIRECT_BATCH | default 1; 0 = each on its own; 2 = batches (launcher: 2) | VICTORY_INDIRECT_BATCH=0: each on its own, or in windows ([windows])). | [S] crates\victory-gpu\src\draw.rs:340 | [X] safe | [X] launcher=2 |
| VICTORY_INDIRECT_WINDOW | off by default; 1 = on | Whether indirect draws that read record after record of one argument buffer are clamped a window at a time (VICTORY_INDIRECT_WINDOW=1; off by default). | [S] crates\victory-gpu\src\draw.rs:308 | [X] safe | [X] launcher=1 |
| VICTORY_JOIN_COPIES | off by default; 1 = on | Whether a title buffer copy that continues the one recorded before it in its list becomes one step with it (VICTORY_JOIN_COPIES=1; off by default). | [S] crates\victory-gpu\src\host.rs:3958 | [X] safe | [X] stable=1 |
| VICTORY_JOIN_LISTS | default 48; set overrides; 1 = no list joining | Number of lists grouped with each joined submission part; default 48. | [S] crates\victory-gpu\src\host.rs:3261 | [X] safe | [X] default/unset |
| VICTORY_JOIN_PARTS | default 1 (off); set N = join N parts; launcher stable value 8 | Groups N submission parts and lists handed to the host as one; default 1 is off, launcher stable value is 8. | [S] crates\victory-gpu\src\host.rs:3261 | [X] safe | [X] stable=8 |
| VICTORY_KEEP_SHOWN | default 1; set overrides; 0 = none/off | (Width, 64 bits, height, depth and levels, format: words 4 to 8.) Whether a slot that is written with a view of another texture goes on showing the one it shows until the new one is made and its upload has run (VICTORY_KEEP_SHOWN): 0: never, it reads as zeros, then as the neutral texture; 1: one of the same kind in another place or size; 2: any of the same dimension. | [S] crates\victory-gpu\src\descriptor\host.rs:4560 | [X] safe | [X] default/unset |
| VICTORY_KEEP_VIEWS | on by default; 0 = off | VICTORY_KEEP_VIEWS=0 makes it null at once, as before. | [S] crates\victory-gpu\src\descriptor\host.rs:4484 | [X] safe | [X] default/unset |
| VICTORY_KNOWN_HOLES | on by default; 0 = off | An asking made blocks of pages clean and noted them in the journal. (Put there since: whoever did clears the bit after this is set, or its own bit is found here.) Whether placeholders are known for what they are (VICTORY_KNOWN_HOLES=0: every hole is looked at at every asking, as before). | [S] crates\victory-gpu\src\watch.rs:1254 | [X] safe | [X] default/unset |
| VICTORY_LAND | on by default; 0 = off | What shaders wrote goes into title memory on a few threads (VICTORY_LAND, on by default; | [S] crates\victory-gpu\src\land.rs:46 | [X] safe | [X] default/unset |
| VICTORY_LAND_ANYTIME | on by default; 0 = off | Whether a piece is put through a view of ours while the runtime changes a mapping too (VICTORY_LAND_ANYTIME=0: through the title's address, as before). | [S] crates\victory-gpu\src\land.rs:475 | [X] safe | [X] default/unset |
| VICTORY_LAND_BESIDE | on by default; 0 = off | other copies; a landing is done, whole, before the title is told anything and before the next one starts (Host::relay_land). With VICTORY_LAND_BESIDE (on by default) title memory that is a view of the title's physical pages is written through a view of our own of the same pages ([crate::inplace::beside]). | [S] crates\victory-gpu\src\land.rs:62 | [X] safe | [X] default/unset |
| VICTORY_LAND_TAKEN | on by default; 0 = off | Whether a copy a landing went through is noted as up to date with it (VICTORY_LAND_TAKEN=0: it is not, and the next refresh copies the 64 KiB again and sends them up to the card, as before). | [S] crates\victory-gpu\src\land.rs:511 | [X] safe | [X] default/unset |
| VICTORY_LAZY_PRELUDE | on by default; 0 = off | VICTORY_LAZY_PRELUDE=0: made with the list, as before. | [S] crates\victory-gpu\src\host.rs:1375 | [X] safe | [X] default/unset |
| VICTORY_LAZY_TEXTURES | on by default; 0 = off | VICTORY_LAZY_TEXTURES=0 makes each when the title creates its texture, as before. | [S] crates\victory-gpu\src\resource.rs:1587 | [X] safe | [X] default/unset |
| VICTORY_LENT_HEAP | on by default; 0 = off | VICTORY_LENT_HEAP=0: none, such a dispatch is dropped, as before. | [S] crates\victory-gpu\src\descriptor.rs:763 | [X] safe | [X] default/unset |
| VICTORY_LEVELS_MIN_KB | default adapter-derived floor; set: KiB floor | The bytes from which a texture is made this way: a megabyte, or VICTORY_LEVELS_MIN_KB. (The accounting of run 189: the levels not held are 1.9 MB a copy on some 1,600 copies; a 512x512 texture has six tiles at most, and most of the calls for nothing.) | [S] crates\victory-gpu\src\tiles.rs:120 | [X] safe | [X] default/unset |
| VICTORY_LEVELS_ON_DEMAND | off by default; 1 = on | Off unless VICTORY_LEVELS_ON_DEMAND=1. | [S] crates\victory-gpu\src\tiles.rs:81 | [X] safe | [X] stable=1 |
| VICTORY_LIBRARY_HANDLE | on by default; 0 = off | VICTORY_LIBRARY_HANDLE=0: closed, as before. | [S] crates\victory-gpu\src\pipeline\library.rs:121 | [X] safe | [X] default/unset |
| VICTORY_LIBRARY_MAP | on by default; 0 = off | A save writes the new library through a mapping of the new file in the same way (a buffer of the library's size was made, filled and written out at each save). VICTORY_LIBRARY_MAP=0: read and written through buffers, as before. The mapped file's handle stays open for as long as the mapping lives ([holds]). | [S] crates\victory-gpu\src\pipeline\library.rs:112 | [X] safe | [X] default/unset |
| VICTORY_LIGHT_PROBE | unset or 0: off; set: output file path | Diagnostics of the picture's light, frame by frame (VICTORY_LIGHT_PROBE=&lt;file.csv&gt;): what the title's exposure programs and the stand-in for the indirect light (crate::ambient) hold, written by the card into a ring of records the processor reads a few frames later, one line a frame. What the title does (programs by their names in the containers): - PS_CalculateExposure (one 1x1 target a frame) moves the exposure toward a target by the frame's time (constant 0x3a4, 1/15 s at most) at | [S] crates\victory-gpu\src\lightprobe.rs:74 | [X] safe | [X] default/unset |
| VICTORY_LIGHT_PROBE_LUX | off by default; 1 = on | The lux program is looked at too (VICTORY_LIGHT_PROBE_LUX=1; off: run light-21 lost the device in the pass after it, with a view of the frame before bound as a raw buffer where the plain form has a texture). | [S] crates\victory-gpu\src\lightprobe.rs:49 | [X] safe | [X] default/unset |
| VICTORY_LIST_POOL | on by default; 0 = off | VICTORY_LIST_POOL=0: each is made new and thrown away, as before). | [S] crates\victory-gpu\src\list.rs:255 | [X] safe | [X] default/unset |
| VICTORY_LIST_SLOTS | unset: none; set: comma-separated shader hash prefixes | The pixel shaders whose draws get their slots listed ([State::slots_text]): VICTORY_LIST_SLOTS, hash prefixes separated by commas. | [S] crates\victory-gpu\src\draw.rs:4468 | [X] safe | [X] default/unset |
| VICTORY_LIST_VIEWS | on by default; 0 = make a view for every table | Makes a descriptor view once per list instead of once per table; 0 restores per-table views. | [S] crates\victory-gpu\src\descriptor\host.rs:6032 | [X] safe | [X] default/unset |
| VICTORY_LOG | unset: off/default; set: value applies | One tracing setup for every binary. Filter with VICTORY_LOG (falls back to RUST_LOG), e.g. VICTORY_LOG=victory_loader=trace,info. | [S] crates\victory-core\src\logging.rs:21 | [X] safe | [X] default/unset |
| VICTORY_MAP_LEAN | on by default; 0 = off | Whether a mapping change asks the host only for what it needs: no split of a placeholder that is already the view's own, no commit of section pages that are committed (VICTORY_MAP_LEAN=0: both every time, as before). | [S] crates\victory-hle\src\modules\xmem.rs:1058 | [X] safe | [X] default/unset |
| VICTORY_MAP_THREADS | default 8 clamped 1..32; auto = system choice; launcher: 1 | How many threads map a group of pages side by side (VICTORY_MAP_THREADS; 8 unless set; 1: the caller alone, a page after the other; | [S] crates\victory-hle\src\modules\xmem.rs:1435 | [X] safe | [X] launcher=1 |
| VICTORY_MAPPED_BY_VIEWS | on by default; 0 = off | VICTORY_MAPPED_BY_VIEWS=0: the host is asked, as before. | [S] crates\victory-gpu\src\texture.rs:1789 | [X] safe | [X] default/unset |
| VICTORY_MEMORY_CARD_MB | default 4096 MiB; set: MiB cap; preset: 1024 | Caps how much by-address copy data is placed in card-local memory; default 4096 MiB, preset 1024. | [S] crates\victory-gpu\src\shadow.rs:5478 | [X] safe | [X] stable=1024 MiB |
| VICTORY_MEMORY_CATEGORIES | off by default; 1 = add periodic approximate memory-category line | Adds a periodic approximate line grouping already counted memory categories; 1 enables. | [S] crates\victory-gpu\src\copystat.rs:618 | [X] safe | [X] default/unset |
| VICTORY_MEMORY_DUMP | unset: off/default; set: value applies | VICTORY_MEMORY_DUMP=&lt;folder&gt;: when a file go appears there, the arenas as the card holds them are copied out and written (arena-&lt;n&gt;.bin), with pages.txt (title page, arena, offset) and the structures the walking programs were given: to look at the structures offline. | [S] crates\victory-gpu\src\memory.rs:1197 | [X] safe | [X] default/unset |
| VICTORY_MEMORY_MAP | default 60; set overrides; 0 = none/off | Sets how often the diagnostics build walks the address space for the memory-map line; default 60 lines (about five minutes), 0 omits the walk. | [S] crates\victory-gpu\src\copystat.rs:609 | [X] safe | [X] default/unset |
| VICTORY_METER_THREAD | on by default; 0 = frame-meter lines on presenting thread | Makes the frame meter's lines of every 5 s: on a thread of ours ("victory-meter"), so presenting goes on (VICTORY_METER_THREAD, on unless =0: by the presenting thread, as before). | [S] crates\victory-gpu\src\host.rs:8894 | [X] safe | [X] default/unset |
| VICTORY_OPEN_ONE_VIEW | on by default; 0 = open all views of a faulted page | On a write fault opens only the faulting view; 0 opens every view of the page as before. | [S] crates\victory-gpu\src\watch.rs:1510 | [X] safe | [X] default/unset |
| VICTORY_PAGE_PARTS | on by default; 0 = off | Whether the parts of a page that the kernel names are kept, and a refresh copies those (VICTORY_PAGE_PARTS=0: the 64 KiB page, as before). | [S] crates\victory-gpu\src\watch.rs:54 | [X] safe | [X] default/unset |
| VICTORY_PAIRS | unset: none; set: comma-separated name+pattern pairs | VICTORY_HOST_RDNA=1: as for an AMD RDNA card (VICTORY_RDNA_FLOAT). | [S] apps\victory\src\translate.rs:281 | [X] safe | [X] default/unset |
| VICTORY_PATCH_CLZERO | on by default; 0 = off | VICTORY_PATCH_CLZERO=0 emulates each time, as before. | [S] crates\victory-loader\src\console_insn.rs:76 | [X] safe | [X] default/unset |
| VICTORY_PATCH_WAITS | on by default; 0 = off | VICTORY_PATCH_WAITS=0 emulates each time, as before. | [S] crates\victory-loader\src\console_insn.rs:57 | [X] safe | [X] default/unset |
| VICTORY_PICKED_MB | default 32; set overrides; 0 = none/off | Bytes looked at in turn per frame (VICTORY_PICKED_MB). | [S] crates\victory-gpu\src\picked.rs:76 | [X] safe | [X] default/unset |
| VICTORY_PIPELINE_LIBRARY | on by default; 0 = no library calls at all | Uses the D3D12 pipeline library; 0 disables all library calls. | [S] crates\victory-gpu\src\pipeline\library.rs:475 | [X] safe | [X] default/unset |
| VICTORY_PIPELINE_WAIT_SHARED | on by default; 0 = off | VICTORY_PIPELINE_WAIT_SHARED=0 counts as before. | [S] crates\victory-gpu\src\pipeline\make.rs:201 | [X] safe | [X] default/unset |
| VICTORY_PLACED_ORDER | off by default; 1 = cut submission around stale in-place copy | Cuts a submission around an in-place copy that would otherwise read stale bytes; 1 enables. | [S] crates\victory-gpu\src\host\card_steps.rs:103 | [X] safe | [X] default/unset |
| VICTORY_POP_FOLDER | unset: off; set: folder for popped-frame captures | width * height 8-bit RGBA (or BGRA) pixels made small. | [S] crates\victory-gpu\src\popwatch.rs:295 | [X] safe | [X] default/unset |
| VICTORY_POP_WATCH | unset: none; set: from-to second intervals | VICTORY_POP_WATCH=&lt;from&gt;-&lt;to&gt;[,&lt;from&gt;-&lt;to&gt;..] (seconds since the start): every presented frame in those times is read back, made small on a thread of its own and compared with its neighbours, block by block. | [S] crates\victory-gpu\src\popwatch.rs:46 | [X] safe | [X] default/unset |
| VICTORY_PROCESS_PRIORITY | default above-normal; 0 or normal = leave at normal | VICTORY_PROCESS_PRIORITY=normal: as it was started. | [S] crates\victory-hle\src\runtime.rs:284 | [X] safe | [X] default/unset |
| VICTORY_QUEUE_WAIT | on by default; 0 = off | VICTORY_QUEUE_WAIT=0: they do not, and every submission runs when it is made (as before). | [S] crates\victory-gpu\src\queue.rs:75 | [X] safe | [X] default/unset |
| VICTORY_QUICK_FIND | on by default; 0 = disable thread-local lookup cache | Keeps a thread-local cache of buffer-lookup answers; 0 disables it. | [S] crates\victory-gpu\src\shadow.rs:5060 | [X] safe | [X] default/unset |
| VICTORY_QUICK_MIRROR | on by default; 0 = off | Whether a slot already made from its record is told so without the lock (VICTORY_QUICK_MIRROR=0: with it, as before). | [S] crates\victory-gpu\src\descriptor\host.rs:4645 | [X] safe | [X] default/unset |
| VICTORY_RAW_VIEWS | on by default; 0 = off | VICTORY_RAW_VIEWS=0: they read the title's slots themselves, as before). | [S] crates\victory-gpu\src\descriptor\host.rs:1541 | [X] safe | [X] default/unset |
| VICTORY_READ_BACK | on by default; 0 = off | Records a texture to buffer copy (a read back) of [copy_texture_region] into list, or says why not. | [S] crates\victory-gpu\src\list.rs:1223 | [X] safe | [X] default/unset |
| VICTORY_READY_ONCE | on by default; 0 = recheck every table entry at every draw | Skips rechecking unchanged dynamic descriptor tables; 0 rechecks every entry at every draw. | [S] crates\victory-gpu\src\draw.rs:4356 | [X] safe | [X] default/unset |
| VICTORY_RECHECK_SOON | on by default; 0 = off | Whether a texture found changed with nothing to tell of it is looked at again in the next frame (VICTORY_RECHECK_SOON=0: after four, as before). | [S] crates\victory-gpu\src\draw.rs:206 | [X] safe | [X] default/unset |
| VICTORY_RECORD | unset: off; set: capture folder to record the D3D12 boundary | Records D3D12 calls and descriptor states to a folder; unset hooks nothing. | [S] crates\victory-gpu\src\replay\record.rs:61 | [X] safe | [X] default/unset |
| VICTORY_RECORD_ALWAYS | off by default; 1 = record every frame in the capture window | Records every frame in the capture window; 1 enables. | [S] crates\victory-gpu\src\replay\record.rs:67 | [X] safe | [X] default/unset |
| VICTORY_RECORD_AT | default: trigger file named go; set seconds or f&lt;frame&gt; to arm at a time | Arms recording at a time in seconds, a frame with fN, or a trigger file named go by default. | [S] crates\victory-gpu\src\replay\record.rs:62 | [X] safe | [X] default/unset |
| VICTORY_RECORD_FRAMES | default 1; set: frames to record, clamped to at least 1 | Number of presents recorded after arming; default 1. | [S] crates\victory-gpu\src\replay\record.rs:63 | [X] safe | [X] default/unset |
| VICTORY_REFRESH_FRONT | on by default; 0 = off | Whether everything a submission refreshes is brought up to date in one go, on several threads, ahead of its steps (VICTORY_REFRESH_FRONT=1, and with | [S] crates\victory-gpu\src\host.rs:7905 | [X] safe | [X] default/unset |
| VICTORY_RELAY | default/off: stage 2 when relay runs; 1 = first stage; launcher: 2 | The relay's first stage (VICTORY_RELAY=1; off by default; it turns [late] on at stage 3 unless VICTORY_LATE_WAIT says another stage, and is off with it, in the timing run and with kept snapshots). | [S] crates\victory-gpu\src\host.rs:2628 | [X] safe | [X] stable=2 |
| VICTORY_RELAY_COPY | off by default; 1 = on | Whether the pieces the relay fetches from the card's memory come over the card's copy queue (VICTORY_RELAY_COPY=1) and not over the queue that draws. | [S] crates\victory-gpu\src\host.rs:2649 | [X] safe | [X] launcher=1 |
| VICTORY_RESIDENCY | off by default; 1 = on | Only with VICTORY_RESIDENCY=1 ([on]): the memory of the system is then asked once a second; below 3 GiB of free RAM or 4 GiB of commit (out again above 5 / 6) texture prefetch is limited to 64 MiB a frame and idle scratch and staging blocks are let go; below 1.5 GiB of commit to 16 MiB; the texture pass stops below 512 MiB of commit, new staging blocks for textures picked by index below 1 GiB. | [S] crates\victory-gpu\src\residency.rs:22 | [X] safe | [X] stable=1 |
| VICTORY_RESIDENCY_LIMITED | off by default unless physical RAM &lt;= 32 GiB; 1 with VICTORY_RESIDENCY forces limited mode | Forces the limited-host-RAM budget path when residency is on; otherwise it is automatic at 32 GiB physical RAM or less. | [S] crates\victory-gpu\src\residency.rs:119 | [X] safe | [X] stable=1 |
| VICTORY_REUPLOAD_WHEN_FULL | on by default; 0 = off | Whether a texture that has its host copy is still brought up to date while the card has no room for new ones (VICTORY_REUPLOAD_WHEN_FULL=0: no). | [S] crates\victory-gpu\src\draw.rs:763 | [X] safe | [X] default/unset |
| VICTORY_RIPE_BLOCKS | default 12; 0 = every block ripe at once | frames, a tenth of a second while the title shows a loading screen at 30 a second, with up to 18 submissions in the air.) How many blocks of textures are made ahead, so that one has been there for a while when its first piece is taken (VICTORY_RIPE_BLOCKS, 12; 0: none, and new blocks are used at once, as before). | [S] crates\victory-gpu\src\pool.rs:109 | [X] safe | [X] default/unset |
| VICTORY_ROOT_SRV_DIRECT | on by default; 0 = off | VICTORY_ROOT_SRV_DIRECT=1 goes back to root descriptors. | [S] crates\victory-gpu\src\pipeline\host.rs:355 | [X] safe | [X] default/unset |
| VICTORY_SAFE_COPY | on by default; 0 = off | Whether copies are made here and not by the kernel. | [S] crates\victory-gpu\src\safecopy.rs:383 | [X] safe | [X] default/unset |
| VICTORY_SAME_RECORDS | on by default; 0 = always write descriptor-copy bytes | Skips writing descriptor-copy bytes that are already equal; 0 always writes them. | [S] crates\victory-gpu\src\titlewrite.rs:185 | [X] safe | [X] default/unset |
| VICTORY_SCRATCH_POOL | on by default; 0 = off | VICTORY_SCRATCH_POOL=0: chunks of 4 MiB kept by their list, as before. | [S] crates\victory-gpu\src\host.rs:2016 | [X] safe | [X] default/unset |
| VICTORY_SECTION_WINDOW | on by default; 0 = off | VICTORY_SECTION_WINDOW=0: a view for each write, as before. | [S] crates\victory-hle\src\modules\xmem.rs:418 | [X] safe | [X] default/unset |
| VICTORY_SHADER_CENSUS | off by default; any nonzero/set value = on | Counts of a module's instructions by kind (a diagnostic): what a translated program costs before the driver's compiler sees it. VICTORY_SHADER_CENSUS (any value) turns the counting on; the counts of the module a thread wrote last are read with [take]. | [S] crates\victory-shader\src\emit\bitcode\census.rs:63 | [X] safe | [X] default/unset |
| VICTORY_SHADER_SAVE | unset: off; set: folder for original and translated shaders | VICTORY_SHADER_SAVE=&lt;dir&gt;: each shader as the title gave it (.cdxil) and as translated (.dxil), by the hash crash reports name it with | [S] crates\victory-gpu\src\pipeline.rs:162 | [X] safe | [X] default/unset |
| VICTORY_SHOW_AFTER | off by default; any nonzero/set value = on | Whether a title slot shows a texture that is new to it only once the submission with its upload has finished (VICTORY_SHOW_AFTER=1; off). | [S] crates\victory-gpu\src\descriptor\host.rs:341 | [X] safe | [X] stable=1 |
| VICTORY_SHOW_NEW_LATER | on by default; 0 = off | Whether a title slot that would show a texture made while submissions begun before it may still run shows it only once those have finished (VICTORY_SHOW_NEW_LATER, on; 0: at once, as before; | [S] crates\victory-gpu\src\descriptor\host.rs:361 | [X] safe | [X] default/unset |
| VICTORY_SLOT_HOLDS | on by default; 0 = off | VICTORY_SLOT_HOLDS=0: only the list holds it, as before. | [S] crates\victory-gpu\src\descriptor\host.rs:3056 | [X] safe | [X] default/unset |
| VICTORY_SPANS_QUICK | on by default; 0 = off | VICTORY_SPANS_QUICK=0: its lock is taken for every write, as before). | [S] crates\victory-gpu\src\descriptor\host.rs:261 | [X] safe | [X] default/unset |
| VICTORY_SPLIT_WAITS | on by default; 0 = off | VICTORY_SPLIT_WAITS=0 holds whole submissions, as before. | [S] crates\victory-gpu\src\queue.rs:94 | [X] safe | [X] default/unset |
| VICTORY_STREAM_NOTICE | on by default; 0 = off | Notifies the GPU side of DirectStorage page arrivals by default; 0 routes them through page-write handling instead. | [S] crates\victory-hle\src\modules\xmem.rs:607 | [X] safe | [X] default/unset |
| VICTORY_STREAM_PRIORITY | on by default; 0 = off | Called where that thread maps and submits: lifts a thread that is below normal to above it (VICTORY_STREAM_PRIORITY=0: left as the title set it). | [S] crates\victory-hle\src\modules\xmem.rs:1072 | [X] safe | [X] default/unset |
| VICTORY_SYNC_IN_PLACE | on by default; 0 = off | Whether [sync_heaps] reads a changed page's records where they are, each once, and compares each with the one last seen as it reads it, 32 bytes at a time (VICTORY_SYNC_IN_PLACE=0: into a copy of the page first, then compared, as before). | [S] crates\victory-gpu\src\descriptor.rs:596 | [X] safe | [X] default/unset |
| VICTORY_TAKE_PARTS | on by default (known dirty sub-pages); 0 = treat whole page | Tracks known dirty sub-pages when a page is taken; 0 treats the whole page as dirty. | [S] crates\victory-gpu\src\watch.rs:971 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_BACK | unset or 1: four water formats; set: comma-separated widthxheightfFormat list | nothing had written (run rw1, VICTORY_READ_WATCH=1: about 30 places in the title read those two kinds), and boats sank. For textures of the kinds in VICTORY_TEXTURE_BACK (comma-separated &lt;width&gt;x&lt;height&gt;f&lt;format&gt;; unset or 1: the four water formats found by the upstream trace; | [S] crates\victory-gpu\src\texback.rs:34 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_BUDGET_MB | unset: VRAM-derived budget (128 MiB with limited residency); set: MiB; stable: 1792 | VICTORY_TEXTURE_BUDGET_MB sets a limit on those copies' bytes instead). | [S] crates\victory-gpu\src\resource.rs:1792 | [X] safe | [X] stable=1792 MiB |
| VICTORY_TEXTURE_FILL | on by default; 0 = off | Whether a refresh that does not wait ([no_wait]) and finds a page missing fills a staging buffer that was never filled from the pages that are there (VICTORY_TEXTURE_FILL=0: it was left as it was made). | [S] crates\victory-gpu\src\texture.rs:391 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_HOT | on by default; 0 = off | VICTORY_TEXTURE_HOT=0: every eighth frame only, as before. | [S] crates\victory-gpu\src\texture.rs:130 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_KEEP | on by default; 0 = off | VICTORY_TEXTURE_KEEP=0: [vram_idle_ms]' older rule, all that are idle; | [S] crates\victory-gpu\src\host.rs:195 | [X] safe | [X] stable=0 |
| VICTORY_TEXTURE_MAX | unset: 1024 / 512 at 92% / 256 at 97% VRAM; 0 = uncapped; stable: 256 | How many of a streamed placed 2D texture's largest mips to skip so no side passes VICTORY_TEXTURE_MAX (0: uncapped; unset: 1024, then 512 from 92 % of the VRAM budget and 256 from 97 %). | [S] crates\victory-gpu\src\resource.rs:1311 | [X] safe | [X] stable=256 |
| VICTORY_TEXTURE_NO_WAIT | off by default; 1 = on | Whether a texture refresh that finds the runtime remapping title memory goes on without waiting for it (VICTORY_TEXTURE_NO_WAIT=1; off by default). | [S] crates\victory-gpu\src\texture.rs:373 | [X] safe | [X] stable=1 |
| VICTORY_TEXTURE_ONCE | on by default; 0 = off | Whether a staging buffer made for one upload of a texture picked by index is filled without asking the write watch and the guards (VICTORY_TEXTURE_ONCE=0: with, as before). | [S] crates\victory-gpu\src\texture.rs:675 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_POOL | on by default; 0 = off | Asked once a second. (VICTORY_RESIDENCY=1, codec-d/cool_fox c64fc9b4/e94d277a: fewer spares while the system is short of memory, and idle blocks let go now, not at the pool's next allocation.) Milliseconds until a piece given back is used again. (It was three frames, a tenth of a second while the title shows a loading screen at 30 a second, with up to 18 submissions in the air.) | [S] crates\victory-gpu\src\pool.rs:92 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_ROOM_PERCENT | default 90; clamped 50..97; stable: 60 | The share of the card's budget, in percent, up to which host copies of textures picked by index are made ([room]): 90 unless VICTORY_TEXTURE_ROOM_PERCENT says another (50 to 97). | [S] crates\victory-gpu\src\resource.rs:1879 | [X] safe | [X] stable=60 |
| VICTORY_TEXTURE_SAME | on by default; 0 = off | from the bytes title memory holds now: an upload would bring nothing new. (Of 787 repeated uploads of a frame that streams 398 were equal in every byte, and a texture uploaded again costs a staging buffer, a detiling and a copy more than this look.) VICTORY_TEXTURE_SAME=0: not asked. | [S] crates\victory-gpu\src\texture.rs:1627 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_STAGE_MS | default 250 ms; set: milliseconds | The rest waits for the next frames, as it does past the bytes. | [S] crates\victory-gpu\src\draw.rs:2372 | [X] safe | [X] default/unset |
| VICTORY_TEXTURE_SWEEP | on by default; 0 = off | VICTORY_TEXTURE_SWEEP=0 lets nothing go. | [S] crates\victory-gpu\src\resource.rs:2131 | [X] safe | [X] default/unset |
| VICTORY_THIN | off by default; 1 = on | List calls that only write down their arguments (VICTORY_THIN=1); what they mean is worked out by threads of ours, beside the title's. Why: the title makes 45,000 to 60,000 list calls a frame. | [S] crates\victory-gpu\src\list\thin.rs:58 | [X] safe | [X] stable=1 |
| VICTORY_THIN_THREADS | default 8 clamped 1..32; stable: 5 | SAFETY: a list of ours nobody uses. | [S] crates\victory-gpu\src\list\thin.rs:321 | [X] safe | [X] stable=5 |
| VICTORY_THREAD_DIMENSIONS | on by default; 0 = off | VICTORY_THREAD_DIMENSIONS=0: such counts are taken for groups, as before. | [S] crates\victory-gpu\src\draw.rs:4193 | [X] safe | [X] default/unset |
| VICTORY_TIMELINE | unset: off; set: file or from,frames,file trace specification | The variables, read once (before the title runs: its imports are bound by them). | [S] crates\victory-gpu\src\timeline\record.rs:467 | [X] safe | [X] default/unset |
| VICTORY_TIMELINE_AT | default 60 seconds; set: start time for VICTORY_TIMELINE | Start time in seconds for a VICTORY_TIMELINE trace; default 60. | [S] crates\victory-gpu\src\timeline\record.rs:473 | [X] safe | [X] default/unset |
| VICTORY_TIMELINE_FRAMES | default 3 frames; set: frame count for VICTORY_TIMELINE | Frame count for a VICTORY_TIMELINE trace; default 3. | [S] crates\victory-gpu\src\timeline\record.rs:474 | [X] safe | [X] default/unset |
| VICTORY_TIMER_LOG | off by default; 1 = on | How even the frames are (VICTORY_TIMER_LOG=1): the times between frame beginnings, logged every 5 s by bands, with the pairs of a short frame next to a long one (a 16/33 alternation shows as many of them). | [S] crates\victory-gpu\src\frame.rs:251 | [X] safe | [X] default/unset |
| VICTORY_TITLE_FPS | default: title rate unless frame-interval clock is set; set fps overrides; off leaves title alone | The frame rate (VICTORY_FRAME_INTERVAL_MS, off without it): our frame clock ticks at that interval (victory-gpu), and the title is given the matching rate in place of its setting's 30 (VICTORY_TITLE_FPS overrides it; | [S] apps\victory\src\run.rs:191 | [X] safe | [X] default/unset |
| VICTORY_TITLE_PRIORITIES | on by default (normalize title priorities); 0 = leave as title sets; launcher=0 | Normalizes title thread priorities for the host; 0 leaves the title values unchanged and the launcher sets 0. | [S] crates\victory-hle\src\modules\kernel.rs:431 | [X] safe | [X] launcher=0 |
| VICTORY_TRAIL | on by default; 0 = off | VICTORY_TRAIL=0: nothing is kept and nothing is said. | [S] crates\victory-gpu\src\host.rs:659 | [X] safe | [X] default/unset |
| VICTORY_TRANSLATE_ONLY | unset: all shaders; set: comma-separated hashes to translate only | Diagnostics: VICTORY_TRANSLATE_ONLY=&lt;hash prefix&gt;,... translates those containers alone. | [S] apps\victory\src\translate.rs:509 | [X] safe | [X] default/unset |
| VICTORY_TRAP_LOG | unset: off; set: crash-log path | In a child process of the next test: calls an unimplemented import that traps, with the crash log where VICTORY_TRAP_LOG says. | [S] crates\victory-loader\src\thunks.rs:160 | [X] safe | [X] default/unset |
| VICTORY_UNDER_FUSED | on by default; 0 = find runs first, then copy them one by one | Fuses compare and write-back in 32-byte blocks; 0 finds runs first and copies them afterwards. | [S] crates\victory-gpu\src\shadow.rs:2212 | [X] safe | [X] default/unset |
| VICTORY_UNDER_WIDE | on by default; 0 = compare under-write pages on submitting thread; -Safe sets 0 | Compares under-write pages on several threads; 0 uses the submitting thread and -Safe sets 0. | [S] crates\victory-gpu\src\shadow.rs:2283 | [X] safe | [X] default/unset |
| VICTORY_UPLOAD_AHEAD | off by default; any nonzero/set value = on | First uploads of textures picked by index on a copy queue of their own (VICTORY_UPLOAD_AHEAD): read, detiled and copied by threads of ours as soon as the texture pass has made them, and the slots that wait for them shown when the copy has run. | [S] crates\victory-gpu\src\texture\ahead.rs:46 | [X] safe | [X] stable=1 |
| VICTORY_UPLOAD_LOW | on by default; 0 = off | copies ([crate::shadow]) and lives as long as the process: the directory of memory by address ([crate::memory]) keeps the copy it found at an address for good, so the same addresses must stay the same copy. VICTORY_UPLOAD_LOW=0: from the process heap, as before. | [S] crates\victory-gpu\src\upload.rs:42 | [X] safe | [X] default/unset |
| VICTORY_VIEW_BYTES | on by default; 0 = off | VICTORY_VIEW_BYTES=0 leaves them null, as before. | [S] crates\victory-gpu\src\descriptor\host.rs:1371 | [X] safe | [X] default/unset |
| VICTORY_VIEW_EXTENT | on by default; 0 = off | VICTORY_VIEW_EXTENT=0 looks the copy up by the view's range alone, as before. | [S] crates\victory-gpu\src\descriptor\host.rs:3655 | [X] safe | [X] default/unset |
| VICTORY_VIEW_GUARD | on by default; 0 = off | VICTORY_VIEW_GUARD=0 leaves the other views as they are, as before. | [S] crates\victory-gpu\src\watch.rs:1993 | [X] safe | [X] default/unset |
| VICTORY_VIEW_INLINE | on by default; 0 = off | VICTORY_VIEW_INLINE=0: every view is an entry, as before. | [S] crates\victory-gpu\src\descriptor.rs:1070 | [X] safe | [X] default/unset |
| VICTORY_WAIT_FORCE | on by default; 0 = off | VICTORY_WAIT_FORCE=0 keeps it held: for finding out whether the title's waits reach across its presents; a wait nothing ever meets then stops the title for good. | [S] crates\victory-gpu\src\queue.rs:123 | [X] safe | [X] default/unset |
| VICTORY_WAIT_RESIDENT | on by default; 0 = off | VICTORY_WAIT_RESIDENT=0: as before). | [S] crates\victory-gpu\src\host.rs:236 | [X] safe | [X] default/unset |
| VICTORY_WARM_SECONDS | default 4; set overrides; 0 = none/off | VICTORY_WARM_SECONDS=&lt;n&gt;: stop taking new shaders after n seconds (what is done stays in the cache; the next warm-up goes on from there). | [S] apps\victory\src\translate.rs:178 | [X] safe | [X] default/unset |
| VICTORY_WATCH | unset: off; set: comma-separated hexadecimal RVAs to watch | Debugging aid: VICTORY_WATCH=&lt;rva&gt;,... (hex) logs the u32 at each title+rva whenever it changes, polled every 5 ms (an engine's state, say). | [S] apps\victory\src\run.rs:271 | [X] safe | [X] default/unset |
| VICTORY_WAVE_DEEP_SKIPS | on by default; 0 = off | Every skip left out that the code after it cannot see ([ir::without_skips], deep): most of the body is then code every lane runs, where the two host waves can exchange. (VICTORY_WAVE_DEEP_SKIPS=0 and VICTORY_WAVE_WIDE=0 turn the two off.) | [S] crates\victory-shader\src\emit\mod.rs:555 | [X] safe | [X] default/unset |
| VICTORY_WAVE_DUMP | off by default; any nonzero/set value = on | Prints a WAVE64-LDS-FLAGS diagnostic line from shader lowering when set. | [S] crates\victory-shader\src\emit\lower.rs:1390 | [X] safe | [X] default/unset |
| VICTORY_WAVE_LOCAL | on by default; 0 = off | Lowers each host wave as its own wave for programs with partial-lane execution; 0 restores the earlier lowering. | [S] crates\victory-shader\src\emit\mod.rs:501 | [X] safe | [X] default/unset |
| VICTORY_WAVE_OWN_BITS | on by default; 0 = off | VICTORY_WAVE_OWN_BITS=0: a wave OR where not every lane runs is refused as before ([super::own_bits]). | [S] crates\victory-shader\src\emit\lower.rs:1511 | [X] safe | [X] default/unset |
| VICTORY_WAVE_WHY | off by default; any nonzero/set value = on | branches around them taken wave-wide they get their barriers) lanes 32..63 are the other host wave: masks, lane reads and lane numbers go through two exchange dwords past the program's LDS VICTORY_WAVE_WHY=1: why a program keeps 64-lane waves (one line per reason) | [S] crates\victory-shader\src\emit\lower.rs:1908 | [X] safe | [X] default/unset |
| VICTORY_WIDE_BACK | on by default; 0 = off | Whether the snapshots of a submission's shader-written ranges, and the compare that finds what the shaders wrote, run on several threads across ranges (VICTORY_WIDE_BACK=1; off by default). | [S] crates\victory-gpu\src\shadow.rs:1467 | [X] safe | [X] stable=1 |
| VICTORY_WIDE_FILLS | on by default; 0 = off | Whether the fills of a submission's upload memory are done together on several threads (VICTORY_WIDE_FILLS=0: one after the other, where the lists name them). | [S] crates\victory-gpu\src\host.rs:8091 | [X] safe | [X] default/unset |
| VICTORY_WIDE_TEXTURES | on by default; 0 = off | Whether a submission's textures are brought up to date on several threads (VICTORY_WIDE_TEXTURES=0: one after the other, where the lists name them, as before). | [S] crates\victory-gpu\src\host.rs:8109 | [X] safe | [X] default/unset |
| VICTORY_WRITE_SITES | on by default; 0 = off | With VICTORY_WRITE_SITES=&lt;file&gt;, a place that can be made to look first (can_look) and mostly left it is written into that file, for the next start (victory_loader::write_sites). (Nothing more once the file has been refused.) | [S] crates\victory-gpu\src\titlewrite.rs:274 | [X] safe | [X] default/unset |
| VICTORY_WRITE_SKIP | on by default; 0 = off | VICTORY_WRITE_SKIP=0 declares every such range, as before. | [S] crates\victory-gpu\src\draw.rs:241 | [X] safe | [X] default/unset |
| VICTORY_XMA_DUMP | unset: off; set: folder for decoded XMA dumps | VICTORY_XMA_DUMP=&lt;dir&gt;: saves the context words (&lt;n&gt;-&lt;index&gt;.ctx) and input buffer 0 (.xma) of the first 32 voices enabled, to test the decoder on a title's streams outside the title. | [S] crates\victory-hle\src\modules\audio.rs:680 | [X] safe | [X] default/unset |

## Group B [X]

| Switch | Default / off / on | Effect | Source | Risk | Current |
|---|---|---|---|---|---|
| VICTORY_ASK_EARLY | default 0 ms (off); set: milliseconds between ask rounds | Adds an asking pass between submission ask rounds; 0 ms is off. | [S] crates\victory-gpu\src\watch.rs:523 | [X] stability tradeoff | [X] default/unset |
| VICTORY_ASK_NORESET | off by default; 1 = on | Whether an asking walks the pages without the kernel's reset, and resets only the pages it found written after (VICTORY_ASK_NORESET=1; off by default). | [S] crates\victory-gpu\src\watch.rs:300 | [X] stability tradeoff | [X] default/unset |
| VICTORY_ASK_SPREAD | off by default; 1 = on | Whether a submission's askings are made on several threads at once (VICTORY_ASK_SPREAD=1; off by default): the same askings of the same ranges, all held by the asking thread meanwhile. | [S] crates\victory-gpu\src\watch.rs:329 | [X] stability tradeoff | [X] default/unset |
| VICTORY_BVH_BUILDER | off by default; 1 = on | frame and the next ([builder_rests]); it turned the builder off for the rest of the run at first. shortcut: and only with VICTORY_BVH_BUILDER=1, until a run has shown the whole builder and the host side of title memory by address (memory.rs) working on a card; nothing reads the structures before the programs that walk them translate. | [S] crates\victory-gpu\src\pipeline.rs:348 | [X] stability tradeoff | [X] launcher=1 |
| VICTORY_BVH_QUARANTINE | off by default; 1 = on | VICTORY_BVH_QUARANTINE=1: what the structure builder's stages store stays in the host's copies and is not copied back into title memory. | [S] crates\victory-gpu\src\pipeline.rs:322 | [X] stability tradeoff | [X] default/unset |
| VICTORY_BVH_SIZES_WAIT | off by default; 1 = on | Whether a submission that asks for the sizes of structures is waited for, and landed, before the title goes on (VICTORY_BVH_SIZES_WAIT=1; off). | [S] crates\victory-gpu\src\memory.rs:819 | [X] stability tradeoff | [X] default/unset |
| VICTORY_BVH_TRACE | off by default; 1 = on | VICTORY_BVH_TRACE=1: the sizes the builder is asked for (its program of one thread that stores a structure's compacted size) and when title memory has them, and the copies to a place of that size. | [S] crates\victory-gpu\src\memory.rs:1091 | [X] stability tradeoff | [X] default/unset |
| VICTORY_CARD_ALL | off by default; 1 = on | Whether every title buffer's copy has two sides, however small (VICTORY_CARD_ALL=1; off by default). | [S] crates\victory-gpu\src\shadow.rs:377 | [X] stability tradeoff | [X] default/unset |
| VICTORY_CARD_BUFFERS_MIN_KB | default: MiB floor applies; set: KiB floor; 64 = every title buffer | VICTORY_CARD_BUFFERS_MIN_KB (after fxceless c36971b2) says the least size in KiB, so that it can go under 1 MiB: 64 is every title buffer. | [S] crates\victory-gpu\src\shadow.rs:232 | [X] stability tradeoff | [X] default/unset |
| VICTORY_CARD_WINDOWS_MB | default 0 (none); set: MiB cap | The most bytes of windows outside buffers whose copies go to the card's memory (VICTORY_CARD_WINDOWS_MB; 0, the default, none). | [S] crates\victory-gpu\src\shadow.rs:459 | [X] stability tradeoff | [X] default/unset |
| VICTORY_COPY_ASK | off by default; 1 = on | VICTORY_COPY_ASK=1 asks first, as before. | [S] crates\victory-gpu\src\host.rs:8492 | [X] stability tradeoff | [X] default/unset |
| VICTORY_COPY_MODE | default 0 = guarded copies; 1 = plain; 2 = no copies | How copies run: 0 guarded (as always), 1 plain, 2 not at all. | [S] crates\victory-gpu\src\copystat.rs:181 | [X] stability tradeoff | [X] default/unset |
| VICTORY_COPY_OVER_TITLE | default 2 = zero unused title textures and upload used or staged ones; title/1 = reuse title memory; 0 = leave host-block bytes | Controls bytes under a first copy into a title texture: default zeros unused textures and uploads used or staged ones; title reuses title memory; 0 leaves host-block bytes. | [S] crates\victory-gpu\src\list.rs:1130 | [X] stability tradeoff | [X] default/unset |
| VICTORY_CUT_WRITES | off by default; 1 = on | The title wrote a value at the bottom of the pipe (not a timestamp, not a query result): listed (diagnostics), and with VICTORY_CUT_WRITES=1 the host list is cut right behind it, so that the value is stored when the card has run the list up to there, as on the console, and not when the whole list has run. | [S] crates\victory-gpu\src\list.rs:2224 | [X] stability tradeoff | [X] default/unset |
| VICTORY_D3D12_BACKGROUND | on by default (runtime background shader work left enabled); 0 = disable it | Leaves D3D12 runtime background shader processing on by default; 0 disables it through SetBackgroundProcessingMode. | [S] crates\victory-gpu\src\host.rs:1046 | [X] stability tradeoff | [X] default/unset |
| VICTORY_DSTORAGE_HALF | default off; on: 1 | Whether a queue submits itself once half of it is enqueued (VICTORY_DSTORAGE_HALF=1), as DirectStorage for the PC does and as ours did. | [S] crates\victory-hle\src\modules\dstorage.rs:1304 | [X] stability tradeoff | [X] default/unset |
| VICTORY_DSTORAGE_IO | default: title request; one/handles/overlapped/direct | How files are read (VICTORY_DSTORAGE_IO). | [S] crates\victory-hle\src\modules\dstorage.rs:300 | [X] stability tradeoff | [X] default/unset |
| VICTORY_DSTORAGE_RETRIES | default 12; set: retry count | A page the title has just made, or a view the host refuses for a moment (commit or address space short while a load maps many at once), can come right a little later: tried again before the request fails (VICTORY_DSTORAGE_RETRIES, default 12, about 1.5 s in all). | [S] crates\victory-hle\src\modules\dstorage.rs:1666 | [X] stability tradeoff | [X] default/unset |
| VICTORY_DSTORAGE_STAGING_MB | unset: title request; set: minimum MiB | VICTORY_DSTORAGE_STAGING_MB=&lt;n&gt;: at least that much (codec-d/cool_fox 641835a4, which makes it 256 MiB by default, so multi-MB RPF chunks do not starve the other cores); unset: what the title asks for. | [S] crates\victory-hle\src\modules\dstorage.rs:238 | [X] stability tradeoff | [X] default/unset |
| VICTORY_EFFICIENCY_MODE | off by default; 1 = on | VICTORY_EFFICIENCY_MODE=1 leaves the system its choice. | [S] crates\victory-hle\src\runtime.rs:251 | [X] stability tradeoff | [X] default/unset |
| VICTORY_FALLBACK_HEAPS | on by default; 0 = off | Whether a list always has a view heap and a sampler heap bound, ours of one slot for one the title did not set (, from codec-d/cool_fox 641835a4; off by default). | [S] crates\victory-gpu\src\host.rs:386 | [X] stability tradeoff | [X] default/unset |
| VICTORY_FAST_CORES | default 2; 0 = none; 1 = waited threads; 2 = shared workers; 3 = all helpers | VICTORY_FAST_CORES: 0: no thread asks; 1: the threads a frame waits for one by one; 2 (the default): the threads they share their work with too; 3: those that work beside the rest as well (lists translated, descriptors made): more threads by then than the fast cores run at a time, while the slow ones stood idle. | [S] crates\victory-gpu\src\cores.rs:225 | [X] stability tradeoff | [X] default/unset |
| VICTORY_FETCH_CHECK | off by default; 1 = on | Pieces of card copies that came down while a later flight was writing them (VICTORY_FETCH_CHECK, with VICTORY_RELAY_COPY). On the copy queue a fetch runs beside later submissions (relay_copy), so what comes down of a piece may be what it held in the middle of one: a counter cleared and not counted up again, a list half filled. | [S] crates\victory-gpu\src\host\torn.rs:35 | [X] stability tradeoff | [X] default/unset |
| VICTORY_GPU_LOAD_MS | default 0 (no fake load); set: milliseconds | What the title's GPU time is made to look like, in ticks (VICTORY_GPU_LOAD_MS; unset: as it is). | [S] crates\victory-gpu\src\queue.rs:874 | [X] stability tradeoff | [X] default/unset |
| VICTORY_GUARD_ASK | default off; on: 1 | VICTORY_GUARD_ASK=1 asks every time, as before. | [S] crates\victory-gpu\src\watch.rs:1830 | [X] stability tradeoff | [X] default/unset |
| VICTORY_GUARD_HOLES | on by default; 0 = off | VICTORY_GUARD_HOLES=0 looks at the first address only, as before. | [S] crates\victory-gpu\src\watch.rs:1946 | [X] stability tradeoff | [X] default/unset |
| VICTORY_GUARD_REST | default 3000 microseconds; set: &gt;1 microseconds | How long a block the title has just opened by a write is left open by those that take it (VICTORY_GUARD_REST=&lt;microseconds&gt;, 3,000 unless given; | [S] crates\victory-gpu\src\watch.rs:1536 | [X] stability tradeoff | [X] default/unset |
| VICTORY_HEAP_SYNC_ASIDE | on by default; 0 = off | Whether a submission's [sync_heaps] is done by a thread of its own beside the rest of the preparing (VICTORY_HEAP_SYNC_ASIDE=0: in front of it, as before). | [S] crates\victory-gpu\src\descriptor.rs:185 | [X] stability tradeoff | [X] default/unset |
| VICTORY_HEAP_SYNC_EARLY | default 4 ms; 0 = none | How long that thread waits for a submission before it makes a round of its own (VICTORY_HEAP_SYNC_EARLY=&lt;ms&gt;, 4 if not given; | [S] crates\victory-gpu\src\descriptor.rs:197 | [X] stability tradeoff | [X] default/unset |
| VICTORY_HEAP_TEXTURES | on by default; 0 = off (known missing index-picked textures); stable=0 | Runs the heap-texture upload pass for index-picked textures; 0 disables it and can leave such textures missing; stable uses 0. | [S] crates\victory-gpu\src\draw.rs:2258 | [X] stability tradeoff | [X] stable=0 |
| VICTORY_HELD_LEVELS | on by default; 0 = off | Whether a texture the title places in memory is read, kept and uploaded from the first level its views show on (VICTORY_HELD_LEVELS=0: whole, as before). | [S] crates\victory-gpu\src\resource.rs:1254 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INDIRECT_CARD_BUDGET | on by default; 0 = off | Whether a list's indirect-work budget lives in the card's own memory (VICTORY_INDIRECT_CARD_BUDGET=0 keeps it in memory the CPU maps, as before). | [S] crates\victory-gpu\src\host.rs:1888 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INDIRECT_REST | on by default; 0 = off | Whether a record that does not fit in what is left of its list's budget takes the rest, so that every record after it runs empty too (VICTORY_INDIRECT_REST=0: it takes nothing, and the next one that fits runs). | [S] crates\victory-gpu\src\indirect.rs:303 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INDIRECT_WIDE | on by default; 0 = off | The most groups in x that an indirect dispatch runs as the title asks: 65,535 is the most D3D12 names for a dispatch, 2^20 ([SOURCE]'s GROUPS) what is bounded here anyway (VICTORY_INDIRECT_WIDE=0: 65,535; a record that asks for more still runs 65,535). | [S] crates\victory-gpu\src\indirect.rs:280 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INPLACE | default 0; set overrides; 0 = none/off | VICTORY_INPLACE_PROBE: 0 (unset) nothing; 1 the probe on memory of its own at the first sweep, and the census 30 and 150 seconds later; 2 also opens one part of the title's own memory for a moment at the first census. | [S] crates\victory-gpu\src\inplace.rs:89 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INPLACE_MB | default 4096; set overrides; 0 = none/off | The most title memory in place at once, in bytes (VICTORY_INPLACE_MB, 4096): opening locks the pages into the PC's memory, also those the title never touched. | [S] crates\victory-gpu\src\inplace.rs:97 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INPLACE_PROBE | default 0; set overrides; 0 = none/off | This file holds the two openings Direct3D has, a probe that says what this PC's driver makes of them (VICTORY_INPLACE_PROBE), and a census of which title memory could be opened. What the Direct3D runtime and the kernel answer, measured on this PC with the software adapter (the rules are theirs, not the adapter's; what the card's driver adds is what the probe is for): - OpenExistingHeapFromAddress takes the base address of a whole | [S] crates\victory-gpu\src\inplace.rs:62 | [X] stability tradeoff | [X] default/unset |
| VICTORY_INPLACE_PROBE_MB | default 64 MiB; set: MiB, clamped to 1024 MiB | Called once a second by the thread that submits, before a submission (host::sweep): with [probe_level], the probe at the first call, the census (on a thread of its own: it asks Windows about every copy) 30 and 150 seconds later. | [S] crates\victory-gpu\src\inplace.rs:1280 | [X] stability tradeoff | [X] default/unset |
| VICTORY_KEEP_SNAPSHOTS | off by default; 1 = on | Whether a copy's snapshot is kept from one submission to the next and only the pieces that changed in between are taken again (VICTORY_KEEP_SNAPSHOTS=1; off by default). | [S] crates\victory-gpu\src\shadow.rs:2675 | [X] stability tradeoff | [X] default/unset |
| VICTORY_KEEP_SNAPSHOTS_MB | default 256; set overrides; 0 = none/off | VICTORY_KEEP_SNAPSHOTS_MB, 256 unless set (it was 768: run 80, with kept snapshots beside copies in the card's memory, ran the PC out of memory in 27 s; kept snapshots are the PC's memory, all of it resident). | [S] crates\victory-gpu\src\shadow.rs:2686 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LAND_ECHO | on by default; 0 = copy and send landing-only pages as before; -Safe sets 0 | Drops re-upload of pages changed only by a landing; 0 copies and sends them as before; -Safe sets 0. | [S] crates\victory-gpu\src\shadow.rs:2060 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LAND_SKIP | off by default; 1 = on | VICTORY_LAND_SKIP=1, off by default: counted either way). | [S] crates\victory-gpu\src\land.rs:69 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LAND_THREADS | default available_parallelism()/4 clamped 1..4; set clamped 1..16 | How many threads land, the relay's own counted (VICTORY_LAND_THREADS). | [S] crates\victory-gpu\src\land.rs:54 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LANE_CORE | off by default; 1 = on | Whether the submitting thread has a fast core to itself, as far as this process goes (VICTORY_LANE_CORE=1): nothing else of it runs on the core's two threads. | [S] crates\victory-gpu\src\cores.rs:173 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LATE_WAIT | default stage 3 when relay runs, else 0; 1/2/3 select stage explicitly | Whether a queue's submissions go to the card without a wait for each (VICTORY_LATE_WAIT=1; off by default, and off in the timing run, which waits for every list on its own). | [S] crates\victory-gpu\src\host.rs:2528 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LATE_WAIT_LISTS | default 256; set overrides; 0 = none/off | The most host lists in the air before the flights are settled (VICTORY_LATE_WAIT_LISTS, 256; | [S] crates\victory-gpu\src\host.rs:2754 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LATE_WAIT_WRITES | on by default; 0 = off | Whether a submission with bottom-of-pipe writes may fly (VICTORY_LATE_WAIT_WRITES=0: it is settled as soon as it is sent, so the title is told at once, as before; for telling a title that polls such a value from one that does not). | [S] crates\victory-gpu\src\host.rs:2764 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LATE_WAITS | off by default; 1 = on | VICTORY_LATE_WAITS=1 sleeps to the next tick, as before. | [S] crates\victory-gpu\src\frame.rs:178 | [X] stability tradeoff | [X] default/unset |
| VICTORY_LIBRARY_TRIM | on by default; 0 = off | VICTORY_LIBRARY_TRIM=0: the pages stay until Windows takes them. | [S] crates\victory-gpu\src\pipeline\library.rs:401 | [X] stability tradeoff | [X] default/unset |
| VICTORY_MAPPED_BY_PAGE | off by default; 1 = on | VICTORY_MAPPED_BY_VIEWS=0: the host is asked, as before. | [S] crates\victory-gpu\src\texture.rs:1799 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PAGE_WRITES | default/guards = bit 1 only; 0 = none; 1 = bits 1+2; slots = bit 2; all = bits 1+2+4 | Decides how writes outside guards are handled: bit 1 opens guarded blocks, bit 2 makes placed textures due, bit 4 covers plain reads. | [S] crates\victory-gpu\src\watch.rs:2300 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PICKED_WRITES | default 0 (off); 1/2 select staged handling of picked-view writes | Buffers shaders write through views they pick from the heap by an index they compute (VICTORY_PICKED_WRITES; off by default, [stage]). Which views a draw or dispatch writes through is known from its tables and root parameters, and their ranges are declared: what is written there comes back to title memory (Shadow::gpu_writes). | [S] crates\victory-gpu\src\picked.rs:60 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PIPELINE_BOOK | off by default; 1 = on | Every pipeline the title has ever created, kept on disk (VICTORY_PIPELINE_BOOK=1), and their host pipelines made ahead of a run (victory warm), so that the driver's own cache on disk has them before a draw asks for one. The title creates 84,000 pipelines while it loads and draws with some 2,000 of them; which ones is known from earlier runs (library), and those are made during loading. | [S] crates\victory-gpu\src\pipeline\known.rs:45 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PIPELINE_LOWEST | on by default; 0 = off | Below the title's own threads (loading, recording), and the streaming one, which is below normal itself (VICTORY_PIPELINE_LOWEST=0: level with it, as before). | [S] crates\victory-gpu\src\pipeline\make.rs:433 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PIPELINE_SLOW | unset: off/default; set: value applies | VICTORY_PIPELINE_SLOW=0: in the order the title creates them, as before. | [S] crates\victory-gpu\src\pipeline\make.rs:286 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PIPELINE_WAIT_MS | default 500 ms; set: milliseconds | Waiting allowed per title frame, over all threads. | [S] crates\victory-gpu\src\pipeline\make.rs:128 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PIPELINE_WORKERS | default two thirds of logical processors clamped 2..16; set clamped 1..64 | How many workers make pipelines: asked (VICTORY_PIPELINE_WORKERS, 1 to 64), else two thirds of the logical processors, 2 to 16. | [S] crates\victory-gpu\src\pipeline\make.rs:418 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PLACED_FILLER | off by default; 1 = on | VICTORY_PLACED_FILLER=1: kept in the key, as before. | [S] crates\victory-gpu\src\resource.rs:3156 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PLACED_READERS | on by default; 0 = count readers ahead of an in-place copy as before | Whether a step of runs reads on the CPU what one of their copies at its place, ahead of it, waits for its readers ([Waits::ForReaders]) with. (A reader ahead of the copy wants what was there before it, and the steps are done in this order: VICTORY_PLACED_READERS=0 counts those as well, as before.) | [S] crates\victory-gpu\src\host\place.rs:119 | [X] stability tradeoff | [X] default/unset |
| VICTORY_POOL_SMALL | off by default; any nonzero/set value = on | Whether textures of 64 KiB and less are placed at multiples of 4 KiB in their block, where the host allows it (VICTORY_POOL_SMALL=1; otherwise at multiples of 64 KiB, as every other texture). | [S] crates\victory-gpu\src\pool.rs:498 | [X] stability tradeoff | [X] default/unset |
| VICTORY_POP_ALL | off by default; 1 = on | width * height 8-bit RGBA (or BGRA) pixels made small. | [S] crates\victory-gpu\src\popwatch.rs:314 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PORT_CONSTANTS | off by default; 1 = on | Enables renderer port 1, placing title buffers and windows inside the title 32-bit graphics memory; only 1 turns it on. | [S] crates\victory-gpu\src\port.rs:78 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PORT_CONSTANTS_ORDER | on by default; 0 = clamp indirect arguments in batches/windows as before | Whether indirect arguments in in-place title memory are clamped one at a time, right before the execution that reads them (VICTORY_PORT_CONSTANTS_ORDER, on by default; | [S] crates\victory-gpu\src\port.rs:94 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PORT_DESCRIPTORS_CHECK | default 16 pages; 0 = none | Pages the fallback looks at a frame (VICTORY_PORT_DESCRIPTORS_CHECK=&lt;pages&gt;, 16 if not given; 0: none). | [S] crates\victory-gpu\src\port_descriptors.rs:238 | [X] stability tradeoff | [X] default/unset |
| VICTORY_PORT_DESCRIPTORS_EVERY | default 8 frames; set overrides | Frames between askings of the write watch for the fallback (VICTORY_PORT_DESCRIPTORS_EVERY=&lt;frames&gt;, 8 if not given). | [S] crates\victory-gpu\src\port_descriptors.rs:231 | [X] stability tradeoff | [X] default/unset |
| VICTORY_REFRESH_AHEAD | on by default; 0 = off | Whether the copies that a submission's shaders write are brought up to date together, on several threads, ahead of its steps (VICTORY_REFRESH_AHEAD=0: each before the step that gives it to them). 580 copies a frame, one after the other on the submitting thread, 3.4 to 6.5 ms (session play-1125-0203). | [S] crates\victory-gpu\src\host.rs:7901 | [X] stability tradeoff | [X] default/unset |
| VICTORY_REFRESH_CHECK | off by default; 1 = on | [Shadow::update] of [from, to) (inside the buffer) where no shader writes. (A range whose blocks rest after a write has no guard now.) Diagnostic (VICTORY_REFRESH_CHECK=1; off by default): after a refresh of [from, to) that trusted the write watch or the guards, the first 256 bytes of every 64 KiB block of it are read from title memory and compared with the copy. | [S] crates\victory-gpu\src\shadow.rs:4067 | [X] stability tradeoff | [X] default/unset |
| VICTORY_ROOT_UAV_MB | default unlimited; set: MiB cap for root UAV view, refresh and copy back | must be dropped. shortcut: a root view has no size: the view, the refresh and the copy back cover all that is left of the title's buffer (VICTORY_ROOT_UAV_MB sets a limit for all three). | [S] crates\victory-gpu\src\draw.rs:1833 | [X] stability tradeoff | [X] default/unset |
| VICTORY_ROOT_VIEW_MB | default unlimited; set: MiB cap for root buffer view, refresh and copy back | VICTORY_ROOT_VIEW_MB sets a limit again.) | [S] crates\victory-gpu\src\draw.rs:822 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SCREEN_WAIT_MS | default 10000 ms; set: milliseconds | As [wait_budget], for passes over the screen (VICTORY_SCREEN_WAIT_MS, 10 s; 0: like the others). | [S] crates\victory-gpu\src\pipeline\make.rs:142 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SEND_BAR | off by default; 1 = on | Whether the memory lies in the card's memory, written by the CPU through the bus (VICTORY_SEND_BAR=1): the copies on the card's drawing queue, which nothing overlaps, then cross no bus. | [S] crates\victory-gpu\src\host\send.rs:141 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SEND_CHANGED | off by default in test; set nonzero = exact changed-bytes landing assertions | Test-only exact-changed-bytes assertion mode for landing writes; set nonzero enables. | [S] crates\victory-gpu\src\host.rs:10532 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SEND_OWN | on by default; 0 = off | What goes up to copies in the card's memory goes up as it was when its submission was prepared (VICTORY_SEND_OWN, on by default; | [S] crates\victory-gpu\src\host\send.rs:27 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SHADER_FRESH | off by default; 1 = on | VICTORY_SHADER_FRESH=1 does the same in a run; | [S] crates\victory-gpu\src\shader_cache.rs:57 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SHADER_KEY | default content-derived key; source = translator-source key | VICTORY_SHADER_KEY=source keys by the translator's source as before (a separate set for each build). The entry is our own encoding of [HostShader]: a field added to it must be added to encode and decode too, and [FORMAT] bumped. | [S] crates\victory-gpu\src\shader_cache.rs:50 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SHADER_LOOP_LIMIT | default translator constant; diagnostics builds accept an integer &gt;=1 | With the diagnostics feature, VICTORY_SHADER_LOOP_LIMIT (decimal or 0x hex, at least 1) sets it instead. | [S] crates\victory-shader\src\emit\mod.rs:145 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SHADER_OPT | default 63 (all but the last pass); 0 = none; number = pass bitmask | VICTORY_SHADER_OPT: - unset: every pass but the last one below (63). - 0: none (the module as the lowering made it). - a number (decimal or 0x hex): those passes; 1 dead code, 2 constants and identities, 4 one instruction for one value, 8 what a branch taken says about its condition, 16 one read for one place within a block, 32 a first-lane read of two host waves without the round that asks which half has a lane (where every lane has one). | [S] crates\victory-shader\src\emit\mod.rs:223 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SKIP_PIPELINES | unset: none; set: comma-separated pipeline hashes to skip | Shader hashes as printed in the pipeline diagnostics. | [S] crates\victory-gpu\src\pipeline.rs:513 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SLOT_CHECK | off by default; any nonzero/set value = on | - At a device loss ([at_loss]): who owns the faulting address and who owned it, newest first, and every slot of the view heap whose descriptor reaches it. - VICTORY_SLOT_CHECK=1: a thread walks the view heap and says which slots name memory that is gone, while nothing is lost yet ([check]). The book is kept with device-removed data on (VICTORY_D3D12_DRED) or the check; | [S] crates\victory-gpu\src\book.rs:86 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SNAPSHOT_POOL | default 1024 buffers; set: count | How many snapshot buffers are kept (VICTORY_SNAPSHOT_POOL; | [S] crates\victory-gpu\src\shadow.rs:1296 | [X] stability tradeoff | [X] default/unset |
| VICTORY_STACKS | unset: off; set: stack-sampling schedule | Where every thread is: VICTORY_STACKS=&lt;seconds&gt;[,&lt;seconds&gt;...] prints each thread's unwound stack as module+rva that many seconds after [dump_stacks_on_schedule], to find what a title waits on. | [S] crates\victory-loader\src\stacks.rs:27 | [X] stability tradeoff | [X] default/unset |
| VICTORY_STALE_TEXTURES | default start rule; 0 = never; overlap = older rule | VICTORY_STALE_TEXTURES=0: never, as before; | [S] crates\victory-gpu\src\descriptor\host.rs:879 | [X] stability tradeoff | [X] default/unset |
| VICTORY_STRICT_JOINS | off by default; any nonzero/set value = on | unmarked, a value without a DXIL form coming into it became zero without a word (the looked-up tint of the material resolve programs, whose size computation had no value, was zero in every lane that way). shortcut: only with VICTORY_STRICT_JOINS set (the offline pack listing sets it to count them): 40 programs that translate today stop by name with it (vehicle paint pixel shaders at "the first half of an interpolation", foliage mesh shaders); until those are lowered they keep drawing with that zero. | [S] crates\victory-shader\src\emit\lower.rs:13212 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SUBMIT_DEPTH | default 64; set clamped to at least 1 | How many submissions may be in the line when a submit call returns (VICTORY_SUBMIT_DEPTH; 64: about two frames of the title's). | [S] crates\victory-gpu\src\queue\behind.rs:620 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SUBMIT_FRAMES | default 1; 0 = both current and previous | How many presents may be in the line when a present call returns (VICTORY_SUBMIT_FRAMES; 1: the frame before is sent, this one may not be; | [S] crates\victory-gpu\src\queue\behind.rs:627 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SWEEP | on by default; 0 = off | VICTORY_SWEEP=0 keeps everything, as before. | [S] crates\victory-gpu\src\host.rs:543 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SWEEP_PER_HEAP | off by default; 1 = on | Whether the heap buffer pass runs once a frame for each view heap a list binds, not once for all of them, and a list holds each heap's table of strides by its own key (VICTORY_SWEEP_PER_HEAP=1, from codec-d/cool_fox c64fc9b4; off by default). | [S] crates\victory-gpu\src\draw.rs:609 | [X] stability tradeoff | [X] default/unset |
| VICTORY_SYNC_FINE | off by default; any nonzero/set value = on | Pages and records [sync_heaps] gives a thread at a time (VICTORY_SYNC_FINE=1: [SYNC_PAGES_FINE] and [SYNC_AT_A_TIME_FINE]; otherwise [SYNC_PAGES] and [SYNC_AT_A_TIME], as before). | [S] crates\victory-gpu\src\descriptor.rs:615 | [X] stability tradeoff | [X] default/unset |
| VICTORY_TABLED_TEXTURES | default 0 (table-read textures leave index queue); 1 = keep them queued | VICTORY_TABLED_TEXTURES=1 keeps them in it as before. | [S] crates\victory-gpu\src\descriptor\host.rs:965 | [X] stability tradeoff | [X] default/unset |
| VICTORY_TEXTURE_CATCHUP | on by default; 0 = off | VICTORY_TEXTURE_CATCHUP=0 keeps the plain budget. | [S] crates\victory-gpu\src\draw.rs:2378 | [X] stability tradeoff | [X] default/unset |
| VICTORY_TEXTURE_COPY | off by default; 1 = on | Whether a texture all of whose memory is mapped is read through the kernel's copy instead of in place (VICTORY_TEXTURE_COPY=1; off by default). | [S] crates\victory-gpu\src\texture.rs:455 | [X] stability tradeoff | [X] default/unset |
| VICTORY_TEXTURE_GUARD | on by default; 0 = off | VICTORY_TEXTURE_GUARD=0 hashes at every check, as before. | [S] crates\victory-gpu\src\texture.rs:1280 | [X] stability tradeoff | [X] default/unset |
| VICTORY_TEXTURE_LOOK_MS | unset: no floor; set: milliseconds &gt;0 | The longest wait, in milliseconds, between two looks at a texture slot whose memory is not there yet (VICTORY_TEXTURE_LOOK_MS; unset: about four seconds counted in passes, as before). | [S] crates\victory-gpu\src\draw.rs:4661 | [X] stability tradeoff | [X] default/unset |
| VICTORY_UNDER_THREADS | default 6 clamped 1..16; set: count | [Pool::each] on threads kept for the title's bytes under flights' writes (VICTORY_UNDER_THREADS, 6 with this one). | [S] crates\victory-gpu\src\land.rs:336 | [X] stability tradeoff | [X] default/unset |
| VICTORY_UNDER_WORDS | on by default; 0 = off | Whether the title's bytes that go in under flights' writes (Shadow::merge_under_writes) go in by whole words (VICTORY_UNDER_WORDS=0: by the bytes that changed, as before). | [S] crates\victory-gpu\src\host\send.rs:60 | [X] stability tradeoff | [X] default/unset |
| VICTORY_UNWATCHED_FRAMES | default 1; set overrides; 0 = none/off | The pass costs some 30 ms a frame this way. | [S] crates\victory-gpu\src\draw.rs:974 | [X] stability tradeoff | [X] default/unset |
| VICTORY_UP_QUEUE | off by default; 1 = on | What changed on the CPU's side of copies in the card's memory goes up on a copy queue of its own (VICTORY_UP_QUEUE=1; off by default; | [S] crates\victory-gpu\src\host\upq.rs:41 | [X] stability tradeoff | [X] default/unset |
| VICTORY_UPCOPY_CHECK | off by default; 1 = on | Diagnostics (VICTORY_UPCOPY_CHECK=1; off by default): whether what goes up to a copy in the card's memory is older than what the card holds. What every send up rests on: outside ranges shaders may be writing, and but for what the title wrote since, a copy's CPU side holds what its card side holds. | [S] crates\victory-gpu\src\host\upcheck.rs:33 | [X] stability tradeoff | [X] default/unset |
| VICTORY_VIEW_COPY | on by default (make descriptor views in copies); 0 = make in place | VICTORY_VIEW_COPY=0: made in place, as before. | [S] crates\victory-gpu\src\descriptor\host.rs:3484 | [X] stability tradeoff | [X] default/unset |
| VICTORY_VIEW_LIMIT | unset: no host view-heap cap; set: null-slot cap for translation | VICTORY_VIEW_LIMIT=&lt;null slot&gt;: translate as on a host whose view heap is capped | [S] apps\victory\src\main.rs:221 | [X] stability tradeoff | [X] default/unset |
| VICTORY_VIEW_THREADS | default 6 with records else 4; set clamped 1..16 | Calls f with every number below count, on this thread and on threads kept for making descriptors (VICTORY_VIEW_THREADS, 4 with this one, 6 for records; 1: on this one alone). | [S] crates\victory-gpu\src\land.rs:351 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WAIT_ASK | off by default; 1 = on | VICTORY_WAIT_ASK=1 asks first, as before. | [S] crates\victory-gpu\src\list.rs:2021 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WALLS_TRACE | off by default; 1 = on | The walls trace (VICTORY_WALLS_TRACE=1 or 2; off by default): log lines that say what the title's CPU was given while it decided whether the camera is in a room. | [S] crates\victory-gpu\src\host.rs:4022 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WARP | off by default; 1 = on | The preferred hardware adapter, or WARP with warp (or VICTORY_WARP=1). | [S] crates\victory-shader\src\emit\host.rs:173 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WIDE_MERGE | off by default; 1 = on | Whether what shaders wrote to copies in the card's memory is merged into title memory on several threads (VICTORY_WIDE_MERGE=1; off by default). | [S] crates\victory-gpu\src\host.rs:2313 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WIDE_REFRESH | default on with at least 4 logical CPUs; 0 = off; 1 = forced on | Refreshes host copies on several threads; default on with at least 4 logical CPUs, 0 off, 1 forced on. | [S] crates\victory-gpu\src\host.rs:7829 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WIDE_SPIN | default 0 (no spin); set: microseconds | Waits awake until there says so, VICTORY_WIDE_SPIN microseconds at most (0, the default: not at all): asleep, a thread is woken in 50 us and more, 95 times a frame. | [S] crates\victory-gpu\src\shadow.rs:1486 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WINDOW_BUDGET_MB | unset or 0: no cap; positive: MiB cap for loose window copies in Watch/High RAM | Caps loose title-window copies in MiB in the Watch and High RAM bands; unset or 0 keeps the current sweep. | [S] crates\victory-gpu\src\shadow.rs:2946 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WINDOW_KB | default 4 MiB; set: power of two from 64 KiB to 4 MiB | The grid the windows of asks with a length are cut on, in bytes: 4 MiB unless VICTORY_WINDOW_KB names a smaller power of two (64 at least). | [S] crates\victory-gpu\src\shadow.rs:5334 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WINDOW_MAX | unset: no cap; set: WIDTHxHEIGHT cap; 0/invalid ignored | VICTORY_WINDOW_MAX=WIDTHxHEIGHT applies a smaller limit without changing the title's render targets. | [S] crates\victory-hle\src\modules\lifecycle.rs:182 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WINDOW_TAILS | off by default; 1 = on | window is the cell's tail from the ask's step on ([TAIL_STEP]); an ask lower in the cell later makes a longer tail, which every ask from then on takes, and the shorter one goes when nothing holds it any more. shortcut: off unless VICTORY_WINDOW_TAILS=1. | [S] crates\victory-gpu\src\shadow.rs:5373 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WINDOWS_BAR_MB | default 0; set overrides; 0 = none/off | The most bytes of windows outside buffers that lie in the card's memory and are filled by the CPU through the bus (VICTORY_WINDOWS_BAR_MB; 0, the default, none): one buffer (D3D12_HEAP_TYPE_GPU_UPLOAD), no CPU's side, no copy to send and no list of changes, unlike [window_card_most]. | [S] crates\victory-gpu\src\shadow.rs:497 | [X] stability tradeoff | [X] default/unset |
| VICTORY_WINDOWS_OWN | off by default; 1 = on | Whether windows outside buffers have two sides too, so that submissions in the air read the bytes they were prepared with (VICTORY_WINDOWS_OWN=1; off by default: it takes the windows' bytes again, 3.3 GB in capture replay2, and what changes in them under submissions in the air is what the title's CPU writes, which it does not while they read it). | [S] crates\victory-gpu\src\shadow.rs:535 | [X] stability tradeoff | [X] default/unset |
| VICTORY_XMA_REFILL | off by default; 1 = on | Fills every enabled context's output as far as it has room. (codec-d/cool_fox fabb872a, VICTORY_XMA_REFILL=1.) A skipped frame or an input boundary can advance the decoder without producing samples: only whole blocks are published, but for the padded tail at the end, and at most 8 empty steps are taken so a broken looping voice holds neither its lock nor other voices. | [S] crates\victory-hle\src\modules\audio.rs:570 | [X] stability tradeoff | [X] default/unset |

## Group C [X]

| Switch | Default / off / on | Effect | Source | Risk | Current |
|---|---|---|---|---|---|
| VICTORY_ASYNC_SUBMIT | off by default; 1 = on | Whether submissions are prepared by a thread of ours (VICTORY_ASYNC_SUBMIT=1; needs flights with the present sent ahead, as the relay has them, and lists cut at their waits). | [S] crates\victory-gpu\src\queue\behind.rs:654 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_CARD_ROOM_FOR_TARGETS_MB | default 3072 MiB; set value capped at 8192 MiB; 0 = none (&lt;3072 forbidden) | The bytes of the card's memory the texture queue leaves free for render targets and other host copies the host itself writes that are not made yet: VICTORY_CARD_ROOM_FOR_TARGETS_MB (3,072; 0: none, as before) less what such copies hold now. | [S] crates\victory-gpu\src\resource.rs:1840 | [X] forbidden by our invariants | [X] stable=3072 MiB |
| VICTORY_EARLY_ALL | off by default; 1 = on | VICTORY_EARLY_ALL=1: every title pipeline is started at creation, requested before or not, so that the driver's own cache holds it for later runs. | [S] crates\victory-gpu\src\pipeline\library.rs:813 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_FILL_TITLE | default 0; 1/2 select the stage | Whether a small fill of upload memory, or copy of a title buffer, goes on without waiting for flights when the title itself wrote the memory since they were given it (VICTORY_FILL_TITLE=1), or only for the second reason below (=2); off by default. | [S] crates\victory-gpu\src\host.rs:2962 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_JOIN_BARRIERS | off by default; 1 = on | A host list's D3D12 list, with barrier calls joined (VICTORY_JOIN_BARRIERS=1; off by default; | [S] crates\victory-gpu\src\host\rec.rs:28 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_KEEP_FREED | on by default; 0 = off | VICTORY_KEEP_FREED=0: it is given back as before). | [S] crates\victory-gpu\src\host.rs:391 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_LIBRARY_LOCK | off by default; 1 = on | With VICTORY_LIBRARY_LOCK=1: held by every library call, as before. | [S] crates\victory-gpu\src\pipeline\library.rs:458 | [X] forbidden by our invariants | [X] stable=1 |
| VICTORY_PORT_DESCRIPTORS | off by default; 1 = on | Renderer port #2: the title's writes of descriptor records into its shader-visible heap say which slots they wrote, and the per-frame look at every changed heap page goes (VICTORY_PORT_DESCRIPTORS=1, off by default; read in [on]). What the title does (game_scarlett_master.exe; | [S] crates\victory-gpu\src\port_descriptors.rs:44 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_PROFILE | unset: default host preset, no stack profile; set default/low-vram or from,to,ms,file | Selects the host preset (default or low-vram) and, with a from,to,ms,file value, starts stack profiling; unset leaves the default preset and no profiler. | [S] apps\victory\src\profile.rs:54; crates\victory-loader\src\profile.rs:64 | [X] forbidden by our invariants | [X] stable=low-vram |
| VICTORY_TEXTURE_AWAY_MS | default 3000 ms; 0 = immediate nulling (known black-texture risk) | Only when it is still away AWAY_MS after it was first found away (VICTORY_TEXTURE_AWAY_MS; 0: at once, as before). | [S] crates\victory-gpu\src\descriptor\host.rs:2284 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_TEXTURE_STAGE_MB | unset: VRAM-derived (96 in low-vram preset); set: MiB; 64 rejected | VICTORY_TEXTURE_STAGE_MB sets it: a backlog of tens of thousands of textures (a scene's first minutes) then drains in fewer frames. | [S] crates\victory-gpu\src\draw.rs:2266 | [X] forbidden by our invariants | [X] stable=96 MiB |
| VICTORY_TEXTURE_STORE | unset: off; set: host texture-store folder (not a RAM fix) | Since the start: entries found at startup, textures kept, keys asked, found, blobs read from the folder, bytes written. | [S] crates\victory-gpu\src\texstore.rs:92 | [X] forbidden by our invariants | [X] default/unset |
| VICTORY_WAVE_WIDE | off by default; 1 = on | Off unless asked for (VICTORY_WAVE_WIDE=1), for a console wave run as two host waves: this form puts group barriers inside branches and loops, and runs 121-124 lost the card in a submission of two programs that had just moved to it (ptfx_CS_lightAtlas_Sprite and _Trail). | [S] crates\victory-shader\src\emit\mod.rs:545 | [X] forbidden by our invariants | [X] default/unset |

## Group D [X]

| Switch | Default / off / on | Effect | Source | Risk | Current |
|---|---|---|---|---|---|
| VICTORY_BAKE_TEXTURES_MS | default 1500 ms before a decoration bake; 0 = no special wait | Milliseconds allowed before a decoration bake to upload index-picked textures; 0 disables the special wait. | [S] crates\victory-gpu\src\draw.rs:182 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_CS | default: built-in CARD_COMPARE source; set: shader source file | VICTORY_BENCH_CS=&lt;file&gt; times another source of the shader. | [S] crates\victory-gpu\src\indirect.rs:974 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_FILE | unset: none; set: unbuffered benchmark output file | VICTORY_BENCH_FILE is a big file to read past the system's cache). | [S] crates\victory-gpu\src\texture.rs:2234 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_HOLES | on by default; 0 = off | VICTORY_BENCH_HOLES=0: views without holes. | [S] crates\victory-gpu\src\host.rs:10841 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_N | default 3; set overrides; 0 = none/off | VICTORY_BENCH_N runs of each, 3). | [S] crates\victory-gpu\src\indirect.rs:1776 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_S | default 5 seconds; set: seconds per measurement way | Whether the card can read a texture's descriptor half written (ignored: a measurement of the card, VICTORY_BENCH_S seconds a way, 5). | [S] crates\victory-gpu\src\indirect.rs:1199 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_THREADS | default 4; set overrides; 0 = none/off | Blocks; microseconds making a block, the longest; waiting, the longest. | [S] crates\victory-gpu\src\indirect.rs:1910 | [X] unknown | [X] default/unset |
| VICTORY_BENCH_WARP | off by default; any nonzero/set value = on | A buffer view of 4 KiB in a buffer of 1 MiB whose every dword says where it lies: zeros past the view, or the bytes there (whatever the card has in that place). | [S] crates\victory-gpu\src\indirect.rs:1026 | [X] unknown | [X] default/unset |
| VICTORY_BLOCK_WAY | default 3; set overrides; 0 = none/off | Threads (VICTORY_BENCH_THREADS, 4) make blocks of 64 MiB, a texture in each and its view, and copies the view into a slot; long dispatches that read all the slots are always on the card. | [S] crates\victory-gpu\src\indirect.rs:1773 | [X] unknown | [X] default/unset |
| VICTORY_CARD_BUFFERS_MB | default 512/2048/up to 8192 MiB by VRAM budget; set: MiB upper cap | Upper MiB cap for title-buffer copies placed in card-local memory; default scales with VRAM. | [S] crates\victory-gpu\src\shadow.rs:225 | [X] unknown | [X] default/unset |
| VICTORY_CARD_BUFFERS_MIN_MB | default 16/4/1 MiB by VRAM budget; set: MiB minimum | Minimum MiB size of a title-buffer copy before it is placed in card-local memory; default scales with VRAM. | [S] crates\victory-gpu\src\shadow.rs:224 | [X] unknown | [X] default/unset |
| VICTORY_COPY_BESIDE | off by default; 1 = route title memcpy/memmove/memset through guarded copies | Routes title memcpy, memmove and memset through guarded copies so written bytes are known; 1 enables. | [S] crates\victory-gpu\src\titlewrite.rs:70 | [X] unknown | [X] default/unset |
| VICTORY_D3D12_GBV | off by default; 1 = GPU-based validation in diagnostics builds | Enables D3D12 GPU-based validation in diagnostics builds; 1 enables. | [S] crates\victory-gpu\src\host.rs:987 | [X] unknown | [X] default/unset |
| VICTORY_D3D12_WARP | off by default; set nonzero = software adapter in diagnostics builds | Selects the D3D12 software adapter in diagnostics builds; set nonzero enables. | [S] crates\victory-gpu\src\host.rs:1025 | [X] unknown | [X] default/unset |
| VICTORY_DUMP_TARGETS | off by default; set nonzero with capture folder = save render-target textures | Saves render-target textures for frames in VICTORY_CAPTURE_FRAMES; set nonzero and a capture folder enables. | [S] crates\victory-gpu\src\capture.rs:361 | [X] unknown | [X] default/unset |
| VICTORY_EARLY_TEXTURES_MS | default 12 ms per frame for index-picked texture uploads; 0 = never | Milliseconds per frame spent uploading index-picked textures before draws ask for them; 0 disables. | [S] crates\victory-gpu\src\draw.rs:182 | [X] unknown | [X] default/unset |
| VICTORY_HOST_LOCK_CHILD | unset in parent test process; 1 = child process marker for the loader-lock regression test | Test-only marker: the parent spawns a child process that holds the loader lock while loading a host DLL. | [S] crates\victory-hle\src\host.rs:174 | [X] unknown | [X] default/unset |
| VICTORY_PROBE | unset: inert; set: ignored probe-test folder | Ignored probe test translates each .dxil file in the folder; unset does nothing. | [S] crates\victory-shader\src\emit\probe_tests.rs:15 | [X] unknown | [X] default/unset |
| VICTORY_READ_WATCH | no runtime read in this tree; docs cite 1 as the shader-written texture read-back diagnostic | Documented shader-written texture read-back diagnostic for title CPU reads; 1 is cited in texback.rs but no runtime env read exists. | [S] crates\victory-gpu\src\texback.rs:7 | [X] unknown | [X] default/unset |
| VICTORY_SAVE_CHILD | unset: test off; set: save root used with VICTORY_SAVE_OP | Run by the crash test in a child process; does nothing otherwise. | [S] crates\victory-hle\src\modules\xgamesave.rs:1050 | [X] unknown | [X] default/unset |
| VICTORY_SAVE_OP | unset: test off; set: operation such as update | Run by the crash test in a child process; does nothing otherwise. | [S] crates\victory-hle\src\modules\xgamesave.rs:1050 | [X] unknown | [X] default/unset |
| VICTORY_SAVE_STOP | unset: test off; set: step number at which to stop | In a child process of the crash test, stops for good at the step VICTORY_SAVE_STOP names and says so. | [S] crates\victory-hle\src\modules\xgamesave.rs:998 | [X] unknown | [X] default/unset |
| VICTORY_SHADER_SOURCE_HASH | build.rs generated, not a runtime knob | FNV-1a, 64 bits, two lanes with different offsets: a mismatch only costs a cache miss, so this need not be cryptographic. | [S] crates\victory-shader\build.rs:62 | [X] unknown | [X] default/unset |
| VICTORY_SHADER_SWITCHES | build.rs generated, not a runtime knob | FNV-1a, 64 bits, two lanes with different offsets: a mismatch only costs a cache miss, so this need not be cryptographic. | [S] crates\victory-shader\build.rs:64 | [X] unknown | [X] default/unset |
| VICTORY_SKIP_CPU_CHECK | off by default; 1 = bypass the AVX2 pre-flight check | Bypasses the AVX2 pre-flight requirement when set to 1, for CPU emulation or diagnostics. | [S] apps\victory\src\run.rs:8 | [X] unknown | [X] default/unset |
| VICTORY_STORE_BESIDE | off by default; 1 = handle faulting title stores beside guards | Handles faulting title stores beside the write guards; 1 enables. | [S] crates\victory-gpu\src\titlewrite.rs:78 | [X] unknown | [X] default/unset |
| VICTORY_TEST_D3D_DEBUG | unset: off; set: replay test under D3D12 debug layer | Replay test runs under the D3D12 debug layer when set; default off. | [S] crates\victory-gpu\tests\replay.rs:1609 | [X] unknown | [X] default/unset |
| VICTORY_TEST_ROUNDS | default 120; set overrides; 0 = none/off | (It fails in the first rounds if landed_beside notes nothing, or only takes the block out of the guards' clean ones and leaves its bit, or if a fault leaves the bit; in some thousand rounds, VICTORY_TEST_ROUNDS, if what is landed is noted before it is in.) | [S] crates\victory-gpu\src\host.rs:10521 | [X] unknown | [X] default/unset |
| VICTORY_TILES_TEST_CARD | off by default; 1 = on | Run by name, alone, no game needed: cargo test -p victory-gpu --release -- --ignored levels_on_demand --nocapture It runs on the SOFTWARE adapter unless VICTORY_TILES_TEST_CARD=1: on that adapter nothing reaches the card or its driver, so nothing it does can reset the driver or touch the screen. | [S] crates\victory-gpu\src\tiles.rs:800 | [X] unknown | [X] default/unset |
| VICTORY_XMA_REFERENCE | unset: test off; set: reference audio directory | Decodes a stream's packets and compares with a reference decode of the same file (16-bit PCM): VICTORY_XMA_REFERENCE=&lt;dir&gt; holding mono.xmadata/mono.ref and stereo.xmadata/stereo.ref (made outside the repository). | [S] crates\victory-formats\src\xma.rs:1788 | [X] unknown | [X] default/unset |
| VICTORY_XMA_STREAMS | unset: test off; set: saved XMA input directory | Walks and decodes saved input buffers (VICTORY_XMA_STREAMS=&lt;dir&gt; of *.xma files with their *.ctx context words, made outside the repository): the frames walked from the first packet must be the frames the packet headers count, and every frame must decode. | [S] crates\victory-formats\src\xma.rs:1743 | [X] unknown | [X] default/unset |

## Group E - doc-only names absent from this tree [X]

| Switch | Default / off / on | Effect | Source | Risk | Current |
|---|---|---|---|---|---|
| VICTORY_PORT_GUARD | none in this tree | Public fork shared write-guard lock; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\avatar-VIctory-7900XTX\README.md:80 | [X] unknown | [X] absent |
| VICTORY_PORT_COPIES | none in this tree | Public fork port optimization; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\handoff-report.md:178 | [X] unknown | [X] absent |
| VICTORY_PORT_CONSTANTS_ORDER_ALONE | none in this tree | Public fork refinement of in-place indirect argument ordering; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\handoff-report.md:177 | [X] unknown | [X] absent |
| VICTORY_PORT_JOURNAL | none in this tree | Public fork descriptor journal split; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\avatar-VIctory-7900XTX\README.md:81 | [X] unknown | [X] absent |
| VICTORY_WARM_BAD | none in this tree | Public fork workaround for an RX 9070 XT compiler crash; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\handoff-report.md:169 | [X] unknown | [X] absent |
| VICTORY_QUEUE2_LANDING_MB | none in this tree | Proposed second-queue landing budget; no definition found locally. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\streaming-plan-20261126.md:57 | [X] unknown | [X] absent |
| VICTORY_PORT_RT | none in this tree | Public fork ray-tracing port work; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\report-reconstructed-draft-20261126-1456.md:287 | [X] unknown | [X] absent |
| VICTORY_COMPILER_GUARD | none in this tree | Public fork workaround for an RX 9070 XT compiler crash; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\handoff-report.md:169 | [X] unknown | [X] absent |
| VICTORY_BVH_FAULTS_ALL | none in this tree | Public fork fault-page bound for BVH work; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\avatar-VIctory-7900XTX\docs\fork-ray-tracing.md:100 | [X] unknown | [X] absent |
| VICTORY_AMBIENT_RT | none in this tree | Public fork ray-traced ambient parameter; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\avatar-VIctory-7900XTX\README.md:49 | [X] unknown | [X] absent |
| VICTORY_FEEDBACK | none in this tree | Proposed sampler-feedback diagnostic; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\sampler-feedback-experiment-prompt.md:159 | [X] unknown | [X] absent |
| VICTORY_PORT_CBV | none in this tree | Public fork raw constant-buffer port; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\avatar-VIctory-7900XTX\README.md:79 | [X] unknown | [X] absent |
| VICTORY_OUTPUT | none in this tree | Public fork switch to render at a title-side output size; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\avatar-VIctory-7900XTX\README.md:88 | [X] unknown | [X] absent |
| VICTORY_FFX_SCALE | none in this tree | Public fork performance/visual switch; absent from local source. | [S] C:\Users\mrgre\AppData\Local\Temp\opencode\handoff-report.md:178 | [X] unknown | [X] absent |

## Disable-by-value index [X]

[X] Switches whose documented value disables or bypasses a behavior (`0`, `none`, `off`, `never`, `plain`, `uncapped`, or an explicit override). This is an index only; the tables above carry the exact semantics and risk.

- VICTORY_ALIAS_COPY - on by default; 0 = off
- VICTORY_AMBIENT_RT - none in this tree
- VICTORY_ASK_NORESET - off by default; 1 = on
- VICTORY_ASK_ONCE - on by default; 0 = off
- VICTORY_ASK_SPREAD - off by default; 1 = on
- VICTORY_ASYNC_SUBMIT - off by default; 1 = on
- VICTORY_BAKE_EXACT - on by default; 0 = off
- VICTORY_BAKE_TEXTURES_MS - default 1500 ms before a decoration bake; 0 = no special wait
- VICTORY_BENCH_HOLES - on by default; 0 = off
- VICTORY_BENCH_N - default 3; set overrides; 0 = none/off
- VICTORY_BENCH_THREADS - default 4; set overrides; 0 = none/off
- VICTORY_BENCH_WARP - off by default; any nonzero/set value = on
- VICTORY_BIND_CACHE - on by default; 0 = off
- VICTORY_BLOCK_WAY - default 3; set overrides; 0 = none/off
- VICTORY_BOOK - on by default; 0 = off
- VICTORY_BURY_LAG - default 64 submissions (16 with limited host RAM); 0 = drop without delay
- VICTORY_BVH_BOUNDS - on by default; 0 = off
- VICTORY_BVH_BUILDER - off by default; 1 = on
- VICTORY_BVH_FAULTS_ALL - none in this tree
- VICTORY_BVH_FENCES - on by default; 0 = off
- VICTORY_BVH_QUARANTINE - off by default; 1 = on
- VICTORY_BVH_SIZES_WAIT - off by default; 1 = on
- VICTORY_BVH_TRACE - off by default; 1 = on
- VICTORY_CACHE_CORES - on by default; 0 = off
- VICTORY_CARD_ACCOUNTING - off by default; 1 = on
- VICTORY_CARD_ALL - off by default; 1 = on
- VICTORY_CARD_BUFFERS - on by default; 0 = off
- VICTORY_CARD_HASH_LEN - on by default; 0 = off
- VICTORY_CARD_REHASH_RUNS - off by default; 1 = on
- VICTORY_CARD_ROOM_FOR_BUFFERS - on by default; 0 = off
- VICTORY_CARD_ROOM_FOR_TARGETS_MB - default 3072 MiB; set value capped at 8192 MiB; 0 = none (&lt;3072 forbidden)
- VICTORY_CARD_SPANS - off by default; 1 = on
- VICTORY_COMMITTED_QUERY - off by default; 1 = on
- VICTORY_COMPILER_GUARD - none in this tree
- VICTORY_COPIES_IN_PLACE - on by default; 0 = off
- VICTORY_COPY_ASK - off by default; 1 = on
- VICTORY_COPY_BESIDE - off by default; 1 = route title memcpy/memmove/memset through guarded copies
- VICTORY_COPY_MODE - default 0 = guarded copies; 1 = plain; 2 = no copies
- VICTORY_COPY_OVER_TITLE - default 2 = zero unused title textures and upload used or staged ones; title/1 = reuse title memory; 0 = leave host-block bytes
- VICTORY_CUT_WAITS - on by default; 0 = off
- VICTORY_CUT_WRITES - off by default; 1 = on
- VICTORY_D3D12_BACKGROUND - on by default (runtime background shader work left enabled); 0 = disable it
- VICTORY_D3D12_DEBUG - off by default; any nonzero/set value = on
- VICTORY_D3D12_GBV - off by default; 1 = GPU-based validation in diagnostics builds
- VICTORY_D3D12_WARP - off by default; set nonzero = software adapter in diagnostics builds
- VICTORY_DECLARE_ONCE - on by default; 0 = off
- VICTORY_DEPTH_TWINS - on by default; 0 = off
- VICTORY_DESC_WHY - off by default; any nonzero/set value = on
- VICTORY_DIRECT_WRITES - on by default; 0 = off
- VICTORY_DUMP_TARGETS - off by default; set nonzero with capture folder = save render-target textures
- VICTORY_EARLY_ALL - off by default; 1 = on
- VICTORY_EARLY_TEXTURES_MS - default 12 ms per frame for index-picked texture uploads; 0 = never
- VICTORY_EFFICIENCY_MODE - off by default; 1 = on
- VICTORY_EXACT_BACK - on by default; 0 = off
- VICTORY_FALLBACK_HEAPS - on by default; 0 = off
- VICTORY_FAST_CORES - default 2; 0 = none; 1 = waited threads; 2 = shared workers; 3 = all helpers
- VICTORY_FEEDBACK - none in this tree
- VICTORY_FETCH_CHECK - off by default; 1 = on
- VICTORY_FFX_SCALE - none in this tree
- VICTORY_FILL_TITLE - default 0; 1/2 select the stage
- VICTORY_FIRST_HALF - on by default; 0 = off
- VICTORY_FIRSTLANE_OWN - off by default; 1 = on
- VICTORY_FULL_CARD_PASS - on by default; 0 = off
- VICTORY_GPU_TIMING - off by default; any nonzero/set value = on
- VICTORY_GUARD_HOLES - on by default; 0 = off
- VICTORY_HEAP_PASS_ASIDE - on by default; 0 = off
- VICTORY_HEAP_RECHECK - on by default; 0 = off
- VICTORY_HEAP_SPREAD - on by default; 0 = off
- VICTORY_HEAP_SYNC - on by default; 0 = off
- VICTORY_HEAP_SYNC_ASIDE - on by default; 0 = off
- VICTORY_HEAP_SYNC_EARLY - default 4 ms; 0 = none
- VICTORY_HEAP_TEXTURES - on by default; 0 = off (known missing index-picked textures); stable=0
- VICTORY_HELD_LEVELS - on by default; 0 = off
- VICTORY_HELPER_OWN - on by default; 0 = off
- VICTORY_HOST_RDNA - off by default; 1 = on
- VICTORY_IMAGE_WATCH - unset: off; set: name=hex-offset:bytes list of title image words
- VICTORY_INDIRECT_CARD_BUDGET - on by default; 0 = off
- VICTORY_INDIRECT_REST - on by default; 0 = off
- VICTORY_INDIRECT_WIDE - on by default; 0 = off
- VICTORY_INDIRECT_WINDOW - off by default; 1 = on
- VICTORY_INPLACE - default 0; set overrides; 0 = none/off
- VICTORY_INPLACE_MB - default 4096; set overrides; 0 = none/off
- VICTORY_INPLACE_PROBE - default 0; set overrides; 0 = none/off
- VICTORY_JOIN_BARRIERS - off by default; 1 = on
- VICTORY_JOIN_COPIES - off by default; 1 = on
- VICTORY_KEEP_FREED - on by default; 0 = off
- VICTORY_KEEP_SHOWN - default 1; set overrides; 0 = none/off
- VICTORY_KEEP_SNAPSHOTS - off by default; 1 = on
- VICTORY_KEEP_SNAPSHOTS_MB - default 256; set overrides; 0 = none/off
- VICTORY_KEEP_VIEWS - on by default; 0 = off
- VICTORY_KNOWN_HOLES - on by default; 0 = off
- VICTORY_LAND - on by default; 0 = off
- VICTORY_LAND_ANYTIME - on by default; 0 = off
- VICTORY_LAND_BESIDE - on by default; 0 = off
- VICTORY_LAND_SKIP - off by default; 1 = on
- VICTORY_LAND_TAKEN - on by default; 0 = off
- VICTORY_LANE_CORE - off by default; 1 = on
- VICTORY_LATE_WAIT - default stage 3 when relay runs, else 0; 1/2/3 select stage explicitly
- VICTORY_LATE_WAIT_LISTS - default 256; set overrides; 0 = none/off
- VICTORY_LATE_WAIT_WRITES - on by default; 0 = off
- VICTORY_LATE_WAITS - off by default; 1 = on
- VICTORY_LAZY_PRELUDE - on by default; 0 = off
- VICTORY_LAZY_TEXTURES - on by default; 0 = off
- VICTORY_LENT_HEAP - on by default; 0 = off
- VICTORY_LEVELS_ON_DEMAND - off by default; 1 = on
- VICTORY_LIBRARY_HANDLE - on by default; 0 = off
- VICTORY_LIBRARY_LOCK - off by default; 1 = on
- VICTORY_LIBRARY_MAP - on by default; 0 = off
- VICTORY_LIBRARY_TRIM - on by default; 0 = off
- VICTORY_LIGHT_PROBE - unset or 0: off; set: output file path
- VICTORY_LIGHT_PROBE_LUX - off by default; 1 = on
- VICTORY_LIST_POOL - on by default; 0 = off
- VICTORY_MAP_LEAN - on by default; 0 = off
- VICTORY_MAPPED_BY_PAGE - off by default; 1 = on
- VICTORY_MAPPED_BY_VIEWS - on by default; 0 = off
- VICTORY_MEMORY_CATEGORIES - off by default; 1 = add periodic approximate memory-category line
- VICTORY_MEMORY_MAP - default 60; set overrides; 0 = none/off
- VICTORY_OUTPUT - none in this tree
- VICTORY_PAGE_PARTS - on by default; 0 = off
- VICTORY_PAGE_WRITES - default/guards = bit 1 only; 0 = none; 1 = bits 1+2; slots = bit 2; all = bits 1+2+4
- VICTORY_PATCH_CLZERO - on by default; 0 = off
- VICTORY_PATCH_WAITS - on by default; 0 = off
- VICTORY_PICKED_MB - default 32; set overrides; 0 = none/off
- VICTORY_PICKED_WRITES - default 0 (off); 1/2 select staged handling of picked-view writes
- VICTORY_PIPELINE_BOOK - off by default; 1 = on
- VICTORY_PIPELINE_LIBRARY - on by default; 0 = no library calls at all
- VICTORY_PIPELINE_LOWEST - on by default; 0 = off
- VICTORY_PIPELINE_WAIT_SHARED - on by default; 0 = off
- VICTORY_PLACED_FILLER - off by default; 1 = on
- VICTORY_PLACED_ORDER - off by default; 1 = cut submission around stale in-place copy
- VICTORY_POOL_SMALL - off by default; any nonzero/set value = on
- VICTORY_POP_ALL - off by default; 1 = on
- VICTORY_PORT_CBV - none in this tree
- VICTORY_PORT_CONSTANTS - off by default; 1 = on
- VICTORY_PORT_CONSTANTS_ORDER_ALONE - none in this tree
- VICTORY_PORT_COPIES - none in this tree
- VICTORY_PORT_DESCRIPTORS - off by default; 1 = on
- VICTORY_PORT_DESCRIPTORS_CHECK - default 16 pages; 0 = none
- VICTORY_PORT_GUARD - none in this tree
- VICTORY_PORT_JOURNAL - none in this tree
- VICTORY_PORT_RT - none in this tree
- VICTORY_QUEUE_WAIT - on by default; 0 = off
- VICTORY_QUEUE2_LANDING_MB - none in this tree
- VICTORY_QUICK_FIND - on by default; 0 = disable thread-local lookup cache
- VICTORY_QUICK_MIRROR - on by default; 0 = off
- VICTORY_RAW_VIEWS - on by default; 0 = off
- VICTORY_READ_BACK - on by default; 0 = off
- VICTORY_RECHECK_SOON - on by default; 0 = off
- VICTORY_RECORD_ALWAYS - off by default; 1 = record every frame in the capture window
- VICTORY_REFRESH_AHEAD - on by default; 0 = off
- VICTORY_REFRESH_CHECK - off by default; 1 = on
- VICTORY_REFRESH_FRONT - on by default; 0 = off
- VICTORY_RELAY - default/off: stage 2 when relay runs; 1 = first stage; launcher: 2
- VICTORY_RELAY_COPY - off by default; 1 = on
- VICTORY_RESIDENCY - off by default; 1 = on
- VICTORY_RESIDENCY_LIMITED - off by default unless physical RAM &lt;= 32 GiB; 1 with VICTORY_RESIDENCY forces limited mode
- VICTORY_REUPLOAD_WHEN_FULL - on by default; 0 = off
- VICTORY_RIPE_BLOCKS - default 12; 0 = every block ripe at once
- VICTORY_ROOT_SRV_DIRECT - on by default; 0 = off
- VICTORY_SAFE_COPY - on by default; 0 = off
- VICTORY_SCRATCH_POOL - on by default; 0 = off
- VICTORY_SECTION_WINDOW - on by default; 0 = off
- VICTORY_SEND_BAR - off by default; 1 = on
- VICTORY_SEND_CHANGED - off by default in test; set nonzero = exact changed-bytes landing assertions
- VICTORY_SEND_OWN - on by default; 0 = off
- VICTORY_SHADER_CENSUS - off by default; any nonzero/set value = on
- VICTORY_SHADER_FRESH - off by default; 1 = on
- VICTORY_SHADER_OPT - default 63 (all but the last pass); 0 = none; number = pass bitmask
- VICTORY_SHOW_AFTER - off by default; any nonzero/set value = on
- VICTORY_SHOW_NEW_LATER - on by default; 0 = off
- VICTORY_SKIP_CPU_CHECK - off by default; 1 = bypass the AVX2 pre-flight check
- VICTORY_SLOT_CHECK - off by default; any nonzero/set value = on
- VICTORY_SLOT_HOLDS - on by default; 0 = off
- VICTORY_SPANS_QUICK - on by default; 0 = off
- VICTORY_SPLIT_WAITS - on by default; 0 = off
- VICTORY_STALE_TEXTURES - default start rule; 0 = never; overlap = older rule
- VICTORY_STORE_BESIDE - off by default; 1 = handle faulting title stores beside guards
- VICTORY_STREAM_NOTICE - on by default; 0 = off
- VICTORY_STREAM_PRIORITY - on by default; 0 = off
- VICTORY_STRICT_JOINS - off by default; any nonzero/set value = on
- VICTORY_SWEEP - on by default; 0 = off
- VICTORY_SWEEP_PER_HEAP - off by default; 1 = on
- VICTORY_SYNC_FINE - off by default; any nonzero/set value = on
- VICTORY_SYNC_IN_PLACE - on by default; 0 = off
- VICTORY_TEST_ROUNDS - default 120; set overrides; 0 = none/off
- VICTORY_TEXTURE_CATCHUP - on by default; 0 = off
- VICTORY_TEXTURE_COPY - off by default; 1 = on
- VICTORY_TEXTURE_FILL - on by default; 0 = off
- VICTORY_TEXTURE_GUARD - on by default; 0 = off
- VICTORY_TEXTURE_HOT - on by default; 0 = off
- VICTORY_TEXTURE_KEEP - on by default; 0 = off
- VICTORY_TEXTURE_MAX - unset: 1024 / 512 at 92% / 256 at 97% VRAM; 0 = uncapped; stable: 256
- VICTORY_TEXTURE_NO_WAIT - off by default; 1 = on
- VICTORY_TEXTURE_ONCE - on by default; 0 = off
- VICTORY_TEXTURE_POOL - on by default; 0 = off
- VICTORY_TEXTURE_SAME - on by default; 0 = off
- VICTORY_TEXTURE_SWEEP - on by default; 0 = off
- VICTORY_THIN - off by default; 1 = on
- VICTORY_THREAD_DIMENSIONS - on by default; 0 = off
- VICTORY_TILES_TEST_CARD - off by default; 1 = on
- VICTORY_TIMER_LOG - off by default; 1 = on
- VICTORY_TITLE_PRIORITIES - on by default (normalize title priorities); 0 = leave as title sets; launcher=0
- VICTORY_TRAIL - on by default; 0 = off
- VICTORY_UNDER_WORDS - on by default; 0 = off
- VICTORY_UNWATCHED_FRAMES - default 1; set overrides; 0 = none/off
- VICTORY_UP_QUEUE - off by default; 1 = on
- VICTORY_UPCOPY_CHECK - off by default; 1 = on
- VICTORY_UPLOAD_AHEAD - off by default; any nonzero/set value = on
- VICTORY_UPLOAD_LOW - on by default; 0 = off
- VICTORY_VIEW_BYTES - on by default; 0 = off
- VICTORY_VIEW_EXTENT - on by default; 0 = off
- VICTORY_VIEW_GUARD - on by default; 0 = off
- VICTORY_VIEW_INLINE - on by default; 0 = off
- VICTORY_WAIT_ASK - off by default; 1 = on
- VICTORY_WAIT_FORCE - on by default; 0 = off
- VICTORY_WAIT_RESIDENT - on by default; 0 = off
- VICTORY_WALLS_TRACE - off by default; 1 = on
- VICTORY_WARM_BAD - none in this tree
- VICTORY_WARM_SECONDS - default 4; set overrides; 0 = none/off
- VICTORY_WARP - off by default; 1 = on
- VICTORY_WATCH - unset: off; set: comma-separated hexadecimal RVAs to watch
- VICTORY_WAVE_DEEP_SKIPS - on by default; 0 = off
- VICTORY_WAVE_DUMP - off by default; any nonzero/set value = on
- VICTORY_WAVE_LOCAL - on by default; 0 = off
- VICTORY_WAVE_OWN_BITS - on by default; 0 = off
- VICTORY_WAVE_WHY - off by default; any nonzero/set value = on
- VICTORY_WAVE_WIDE - off by default; 1 = on
- VICTORY_WIDE_BACK - on by default; 0 = off
- VICTORY_WIDE_FILLS - on by default; 0 = off
- VICTORY_WIDE_MERGE - off by default; 1 = on
- VICTORY_WIDE_REFRESH - default on with at least 4 logical CPUs; 0 = off; 1 = forced on
- VICTORY_WIDE_SPIN - default 0 (no spin); set: microseconds
- VICTORY_WIDE_TEXTURES - on by default; 0 = off
- VICTORY_WINDOW_BUDGET_MB - unset or 0: no cap; positive: MiB cap for loose window copies in Watch/High RAM
- VICTORY_WINDOW_TAILS - off by default; 1 = on
- VICTORY_WINDOWS_BAR_MB - default 0; set overrides; 0 = none/off
- VICTORY_WINDOWS_OWN - off by default; 1 = on
- VICTORY_WRITE_SITES - on by default; 0 = off
- VICTORY_WRITE_SKIP - on by default; 0 = off
- VICTORY_XMA_REFILL - off by default; 1 = on

