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

# An ingredient or result naming a prototype that does not exist fails validation just as
# hard as a missing category, and the recipe carries the blame rather than the line that
# added it. Only names we put in count: removing an ingredient that is not there is fine.
$ingredientPattern = 'type\s*=\s*["''](item|fluid)["'']\s*,\s*name\s*=\s*' + $quoted
$replacePattern = '(?:replace_ingredient|replace_result)\s*\(\s*' + $quoted + '\s*,\s*' + $quoted + '\s*\)'
$itemTypes = @('item', 'tool', 'module', 'capsule', 'ammo', 'gun', 'armor', 'item-with-entity-data', 'rail-planner', 'repair-tool')

# A category or subgroup belongs to whichever mod declared it, so a recipe of ours can be
# fine on every ingredient and still fail on the building it is crafted in.
$categoryPattern = '\bcategor(?:y|ies)\s*=\s*(?:\{([^}]*)\}|' + $quoted + ')'
$subgroupPattern = '\bsubgroup\s*=\s*' + $quoted

# A science pack added to a technology ends up in its unit ingredients, and one added to a
# lab in its inputs, so both have to name something real. Taking a pack away does not.
# A technology unit and some of the older helper calls write ingredients as a name and a
# count rather than a typed table, which is why the pattern above cannot see them.
$packPattern = '(?:add_pack|addscipack)\s*\(\s*' + $quoted
# A prerequisite is just a name in a list until the technology is validated, so pointing one
# at a technology from a mod that is not installed aborts the load the same way. Taking a
# prerequisite away does not, and add_unlock names a technology or a recipe depending on
# whether a recipe or a technology is on the left of it.
$prereqPattern = '(?:add_prereq|tech_add_prerequisites)\s*\(\s*' + $quoted
$unlockPattern = 'add_unlock\s*\(\s*' + $quoted
$labInputPattern = 'inputs\s*,\s*' + $quoted
$pairPattern = '\{\s*["'']([a-z][a-z0-9-]*)["'']\s*,\s*\d+\s*\}'
$packTypes = @('tool') + $itemTypes

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

function Expand-Deps([string[]]$mods) {
    $closed = [System.Collections.Generic.HashSet[string]]::new()
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($mod in $mods) { $queue.Enqueue($mod) }
    while ($queue.Count -gt 0) {
        $mod = $queue.Dequeue()
        if (-not $closed.Add($mod)) { continue }
        if ($upstreamDeps.ContainsKey($mod)) {
            foreach ($next in $upstreamDeps[$mod]) { $queue.Enqueue($next) }
        }
    }
    return , $closed
}

$hardDeps = Expand-Deps (Get-HardDeps (Get-Content (Join-Path $root 'info.json') -Raw | ConvertFrom-Json))

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
    'recipe|steel-plate',
    'item|advanced-circuit'
)

function Get-Indent([string]$line) {
    ($line -replace '\t', '    ') -match '^( *)' | Out-Null
    return $Matches[1].Length
}

# The conditions that must hold to reach a line, found by walking back through lines at
# smaller indentation rather than by parsing Lua blocks. The line itself is included so
# that a same-line "if data.raw.x['y'] then ..." counts as a guard.
function Get-Context([string[]]$lines, [int]$i) {
    $context = @($lines[$i])
    $indent = Get-Indent $lines[$i]
    for ($j = $i - 1; $j -ge 0; $j--) {
        $prev = $lines[$j]
        if ($prev -match '^\s*$' -or $prev -match '^\s*--') { continue }
        $prevIndent = Get-Indent $prev
        if ($prevIndent -ge $indent) { continue }
        # a condition can run over several lines, and the existence test we are looking for
        # is often on one of the continuation lines rather than beside the if
        if ($prev -match '^\s*(if|elseif)\b') {
            $context += $prev
            for ($k = $j; $k -lt $i -and $lines[$k] -notmatch '\bthen\b'; $k++) { $context += $lines[$k + 1] }
        }
        $indent = $prevIndent
        if ($indent -eq 0) { break }
    }
    return ($context -join "`n")
}

