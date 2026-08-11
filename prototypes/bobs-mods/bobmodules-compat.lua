-- Bob's Modules 4 Pyanodons compatibility (merged from bobsmodules4py)
-- Integrates Bob's modules into the Py suite

-- PyPP TECHNOLOGY() errors if the prototype is missing (Bob's 2.0 removed/renamed several of these).
local function with_tech(name, fn)
    if data.raw.technology[name] then
        fn(TECHNOLOGY(name))
    end
end

local function set_module_effect(name, effect)
    local m = data.raw.module[name]
    if m then
        m.effect = effect
    end
end

local function set_recipe_ingredients(name, ingredients)
    local r = data.raw.recipe[name]
    if r then
        r.ingredients = ingredients
    end
end

-- Tech fixes (Bob modules 3.0: dead names like module-merging / basic-electronics / unprefixed pollution techs removed)
with_tech('effect-transmission-2', function(t) t:remove_prereq('advanced-electronics-2') end)
with_tech('speed-module-2', function(t) t:remove_prereq('advanced-circuit'):remove_prereq('machine-components-mk03') end)
with_tech('efficiency-module-2', function(t) t:remove_prereq('advanced-circuit'):remove_prereq('machine-components-mk03') end)
with_tech('productivity-module-2', function(t) t:remove_prereq('advanced-circuit'):remove_prereq('machine-components-mk03') end)
with_tech('speed-module-3', function(t) t:remove_prereq('nano-tech'):remove_prereq('machine-components-mk04') end)
with_tech('efficiency-module-3', function(t) t:remove_prereq('nano-tech'):remove_prereq('machine-components-mk04') end)
with_tech('productivity-module-3', function(t) t:remove_prereq('nano-tech'):remove_prereq('machine-components-mk04') end)

-- Module tech costs: scale down since ModulesLab was removed in 2.0
if data.raw.technology["speed-module-2"] then
    bobmods.lib.tech.remove_science_pack("speed-module-2", "chemical-science-pack")
    bobmods.lib.tech.set_science_pack_count("speed-module-2", 100)
end
if data.raw.technology["speed-module-3"] then
    bobmods.lib.tech.remove_science_pack("speed-module-3", "production-science-pack")
    bobmods.lib.tech.set_science_pack_count("speed-module-3", 150)
end
if data.raw.technology["efficiency-module-2"] then
    bobmods.lib.tech.remove_science_pack("efficiency-module-2", "chemical-science-pack")
    bobmods.lib.tech.set_science_pack_count("efficiency-module-2", 100)
end
if data.raw.technology["efficiency-module-3"] then
    bobmods.lib.tech.remove_science_pack("efficiency-module-3", "production-science-pack")
    bobmods.lib.tech.set_science_pack_count("efficiency-module-3", 150)
end
if data.raw.technology["productivity-module-2"] then
    bobmods.lib.tech.remove_science_pack("productivity-module-2", "chemical-science-pack")
    bobmods.lib.tech.set_science_pack_count("productivity-module-2", 100)
end
if data.raw.technology["productivity-module-3"] then
    bobmods.lib.tech.remove_science_pack("productivity-module-3", "production-science-pack")
    bobmods.lib.tech.set_science_pack_count("productivity-module-3", 150)
end

-- Module effects use Bob's scaling
if bobmods.modules then
    set_module_effect("speed-module", {
        speed = bobmods.modules.SpeedPerLevel + bobmods.modules.SpeedBonus + 0.001,
        consumption = bobmods.modules.ConsumptionPenaltyPerLevel + bobmods.modules.ConsumptionPenalty + 0.001,
    })
    set_module_effect("speed-module-2", {
        speed = 2 * bobmods.modules.SpeedPerLevel + bobmods.modules.SpeedBonus + 0.001,
        consumption = 2 * bobmods.modules.ConsumptionPenaltyPerLevel + bobmods.modules.ConsumptionPenalty + 0.001,
    })
    set_module_effect("speed-module-3", {
        speed = 3 * bobmods.modules.SpeedPerLevel + bobmods.modules.SpeedBonus + 0.001,
        consumption = 3 * bobmods.modules.ConsumptionPenaltyPerLevel + bobmods.modules.ConsumptionPenalty + 0.001,
    })
    set_module_effect("efficiency-module",
        { consumption = -1 * bobmods.modules.ConsumptionPerLevel - bobmods.modules.ConsumptionBonus - 0.001 })
    set_module_effect("efficiency-module-2",
        { consumption = -2 * bobmods.modules.ConsumptionPerLevel - bobmods.modules.ConsumptionBonus - 0.001 })
    set_module_effect("efficiency-module-3",
        { consumption = -3 * bobmods.modules.ConsumptionPerLevel - bobmods.modules.ConsumptionBonus - 0.001 })
    set_module_effect("productivity-module", {
        productivity = bobmods.modules.ProductivityPerLevel + bobmods.modules.ProductivityBonus + 0.001,
        consumption = bobmods.modules.ConsumptionPenaltyPerLevel + bobmods.modules.ConsumptionPenalty + 0.001,
        pollution = bobmods.modules.PollutionPenaltyPerLevel + bobmods.modules.PollutionPenalty + 0.001,
    })
    set_module_effect("productivity-module-2", {
        productivity = 2 * bobmods.modules.ProductivityPerLevel + bobmods.modules.ProductivityBonus + 0.001,
        consumption = 2 * bobmods.modules.ConsumptionPenaltyPerLevel + bobmods.modules.ConsumptionPenalty + 0.001,
        pollution = 2 * bobmods.modules.PollutionPenaltyPerLevel + bobmods.modules.PollutionPenalty + 0.001,
    })
    set_module_effect("productivity-module-3", {
        productivity = 3 * bobmods.modules.ProductivityPerLevel + bobmods.modules.ProductivityBonus + 0.001,
        consumption = 3 * bobmods.modules.ConsumptionPenaltyPerLevel + bobmods.modules.ConsumptionPenalty + 0.001,
        pollution = 3 * bobmods.modules.PollutionPenaltyPerLevel + bobmods.modules.PollutionPenalty + 0.001,
    })
end

-- Prevent creature modules in beacon 2 and 3
if data.raw["beacon"]["bob-beacon-2"] then
    data.raw["beacon"]["bob-beacon-2"].allowed_effects = {'speed', 'consumption'}
end
if data.raw["beacon"]["bob-beacon-3"] then
    data.raw["beacon"]["bob-beacon-3"].allowed_effects = {'speed', 'consumption'}
end

-- Define vanilla module recipes with Bob's ingredients (2.0 names with bob- prefix)
set_recipe_ingredients("speed-module", {
    {type = "item", name = "bob-speed-processor", amount = 1},
    {type = "item", name = "bob-module-case", amount = 1},
    {type = "item", name = "bob-module-circuit-board", amount = 1},
    {type = "item", name = "bob-module-contact", amount = 4},
})
set_recipe_ingredients("efficiency-module", {
    {type = "item", name = "bob-efficiency-processor", amount = 1},
    {type = "item", name = "bob-module-case", amount = 1},
    {type = "item", name = "bob-module-circuit-board", amount = 1},
    {type = "item", name = "bob-module-contact", amount = 4},
})
set_recipe_ingredients("productivity-module", {
    {type = "item", name = "bob-productivity-processor", amount = 1},
    {type = "item", name = "bob-module-case", amount = 1},
    {type = "item", name = "bob-module-circuit-board", amount = 1},
    {type = "item", name = "bob-module-contact", amount = 4},
})

set_recipe_ingredients("speed-module-2", {
    {type = "item", name = "speed-module", amount = 1},
    {type = "item", name = "bob-speed-processor", amount = 2},
    {type = "item", name = "bob-module-contact", amount = 5},
})
set_recipe_ingredients("efficiency-module-2", {
    {type = "item", name = "efficiency-module", amount = 1},
    {type = "item", name = "bob-efficiency-processor", amount = 2},
    {type = "item", name = "bob-module-contact", amount = 5},
})
set_recipe_ingredients("productivity-module-2", {
    {type = "item", name = "productivity-module", amount = 1},
    {type = "item", name = "bob-productivity-processor", amount = 2},
    {type = "item", name = "bob-module-contact", amount = 5},
})

set_recipe_ingredients("speed-module-3", {
    {type = "item", name = "speed-module-2", amount = 1},
    {type = "item", name = "bob-speed-processor-2", amount = 3},
    {type = "item", name = "advanced-circuit", amount = 5},
})
set_recipe_ingredients("efficiency-module-3", {
    {type = "item", name = "efficiency-module-2", amount = 1},
    {type = "item", name = "bob-efficiency-processor-2", amount = 3},
    {type = "item", name = "advanced-circuit", amount = 5},
})
set_recipe_ingredients("productivity-module-3", {
    {type = "item", name = "productivity-module-2", amount = 1},
    {type = "item", name = "bob-productivity-processor-2", amount = 3},
    {type = "item", name = "advanced-circuit", amount = 5},
})

-- Beacon productivity/pollution when Bob's setting allows it
if settings.startup["bobmods-modules-transmitproductivity"] and settings.startup["bobmods-modules-transmitproductivity"].value == true then
    for _, beacon in pairs(data.raw.beacon) do
        if beacon.allowed_effects then
            table.insert(beacon.allowed_effects, "productivity")
            table.insert(beacon.allowed_effects, "pollution")
        end
    end
end
