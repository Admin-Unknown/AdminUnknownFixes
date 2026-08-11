#Requires -Version 5.1
<#
.SYNOPSIS
    Suggest upstream replacements for prototype names this mod references but othermodsource
    does not define.

.DESCRIPTION
    Companion to check-prototype-names.ps1. That script says which names are unknown; this one
    proposes what they were renamed to, by looking for upstream names with the same tokens in
    any order or with a mod prefix added or removed, and reporting the mod and prototype type
    that defines each candidate. The owning mod is what makes a suggestion decidable: a name
    from bobplates is a safe replacement inside a bobplates-guarded block and a bad one anywhere
    else.

    Names with no candidate are almost always owned by a mod that is not checked into
    othermodsource (MoreSciencePacks, omni*, angelsindustries, Flow Control, ...) and are
    filtered out.

.EXAMPLE
    pwsh ./scripts/suggest-renames.ps1
    pwsh ./scripts/suggest-renames.ps1 -Filter player-
#>
param(
    [string]$Filter
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$upstreamRoot = Join-Path $root 'othermodsource'
if (-not (Test-Path $upstreamRoot)) { throw "Missing $upstreamRoot" }

$quoted = '["'']([A-Za-z0-9_%.\-]+)["'']'

$upstream = [System.Collections.Generic.HashSet[string]]::new()
$owner = @{}   # name -> "mod:type"
foreach ($file in (Get-ChildItem $upstreamRoot -Recurse -File -Include *.lua)) {
    $mod = $file.FullName.Substring($upstreamRoot.Length + 1).Split('\')[0]
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $recentType = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $t = [regex]::Match($line, 'type\s*=\s*' + $quoted)
        if ($t.Success) { $recentType = $t.Groups[1].Value }
        foreach ($m in [regex]::Matches($line, $quoted)) { [void]$upstream.Add($m.Groups[1].Value) }
        # a definition puts name on its own line; ingredients keep it inline
        $d = [regex]::Match($line, '^\s*name\s*=\s*' + $quoted + '\s*,?\s*$')
        if ($d.Success -and $recentType) {
            $key = $d.Groups[1].Value
            $value = "$mod/$recentType"
            if (-not $owner.ContainsKey($key)) { $owner[$key] = @() }
            if ($owner[$key] -notcontains $value) { $owner[$key] += $value }
        }
    }
}

$byTokens = @{}
foreach ($u in $upstream) {
    $k = (($u -split '-') | Sort-Object) -join '|'
    if (-not $byTokens.ContainsKey($k)) { $byTokens[$k] = @() }
    $byTokens[$k] += $u
}

$ourFiles = Get-ChildItem $root -Recurse -File -Include *.lua |
    Where-Object { $_.FullName -notlike "$upstreamRoot*" -and $_.FullName -notlike (Join-Path $root 'scripts*') }

$ourDefs = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in $ourFiles) {
    foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
        $d = [regex]::Match($line, '^\s*name\s*=\s*' + $quoted + '\s*,?\s*$')
        if ($d.Success) { [void]$ourDefs.Add($d.Groups[1].Value) }
    }
}

$callSite = 'TECHNOLOGY\(|RECIPE\(|ITEM\(|FLUID\(|data\.raw|fun\.|_replacer|add_unlock|remove_unlock|add_prereq|remove_prereq|add_pack|remove_pack|ingredient|result|add_category|set_to_py1'
$found = @{}
foreach ($file in $ourFiles) {
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
        $lineNumber++
        if ($line -notmatch $callSite) { continue }
        foreach ($m in [regex]::Matches($line, $quoted)) {
            $name = $m.Groups[1].Value
            if ($upstream.Contains($name) -or $ourDefs.Contains($name)) { continue }
            if ($name.Length -lt 4 -or $name -notmatch '-') { continue }
            if ($Filter -and $name -notlike "*$Filter*") { continue }
            if (-not $found.ContainsKey($name)) { $found[$name] = @() }
            $found[$name] += ("{0}:{1}" -f $file.FullName.Replace($root + '\', ''), $lineNumber)
        }
    }
}

$suggested = 0
foreach ($name in ($found.Keys | Sort-Object)) {
    $tokens = $name -split '-'
    $candidates = @()
    $key = ($tokens | Sort-Object) -join '|'
    if ($byTokens.ContainsKey($key)) { $candidates += $byTokens[$key] }
    if ($tokens.Count -gt 1) {
        $withoutFirst = ($tokens[1..($tokens.Count - 1)]) -join '-'
        if ($upstream.Contains($withoutFirst)) { $candidates += $withoutFirst }
        foreach ($prefix in 'bob-', 'angels-', 'py-') {
            if ($upstream.Contains($prefix + $name)) { $candidates += ($prefix + $name) }
        }
    }
    # a candidate is only useful if some mod actually defines a prototype by that name
    $candidates = @($candidates | Sort-Object -Unique | Where-Object { $owner.ContainsKey($_) -and $_ -ne $name })
    if ($candidates.Count -eq 0) { continue }

    $suggested++
    Write-Host $name
    foreach ($candidate in $candidates) {
        Write-Host ("    -> {0,-42} {1}" -f $candidate, (($owner[$candidate] | Sort-Object -Unique) -join ' '))
    }
    foreach ($where in ($found[$name] | Select-Object -Unique | Select-Object -First 4)) {
        Write-Host "       $where"
    }
}

Write-Host "`n$suggested of $($found.Count) unknown names have a candidate that some mod defines"
