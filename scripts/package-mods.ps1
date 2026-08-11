#Requires -Version 5.1
<#
.SYNOPSIS
    Build Factorio release zips for AdminUnknownFixes (repo root) and PyCoalTBaA (PyCoalTBaA-stub/).

.DESCRIPTION
    Stages an allowlisted copy of each mod into <name>_<version>/ and writes zips under dist/.
    Excludes othermodsource, .git, stub folders from the main mod zip.
    Copies the PyCoalTBaA stub zip into repo stubs/ for committed direct-download artifacts.

.EXAMPLE
    From repo root:
        pwsh ./scripts/package-mods.ps1
        pwsh ./scripts/package-mods.ps1 -OutDir dist -Clean
#>
param(
    [string]$OutDir = 'dist',
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dist = Join-Path $root $OutDir

$mainInfoPath = Join-Path $root 'info.json'
if (-not (Test-Path $mainInfoPath)) { throw "Missing $mainInfoPath" }
$main = Get-Content -Raw $mainInfoPath | ConvertFrom-Json

# Companion mods shipped alongside the main one, each a folder of its own that is copied whole
$companionFolders = @('PyCoalTBaA-stub', 'extend-guard-stub')
$companions = foreach ($folder in $companionFolders) {
    $infoPath = Join-Path (Join-Path $root $folder) 'info.json'
    if (-not (Test-Path $infoPath)) { throw "Missing $infoPath" }
    [pscustomobject]@{
        Folder = $folder
        Info   = Get-Content -Raw $infoPath | ConvertFrom-Json
    }
}

$staging = Join-Path $env:TEMP ("auf-pack-" + [guid]::NewGuid().ToString())
try {
    New-Item -ItemType Directory -Path $staging -Force | Out-Null

    $mainInner = Join-Path $staging ("{0}_{1}" -f $main.name, $main.version)
    New-Item -ItemType Directory -Path $mainInner -Force | Out-Null

    $mainFiles = @(
        'control.lua',
        'data.lua',
        'data-updates.lua',
        'data-final-fixes.lua',
        'settings.lua',
        'settings-final-fixes.lua',
        'info.json',
        'changelog.txt',
        'thumbnail.png'
    )
    foreach ($f in $mainFiles) {
        $src = Join-Path $root $f
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $mainInner $f) -Force
        }
    }
    $mainDirs = @('functions', 'graphics', 'locale', 'migrations', 'prototypes')
    foreach ($d in $mainDirs) {
        $src = Join-Path $root $d
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $mainInner $d) -Recurse -Force
        }
    }

    foreach ($companion in $companions) {
        $inner = Join-Path $staging ("{0}_{1}" -f $companion.Info.name, $companion.Info.version)
        New-Item -ItemType Directory -Path $inner -Force | Out-Null
        Copy-Item -Path (Join-Path $root ($companion.Folder + '\*')) -Destination $inner -Recurse -Force
    }

    if ($Clean -and (Test-Path -LiteralPath $dist)) {
        Remove-Item -LiteralPath $dist -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dist -Force | Out-Null

    $mainZip = Join-Path $dist ("{0}_{1}.zip" -f $main.name, $main.version)
    if (Test-Path -LiteralPath $mainZip) { Remove-Item -LiteralPath $mainZip -Force }
    Compress-Archive -Path $mainInner -DestinationPath $mainZip -CompressionLevel Optimal -Force

    Write-Host "Wrote:"
    Write-Host "  $mainZip"

    $stubsDir = Join-Path $root 'stubs'
    New-Item -ItemType Directory -Path $stubsDir -Force | Out-Null

    foreach ($companion in $companions) {
        $inner = Join-Path $staging ("{0}_{1}" -f $companion.Info.name, $companion.Info.version)
        $zip = Join-Path $dist ("{0}_{1}.zip" -f $companion.Info.name, $companion.Info.version)
        if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
        Compress-Archive -Path $inner -DestinationPath $zip -CompressionLevel Optimal -Force
        Write-Host "  $zip"
        Copy-Item -LiteralPath $zip -Destination (Join-Path $stubsDir (Split-Path -Leaf $zip)) -Force
    }

    Write-Host "Copied companion zips to:"
    Write-Host "  $stubsDir"
}
finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
