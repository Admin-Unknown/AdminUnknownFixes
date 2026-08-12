require('prototypes/compatibility/forgiving-data-extend')

--angel mods
require('prototypes/angels-mods/Data-Updates')

--aai
require('prototypes/aai/Data-updates')

--bob mods
require('prototypes/bobs-mods/Data-Updates')

--madclown mods
require('prototypes/madclowns-mods/data-updates')

--omni mods
--require('prototypes/omni-mods/Data-updates')

--msp
if mods['MoreSciencePacks-for1_1'] then
	require('prototypes/msp/Data-updates')
end

--apm mods
require('prototypes/apm-mods/Data-Updates')

----------------------------------------------------
-- Underground belt scaling
----------------------------------------------------
if mods['boblogistics'] then
    local function set_underground_recipe(underground, belt, prev_underground, prev_belt)
        if not data.raw['underground-belt'][underground] then return end
        local dist = data.raw['underground-belt'][underground].max_distance + 1
        local prev_dist = 0

        if prev_underground and data.raw['underground-belt'][prev_underground] then
            prev_dist = data.raw['underground-belt'][prev_underground].max_distance + 1
            local recipe_data = data.raw.recipe[belt]
            if recipe_data and recipe_data.results then
                local belt_count = recipe_data.results[1] and recipe_data.results[1].amount or 1
                for _, ing in pairs(recipe_data.ingredients or {}) do
                    if ing.name ~= prev_belt then
                        RECIPE(underground):remove_ingredient(ing.name)
                            :add_ingredient{type = ing.type, name = ing.name, amount = ing.amount * prev_dist / belt_count}
                    end
                end
            end
        end

        RECIPE(underground):remove_ingredient(belt):add_ingredient{type = "item", name = belt, amount = dist - prev_dist}
    end

    set_underground_recipe("bob-basic-underground-belt", "bob-basic-transport-belt", nil, nil)
    set_underground_recipe("underground-belt", "transport-belt", "bob-basic-underground-belt", "bob-basic-transport-belt")
    set_underground_recipe("fast-underground-belt", "fast-transport-belt", "underground-belt", "transport-belt")
    set_underground_recipe("express-underground-belt", "express-transport-belt", "fast-underground-belt", "fast-transport-belt")
    set_underground_recipe("turbo-underground-belt", "turbo-transport-belt", "express-underground-belt", "express-transport-belt")
    set_underground_recipe("bob-ultimate-underground-belt", "bob-ultimate-transport-belt", "turbo-underground-belt", "turbo-transport-belt")
end

-- Load-order fallback: suppress pypp impossible-to-research (hidden prerequisite) check until our data-final-fixes.
require("functions/patch-pypp-impossible-research-validation")

-- Same pass as at the end of our data.lua, for whatever this stage wrote. Every mod's
-- data-final-fixes is still to come, and Angel's walks all the recipes again in theirs.
require('prototypes/compatibility/normalise-recipe-items')()

-- In case Angel's had not put its override table out yet when our data.lua ran.
require('prototypes/compatibility/tidy-recipes-before-angels-walks')

-- Last point we control before any data-final-fixes runs, so this is where the
-- recipe helpers have to be made safe for every mod that final-fixes ahead of us
-- (pycoalprocessing calls recipe:has_category on all of them). The stamps are
-- removed again at the end of our own data-final-fixes.
local pypp_recipe_meta_guard = require("functions/pypp-recipe-meta-guard")
pypp_recipe_meta_guard.install()
pypp_recipe_meta_guard.heal()
pypp_recipe_meta_guard.stamp_recipes()
