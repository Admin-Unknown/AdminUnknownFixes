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
      index   data.raw.<type>['x'].field chains - indexing a missing prototype aborts the load

    "names" and "tech" only ask whether some mod mentions the name. "index" is stricter and
    asks whether a prototype of that exact type exists, because data.raw.recipe['nitrogen']
    needs a recipe and is unmoved by pyrawores using a fluid of that name. A name counts as
    real if othermodsource defines it, if this mod defines it, or if an upstream mod reads it
    out of data.raw the same way - that last one stands in for the base game, whose prototypes
    are not in this folder.

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
$typeAndName = '(?:\.([A-Za-z_][A-Za-z0-9_]*)|\[\s*["'']([^"'']+)["'']\s*\])\s*\[\s*' + $quoted + '\s*\]'
$patterns = @{
    names = '["'']((?:' + (($Prefixes | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')[A-Za-z0-9_%.\-]*)["'']'
    tech  = 'TECHNOLOGY\s*\(\s*' + $quoted
    # Only the dereferenced form: a bare data.raw[...]['x'] read or assignment is harmless.
    index = 'data\.raw' + $typeAndName + '\s*\.'
}

function Get-LuaFiles([string]$path, [string[]]$exclude) {
    Get-ChildItem -Path $path -Recurse -File -Include *.lua | Where-Object {
        $file = $_
        -not ($exclude | Where-Object { $file.FullName -like $_ })
    }
}

$upstreamFiles = Get-LuaFiles $upstreamRoot @()
$ourFiles = Get-LuaFiles $root @("$upstreamRoot*", (Join-Path $root 'scripts*'))

# every quoted string upstream, for the loose "does anyone mention this" checks
$upstream = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in $upstreamFiles) {
    foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($file.FullName), $quoted)) {
        [void]$upstream.Add($m.Groups[1].Value)
    }
}

# name -> types it is defined as. A definition puts name alone on its line; the type sits
# just above or just below it, so accept either and err towards too many types rather than
# too few, since a missed type reads as a false alarm.
$definedTypes = @{}
function Add-Definitions([System.IO.FileInfo[]]$files) {
    foreach ($file in $files) {
        $lines = [System.IO.File]::ReadAllLines($file.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $d = [regex]::Match($lines[$i], '^\s*name\s*=\s*' + $quoted + '\s*,?\s*$')
            if (-not $d.Success) { continue }
            $name = $d.Groups[1].Value
            if (-not $definedTypes.ContainsKey($name)) {
                $definedTypes[$name] = [System.Collections.Generic.HashSet[string]]::new()
            }
            for ($j = [Math]::Max(0, $i - 6); $j -lt [Math]::Min($lines.Count, $i + 6); $j++) {
                $t = [regex]::Match($lines[$j], '^\s*type\s*=\s*' + $quoted)
                if ($t.Success) { [void]$definedTypes[$name].Add($t.Groups[1].Value) }
            }
        }
    }
}
Add-Definitions $upstreamFiles
Add-Definitions $ourFiles

# base game prototypes are not in othermodsource, so treat "an upstream mod reads
# data.raw.<type>['x'] too" as proof that x exists with that type
$upstreamReads = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in $upstreamFiles) {
    foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($file.FullName), 'data\.raw' + $typeAndName)) {
        $type = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        [void]$upstreamReads.Add($type + '|' + $m.Groups[3].Value)
    }
}

$exitCode = 0

foreach ($check in $Check) {
    $found = @{}
    foreach ($file in $ourFiles) {
        $lineNumber = 0
        foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
            $lineNumber++
            foreach ($m in [regex]::Matches($line, $patterns[$check])) {
                if ($check -eq 'index') {
                    $type = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
                    $name = $m.Groups[3].Value
                    if ($upstreamReads.Contains($type + '|' + $name)) { continue }
                    if ($definedTypes.ContainsKey($name) -and $definedTypes[$name].Contains($type)) { continue }
                    $label = "$name (as $type)"
                    if ($definedTypes.ContainsKey($name)) {
                        $label += " - defined only as: " + (($definedTypes[$name] | Sort-Object) -join ', ')
                    }
                } else {
                    $name = $m.Groups[1].Value
                    if ($upstream.Contains($name)) { continue }
                    $label = $name
                }
                if (-not $found.ContainsKey($label)) { $found[$label] = @() }
                $found[$label] += ("{0}:{1}" -f $file.FullName.Replace($root + '\', ''), $lineNumber)
            }
        }
    }

    Write-Host "`n=== $check : $($found.Count) unknown name(s) ==="
    foreach ($label in ($found.Keys | Sort-Object)) {
        Write-Host $label
        foreach ($where in ($found[$label] | Select-Object -Unique | Select-Object -First 6)) {
            Write-Host "    $where"
        }
    }
    if ($found.Count -gt 0 -and $check -ne 'names') { $exitCode = 1 }
}

exit $exitCode
