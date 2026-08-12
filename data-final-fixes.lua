-- Restore global error() after pypostprocessing (see patch-pypp-impossible-research-validation.lua).
if _G.__auf_saved_global_error then
    local e = _G.__auf_saved_global_error
    _G.__auf_saved_global_error = nil
    _G.error = e
    ---@diagnostic disable-next-line: duplicate-set-field
    error = e
end

require('prototypes/compatibility/forgiving-data-extend')

-- Runs after pycoalprocessing's data-final-fixes (hard dependency). Whatever this
-- logs as rebound is a prototype some earlier final-fixes stripped the
-- pypostprocessing metatable from, which is what the stamps in data-updates cover.
local pypp_recipe_meta_guard = require('functions/pypp-recipe-meta-guard')
pypp_recipe_meta_guard.install()
pypp_recipe_meta_guard.heal()

--angel mods
require('prototypes/angels-mods/Data-Final-Fixes')

--aai
require('prototypes/aai/Data-fixes')

--bobs mods
require('prototypes/bobs-mods/Data-Final-Fixes')

--madclown mods
require('prototypes/madclowns-mods/data-fixes')

--msp
if mods['MoreSciencePacks-for1_1'] then
    require('prototypes/msp/Data-fixes')
end

--apm mods
require('prototypes/apm-mods/Data-Final-Fixes')

if mods['SeaBlockMetaPack'] then
    TECHNOLOGY('chemical-science-pack'):remove_prereq('advanced-circuit')
end

----------------------------------------------------
-- Debug logging
----------------------------------------------------
if settings.startup["debug-techcheck"] and settings.startup["debug-techcheck"].value then
    for _, tech in pairs(data.raw.technology) do
        if not tech.prerequisites then goto continue end
        for _, prereq in pairs(tech.prerequisites) do
            if not data.raw.technology[prereq] then
                log(tech.name .. " is missing prereq: " .. prereq)
                log(serpent.block(tech))
                goto continue
            end
        end
        ::continue::
    end
end

if settings.startup["log-technology"] and data.raw.technology[settings.startup["log-technology"].value] ~= nil then
    log(serpent.block(data.raw.technology[settings.startup["log-technology"].value]))
end

----------------------------------------------------
-- Global Item Replacer
----------------------------------------------------
require('prototypes/global-item-replacer')

-- After replacer may hide items used as minable results for vanilla upgradable assemblers (Factorio 2.0 vs next_upgrade).
require('prototypes/compatibility/fix-chemical-plant-next-upgrade')

----------------------------------------------------
-- Ingredient Deduplicator
----------------------------------------------------
require('prototypes/ingredient-deduplicator')

----------------------------------------------------
-- Icon fixes
----------------------------------------------------
if mods['pyhightech'] and mods['bobelectronics'] then
    if data.raw.item['electronic-circuit'] then
        data.raw.item['electronic-circuit'].icon_size = 64
        data.raw.item['electronic-circuit'].icon = "__pyhightechgraphics__/graphics/icons/circuit-board-1.png"
    end
    if data.raw.item['advanced-circuit'] then
        data.raw.item['advanced-circuit'].icon_size = 64
        data.raw.item['advanced-circuit'].icon = "__pyhightechgraphics__/graphics/icons/circuit-board-2.png"
    end
    if data.raw.item['processing-unit'] then
        data.raw.item['processing-unit'].icon_size = 64
        data.raw.item['processing-unit'].icon = "__pyhightechgraphics__/graphics/icons/circuit-board-3.png"
    end
    if data.raw.item['intelligent-unit'] then
        -- pyhightechgraphics intelligent-unit.png is 32x32; 64 here triggers Factorio sprite bounds error.
        data.raw.item['intelligent-unit'].icon_size = 32
        data.raw.item['intelligent-unit'].icon = "__pyhightechgraphics__/graphics/icons/intelligent-unit.png"
    end
end

----------------------------------------------------
-- MERGED FROM bobsmodules4py: Bob's Modules compat
----------------------------------------------------
if mods['bobmodules'] then
    require('prototypes/bobs-mods/bobmodules-compat')
end

-- After all other final-fixes: ensure bob-lab-2 accepts every pack used by Bob gold + alien bullet-line techs.
require("prototypes/compatibility/fix-bob-lab2-research-inputs")

-- Last pass over the upgrade chains, once every mod has finished resizing things.
require("prototypes/compatibility/fix-mismatched-next-upgrade")

-- Once every mod has finished adding results to each other's recipes. The shapes go first:
-- the icon pass reads the results of every recipe, and the mods that load after this one
-- still have their final-fixes to run.
-- Every item and every fluid there will be is in the game by now, which is the one point at
-- which an entry asking for an item as though it were a fluid can be told apart from one
-- asking for something a later mod was going to add.
require('prototypes/compatibility/normalise-recipe-items'){ correct_types = true }
require("prototypes/compatibility/fix-missing-recipe-icons")

-- Same idea for the technology tree, once every mod has finished rearranging it. The science
-- packs come after the bob-lab-2 fix above, so that anything it hands the lab is checked too.
require("prototypes/compatibility/fix-missing-science-packs")
require("prototypes/compatibility/fix-mine-entity-triggers")
require("prototypes/compatibility/break-technology-cycles")

-- Last thing we do: the helper stamps from data-updates have served their purpose
-- and Factorio cannot serialise a function field ("Cannot serialise ttype=function").
pypp_recipe_meta_guard.heal()
pypp_recipe_meta_guard.strip_function_fields()
