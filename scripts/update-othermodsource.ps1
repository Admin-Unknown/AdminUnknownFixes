#Requires -Version 5.1
<#
.SYNOPSIS
    Download / refresh extracted Factorio mods under othermodsource/ from the mod portal.

.DESCRIPTION
    Scans othermodsource/*/info.json, queries https://mods.factorio.com/api/mods/<name>,
    and replaces each folder with the latest release matching -FactorioVersion
    (default: 2.1).

    Downloads require a Factorio account token (read from %APPDATA%\Factorio\player-data.json
    by default: service-username + service-token).

    Folders are normalized to othermodsource/<mod-name>/ (version suffixes stripped).
    Mods with no release for the requested Factorio line are skipped (e.g. 1.1-only packs).

.EXAMPLE
    pwsh ./scripts/update-othermodsource.ps1 -WhatIf
    pwsh ./scripts/update-othermodsource.ps1
    pwsh ./scripts/update-othermodsource.ps1 -Mods bobmining,angelsrefining
    pwsh ./scripts/update-othermodsource.ps1 -FactorioVersion 2.0
#>
param(
    [string]$OutDir = 'othermodsource',
    [string]$FactorioVersion = '2.1',
    [string[]]$Mods = @(),
    [string]$PlayerDataPath = '',
    [switch]$Force,
    [switch]$WhatIf,
    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceRoot = Join-Path $root $OutDir
if (-not (Test-Path -LiteralPath $sourceRoot)) {
    New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
}

if (-not $PlayerDataPath) {
    $PlayerDataPath = Join-Path $env:APPDATA 'Factorio\player-data.json'
}

function Get-PortalCredentials {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Factorio player-data not found: $Path (log into Factorio once, or pass -PlayerDataPath)"
    }
    $pd = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    $user = [string]$pd.'service-username'
    $token = [string]$pd.'service-token'
    if (-not $user -or -not $token) {
        throw "No service-username/service-token in $Path (Factorio must be logged into the mod portal)"
    }
    [PSCustomObject]@{ Username = $user; Token = $token }
}

function Compare-ModVersion {
    param([string]$A, [string]$B)
    $pa = @($A.Split('.') | ForEach-Object { [int]($_ -replace '[^\d]', '0') })
    $pb = @($B.Split('.') | ForEach-Object { [int]($_ -replace '[^\d]', '0') })
    $n = [Math]::Max($pa.Count, $pb.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $x = if ($i -lt $pa.Count) { $pa[$i] } else { 0 }
        $y = if ($i -lt $pb.Count) { $pb[$i] } else { 0 }
        if ($x -ne $y) { return ($x - $y) }
    }
    return 0
}

function Get-LocalMods {
    param([string]$Dir)
    $items = @()
    Get-ChildItem -LiteralPath $Dir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $infoPath = Join-Path $_.FullName 'info.json'
        if (-not (Test-Path -LiteralPath $infoPath)) { return }
        $info = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json
        $items += [PSCustomObject]@{
            Folder          = $_.Name
            FolderPath      = $_.FullName
            Name            = [string]$info.name
            Version         = [string]$info.version
            FactorioVersion = [string]$info.factorio_version
        }
    }
    $items
}

function Select-ReleaseForFactorio {
    param(
        $Releases,
        [string]$WantedFactorio
    )
    $matches = @($Releases | Where-Object {
        [string]$_.info_json.factorio_version -eq $WantedFactorio
    })
    if ($matches.Count -eq 0) { return $null }

    $best = $matches[0]
    foreach ($r in $matches) {
        if ((Compare-ModVersion $r.version $best.version) -gt 0) {
            $best = $r
        }
    }
    $best
}

function Expand-ModZip {
    param(
        [string]$ZipPath,
        [string]$DestDir,
        [string]$ExpectedModName
    )
    $staging = Join-Path $env:TEMP ("auf-oms-" + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $staging)
        $inner = Get-ChildItem -LiteralPath $staging -Directory | Select-Object -First 1
        if (-not $inner) {
            throw "Zip had no top-level folder: $ZipPath"
        }
        $infoPath = Join-Path $inner.FullName 'info.json'
        if (Test-Path -LiteralPath $infoPath) {
            $zipInfo = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json
            if ($ExpectedModName -and [string]$zipInfo.name -ne $ExpectedModName) {
                throw "Zip mod name '$($zipInfo.name)' does not match expected '$ExpectedModName'"
            }
        }
        if (Test-Path -LiteralPath $DestDir) {
            Remove-Item -LiteralPath $DestDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $DestDir) -Force | Out-Null
        Move-Item -LiteralPath $inner.FullName -Destination $DestDir
    }
    finally {
        if (Test-Path -LiteralPath $staging) {
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

$locals = @(Get-LocalMods -Dir $sourceRoot)
if ($Mods.Count -gt 0) {
    $wanted = @{}
    foreach ($m in $Mods) {
        foreach ($part in ($m -split ',')) {
            $n = $part.Trim()
            if ($n) { $wanted[$n.ToLowerInvariant()] = $true }
        }
    }
    $locals = @($locals | Where-Object { $wanted.ContainsKey($_.Name.ToLowerInvariant()) -or $wanted.ContainsKey($_.Folder.ToLowerInvariant()) })
    $missing = @($wanted.Keys | Where-Object {
        $key = $_
        -not ($locals | Where-Object { $_.Name.ToLowerInvariant() -eq $key -or $_.Folder.ToLowerInvariant() -eq $key })
    })
    # Allow requesting mods not yet present: synthesize entries
    foreach ($key in $missing) {
        $locals += [PSCustomObject]@{
            Folder          = $key
            FolderPath      = Join-Path $sourceRoot $key
            Name            = $key
            Version         = ''
            FactorioVersion = ''
        }
    }
}

if ($locals.Count -eq 0) {
    Write-Host "No mods found under $sourceRoot"
    exit 0
}

# Dedupe by mod name (prefer folder that already matches name)
$byName = @{}
foreach ($m in $locals) {
    $key = $m.Name.ToLowerInvariant()
    if (-not $byName.ContainsKey($key)) {
        $byName[$key] = $m
        continue
    }
    $existing = $byName[$key]
    if ($existing.Folder -ne $existing.Name -and $m.Folder -eq $m.Name) {
        $byName[$key] = $m
    }
}
$locals = @($byName.Values | Sort-Object Name)

Write-Host "Target Factorio version: $FactorioVersion"
Write-Host "Source dir: $sourceRoot"
Write-Host ("Mods: {0}" -f $locals.Count)
Write-Host ""

$creds = $null
if (-not $WhatIf -and -not $ListOnly) {
    $creds = Get-PortalCredentials -Path $PlayerDataPath
}

$updated = 0
$skipped = 0
$failed = 0
$results = @()

foreach ($mod in $locals) {
    $modName = $mod.Name
    Write-Host ("== {0} (local {1} / fv {2}) ==" -f $modName, $(if ($mod.Version) { $mod.Version } else { 'none' }), $(if ($mod.FactorioVersion) { $mod.FactorioVersion } else { '?' }))
    try {
        $api = Invoke-RestMethod -Uri ("https://mods.factorio.com/api/mods/{0}" -f [uri]::EscapeDataString($modName))
        $release = Select-ReleaseForFactorio -Releases $api.releases -WantedFactorio $FactorioVersion
        if (-not $release) {
            Write-Host "  skip: no release for factorio_version $FactorioVersion"
            $skipped++
            $results += [PSCustomObject]@{ Mod = $modName; Status = 'skip-no-release'; Local = $mod.Version; Remote = ''; Factorio = '' }
            continue
        }

        $remoteVer = [string]$release.version
        $remoteFv = [string]$release.info_json.factorio_version
        $versionSame = $mod.Version -and ((Compare-ModVersion $mod.Version $remoteVer) -eq 0)
        $folderOk = ($mod.Folder -eq $modName)
        if ($versionSame -and $folderOk -and -not $Force) {
            Write-Host "  up to date: $remoteVer (fv $remoteFv)"
            $skipped++
            $results += [PSCustomObject]@{ Mod = $modName; Status = 'up-to-date'; Local = $mod.Version; Remote = $remoteVer; Factorio = $remoteFv }
            continue
        }

        if ($versionSame -and -not $folderOk) {
            Write-Host ("  normalize folder {0} -> {1} (still {2})" -f $mod.Folder, $modName, $remoteVer)
        } else {
            Write-Host ("  remote: {0} (fv {1})  file: {2}" -f $remoteVer, $remoteFv, $release.file_name)
        }

        if ($ListOnly -or $WhatIf) {
            $status = if ($WhatIf) { 'would-update' } else { 'available' }
            $results += [PSCustomObject]@{ Mod = $modName; Status = $status; Local = $mod.Version; Remote = $remoteVer; Factorio = $remoteFv }
            if ($WhatIf) { $updated++ }
            continue
        }

        $userQ = [uri]::EscapeDataString($creds.Username)
        $tokenQ = [uri]::EscapeDataString($creds.Token)
        $url = "https://mods.factorio.com$($release.download_url)?username=$userQ&token=$tokenQ"
        $zipPath = Join-Path $env:TEMP $release.file_name
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

        $dest = Join-Path $sourceRoot $modName
        Expand-ModZip -ZipPath $zipPath -DestDir $dest -ExpectedModName $modName
        Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue

        # Remove leftover versioned / alternate folders for the same mod name
        Get-ChildItem -LiteralPath $sourceRoot -Directory | ForEach-Object {
            if ($_.FullName -eq $dest) { return }
            $otherInfo = Join-Path $_.FullName 'info.json'
            if (-not (Test-Path -LiteralPath $otherInfo)) { return }
            $other = Get-Content -Raw -LiteralPath $otherInfo | ConvertFrom-Json
            if ([string]$other.name -eq $modName) {
                Write-Host "  removing duplicate folder: $($_.Name)"
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
        }

        Write-Host "  updated -> $dest"
        $updated++
        $results += [PSCustomObject]@{ Mod = $modName; Status = 'updated'; Local = $mod.Version; Remote = $remoteVer; Factorio = $remoteFv }
    }
    catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
        $results += [PSCustomObject]@{ Mod = $modName; Status = 'failed'; Local = $mod.Version; Remote = ''; Factorio = '' }
    }
}

Write-Host ""
Write-Host ("Done. updated={0} skipped={1} failed={2}" -f $updated, $skipped, $failed)
$results | Format-Table -AutoSize

if ($failed -gt 0) { exit 1 }
