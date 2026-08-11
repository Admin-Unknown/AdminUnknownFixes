-- Global Item Replacer
-- Merges duplicate items between Angel's and Py mods by replacing
-- Angel's item/fluid names with Py equivalents across all recipes.

local dr = data.raw
local dri = dr.item
local drf = dr.fluid
local drr = dr.recipe

local function find_type(item)
    if dri[item] then return 'item' end
    if drf[item] then return 'fluid' end
    for prototype in pairs(defines.prototypes.item) do
        if dr[prototype] and dr[prototype][item] then return prototype end
    end
    return nil
end

local old_to_new = {}

local function global_item_replacer(old, new)
    if not find_type(old) or not find_type(new) then
        log('WARNING: global_item_replacer failed for ' .. tostring(old) .. ' -> ' .. tostring(new))
        return
    end
    old_to_new[old] = new
end

local function replace(product)
    if product[1] then
        product.name = product[1]
        product.amount = product[2]
        product.type = 'item'
        product[1] = nil
        product[2] = nil
    end
    local new = old_to_new[product.name]
    if new then
        product.name = new
        if drf[new] then product.type = 'fluid' end
    end
end

local function process_recipe(recipe)
    if recipe and recipe.ingredients and recipe.results then
        for _, ingredient in pairs(recipe.ingredients) do
            if old_to_new[ingredient.name or ingredient[1]] then replace(ingredient) end
        end
        for _, result in pairs(recipe.results) do
            if old_to_new[result.name or result[1]] then replace(result) end
        end
        if recipe.main_product and old_to_new[recipe.main_product] then
            recipe.main_product = old_to_new[recipe.main_product]
        end
    end
end

local function finalize()
    for name, recipe in pairs(drr) do
        process_recipe(recipe)
    end
end

local function building_item_replacer(old, new)
    if dri[old] ~= nil then
        if dri[new] ~= nil then
            local recipes = table.deepcopy(drr)
            for recipe in pairs(recipes) do
                fun.ingredient_replace(recipe, old, new)
                fun.results_replacer(recipe, old, new)
            end
        end
    end
end

