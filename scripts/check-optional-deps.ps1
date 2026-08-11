<#
.SYNOPSIS
    Find prototype dereferences that crash when an optional dependency is absent.

.DESCRIPTION
    A correct name is not enough. data.raw.recipe['nitrogen'].hidden = false is spelled
    right, but the recipe belongs to pyrawores, so it is nil in any game without pyrawores
    and the assignment aborts the load. check-prototype-names.ps1 cannot see this, because
    the name really does exist in othermodsource.

    So this walks it from the other end: for every data.raw.<type>['name'].field write in
    our Lua, work out which mod defines that prototype, then ask whether reaching the line
    requires that mod to be present. A line is safe when the owning mod is a hard dependency
    in info.json, when an enclosing if tests mods['<owner>'], or when something already
    tests the prototype itself for existence.

    Results split by what actually happens when the mod is missing, because pypp's helpers
    disagree: a missing TECHNOLOGY() or FLUID() aborts the load, while a missing RECIPE()
    quietly swallows the whole call chain and only costs you the override.

    Two blind spots. Enclosing conditions are found by indentation rather than by parsing
    Lua blocks, so a file with irregular formatting can report a guarded line as unguarded;
    verify before editing. And a name held in a variable is invisible here, so a loop over
    a table of prototype names is never checked no matter how it is written.

    Prototypes belonging to a mod outside othermodsource land in a separate "unknown owner"
    list, which is worth a skim but is mostly optional-mod noise.

.EXAMPLE
    pwsh ./scripts/check-optional-deps.ps1
    pwsh ./scripts/check-optional-deps.ps1 -IncludeUnknownOwner