# Each Bob mod raises a flag on the shared bobmods table as it loads, and testing that flag
# is as good a guard as testing the mod list. Only the flags one mod alone can raise are
# listed: logistics is raised by boblogistics and by bobinserters, equipment by bobequipment
# and by bobvehicleequipment, so neither says which of the two is actually installed.
$bobFlags = @{
    assembly    = 'bobassembly'
    avatars     = 'bobclasses'
    classes     = 'bobclasses'
    electronics = 'bobelectronics'
    enemies     = 'bobenemies'
    gems        = 'bobores'
    greenhouse  = 'bobgreenhouse'
    inserters   = 'bobinserters'
    lib         = 'boblibrary'
    migration   = 'boblibrary'
    mining      = 'bobmining'
    modules     = 'bobmodules'
    ores        = 'bobores'
    plates      = 'bobplates'
    power       = 'bobpower'
    revamp      = 'bobrevamp'
    tech        = 'bobtech'
    warfare     = 'bobwarfare'
}

# Testing for a mod also proves everything that mod hard-depends on is present, which is
# what makes most of these guards adequate: pyalternativeenergy cannot load without
# pyalienlife, so a block behind it may use pyalienlife's prototypes freely.
function Get-GuardedMods([string]$context) {
    $named = @()
    foreach ($m in [regex]::Matches($context, 'mods\s*\[\s*["'']([^"'']+)["'']')) {
        $named += $m.Groups[1].Value
    }
    foreach ($m in [regex]::Matches($context, 'bobmods\.([a-z]+)')) {
        $flag = $m.Groups[1].Value
        if ($bobFlags.ContainsKey($flag)) { $named += $bobFlags[$flag] }
    }
    $mods = Expand-Deps $named
    # comma wrapped, otherwise PowerShell enumerates the set and an empty one returns null
    return , $mods
}

$ourFiles = Get-LuaFiles $root @("$upstreamRoot*", (Join-Path $root 'scripts*'))

# Most override files are pulled in by a parent that already tested for the mod, so a guard
# frequently lives in a different file from the line it protects. Follow require() to work
# out which mods every path to a file has already checked.
$requireEdges = @{}
foreach ($file in $ourFiles) {
    $rel = $file.FullName.Replace($root + '\', '')
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*--') { continue }
        foreach ($m in [regex]::Matches($lines[$i], 'require\s*\(?\s*["'']([^"'']+)["'']')) {
            $target = $m.Groups[1].Value -replace '^__AdminUnknownFixes__/', ''
            $target = ($target -replace '\.lua$', '') -replace '[./]', '\'
            if (-not $requireEdges.ContainsKey($rel)) { $requireEdges[$rel] = @() }
            $requireEdges[$rel] += [pscustomobject]@{
                Child = "$target.lua"
                Mods  = Get-GuardedMods (Get-Context $lines $i)
            }
        }
    }
}

# a file reached by several paths is only guaranteed the mods every one of them checked
$pathMods = @{}
function Walk-Requires([string]$rel, [System.Collections.Generic.HashSet[string]]$carried, [string[]]$seen) {
    if ($seen -contains $rel) { return }
    if (-not $pathMods.ContainsKey($rel)) { $pathMods[$rel] = @() }
    $pathMods[$rel] += , $carried
    foreach ($edge in $requireEdges[$rel]) {
        $next = [System.Collections.Generic.HashSet[string]]::new($carried)
        foreach ($mod in $edge.Mods) { [void]$next.Add($mod) }
        Walk-Requires $edge.Child $next ($seen + $rel)
    }
}
# every file the game itself loads, not just the data stage ones
$entryPoints = @('data.lua', 'data-updates.lua', 'data-final-fixes.lua', 'settings.lua',
    'settings-updates.lua', 'settings-final-fixes.lua', 'control.lua')
