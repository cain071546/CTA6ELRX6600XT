# VIctory on RDNA GPUs

A fork of [VIctory](https://github.com/Marvisak/VIctory), a compatibility layer
that runs an Xbox Series title natively on Windows from files the user supplies.
The measurements below are from an RX 7900 XTX; a reusable low-VRAM preset is
provided for 8 GB cards such as the RX 6600 XT.

## The goal

**A stable 30 fps or more without ray tracing, then as high a frame rate and as
low frame times as the PC allows**, on an AMD RX 7900 XTX first and on PCs with
32 GB (later 16 GB) of RAM.

The way there is **porting, not emulating**: patching the title's renderer so it
behaves the way a PC renderer does, rather than having the layer watch and copy
the console's shared memory every frame. Shaders are translated ahead of time
into a versioned store that is kept between builds. Ray tracing stays optional
and off by default. The picture comes after the frame rate: texture pop-in and
lighting that is too bright or too dark when walking indoors are next in line.

**This repository contains no game files, code or assets.** You need your own
copy of the game. It is not affiliated with or endorsed by the game's developer
or publisher.

## Where it stands (2026-11-26)

Frame-rate and memory measurements are from one machine only: Windows 11,
Intel i9-12900K, 64 GB RAM, Radeon RX 7900 XTX, the Series X profile, ray
tracing off. Device creation and shader translation were also checked on a
Windows 10 22H2 machine with an RX 6600 XT (8,147 MiB dedicated VRAM, shader
model 6.6 through the Agility SDK, mesh tier 1, waves 32/64). A full run with
SDK 1.620.2 reached the world but removed the device; the runtime is pinned to
1.614.1 now. A low-VRAM run with serialized pipeline-library loads reached
+frame 2055 without a removal; longer confirmation is still useful.

| | |
|---|---|
| City street, renderer patches 1+2 on | about 53 ms a frame (about 19 fps) |
| Same scene before the patches | 57-75 ms (13-17 fps) |
| Shaders the title uses that translate | all of them (25,790 of 25,985; the rest are unused geometry shaders) |
| Memory | about 35 GB of private memory: **64 GB of RAM recommended** for now |

It started at 280 ms a frame in the same scenes three days earlier.

### Renderer patches (off by default while they are tested)

| Switch | What it does |
|---|---|
| `VICTORY_PORT_CONSTANTS=1` | The title's 174 MB constants heap is read by the card where the title writes it: no uploads, no fills |
| `VICTORY_PORT_CONSTANTS_ORDER=0` | Off: indirect arguments in in-place memory are clamped in batches/windows as before. On by default: each is clamped right before the draw/dispatch that reads it, after the title's culling has written it (2-5 ms a frame) |
| `VICTORY_PORT_DESCRIPTORS=1` | The title's descriptor-table stores are patched (byte-checked) to report the slots they write, instead of a scan of ~600,000 slots a frame |

What is known to be wrong:

- Trees, signs and far objects flicker in the distance in some places.
- Lighting is too bright or too dark after walking indoors, until the title has
  run for a while; rooms with little direct light are too dark without `-RayTracing`.
- Textures of what just came into view appear late while the title streams.
- The first run of a new build stutters while the driver makes pipelines
  (`victory warm` makes them ahead).
- Recording a frame in the world makes the title's own watchdog end it.

## How to run it

You need Windows 10/11 x64, a CPU with AVX2, a Direct3D 12 GPU with shader
model 6.6 and mesh shaders, Rust (the toolchain is pinned), the MSVC build
tools, and your own dump of the title.

```powershell
git clone https://github.com/avatarmanz/VIctory-7900XTX
cd VIctory-7900XTX
copy victory.example.toml victory.toml      # then set your paths, outside this folder
cargo xtask agility                         # Windows 10: newer D3D12 for shader model 6.6
cargo build --locked --profile diag -p victory --features diagnostics
scripts\play.ps1 -Exe <path of your copy's executable>
```

`scripts\play.ps1 -Safe` leaves out the newest, faster ways; try it first when
something is wrong. `-RayTracing` turns the title's ray-traced indirect light on.

### Windows 10 and shader model 6.6

Windows 10's in-box D3D12 runtime stops at shader model 6.5, so every translated
pipeline is refused there even when the card supports 6.6. `cargo xtask agility`
downloads Microsoft's Direct3D 12 Agility SDK 1.614.1, checks its published
SHA-512, and copies `D3D12Core.dll` into `target\<profile>\D3D12\` beside each
`victory.exe`, and into `target\<profile>\deps\D3D12\` for GPU-backed tests.
Both export the SDK version and path that make D3D12 load it. Windows 11 uses
its newer in-box runtime; the extra folders are harmless.
`target\diag\victory.exe config` says whether the runtime is in place.

The pin is deliberately 1.614.1, not the newer 1.620.2: on RDNA2 cards the
newer runtime reached SM 6.6 but then removed the device in the world
(Marvisak/VIctory#746), while 1.614.1 reached SM 6.6 and stayed up on RX 6800
XT and RX 6750 XT (Marvisak/VIctory#84). Do not replace the DLL with 620 just
because it is newer.

### Low-VRAM cards

Use `-Profile low-vram` for an 8 GB card such as the RX 6600 XT:

```powershell
scripts\play.ps1 -Exe <path of your copy's executable> -Profile low-vram
```

This is a reusable preset, not a device-ID check. It only supplies defaults:
anything passed with `-More` (or set by another launcher) wins. It replaces the
sizes measured on a 24 GB card with these:

| Switch | Preset | Instead of |
|---|---|---|
| `VICTORY_PROFILE` | `low-vram` | unset (`play.ps1` passes `default`) |
| `VICTORY_TEXTURE_STAGE_MB` | 96 | 192 (also chosen automatically at 8 GiB or less) |
| `VICTORY_TEXTURE_KEEP` | `0` | idle texture copies kept for ten minutes |
| `VICTORY_CARD_ROOM_FOR_TARGETS_MB` | 3072 (kept) | 3072 |
| `VICTORY_MEMORY_CARD_MB` | 1024 | 4096 |
| `VICTORY_LIBRARY_LOCK` | `1` | unset |

`VICTORY_CARD_ROOM_FOR_TARGETS_MB` is deliberately **not** lowered: it is the
room the texture queue leaves for render targets, not a cap on them. Lowering
it lets textures fill an 8 GB card past its budget, which removed the device
in-world; keep the 3072 MB reservation.

`VICTORY_TEXTURE_MAX` is a separate, per-texture side cap for streamed placed
2D textures. Unset, it skips the largest mips above 1024 pixels, tightening to
512 above 92 % of the card's VRAM budget and 256 above 97 %; an explicit value
such as `512` or `256` fixes the cap, while `0` leaves textures uncapped. It is
not part of `low-vram` yet because it changes visible detail and has not been
isolated on RX 6600 XT. Use it in `-More` for A/B tests while keeping the
3072 MB target reservation.

`VICTORY_LIBRARY_LOCK=1` serializes pipeline-library loads and compiles. On
RX 6600 XT, a low-VRAM run without it removed the device during a large
first-run shader burst with many loads still running; with it, one run reached
frame 2055 without a removal. It is a **partial mitigation, not a fix**: a
later locked run with a fresh cache still removed the device while a submission
was being prepared. It trades some startup throughput for stability, so leave
it on unless you are deliberately testing the old behavior.

To diagnose a remaining removal, note that on Windows 10 the D3D12 debug layer
needs the **Graphics Tools** optional feature even though `cargo xtask agility`
ships `d3d12SDKLayers.dll` beside `D3D12Core.dll`. Without it,
`VICTORY_D3D12_DEBUG=1` cannot attach an info queue and cannot name a command.
Install it once with:

```powershell
Add-WindowsCapability -Online -Name "Tools.Graphics.DirectX~~~~0.0.1.0"
```

Or add **Graphics Tools** in Settings → System → Optional features. Then
capture the whole log (including the startup line `host D3D12 debug layer`)
from a run such as:

```powershell
$cache = Join-Path $env:TEMP 'victory-removal-debug'
New-Item -ItemType Directory -Force $cache | Out-Null
scripts\play.ps1 -Exe <path of your copy's executable> -Profile low-vram -More @{
  VICTORY_CACHE_DIR = $cache
  VICTORY_D3D12_DEBUG = '1'
  VICTORY_D3D12_DRED = '1'
}
```

`VICTORY_D3D12_DRED='light'` (the launcher default) is cheap but records no
marker text; `='1'` records command notes and fault allocations for the report.

In diagnostics builds the host PSO's debug name also carries the title
pipeline key and pipeline-library name (both 32 hex) and each shader's full
container hash, next to the 16-hex hashes printed in draw notes. That joins a
DRED pipeline target to the draw that used it. With
`VICTORY_SHADER_SAVE=<dir>`, the same short hashes and stages name the title's
`.cdxil` and its translated `.dxil` in that folder.

The shader cache key includes host wave width and RDNA settings, so changing
adapter or those host settings can make the first run translate shaders again;
the preset itself does not change them. Changing the Agility runtime discards
the compiled pipeline library automatically. The launcher does not set
`VICTORY_KEEP_FREED=0`: releasing freed VRAM can lose the device when
translated shaders read past a view. If needed, pass it explicitly with `-More`
after weighing that risk.

On the RX 6600 XT, one GPU unit test (`views_are_made_beside_the_heap_and_copied_in`)
still compares raw descriptor bytes differently; it fails on the unmodified tree
too. The diagnostics replay harness reached with `--all-features` crashes in its
recorder on this card; ordinary runs do not use it.

On a hybrid-graphics PC, the runtime and offline pipeline checks prefer a
high-performance adapter with Shader Model 6.6. The runtime logs its adapter
name, PCI vendor and device IDs, and dedicated VRAM. Set
`VICTORY_D3D12_ADAPTER` to a zero-based DXGI index or part of the adapter's
name to select it explicitly. With the launcher, pass
`-More @{VICTORY_D3D12_ADAPTER='NVIDIA'}`.

Before the first run, ahead of time (both can be stopped and go on later):

```powershell
target\diag\victory.exe shaders <the shader archives>   # every shader translated, minutes
target\diag\victory.exe warm --used                     # pipelines earlier runs drew with, for a new driver or build
```

Commands, debugging switches and upstream's own description:
[docs/README-fxceless.md](docs/README-fxceless.md). Every `VICTORY_...` switch is
described in a comment where it is read.

## What is different here

In short; the reasons and the measurements are in [docs/findings.md](docs/findings.md).

- **List calls are written down, not carried out, on the title's threads**
  (`VICTORY_THIN`): eight threads of ours translate them.
- **Submissions are prepared by a thread of ours and joined**
  (`VICTORY_ASYNC_SUBMIT`, `VICTORY_JOIN_PARTS`), with what can be spread over
  threads spread: refreshes, compares (AVX2), descriptor records, landings.
- **What shaders wrote comes back beside the write guards**, by the dwords that
  changed, on a thread of its own (`VICTORY_RELAY`, `VICTORY_LAND`).
- **Buffer fills that need bytes still on the card are done on the card**
  (`VICTORY_CARD_STEPS`) instead of waiting for it.
- **The title's writes are caught more cheaply**: one view opened at a fault,
  blocks that rest, places in the title's code that look before they write.
- **Textures go up on a copy queue of their own** and a slot shows one only after
  its upload ran, which also ended a device loss that came every 15 minutes or so.
- **Boats float**: textures that shaders write and the title's CPU reads go back
  to title memory (from fxceless and Geckomacabre, on by default here).
- **Frame record and replay** with per-pass times and shader variants compared
  turn by turn ([docs/replay.md](docs/replay.md)).

## Credits

This is a tree of other people's work with more on top. The history is kept, and
commits taken from elsewhere name the commit and its author.

- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its
  contributors: the loader, the runtime services, the Direct3D 12 back end and
  the shader recompiler.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**: the fork
  this one started from, and the people whose pull requests it carries.
- **[DexNom/VIctory](https://github.com/DexNom/VIctory)**: ray tracing fixes,
  cube gradients, sparse textures.
- **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)**:
  the ambient light idea, pipeline workers, and work by romainhedouin.
- **[FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY)**.
- **[myokex/victory-amd](https://github.com/myokex/victory-amd)**: the guard over
  every view of a page (with Spexivus, joroyt and tightfall), and Joshua Odom's
  reads into title memory.
- **Geckomacabre** and **cxy0072019-sketch**: the texture read-back.
- **[XCL](https://github.com/ivall/xcl)** (GPL-2.0-only) was read for how the same
  title behaves under another layer; no code of it is here.
- This fork's changes were made with [Claude Code](https://claude.com/claude-code).

## License

GPL-3.0-or-later, as VIctory. See [LICENSE](LICENSE); the one file that is not
covered is named in [docs/asset-policy.md](docs/asset-policy.md).