#>
param(
    [switch]$IncludeUnknownOwner
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$upstreamRoot = Join-Path $root 'othermodsource'
if (-not (Test-Path $upstreamRoot)) { throw "Missing $upstreamRoot" }

$quoted = '["'']([A-Za-z0-9_%.\-]+)["'']'
$derefPattern = 'data\.raw(?:\.([A-Za-z_][A-Za-z0-9_]*)|\[\s*["'']([^"'']+)["'']\s*\])\s*\[\s*' + $quoted + '\s*\]\s*\.'
# pypp's helpers disagree about missing prototypes: TECHNOLOGY() and FLUID() call error(),
# ITEM() returns nil so the chained call dies, but RECIPE() hands back a black-hole dummy
# that swallows the whole chain. A missing recipe is therefore a silently skipped override
# rather than a crash, which is worth reporting separately.
$helperPattern = '\b(TECHNOLOGY|RECIPE|FLUID|ITEM)\s*\(\s*' + $quoted + '\s*\)'
$helperTypes = @{
    TECHNOLOGY = @('technology')
    RECIPE     = @('recipe')
    FLUID      = @('fluid')
    ITEM       = @('item', 'tool', 'module', 'capsule', 'ammo', 'gun', 'armor', 'item-with-entity-data', 'rail-planner', 'repair-tool')
}
$noopHelpers = @('RECIPE')

function Get-LuaFiles([string]$path, [string[]]$exclude) {
    Get-ChildItem -Path $path -Recurse -File -Include *.lua | Where-Object {
        $file = $_
        -not ($exclude | Where-Object { $file.FullName -like $_ })
    }
}

function Get-HardDeps($info) {
    $result = @()
    foreach ($dep in $info.dependencies) {
        if ($dep -match '^\s*[?!(]') { continue }
        $name = ($dep -replace '^\s*~?\s*', '') -split '\s+' | Select-Object -First 1
        if ($name) { $result += $name }
    }
    return $result
}

# a hard dependency is always present, and so is anything it hard-depends on in turn:
# pyindustry never needs a guard because pycoalprocessing drags it in
$upstreamDeps = @{}
foreach ($modInfo in (Get-ChildItem -Path $upstreamRoot -Recurse -Depth 1 -Filter 'info.json' -File)) {
    try { $parsed = Get-Content $modInfo.FullName -Raw | ConvertFrom-Json } catch { continue }
    if ($parsed.name) { $upstreamDeps[$parsed.name] = Get-HardDeps $parsed }
}

$hardDeps = [System.Collections.Generic.HashSet[string]]::new()
$queue = [System.Collections.Generic.Queue[string]]::new()
foreach ($dep in (Get-HardDeps (Get-Content (Join-Path $root 'info.json') -Raw | ConvertFrom-Json))) { $queue.Enqueue($dep) }
while ($queue.Count -gt 0) {
    $dep = $queue.Dequeue()
    if (-not $hardDeps.Add($dep)) { continue }
    if ($upstreamDeps.ContainsKey($dep)) {
        foreach ($next in $upstreamDeps[$dep]) { $queue.Enqueue($next) }
    }
}

# "type|name" -> mods defining it
$owners = @{}
foreach ($modDir in (Get-ChildItem -Path $upstreamRoot -Directory)) {
    foreach ($file in (Get-LuaFiles $modDir.FullName @())) {
        $lines = [System.IO.File]::ReadAllLines($file.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $d = [regex]::Match($lines[$i], '^\s*name\s*=\s*' + $quoted + '\s*,?\s*$')
            if (-not $d.Success) { continue }
            for ($j = [Math]::Max(0, $i - 6); $j -lt [Math]::Min($lines.Count, $i + 6); $j++) {
                $t = [regex]::Match($lines[$j], '^\s*type\s*=\s*' + $quoted)
                if (-not $t.Success) { continue }
                $key = $t.Groups[1].Value + '|' + $d.Groups[1].Value
                if (-not $owners.ContainsKey($key)) {
                    $owners[$key] = [System.Collections.Generic.HashSet[string]]::new()
                }
                [void]$owners[$key].Add($modDir.Name)
            }
        }
    }
}

# Base game prototypes are not in othermodsource, so one that a mod merely redefines looks
# like it belongs to that mod. Add names here as they surface rather than guarding a
# prototype the base game guarantees.
$baseGame = @(
    'recipe|steel-plate'
)

function Get-Indent([string]$line) {
    ($line -replace '\t', '    ') -match '^( *)' | Out-Null
    return $Matches[1].Length
}

$risky = @{}
$skipped = @{}
$unknown = @{}

foreach ($file in (Get-LuaFiles $root @("$upstreamRoot*", (Join-Path $root 'scripts*')))) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $rel = $file.FullName.Replace($root + '\', '')

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*--') { continue }

        $sites = @()
        foreach ($m in [regex]::Matches($line, $derefPattern)) {
            $type = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
            $sites += [pscustomobject]@{ Types = @($type); Name = $m.Groups[3].Value; Label = $type; Crashes = $true }
        }
        foreach ($m in [regex]::Matches($line, $helperPattern)) {
            $helper = $m.Groups[1].Value
            $sites += [pscustomobject]@{
                Types   = $helperTypes[$helper]
                Name    = $m.Groups[2].Value
                Label   = "$helper()"
                Crashes = $helper -notin $noopHelpers
            }
        }

        foreach ($site in $sites) {
            $name = $site.Name

            # collect the conditions that must hold to reach this line, plus the line itself
            # so that a same-line "if data.raw.x['y'] then ..." counts as a guard
            $context = @($line)
            $indent = Get-Indent $line
            for ($j = $i - 1; $j -ge 0; $j--) {
                $prev = $lines[$j]
                if ($prev -match '^\s*$' -or $prev -match '^\s*--') { continue }
                $prevIndent = Get-Indent $prev
                if ($prevIndent -ge $indent) { continue }
                if ($prev -match '^\s*(if|elseif)\b') { $context += $prev }
                $indent = $prevIndent
                if ($indent -eq 0) { break }
            }
            $context = $context -join "`n"

            # already tested for existence anywhere in the guard chain?
            if ($context -match ('\[\s*["'']' + [regex]::Escape($name) + '["'']\s*\]\s*(then|and|~=|==|\))')) { continue }

            $where = "{0}:{1}" -f $rel, ($i + 1)
            if (($site.Types | ForEach-Object { $_ + '|' + $name }) | Where-Object { $baseGame -contains $_ }) { continue }
            $owner = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($type in $site.Types) {
                if ($owners.ContainsKey($type + '|' + $name)) {
                    foreach ($mod in $owners[$type + '|' + $name]) { [void]$owner.Add($mod) }
                }
            }

            if ($owner.Count -eq 0) {
                $key = $site.Label + '|' + $name
                if (-not $unknown.ContainsKey($key)) { $unknown[$key] = @() }
                $unknown[$key] += $where
                continue
            }
            if (($owner | Where-Object { $hardDeps.Contains($_) })) { continue }
            if (($owner | Where-Object { $context -match ("mods\s*\[\s*[""']" + [regex]::Escape($_) + "[""']") })) { continue }

            $label = "$name (as $($site.Label)) - owned by " + (($owner | Sort-Object) -join ', ')
            $bucket = if ($site.Crashes) { $risky } else { $skipped }
            if (-not $bucket.ContainsKey($label)) { $bucket[$label] = @() }
            $bucket[$label] += $where
        }
    }
}

Write-Host "`n=== aborts the load when the owning mod is absent : $($risky.Count) ==="
foreach ($label in ($risky.Keys | Sort-Object)) {
    Write-Host $label
    foreach ($site in ($risky[$label] | Select-Object -Unique)) { Write-Host "    $site" }
}

Write-Host "`n=== override silently does nothing when the owning mod is absent : $($skipped.Count) ==="
foreach ($label in ($skipped.Keys | Sort-Object)) {
    Write-Host $label
    foreach ($site in ($skipped[$label] | Select-Object -Unique)) { Write-Host "    $site" }
}

if ($IncludeUnknownOwner) {
    Write-Host "`n=== unguarded, owner not in othermodsource : $($unknown.Count) ==="
    foreach ($key in ($unknown.Keys | Sort-Object)) {
        Write-Host $key
        foreach ($site in ($unknown[$key] | Select-Object -Unique)) { Write-Host "    $site" }
    }
}

exit ([int]($risky.Count -gt 0))
