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
$pycoalStubInfoPath = Join-Path (Join-Path $root 'PyCoalTBaA-stub') 'info.json'
if (-not (Test-Path $mainInfoPath)) { throw "Missing $mainInfoPath" }
if (-not (Test-Path $pycoalStubInfoPath)) { throw "Missing $pycoalStubInfoPath" }

$main = Get-Content -Raw $mainInfoPath | ConvertFrom-Json
$pycoalStub = Get-Content -Raw $pycoalStubInfoPath | ConvertFrom-Json

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

    $pycoalStubInner = Join-Path $staging ("{0}_{1}" -f $pycoalStub.name, $pycoalStub.version)
    New-Item -ItemType Directory -Path $pycoalStubInner -Force | Out-Null
    Copy-Item -Path (Join-Path $root 'PyCoalTBaA-stub\*') -Destination $pycoalStubInner -Recurse -Force

    if ($Clean -and (Test-Path -LiteralPath $dist)) {
        Remove-Item -LiteralPath $dist -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dist -Force | Out-Null

    $mainZip = Join-Path $dist ("{0}_{1}.zip" -f $main.name, $main.version)
    $pycoalStubZip = Join-Path $dist ("{0}_{1}.zip" -f $pycoalStub.name, $pycoalStub.version)
    if (Test-Path -LiteralPath $mainZip) { Remove-Item -LiteralPath $mainZip -Force }
    if (Test-Path -LiteralPath $pycoalStubZip) { Remove-Item -LiteralPath $pycoalStubZip -Force }

    Compress-Archive -Path $mainInner -DestinationPath $mainZip -CompressionLevel Optimal -Force
    Compress-Archive -Path $pycoalStubInner -DestinationPath $pycoalStubZip -CompressionLevel Optimal -Force

    Write-Host "Wrote:"
    Write-Host "  $mainZip"
    Write-Host "  $pycoalStubZip"

    $stubsDir = Join-Path $root 'stubs'
    New-Item -ItemType Directory -Path $stubsDir -Force | Out-Null
    Copy-Item -LiteralPath $pycoalStubZip -Destination (Join-Path $stubsDir (Split-Path -Leaf $pycoalStubZip)) -Force
    Write-Host "Copied stub zip to:"
    Write-Host "  $(Join-Path $stubsDir (Split-Path -Leaf $pycoalStubZip))"
}
finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
