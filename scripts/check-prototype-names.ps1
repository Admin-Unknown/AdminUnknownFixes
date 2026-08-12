#Requires -Version 5.1
<#
.SYNOPSIS
    Report prototype names referenced by this mod that no longer exist in othermodsource.

.DESCRIPTION
    The 2.1 releases of Bob's and Angel's renamed a lot of prototypes, and a real load only
    reveals one stale name per crash. This compares names we reference against every quoted
    string in othermodsource, in three groups:

      names       quoted "bob-*"/"angels-*" strings anywhere in our Lua (broadest, noisiest)
      tech        TECHNOLOGY('x') arguments - pypostprocessing raises on an unknown technology
      index       data.raw.<type>['x'].field chains - indexing a missing prototype aborts the load
      category    recipe categories we assign - prototype validation rejects an unknown one
      ingredient  names we put in a recipe - these have to be an item or a fluid, specifically

    "names" and "tech" only ask whether some mod mentions the name. "index" is stricter and
    asks whether a prototype of that exact type exists, because data.raw.recipe['nitrogen']
    needs a recipe and is unmoved by pyrawores using a fluid of that name. A name counts as
    real if othermodsource defines it, if this mod defines it, or if an upstream mod reads it
    out of data.raw the same way - that last one stands in for the base game, whose prototypes
    are not in this folder.

    "category" is the same idea applied to recipe and crafting categories, which are
    prototypes in their own right: assigning a recipe to a category nothing defines fails
    validation at the end of the load rather than where the assignment happened.

    "ingredient" exists because a name can be real and still be the wrong sort of thing. Bob's
    red inserter is an entity built from the long handed inserter item, so bob-red-inserter
    resolves as an entity and as nothing else, and a recipe asking for one of them fails with
    "item with name 'bob-red-inserter' does not exist" - a report that reaches you through
    whichever mod happened to read the recipe rather than through the mod that wrote it.

    Only "tech", "index", "category" and "ingredient" hits can abort a load; "names" hits are usually a
    silently skipped override. A hit is a hint, not proof: names built by concatenation are invisible
    here, and othermodsource only holds the mods checked into this repo, so anything belonging
    to a mod that is not in that folder (angelsindustries, omni*, madclowns*, ...) always
    reports as missing.

.EXAMPLE
    pwsh ./scripts/check-prototype-names.ps1
    pwsh ./scripts/check-prototype-names.ps1 -Check tech,index
#>
param(
    [ValidateSet('names', 'tech', 'index', 'category', 'ingredient')]
    [string[]]$Check = @('names', 'tech', 'index', 'category', 'ingredient'),
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
    # A technology or recipe named in an unlock or prerequisite call has to exist for the
    # same reason TECHNOLOGY() does. Which of the two a name has to be depends on the
    # receiver, so the loose oracle below, which only asks whether upstream mentions the
    # name at all, is the right strength here: a renamed prototype is mentioned nowhere.
    tech  = '(?:TECHNOLOGY|Tech_create|add_prereq|remove_prereq|add_unlock|tech_add_recipe|tech_remove_recipe|tech_add_prerequisites|global_prereq_replacer)\s*\(\s*' + $quoted
    # Only the dereferenced form: a bare data.raw[...]['x'] read or assignment is harmless.
    index = 'data\.raw' + $typeAndName + '\s*\.'
}

# Fields whose value is the name of another prototype. Factorio resolves these when it
# validates prototypes, so a stale one fails the load pointing at the prototype that holds
# the field rather than at the code that set it. A field with more than one type listed is
# ambiguous out of context: category is a recipe category on a recipe and a resource
# category on an ore, and reporting only when neither exists keeps that from crying wolf.
$scalarFields = @{
    subgroup           = @('item-subgroup')
    group              = @('item-group')
    category           = @('recipe-category', 'resource-category', 'equipment-category')
    fuel_category      = @('fuel-category')
    resource_category  = @('resource-category')
    equipment_category = @('equipment-category')
    ammo_category      = @('ammo-category')
    damage_type        = @('damage-type')
}
$listFields = @{
    categories                = @('recipe-category')
    crafting_categories       = @('recipe-category')
    fuel_categories           = @('fuel-category')
    resource_categories       = @('resource-category')
    equipment_categories      = @('equipment-category')
    allowed_module_categories = @('module-category')
}

