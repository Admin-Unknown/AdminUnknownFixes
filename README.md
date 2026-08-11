# AdminUnknownFixes

Bridge mod for **Pyanodon**, **Angel’s**, and **Bob’s** on Factorio 2.1: merged compatibility content, recipe/tech fixes, and related shims.

Homepage: [https://github.com/jakegodding/AdminUnknownFixes](https://github.com/jakegodding/AdminUnknownFixes)

## Building release zips

From the repository root:

- **Windows:** `pwsh -File scripts/package-mods.ps1`
- **Unix:** `./scripts/package-mods.sh`

Outputs under `dist/` (gitignored): main mod plus the PyCoalTBaA stub. After each run, the stub zip is also copied to `stubs/` in the repo for direct download (see below).

## Manual stub install

PyPostProcessing still requires a mod named **PyCoalTBaA** when Angel’s Refining is active. Download and install the stub into your Factorio `mods` folder (same place as other mods). Enable it from the in-game mod UI.

| Stub | Direct download (raw `main` branch) |
|------|-------------------------------------|
| PyCoalTBaA | [PyCoalTBaA_0.0.7.zip](https://github.com/jakegodding/AdminUnknownFixes/raw/main/stubs/PyCoalTBaA_0.0.7.zip) |

**Install:** copy `PyCoalTBaA_0.0.7.zip` into `%APPDATA%\Factorio\mods` (Windows) or `~/.factorio/mods` (Linux/macOS). **Delete every older `PyCoalTBaA_0.0.*.zip`.** Then restart and enable the stub if it is not auto-enabled.

A future **PyPostProcessing** release may accept **AdminUnknownFixes** in place of PyCoalTBaA; see [docs/pypostprocessing-upstream-pr.md](docs/pypostprocessing-upstream-pr.md) for the proposed upstream change.
