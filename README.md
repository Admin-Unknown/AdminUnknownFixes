# AdminUnknownFixes

Bridge mod for **Pyanodon**, **Angel’s**, and **Bob’s** on Factorio 2.1: merged compatibility content, recipe/tech fixes, and related shims.

Homepage: [https://github.com/jakegodding/AdminUnknownFixes](https://github.com/jakegodding/AdminUnknownFixes)

## Building release zips

From the repository root:

- **Windows:** `pwsh -File scripts/package-mods.ps1`
- **Unix:** `./scripts/package-mods.sh`

Outputs under `dist/` (gitignored): main mod plus its companion mods. After each run, the companion zips are also copied to `stubs/` in the repo for direct download (see below).

## Manual companion installs

Both of these are separate mods because neither can do its job from inside AdminUnknownFixes. Download them into your Factorio `mods` folder (same place as other mods) and enable them from the in-game mod UI.

| Mod | Why it is separate | Direct download (raw `main` branch) |
|-----|--------------------|-------------------------------------|
| PyCoalTBaA | PyPostProcessing still requires a mod of that name when Angel’s Refining is active | [PyCoalTBaA_0.0.7.zip](https://github.com/jakegodding/AdminUnknownFixes/raw/main/stubs/PyCoalTBaA_0.0.7.zip) |
| 0-auf-extend-guard | Has to load before every other mod, which AdminUnknownFixes cannot: requiring pycoalprocessing holds it behind everything that sorts earlier | [0-auf-extend-guard_0.0.1.zip](https://github.com/jakegodding/AdminUnknownFixes/raw/main/stubs/0-auf-extend-guard_0.0.1.zip) |

**Install:** copy the zips into `%APPDATA%\Factorio\mods` (Windows) or `~/.factorio/mods` (Linux/macOS). **Delete every older copy of the same mod.** Then restart and enable them if they are not auto-enabled.

`0-auf-extend-guard` is only needed if you run a mod that leaves a stray field in the list it hands to `data:extend`. bobpower 3.0.0 does, and without the guard it stops the load with an error naming PyPostProcessing’s `metas.lua`. It is harmless otherwise, and the leading zero in its name is what puts it first in the load order.

A future **PyPostProcessing** release may accept **AdminUnknownFixes** in place of PyCoalTBaA; see [docs/pypostprocessing-upstream-pr.md](docs/pypostprocessing-upstream-pr.md) for the proposed upstream change.