# a list written across several lines is missed; only same-line braces are read
$scalarPattern = '\b(' + (($scalarFields.Keys | Sort-Object) -join '|') + ')\s*=\s*' + $quoted
$listPattern = '\b(' + (($listFields.Keys | Sort-Object) -join '|') + ')\s*=\s*\{([^}]*)\}'
$categorySwap = 'replace_category\s*\(\s*' + $quoted + '\s*,\s*' + $quoted + '\s*\)'
# a category can also be pushed onto a machine after the fact. Bob's add_category checks the
# category exists and only logs if it does not, but a raw table.insert has no such guard.
$categoryPush = '(?:table\.insert\s*\([^,]*crafting_categories\s*,|add_category\s*\([^,]*,)\s*' + $quoted

function Get-FieldRefs([string]$line) {
    $refs = @()
    foreach ($m in [regex]::Matches($line, $scalarPattern)) {
        $field = $m.Groups[1].Value
        $refs += [pscustomobject]@{ Name = $m.Groups[2].Value; Types = $scalarFields[$field]; Field = $field }
    }
    foreach ($m in [regex]::Matches($line, $listPattern)) {
        $field = $m.Groups[1].Value
        foreach ($q in [regex]::Matches($m.Groups[2].Value, $quoted)) {
            $refs += [pscustomobject]@{ Name = $q.Groups[1].Value; Types = $listFields[$field]; Field = $field }
        }
    }
    foreach ($m in [regex]::Matches($line, $categorySwap)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[1].Value; Types = @('recipe-category'); Field = 'replace_category' }
        $refs += [pscustomobject]@{ Name = $m.Groups[2].Value; Types = @('recipe-category'); Field = 'replace_category' }
    }
    foreach ($m in [regex]::Matches($line, $categoryPush)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[1].Value; Types = @('recipe-category'); Field = 'crafting_categories' }
    }
    return $refs
}

# Every type an ingredient or a result is allowed to be. Anything else with the right name is
# the wrong sort of thing: an entity, a technology, a recipe category.
$itemTypes = @(
    'ammo', 'armor', 'blueprint', 'blueprint-book', 'capsule', 'copy-paste-tool',
    'deconstruction-item', 'gun', 'item', 'item-with-entity-data', 'item-with-inventory',
    'item-with-label', 'item-with-tags', 'mining-tool', 'module', 'rail-planner',
    'repair-tool', 'selection-tool', 'space-platform-starter-pack', 'spidertron-remote',
    'tool', 'upgrade-item'
)

# the table form, written either way round. Kept as two variables rather than one array
# because a comma binds tighter than a plus here, so the two would be concatenated into a
# single pattern and asking for the first of them would hand back its first character.
$ingredientTypeFirst = 'type\s*=\s*["''](item|fluid)["'']\s*,\s*name\s*=\s*' + $quoted
$ingredientNameFirst = 'name\s*=\s*' + $quoted + '\s*,\s*type\s*=\s*["''](item|fluid)["'']'
# the string form. Which of the two kinds it is depends on the recipe, so either will do.
$ingredientCalls = '(?::|\.)(?:remove_ingredient|remove_result|add_pack|remove_pack)\s*\(\s*' + $quoted
$ingredientSwap = '(?::|\.)replace_ingredient\s*\(\s*' + $quoted + '\s*,\s*' + $quoted
# fun.ingredient_replace(recipe, old, new), and the two beside it that read the same way. The
# recipe is the first argument and is not an ingredient, so it is stepped over.
$ingredientHelpers = 'fun\.(?:ingredient_replace|results_replacer)\s*\(\s*' + $quoted + '\s*,\s*' + $quoted + '\s*,\s*' + $quoted
$itemHelper = 'fun\.global_item_replacer\s*\(\s*' + $quoted + '\s*,\s*' + $quoted
# An upstream mod putting something in a cursor or a chest is naming an item just as surely as
# a recipe is, and for the base game's own items that is sometimes the only mention there is:
# red-wire is named nowhere upstream except a tips-and-tricks script that hands you one.
$stackForm = 'name\s*=\s*' + $quoted + '\s*,\s*count\s*='