----------------------------------------------------
-- ITEM REPLACEMENTS (Angel's 2.0 -> Py 2.0)
----------------------------------------------------
-- These mappings will be populated in Phase 5

-- Solids: Angel's angels-solid-* -> Py unprefixed
global_item_replacer('angels-solid-coke', 'coke')
global_item_replacer('angels-solid-limestone', 'limestone')
global_item_replacer('angels-solid-salt', 'salt')
global_item_replacer('angels-solid-sand', 'sand')
global_item_replacer('angels-solid-carbon', 'carbon')
global_item_replacer('angels-solid-lime', 'lime')
global_item_replacer('angels-solid-clay', 'clay')

-- Gases: Angel's angels-gas-* -> Py unprefixed
global_item_replacer('angels-gas-synthesis', 'syngas')
global_item_replacer('angels-gas-methanol', 'methanol')
global_item_replacer('angels-gas-carbon-dioxide', 'carbon-dioxide')
global_item_replacer('angels-gas-benzene', 'benzene')
global_item_replacer('angels-gas-propene', 'propene')
global_item_replacer('angels-gas-acetone', 'acetone')
global_item_replacer('angels-gas-methane', 'methane')
global_item_replacer('angels-gas-formaldehyde', 'methanal')
global_item_replacer('angels-gas-ammonia', 'ammonia')
global_item_replacer('angels-gas-epichlorohydrin', 'ech')
global_item_replacer('angels-gas-ethylene', 'ethylene')
global_item_replacer('angels-gas-chlor-methane', 'chloromethane')
global_item_replacer('angels-gas-hydrogen', 'hydrogen')
global_item_replacer('angels-gas-chlorine', 'chlorine')
global_item_replacer('angels-gas-oxygen', 'oxygen')
global_item_replacer('angels-gas-nitrogen', 'nitrogen')
global_item_replacer('angels-gas-hydrogen-chloride', 'hydrogen-chloride')

-- Liquids: Angel's angels-liquid-* -> Py unprefixed
global_item_replacer('angels-liquid-molten-aluminium', 'molten-aluminium')
global_item_replacer('angels-liquid-molten-copper', 'molten-copper')
global_item_replacer('angels-liquid-molten-iron', 'molten-iron')
global_item_replacer('angels-liquid-molten-lead', 'molten-lead')
global_item_replacer('angels-liquid-molten-silver', 'molten-silver')
global_item_replacer('angels-liquid-molten-nickel', 'molten-nickel')
global_item_replacer('angels-liquid-molten-steel', 'molten-steel')
global_item_replacer('angels-liquid-molten-tin', 'molten-tin')
global_item_replacer('angels-liquid-molten-titanium', 'molten-titanium')
global_item_replacer('angels-liquid-molten-zinc', 'molten-zinc')
global_item_replacer('angels-liquid-molten-chrome', 'molten-chromium')

-- Other Angel's liquids
global_item_replacer('angels-liquid-naphtha', 'naphtha')
global_item_replacer('angels-liquid-fuel-oil', 'fuel-oil')

-- Angel's solids -> Py items
global_item_replacer('angels-solid-sodium-chlorate', 'sodium-chlorate')
global_item_replacer('angels-solid-sodium-carbonate', 'sodium-carbonate')
global_item_replacer('angels-solid-sodium-hydroxide', 'sodium-hydroxide')
global_item_replacer('angels-solid-sodium-sulfate', 'sodium-sulfate')
global_item_replacer('angels-solid-fertilizer', 'fertilizer')
global_item_replacer('angels-solid-soil', 'soil')

-- Bob's electronics -> Py electronics
global_item_replacer('bob-phenolic-board', 'phenolicboard')
global_item_replacer('bob-fibreglass-board', 'fiberglass')
global_item_replacer('bob-wooden-board', 'fiberboard')
global_item_replacer('bob-superior-circuit-board', 'intelligent-unit')
global_item_replacer('bob-electronic-components', 'transistor')
global_item_replacer('bob-basic-electronic-components', 'resistor2')
global_item_replacer('bob-processing-electronics', 'kondo-processor')
global_item_replacer('bob-integrated-electronics', 'microchip')
global_item_replacer('bob-module-processor-board', 'pcb2')
global_item_replacer('bob-module-processor-board-2', 'pcb3')
global_item_replacer('bob-module-processor-board-3', 'pcb4')
global_item_replacer('bob-basic-circuit-board', 'pcb1')

-- Bob's items -> Py items
global_item_replacer('bob-tinned-copper-cable', 'tinned-cable')
global_item_replacer('bob-glass-fiber', 'angels-coil-glass-fiber')
global_item_replacer('bob-resin', 'saps')
global_item_replacer('bob-silicon-carbide', 'sic')

-- Angel's bio items -> Py items
global_item_replacer('angels-bio-raw-meat', 'meat')
global_item_replacer('angels-cellulose-fiber', 'cellulose')

-- Angel's misc -> Py
global_item_replacer('angels-quartz-crucible', 'quartz-crucible')
global_item_replacer('angels-mono-silicon', 'silicon')

-- Liquids misc
global_item_replacer('angels-liquid-black-liquor', 'black-liquor')
global_item_replacer('angels-liquid-acetic-acid', 'acetic-acid')
global_item_replacer('angels-liquid-glycerol', 'glycerol')
global_item_replacer('angels-gas-residual', 'residual-gas')

-- Angel's buildings -> Py buildings (item replacements in recipes)
global_item_replacer('angels-ore-floatation-cell', 'flotation-cell-mk01')
global_item_replacer('angels-ore-floatation-cell-2', 'flotation-cell-mk02')
global_item_replacer('angels-ore-floatation-cell-3', 'flotation-cell-mk03')
global_item_replacer('angels-ore-leaching-plant', 'leaching-station-mk01')
global_item_replacer('angels-ore-leaching-plant-2', 'leaching-station-mk02')
global_item_replacer('angels-ore-leaching-plant-3', 'leaching-station-mk03')
global_item_replacer('angels-filtration-unit', 'carbon-filter')
global_item_replacer('angels-filtration-unit-2', 'carbon-filter-mk02')
global_item_replacer('angels-filtration-unit-3', 'carbon-filter-mk03')
global_item_replacer('angels-barreling-pump', 'barrel-machine-mk01')

-- Bob's valves -> Py valves
global_item_replacer('bob-valve', 'py-check-valve')
global_item_replacer('bob-overflow-valve', 'py-overflow-valve')
global_item_replacer('bob-topup-valve', 'py-underflow-valve')

-- Bob's robot -> Py robot
global_item_replacer('bob-construction-robot', 'py-construction-robot-mk01')

-- Bob's centrifuges -> Py centrifuges
global_item_replacer('centrifuge', 'centrifuge-mk01')
global_item_replacer('bob-centrifuge-2', 'centrifuge-mk02')
global_item_replacer('bob-centrifuge-3', 'centrifuge-mk03')

-- Bob's batteries -> Py batteries
global_item_replacer('bob-battery-equipment', 'battery-mk01')
global_item_replacer('bob-battery-mk2-equipment', 'nexelit-battery')

-- Angel's petri dish
global_item_replacer('angels-petri-dish', 'petri-dish')

-- Angel's plates (keep Angel's names where Py doesn't have equivalents)
global_item_replacer('angels-plate-chrome', 'chromium')

-- Angel's ores -> Py ores
global_item_replacer('angels-bauxite-ore', 'ore-aluminium')
global_item_replacer('angels-chrome-ore', 'ore-chromium')
global_item_replacer('angels-lead-ore', 'ore-lead')
global_item_replacer('angels-nickel-ore', 'ore-nickel')
global_item_replacer('angels-tin-ore', 'ore-tin')
global_item_replacer('angels-zinc-ore', 'ore-zinc')

-- Angel's plates -> Py plates
global_item_replacer('bob-aluminium-plate', 'angels-plate-aluminium')
global_item_replacer('bob-lead-plate', 'angels-plate-lead')
global_item_replacer('bob-nickel-plate', 'angels-plate-nickel')
global_item_replacer('bob-tin-plate', 'angels-plate-tin')
global_item_replacer('bob-zinc-plate', 'angels-plate-zinc')

-- Bob's charcoal -> Py charcoal
global_item_replacer('bob-wood-charcoal', 'charcoal-briquette')

-- Angel's compressed air
global_item_replacer('angels-gas-compressed-air', 'pressured-air')

----------------------------------------------------
-- FINALIZE
----------------------------------------------------
finalize()

----------------------------------------------------
-- BUILDING REPLACEMENTS
----------------------------------------------------
building_item_replacer('angels-washing-plant', 'washer')
building_item_replacer('angels-washing-plant-2', 'washer-mk02')
building_item_replacer('angels-washing-plant-3', 'washer-mk03')
building_item_replacer('angels-washing-plant-4', 'washer-mk04')
