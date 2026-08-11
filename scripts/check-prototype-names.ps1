#Requires -Version 5.1
<#
.SYNOPSIS
    Report prototype names referenced by this mod that no longer exist in othermodsource.

.DESCRIPTION
    The 2.1 releases of Bob's and Angel's renamed a lot of prototypes, and a real load only
    reveals one stale name per crash. This compares names we reference against every quoted
    string in othermodsource, in three groups:

      names   quoted "bob-*"/"angels-*" strings anywhere in our Lua (broadest, noisiest)
      tech    TECHNOLOGY('x') arguments - pypostprocessing raises on an unknown technology
      index   data.raw[...]['x'].field chains - indexing a missing prototype aborts the load

    Only "tech" and "index" hits can abort a load; "names" hits are usually a silently
    skipped override. A hit is a hint, not proof: names built by concatenation are invisible
    here, and othermodsource only holds the mods checked into this repo, so anything belonging
    to a mod that is not in that folder (angelsindustries, omni*, madclowns*, ...) always
    reports as missing.

.EXAMPLE
    pwsh ./scripts/check-prototype-names.ps1
    pwsh ./scripts/check-prototype-names.ps1 -Check tech,index
#>
param(
    [ValidateSet('names', 'tech', 'index')]
    [string[]]$Check = @('names', 'tech', 'index'),
    [string[]]$Prefixes = @('bob-', 'angels-')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$upstreamRoot = Join-Path $root 'othermodsource'
if (-not (Test-Path $upstreamRoot)) { throw "Missing $upstreamRoot" }

$quoted = '["'']([A-Za-z0-9_%.\-]+)["'']'
$patterns = @{
    names = '["'']((?:' + (($Prefixes | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')[A-Za-z0-9_%.\-]*)["'']'
    tech  = 'TECHNOLOGY\s*\(\s*' + $quoted
    # Only the dereferenced form: a bare data.raw[...]['x'] read or assignment is harmless.
    index = 'data\.raw(?:\.[A-Za-z_]+|\s*\[\s*["''][^"'']+["'']\s*\])\s*\[\s*' + $quoted + '\s*\]\s*\.'
}

function Get-LuaFiles([string]$path, [string[]]$exclude) {
    Get-ChildItem -Path $path -Recurse -File -Include *.lua | Where-Object {
        $file = $_
        -not ($exclude | Where-Object { $file.FullName -like $_ })
    }
}

$upstream = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in (Get-LuaFiles $upstreamRoot @())) {
    foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($file.FullName), $quoted)) {
        [void]$upstream.Add($m.Groups[1].Value)
    }
}

$ourFiles = Get-LuaFiles $root @("$upstreamRoot*", (Join-Path $root 'scripts*'))
$exitCode = 0

foreach ($check in $Check) {
    $found = @{}
    foreach ($file in $ourFiles) {
        $lineNumber = 0
        foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
            $lineNumber++
            foreach ($m in [regex]::Matches($line, $patterns[$check])) {
                $name = $m.Groups[1].Value
                if ($upstream.Contains($name)) { continue }
                if (-not $found.ContainsKey($name)) { $found[$name] = @() }
                $found[$name] += ("{0}:{1}" -f $file.FullName.Replace($root + '\', ''), $lineNumber)
            }
        }
    }

    Write-Host "`n=== $check : $($found.Count) unknown name(s) ==="
    foreach ($name in ($found.Keys | Sort-Object)) {
        Write-Host $name
        foreach ($where in ($found[$name] | Select-Object -Unique | Select-Object -First 6)) {
            Write-Host "    $where"
        }
    }
    if ($found.Count -gt 0 -and $check -ne 'names') { $exitCode = 1 }
}

exit $exitCode