function Get-IngredientRefs([string]$line) {
    $refs = @()
    foreach ($m in [regex]::Matches($line, $ingredientTypeFirst)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[2].Value; Kind = $m.Groups[1].Value }
    }
    foreach ($m in [regex]::Matches($line, $ingredientNameFirst)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[1].Value; Kind = $m.Groups[2].Value }
    }
    foreach ($m in [regex]::Matches($line, $ingredientCalls)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[1].Value; Kind = 'either' }
    }
    foreach ($m in [regex]::Matches($line, $ingredientSwap)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[1].Value; Kind = 'either' }
        $refs += [pscustomobject]@{ Name = $m.Groups[2].Value; Kind = 'either' }
    }
    foreach ($m in [regex]::Matches($line, $ingredientHelpers)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[2].Value; Kind = 'either' }
        $refs += [pscustomobject]@{ Name = $m.Groups[3].Value; Kind = 'either' }
    }
    foreach ($m in [regex]::Matches($line, $itemHelper)) {
        $refs += [pscustomobject]@{ Name = $m.Groups[1].Value; Kind = 'either' }
        $refs += [pscustomobject]@{ Name = $m.Groups[2].Value; Kind = 'either' }
    }
    return $refs
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
            # An ingredient is written the same way a prototype is, so {type = "item", name =
            # "bob-red-inserter", amount = 1} would otherwise be read as an item existing under
            # that name, and every name used in a recipe would vouch for itself. An amount is
            # what tells the two apart: prototypes do not carry one.
            if ($lines[$i] -match '\b(amount|amount_min|amount_max|probability|quantity)\s*=') { continue }

            # short prototypes such as Angel's recipe categories put type and name on one line
            $pair = [regex]::Match($lines[$i], 'type\s*=\s*' + $quoted + '\s*,\s*name\s*=\s*' + $quoted)
            if ($pair.Success) {
                $name = $pair.Groups[2].Value
                if (-not $definedTypes.ContainsKey($name)) {
                    $definedTypes[$name] = [System.Collections.Generic.HashSet[string]]::new()
                }
                [void]$definedTypes[$name].Add($pair.Groups[1].Value)
                continue
            }

            $d = [regex]::Match($lines[$i], '^\s*name\s*=\s*' + $quoted + '\s*,?\s*$')
            if (-not $d.Success) { continue }
            # the same ingredient table, written across several lines
            $spread = $false
            for ($k = $i + 1; $k -lt [Math]::Min($lines.Count, $i + 4); $k++) {
                if ($lines[$k] -match '^\s*(amount|amount_min|amount_max|probability|quantity)\s*=') { $spread = $true; break }
            }
            if ($spread) { continue }
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
$upstreamCategories = [System.Collections.Generic.HashSet[string]]::new()
$upstreamConsumables = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in $upstreamFiles) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    foreach ($m in [regex]::Matches($text, 'data\.raw' + $typeAndName)) {
        $type = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        [void]$upstreamReads.Add($type + '|' + $m.Groups[3].Value)
    }
    # base game names such as the crafting category or the raw-material subgroup are defined
    # outside this folder, so take an upstream mod using one as evidence that it exists
    # a dozen regexes against every line of every upstream mod takes minutes. Almost none of
    # those lines can match, and the two words below are in all the ones that can, so asking
    # the cheap question first turns most of those minutes into seconds.
    foreach ($line in ($text -split "`n")) {
        if ($line -notmatch 'name|categor|group|_type|ingredient|result|_pack') { continue }
        foreach ($ref in (Get-FieldRefs $line)) {
            foreach ($type in $ref.Types) { [void]$upstreamCategories.Add($type + '|' + $ref.Name) }
        }
        # an upstream mod putting a name in a recipe is proof that it is something a recipe can
        # ask for, which is the only evidence available for the base game's own items
        foreach ($ref in (Get-IngredientRefs $line)) { [void]$upstreamConsumables.Add($ref.Name) }
        foreach ($m in [regex]::Matches($line, $stackForm)) { [void]$upstreamConsumables.Add($m.Groups[1].Value) }
    }
}
foreach ($key in $upstreamReads) {
    $type, $name = $key -split '\|', 2
    if ($itemTypes -contains $type -or $type -eq 'fluid') { [void]$upstreamConsumables.Add($name) }
}
# The base game is not in othermodsource, so one of its items is only known here if some mod
# happens to mention it, and nearly all of them do. Green wire is the exception: not one mod
# in the folder names it, though several hand out a red one.
foreach ($name in @('green-wire')) { [void]$upstreamConsumables.Add($name) }