$entryPoints += $ourFiles |
    Where-Object { $_.FullName -match '\\(migrations|PyCoalTBaA-stub)\\' } |
    ForEach-Object { $_.FullName.Replace($root + '\', '') }
foreach ($entry in $entryPoints) {
    Walk-Requires $entry ([System.Collections.Generic.HashSet[string]]::new()) @()
}

$inheritedMods = @{}
foreach ($rel in $pathMods.Keys) {
    $sets = $pathMods[$rel]
    $common = [System.Collections.Generic.HashSet[string]]::new($sets[0])
    foreach ($set in $sets) { $common.IntersectWith($set) }
    $inheritedMods[$rel] = $common
}

$risky = @{}
$skipped = @{}
$unknown = @{}

$unreachable = @()

foreach ($file in $ourFiles) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $rel = $file.FullName.Replace($root + '\', '')
    # nothing requires it, so nothing in it can break a load however wrong it is
    if (-not $inheritedMods.ContainsKey($rel)) {
        $unreachable += $rel
        continue
    }
    $inherited = $inheritedMods[$rel]
    # Angel's recipe builder takes a list of alternatives and uses the first that exists,
    # so names that are absent are the whole point of the file rather than a mistake
    $fallbacks = [bool]($lines -match 'RB\.set_fallback')

    # a function that bails out at the top has tested the name just as surely as one that
    # wraps its body in the check, and the walker below only sees the wrapping kind
    $earlyReturns = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($line in $lines) {
        foreach ($m in [regex]::Matches($line, 'if\s+not\s+[^\r\n]*\[\s*["'']([^"'']+)["'']\s*\][^\r\n]*\breturn\b')) {
            [void]$earlyReturns.Add($m.Groups[1].Value)
        }
    }

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
        foreach ($m in [regex]::Matches($line, $ingredientPattern)) {
            $types = if ($m.Groups[1].Value -eq 'fluid') { @('fluid') } else { $itemTypes }
            $sites += [pscustomobject]@{ Types = $types; Name = $m.Groups[2].Value; Label = 'ingredient'; Crashes = $true }
        }
        foreach ($m in [regex]::Matches($line, $categoryPattern)) {
            $names = if ($m.Groups[1].Success) {
                [regex]::Matches($m.Groups[1].Value, $quoted) | ForEach-Object { $_.Groups[1].Value }
            }
            else { @($m.Groups[2].Value) }
            foreach ($name in $names) {
                $sites += [pscustomobject]@{
                    Types   = @('recipe-category', 'resource-category')
                    Name    = $name
                    Label   = 'category'
                    Crashes = $true
                }
            }
        }
        foreach ($m in [regex]::Matches($line, $packPattern)) {
            $sites += [pscustomobject]@{ Types = $packTypes; Name = $m.Groups[1].Value; Label = 'science pack'; Crashes = $true }
        }
        foreach ($m in [regex]::Matches($line, $prereqPattern)) {
            $sites += [pscustomobject]@{ Types = @('technology'); Name = $m.Groups[1].Value; Label = 'prerequisite'; Crashes = $true }
        }
        foreach ($m in [regex]::Matches($line, $unlockPattern)) {
            $sites += [pscustomobject]@{ Types = @('technology', 'recipe'); Name = $m.Groups[1].Value; Label = 'unlock'; Crashes = $true }
        }
        foreach ($m in [regex]::Matches($line, $labInputPattern)) {
            $sites += [pscustomobject]@{ Types = $packTypes; Name = $m.Groups[1].Value; Label = 'lab input'; Crashes = $true }
        }
        if (-not $fallbacks) {
            foreach ($m in [regex]::Matches($line, $pairPattern)) {
                $sites += [pscustomobject]@{ Types = $packTypes; Name = $m.Groups[1].Value; Label = 'name and count pair'; Crashes = $true }
            }
        }
        foreach ($m in [regex]::Matches($line, $subgroupPattern)) {
            $sites += [pscustomobject]@{ Types = @('item-subgroup'); Name = $m.Groups[1].Value; Label = 'subgroup'; Crashes = $true }
        }
        foreach ($m in [regex]::Matches($line, $replacePattern)) {
            $sites += [pscustomobject]@{
                Types   = $itemTypes + @('fluid')
                Name    = $m.Groups[2].Value
                Label   = 'replacement'
                Crashes = $true
            }
        }

        foreach ($site in $sites) {
            $name = $site.Name

            $context = Get-Context $lines $i
            $guarded = Get-GuardedMods $context
            if ($inherited) { foreach ($mod in $inherited) { [void]$guarded.Add($mod) } }

            # already tested for existence anywhere in the guard chain?
            if ($context -match ('\[\s*["'']' + [regex]::Escape($name) + '["'']\s*\]\s*(then|and|~=|==|\))')) { continue }
            if ($earlyReturns.Contains($name)) { continue }

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
            if (($owner | Where-Object { $guarded.Contains($_) })) { continue }

            $label = "$name (as $($site.Label)) - owned by " + (($owner | Sort-Object) -join ', ')
            $bucket = if ($site.Crashes) { $risky } else { $skipped }
            if (-not $bucket.ContainsKey($label)) { $bucket[$label] = @() }
            $bucket[$label] += $where
        }
    }
}

if ($unreachable) {
    Write-Host "`n=== skipped, nothing requires these files : $($unreachable.Count) ==="
    foreach ($rel in ($unreachable | Sort-Object)) { Write-Host "    $rel" }
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