$exitCode = 0

foreach ($check in $Check) {
    $found = @{}
    foreach ($file in $ourFiles) {
        $lineNumber = 0
        $inBlockComment = $false
        foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
            $lineNumber++
            # a name only commented out is not a name the game ever resolves, and the worked
            # example of a recipe in functions.lua sits inside a block comment
            $line = [regex]::Replace($line, '--\[\[.*?\]\]', '')
            if ($inBlockComment) {
                if ($line -notmatch '\]\]') { continue }
                $inBlockComment = $false
                $line = $line -replace '^.*?\]\]', ''
            }
            if ($line -match '--\[\[') {
                $inBlockComment = $true
                $line = $line -replace '--\[\[.*$', ''
            }
            if ($line -match '^\s*--') { continue }
            if ($check -eq 'ingredient') {
                foreach ($ref in (Get-IngredientRefs $line)) {
                    $allowed = switch ($ref.Kind) {
                        'item'  { $itemTypes }
                        'fluid' { @('fluid') }
                        default { $itemTypes + @('fluid') }
                    }
                    $known = $false
                    if ($definedTypes.ContainsKey($ref.Name)) {
                        foreach ($type in $allowed) {
                            if ($definedTypes[$ref.Name].Contains($type)) { $known = $true; break }
                        }
                    }
                    # the base game's own items are not in othermodsource, so an upstream recipe
                    # asking for the name stands in for a definition we cannot see
                    if (-not $known -and $upstreamConsumables.Contains($ref.Name)) { $known = $true }
                    if ($known) { continue }

                    $label = "{0} (as {1})" -f $ref.Name, $(if ($ref.Kind -eq 'either') { 'an ingredient' } else { $ref.Kind })
                    if ($definedTypes.ContainsKey($ref.Name) -and $definedTypes[$ref.Name].Count -gt 0) {
                        $label += " - exists, but only as: " + (($definedTypes[$ref.Name] | Sort-Object) -join ', ')
                    }
                    if (-not $found.ContainsKey($label)) { $found[$label] = @() }
                    $found[$label] += ("{0}:{1}" -f $file.FullName.Replace($root + '\', ''), $lineNumber)
                }
                continue
            }

            if ($check -eq 'category') {
                foreach ($ref in (Get-FieldRefs $line)) {
                    $known = $false
                    foreach ($type in $ref.Types) {
                        if ($upstreamCategories.Contains($type + '|' + $ref.Name)) { $known = $true; break }
                        if ($definedTypes.ContainsKey($ref.Name) -and $definedTypes[$ref.Name].Contains($type)) { $known = $true; break }
                    }
                    if ($known) { continue }
                    $label = "{0} (as {1})" -f $ref.Name, ($ref.Types -join ' or ')
                    if (-not $found.ContainsKey($label)) { $found[$label] = @() }
                    $found[$label] += ("{0}:{1}" -f $file.FullName.Replace($root + '\', ''), $lineNumber)
                }
                continue
            }

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
