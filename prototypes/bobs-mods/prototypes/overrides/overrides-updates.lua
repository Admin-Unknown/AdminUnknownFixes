if mods['bobelectronics'] then
    if mods['pyhightech'] then
        if data.raw.recipe['bob-silicon-wafer'] then
            data.raw.recipe['bob-silicon-wafer'].enabled = false
        end
        if data.raw.recipe['bob-rubber'] then
            data.raw.recipe['bob-rubber'].enabled = false
            data.raw.recipe['bob-rubber'].hidden = true
        end
        
        if mods["angelsindustries"] and not settings.startup["angels-enable-components"].value then

            if data.raw.recipe['bob-wooden-board'] then
                data.raw.recipe['bob-wooden-board'].enabled = false
                data.raw.recipe['bob-wooden-board'].hidden = true
            end
            if data.raw.recipe['bob-basic-circuit-board'] then
                data.raw.recipe['bob-basic-circuit-board'].enabled = false
                data.raw.recipe['bob-basic-circuit-board'].hidden = true
            end


            RECIPE('offshore-pump'):remove_ingredient('bob-basic-circuit-board')
            RECIPE('assembling-machine-1'):remove_ingredient('bob-basic-circuit-board')

            RECIPE('angels-algae-farm'):replace_ingredient('bob-basic-circuit-board', 'inductor1')
            RECIPE('repair-pack'):replace_ingredient('bob-basic-circuit-board', 'inductor1')
            RECIPE('lab'):replace_ingredient('bob-basic-circuit-board', 'inductor1')

            RECIPE('angels-algae-farm-2'):replace_ingredient('bob-basic-circuit-board', 'electronic-circuit')
            RECIPE('bob-repair-pack-2'):replace_ingredient('bob-basic-circuit-board', 'electronic-circuit')

            RECIPE('assembling-machine-1'):add_ingredient({type = "item", name = "inductor1", amount = 3})

            TECHNOLOGY('automation'):add_prereq('coal-processing-1')
            -- both the setting and logistics-0 come from boblogistics
            if mods['boblogistics'] and settings.startup["bobmods-logistics-beltoverhaul"].value then
                TECHNOLOGY('logistics-0'):add_prereq('coal-processing-1')
            end
            
            if mods['boblogistics'] then
                RECIPE('splitter'):remove_ingredient('bob-basic-circuit-board')
                RECIPE('bob-basic-splitter'):remove_ingredient('wood')
            end
        end
    end
end

if mods['boblogistics'] then
    data.raw.recipe['underground-belt'].enabled = false
    RECIPE('underground-belt'):add_unlock('logistics')

    RECIPE('bob-repair-pack-2'):remove_ingredient("iron-gear-wheel"):add_ingredient({type = "item", name = "repair-pack", amount = 1})

    if settings.startup['bobmods-logistics-inserteroverhaul'].value then
        -- The overhaul puts a red inserter between the yellow and the fast one, and py's rare
        -- earth mine should ask for that rather than the fast one it was written against.
        -- The red inserter is only ever an entity: Bob's builds it from the long handed
        -- inserter item, which keeps its own name and gains the red icon. So the item to name
        -- here is long-handed-inserter, and bob-red-inserter cannot go in a recipe at all.
        fun.ingredient_replace('rare-earth-mine','fast-inserter','long-handed-inserter')
    end

    if mods['pyindustry'] then
        fun.tech_remove_recipe('fluid-handling', 'bob-storage-tank-all-corners')
    end
    if mods['pyhightech'] then
      --more robot stuff
      RECIPE('bob-repair-pack-2'):remove_ingredient("electronic-circuit"):add_ingredient({type = "item", name = "pcb1", amount = 1})
      RECIPE('bob-robot-brain'):remove_ingredient("advanced-circuit")
      RECIPE('bob-robot-brain'):add_ingredient({type = "item", name = "plastic-bar", amount = 5})
      RECIPE('py-construction-robot-mk01'):add_ingredient({type = "item", name = "bob-robot-brain", amount = 1})
      RECIPE('py-construction-robot-mk01'):add_ingredient({type = "item", name = "bob-robot-tool-construction", amount = 1})
      RECIPE('py-construction-robot-mk01'):remove_ingredient("electronic-circuit")
      RECIPE('bob-roboport-antenna-1'):replace_ingredient("advanced-circuit", "electronic-circuit")
      RECIPE('bob-roboport-chargepad-1'):replace_ingredient("advanced-circuit", "electronic-circuit")
    end
    
    settings.startup["bobmods-logistics-beltperlevel"].hidden = true

    if settings.startup["bobmods-logistics-beltoverhaul"].value then
        local logilevel = settings.startup["bobmods-logistics-beltperlevel"].value
        data.raw['underground-belt']['bob-basic-underground-belt'].max_distance = 5 + logilevel
        data.raw['underground-belt']['underground-belt'].max_distance = 9 + logilevel
        data.raw['underground-belt']['fast-underground-belt'].max_distance = 17 + logilevel
        data.raw['underground-belt']['express-underground-belt'].max_distance = 33 + logilevel
        data.raw['underground-belt']['turbo-underground-belt'].max_distance = 65 + logilevel
        data.raw['underground-belt']['bob-ultimate-underground-belt'].max_distance = 129 + logilevel
    end
end

if mods['bobmining'] then
    if mods['pyalienlife'] and mods['pyhightech'] then
        if settings.startup["bobmods-mining-miningdrills"].value then
            data.raw["mining-drill"]["bob-mining-drill-1"].input_fluid_box = nil
            data.raw["mining-drill"]["bob-mining-drill-2"].input_fluid_box = nil
            data.raw["mining-drill"]["bob-mining-drill-3"].input_fluid_box = nil
            data.raw["mining-drill"]["bob-mining-drill-4"].input_fluid_box = nil
            if data.raw["mining-drill"]["bob-area-mining-drill-1"] then
                data.raw["mining-drill"]["bob-area-mining-drill-1"].input_fluid_box = nil
                data.raw["mining-drill"]["bob-area-mining-drill-2"].input_fluid_box = nil
                data.raw["mining-drill"]["bob-area-mining-drill-3"].input_fluid_box = nil
                data.raw["mining-drill"]["bob-area-mining-drill-4"].input_fluid_box = nil
            end
        end
    end
end

if mods['bobores'] then
    if mods['pyrawores'] then
        if data.raw.resource['bob-bauxite-ore'] then
            data.raw.resource['bob-bauxite-ore'].minable.results = {
                {
                    type = 'item',
                    name = 'ore-aluminium',
                    amount = 1
                }
            }
        end
    end
end

if mods['bobplates'] then
    if mods['pyalienlife'] then
        if data.raw.recipe['bob-silicon-carbide'] then
            RECIPE('bob-silicon-carbide'):remove_unlock('bob-grinding')
            data.raw.recipe['bob-silicon-carbide'] = nil
        end

        if data.raw.technology['bob-grinding'] and data.raw.technology['bob-silicon-carbide'] then
            TECHNOLOGY('bob-grinding'):add_prereq('bob-silicon-carbide')
        end

        if data.raw.technology['bob-fluid-barrel-processing'] then
            TECHNOLOGY('bob-fluid-barrel-processing'):add_prereq('fluid-handling')
            TECHNOLOGY('bob-fluid-barrel-processing'):remove_prereq('logistic-science-pack')
            if not data.raw.technology['bob-fluid-barrel-processing'].research_trigger then
                TECHNOLOGY('bob-fluid-barrel-processing'):remove_pack('logistic-science-pack'):remove_pack('py-science-pack-1')
            end
        end
    end
end

if mods['bobpower'] then
    if settings.startup["bobmods-power-steam"].value == true then
        --Change Bob's boiler's and engines to be in line with Py's
        data.raw.boiler['bob-boiler-2'].target_temperature = 300
        data.raw.boiler['bob-boiler-2'].energy_consumption = '5.50125MW'
        data.raw.boiler['bob-boiler-3'].target_temperature = 350
        data.raw.boiler['bob-boiler-3'].energy_consumption = '7.30125MW'
        data.raw.boiler['bob-boiler-4'].target_temperature = 400
        data.raw.boiler['bob-boiler-4'].energy_consumption = '9.10125MW'
        data.raw.boiler['bob-boiler-5'].target_temperature = 450
        data.raw.boiler['bob-boiler-5'].energy_consumption = '10.90125MW'

        data.raw.boiler['bob-boiler-2'].energy_source.fuel_categories = {'chemical', 'biomass'}
        data.raw.boiler['bob-boiler-3'].energy_source.fuel_categories = {'chemical', 'biomass'}
        data.raw.boiler['bob-boiler-4'].energy_source.fuel_categories = {'chemical', 'biomass'}
        data.raw.boiler['bob-boiler-5'].energy_source.fuel_categories = {'chemical', 'biomass'}

        data.raw.generator['steam-engine'].maximum_temperature = 250
        data.raw.generator['bob-steam-engine-2'].maximum_temperature = 300
        data.raw.generator['bob-steam-engine-3'].maximum_temperature = 350
        data.raw.generator['bob-steam-engine-4'].maximum_temperature = 400
        data.raw.generator['bob-steam-engine-5'].maximum_temperature = 450

        data.raw.generator['bob-steam-engine-2'].destroy_non_fuel_fluid = false
        data.raw.generator['bob-steam-engine-3'].destroy_non_fuel_fluid = false
        data.raw.generator['bob-steam-engine-4'].destroy_non_fuel_fluid = false
        data.raw.generator['bob-steam-engine-5'].destroy_non_fuel_fluid = false

        data.raw.generator['steam-engine'].fluid_usage_per_tick = 0.25
        data.raw.generator['bob-steam-engine-2'].fluid_usage_per_tick = 0.25
        data.raw.generator['bob-steam-engine-3'].fluid_usage_per_tick = 0.25
        data.raw.generator['bob-steam-engine-4'].fluid_usage_per_tick = 0.25
        data.raw.generator['bob-steam-engine-5'].fluid_usage_per_tick = 0.25
    end
    if mods['pyalienlife'] then
        fun.ingredient_replace('collector','steam-engine','bob-burner-generator')
    end
    if mods['pyalternativeenergy'] then
        fun.tech_remove_recipe("advanced-material-processing-2", "heat-pipe")
        fun.tech_remove_recipe("advanced-material-processing-2", "heat-exchanger")

        fun.tech_remove_recipe("bob-steam-turbine-1", "steam-turbine")

        TECHNOLOGY("bob-steam-turbine-2"):remove_prereq("bob-steam-turbine-1")

        data.raw.technology["bob-steam-turbine-1"].hidden = true
        data.raw.technology["bob-steam-turbine-1"].enabled = false
    end
    if mods['pyhardmode'] then
        data.raw['heat-pipe']['heat-pipe'].heat_buffer.min_temperature_gradient = 3
        data.raw['heat-pipe']['bob-heat-pipe-2'].heat_buffer.min_temperature_gradient = 2
        data.raw['heat-pipe']['bob-heat-pipe-3'].heat_buffer.min_temperature_gradient = 1
        data.raw['heat-pipe']['bob-heat-pipe-4'].heat_buffer.min_temperature_gradient = 0
    end
end

if mods['bobassembly'] then
    if settings.startup["burner-start"].value then
        local burner = {
            type = "burner",
            fuel_categories = {"chemical", "biomass"},
            effectivity = 1,
            fuel_inventory_size = 1,
            burnt_inventory_size = 1,
            emissions_per_minute = {pollution = 12},
        }
        --modify assembly machine 4
        data.raw['assembling-machine']['bob-assembling-machine-4'].crafting_speed = 6
        data.raw['assembling-machine']['bob-assembling-machine-4'].energy_source = table.deepcopy(burner)
        table.insert(data.raw['assembling-machine']['bob-assembling-machine-4'].energy_source.fuel_categories, "jerry")
        data.raw['assembling-machine']['bob-assembling-machine-4'].allowed_effects = {}
        data.raw['assembling-machine']['bob-assembling-machine-4'].module_slots = 0
        --modify assembly machine 5
        data.raw['assembling-machine']['bob-assembling-machine-5'].crafting_speed = 8
        data.raw['assembling-machine']['bob-assembling-machine-5'].energy_source = table.deepcopy(burner)
        table.insert(data.raw['assembling-machine']['bob-assembling-machine-5'].energy_source.fuel_categories, "jerry")
        data.raw['assembling-machine']['bob-assembling-machine-5'].allowed_effects = {}
        data.raw['assembling-machine']['bob-assembling-machine-5'].module_slots = 0
        --modify assembly machine 6
        data.raw['assembling-machine']['bob-assembling-machine-6'].crafting_speed = 10
        data.raw['assembling-machine']['bob-assembling-machine-6'].energy_source = table.deepcopy(burner)
        table.insert(data.raw['assembling-machine']['bob-assembling-machine-6'].energy_source.fuel_categories, "jerry")
        data.raw['assembling-machine']['bob-assembling-machine-6'].allowed_effects = {}
        data.raw['assembling-machine']['bob-assembling-machine-6'].module_slots = 0
        --modify steam assembly machine
        if settings.startup["bobmods-assembly-burner"].value then
            data.raw['assembling-machine']['bob-steam-assembling-machine'].crafting_speed = 0.5
            data.raw['assembling-machine']['bob-steam-assembling-machine'].allowed_effects = {}
            --mechanical assembler
            data.raw['assembling-machine']['bob-burner-assembling-machine'].energy_source.type = "void"
            data.raw['assembling-machine']['bob-burner-assembling-machine'].crafting_speed = 0.1
            data.raw['assembling-machine']['bob-burner-assembling-machine'].allowed_effects = {}
        end
    end

    if mods['pyalternativeenergy'] then
        require('__AdminUnknownFixes__/prototypes/bobs-mods/prototypes/entity/furnace')
    end
    
    if mods['pyhightech'] then
        data:extend({
            {
                type = "recipe-category",
                name = "circuits",
            },
        })
        data.raw.recipe["electronic-circuit"].categories = {"circuits"}
        data.raw.recipe["advanced-circuit"].categories = {"circuits"}
        data.raw.recipe["processing-unit"].categories = {"circuits"}
        data.raw.recipe["intelligent-unit"].categories = {"circuits"}
        table.insert(data.raw['assembling-machine']['bob-electronics-machine-1'].crafting_categories, 'circuits')
        table.insert(data.raw['assembling-machine']['bob-electronics-machine-2'].crafting_categories, 'circuits')
        table.insert(data.raw['assembling-machine']['bob-electronics-machine-3'].crafting_categories, 'circuits')
        data.raw['assembling-machine']['bob-electronics-machine-1'].allowed_effects = { 'speed', 'consumption', 'pollution' }
        data.raw['assembling-machine']['bob-electronics-machine-2'].allowed_effects = { 'speed', 'consumption', 'pollution' }
        data.raw['assembling-machine']['bob-electronics-machine-3'].allowed_effects = { 'speed', 'consumption', 'pollution' }
        table.insert(data.raw['assembling-machine']['chipshooter-mk01'].crafting_categories, 'circuits')
        data.raw['assembling-machine']['chipshooter-mk01'].module_slots = 2
        data.raw['assembling-machine']['chipshooter-mk01'].crafting_speed = 2
        table.insert(data.raw['assembling-machine']['chipshooter-mk02'].crafting_categories, 'circuits')
        data.raw['assembling-machine']['chipshooter-mk02'].module_slots = 4
        data.raw['assembling-machine']['chipshooter-mk02'].crafting_speed = 4
        table.insert(data.raw['assembling-machine']['chipshooter-mk03'].crafting_categories, 'circuits')
        data.raw['assembling-machine']['chipshooter-mk03'].module_slots = 6
        data.raw['assembling-machine']['chipshooter-mk03'].crafting_speed = 6
        table.insert(data.raw['assembling-machine']['chipshooter-mk04'].crafting_categories, 'circuits')
        data.raw['assembling-machine']['chipshooter-mk04'].module_slots = 8
        data.raw['assembling-machine']['chipshooter-mk04'].crafting_speed = 8
        data.raw['assembling-machine']['bob-electronics-machine-1'].energy_usage = "300kW"
        data.raw['assembling-machine']['bob-electronics-machine-2'].energy_usage = "600kW"
        data.raw['assembling-machine']['bob-electronics-machine-3'].energy_usage = "1MW"
        if not mods['angelsindustries'] then
            TECHNOLOGY('bob-electronics-machine-1'):add_prereq('electronics')
        end
    end

    if mods['pyalternativeenergy'] then
        -- merge bobs centrifuges into pys centrifuges
        -- mk01
        data.raw["assembling-machine"]["centrifuge"].minable = { mining_time = 0.5, result = "centrifuge-mk01" }
        fun.remove_recipe_unlock('centrifuge')
        -- mk02
        data.raw["assembling-machine"]["bob-centrifuge-2"].minable = { mining_time = 0.5, result = "centrifuge-mk02" }
        fun.remove_recipe_unlock('bob-centrifuge-2')
        -- mk03
        data.raw["assembling-machine"]["bob-centrifuge-3"].minable = { mining_time = 0.5, result = "centrifuge-mk03" }
        fun.remove_recipe_unlock('bob-centrifuge-3')
    end
end

if mods['bobgreenhouse'] then
    local gh = data.raw['assembling-machine']['bob-greenhouse']
    if gh then
        gh.energy_usage = "300kW"
        -- Factorio 2.0: module slots > 0 with allowed_effects = {} is invalid. Allow speed/consumption only (no productivity on crops).
        gh.allowed_effects = { "speed", "consumption" }
    end
    if mods['pyalienlife'] and not mods['angelsbioprocessing'] then
        require('__AdminUnknownFixes__/prototypes/bobs-mods/prototypes/recipes/charcoal')
        TECHNOLOGY('energy-3'):add_prereq('bob-greenhouse')
    end
end

if mods['bobwarfare'] then
    if data.raw.recipe['bob-rocket-engine'] then
        fun.tech_remove_recipe('rocket-silo', 'bob-rocket-engine')
        data.raw.recipe['bob-rocket-engine'].ingredients = nil
        RECIPE('bob-rocket-engine'):add_ingredient({type = "item", name = "low-density-structure", amount = 5})
        if mods['pyrawores'] then
            RECIPE('bob-rocket-engine'):add_ingredient({type = "item", name = "solder", amount = 20})
            RECIPE('bob-rocket-engine'):add_ingredient({type = "item", name = "super-steel", amount = 10})
        end
    end
    if data.raw.technology['bob-rocket'] then
        data.raw.technology['bob-rocket'].prerequisites = {
            'rocketry',
            'military-3',
            'low-density-structure'
        }
    end
end

if mods['bobrevamp'] then
    if data.raw.recipe['bob-heat-shield-tile'] then
        -- graphite is pyhightech's and saps pyalienlife's; bobrevamp implies neither
        if mods['pyhightech'] and mods['pyalienlife'] then
            RECIPE('bob-heat-shield-tile'):add_ingredient({type = "item", name = "coke", amount = 5}):add_ingredient({type = "item", name = "graphite", amount = 1}):add_ingredient({type = "item", name = "saps", amount = 10}):add_ingredient({type = "item", name = "nichrome", amount = 2}):remove_ingredient('steel-plate'):remove_ingredient('plastic-bar')
        end
        if mods['angelssmelting'] then
            data.raw.recipe['bob-heat-shield-tile'].categories = {'angels-sintering'}

            if data.raw.technology['bob-heat-shield'] then
                TECHNOLOGY('bob-heat-shield'):remove_prereq('angels-powder-metallurgy-4'):add_prereq('angels-powder-metallurgy-1')

                OV.remove_science_pack('bob-heat-shield', 'production-science-pack')

                -- the pack and the technology named after it are both pyalienlife's, which
                -- neither bobrevamp nor angelssmelting brings with them
                if mods['pyalienlife'] then
                    TECHNOLOGY('bob-heat-shield'):add_prereq('py-science-pack-3'):add_pack("py-science-pack-3")
                end
            end
        end
    end
end

if mods['bobclasses'] then
    table.insert(data.raw['character']['bob-character-miner'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-fighter'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-builder'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-balanced-2'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-miner-2'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-fighter-2'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-builder-2'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-engineer'].flags, 'not-in-made-in')
    table.insert(data.raw['character']['bob-character-prospector'].flags, 'not-in-made-in')
    if mods['pyhightech'] then
        RECIPE('bob-player-power-core'):set_fields{ categories = {"pa"} }:set_fields{energy_required = 45}
        RECIPE('bob-player-power-core'):remove_ingredient('battery-mk01'):remove_ingredient('bob-rtg'):remove_ingredient('processing-unit')
        RECIPE('bob-player-power-core'):add_ingredient({type = "item", name = "nexelit-battery", amount = 5}):add_ingredient({type = "item", name = "nuclear-sample", amount = 1}):add_ingredient({type = "item", name = "processing-unit", amount = 15})
    end
    if mods['pyalternativeenergy'] then
        --mk01
        TECHNOLOGY('bob-bodies'):add_pack("py-science-pack-3")
        TECHNOLOGY('bob-bodies'):add_prereq("simik-mk01")

        TECHNOLOGY('bob-fighter-body'):remove_prereq('exoskeleton-equipment'):add_prereq('energy-shield-mk2-equipment'):add_pack('py-science-pack-3')
        TECHNOLOGY('bob-builder-body'):add_pack('py-science-pack-3')
        TECHNOLOGY('bob-miner-body'):add_pack('py-science-pack-3')

        RECIPE('bob-player-brain'):set_fields{ categories = {"data-array"} }:set_fields{energy_required = 30}
        RECIPE('bob-player-brain'):remove_ingredient('bob-superior-circuit-board'):remove_ingredient('bob-integrated-electronics'):remove_ingredient('bob-basic-electronic-components'):remove_ingredient('bob-electronic-components')
        RECIPE('bob-player-brain'):add_ingredient({type = "item", name = "neuroprocessor", amount = 5})

        RECIPE('bob-player-head'):set_fields{energy_required = 50}
        RECIPE('bob-player-head'):remove_ingredient('steel-plate'):add_ingredient({type = "item", name = "bones", amount = 22})

        RECIPE('bob-player-boots'):set_fields{ categories = {"crafting-with-fluid"} }:set_fields{energy_required = 50}
        RECIPE('bob-player-boots'):remove_ingredient('steel-plate')
        RECIPE('bob-player-boots'):add_ingredient({type = "fluid", name = "flue-gas", amount = 200}):add_ingredient({type = "item", name = "skin", amount = 10})

        RECIPE('bob-player-gloves'):set_fields{ categories = {"nano"} }:set_fields{energy_required = 70}
        RECIPE('bob-player-gloves'):remove_ingredient('steel-plate'):remove_ingredient('small-parts-01')
        RECIPE('bob-player-gloves'):add_ingredient({type = "item", name = "rayon", amount = 20}):add_ingredient({type = "item", name = "diamond-wire", amount = 5}):add_ingredient({type = "item", name = "latex", amount = 2})

        RECIPE('bob-player-frame'):set_fields{ categories = {"nano"} }:set_fields{energy_required = 70}
        RECIPE('bob-player-frame'):remove_ingredient('steel-plate'):remove_ingredient('advanced-circuit'):remove_ingredient('electric-engine-unit')
        RECIPE('bob-player-frame'):add_ingredient({type = "item", name = "super-steel", amount = 15}):add_ingredient({type = "item", name = "red-wire", amount = 10}):add_ingredient({type = "item", name = "green-wire", amount = 10}):add_ingredient({type = "item", name = "tinned-cable", amount = 50})

        RECIPE('character'):set_fields{ categories = {"creature-chamber"} }:set_fields{energy_required = 500}
        RECIPE('character'):remove_ingredient('assembling-machine-2')
        RECIPE('character'):add_ingredient({type = "item", name = "bones", amount = 184}):add_ingredient({type = "item", name = "bio-sample", amount = 20}):add_ingredient({type = "item", name = "bio-sample", amount = 10}):add_ingredient({type = "item", name = "alien-sample-03", amount = 5}):add_ingredient({type = "item", name = "strorix-unknown-sample", amount = 2}):add_ingredient({type = "item", name = "earth-generic-sample", amount = 4})
        RECIPE('character'):add_ingredient({type = "fluid", name = "fetal-serum", amount = 100}):add_ingredient({type = "fluid", name = "artificial-blood", amount = 300}):add_ingredient({type = "fluid", name = "blood", amount = 700})

        RECIPE('bob-character-builder'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-builder'):remove_ingredient('bob-player-frame'):remove_ingredient('assembling-machine-2')
        RECIPE('bob-character-builder'):add_ingredient({type = "item", name = "character", amount = 1}):add_ingredient({type = "item", name = "mechanical-parts-02", amount = 5})

        RECIPE('bob-character-fighter'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-fighter'):remove_ingredient('assembling-machine-2'):remove_ingredient('exoskeleton-equipment'):remove_ingredient('bob-player-frame')
        RECIPE('bob-character-fighter'):add_ingredient({type = "item", name = "character", amount = 1}):add_ingredient({type = "item", name = "gunpowder", amount = 20}):add_ingredient({type = "item", name = "pu-239", amount = 15}):add_ingredient({type = "item", name = "energy-shield-mk2-equipment", amount = 1})

        RECIPE('bob-character-miner'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-miner'):remove_ingredient('assembling-machine-2'):remove_ingredient('electric-furnace'):remove_ingredient('bob-player-frame')
        RECIPE('bob-character-miner'):add_ingredient({type = "item", name = "character", amount = 1}):add_ingredient({type = "item", name = "drill-head", amount = 5}):add_ingredient({type = "fluid", name = "drilling-fluid-1", amount = 200})
        --mk02
        TECHNOLOGY('bob-bodies-2'):remove_prereq('production-science-pack'):remove_prereq('nano-tech'):add_prereq('mass-production'):add_pack('utility-science-pack')
        TECHNOLOGY('bob-fighter-body-2'):remove_prereq('bob-exoskeleton-equipment-2'):add_pack('utility-science-pack')
        -- the shield technology is bobequipment's, which bobclasses does not require
        if mods['bobequipment'] then
            TECHNOLOGY('bob-fighter-body-2'):add_prereq('bob-energy-shield-equipment-3')
        end
        TECHNOLOGY('bob-miner-body-2'):add_prereq('drilling-fluid-mk04'):add_pack('utility-science-pack')
        TECHNOLOGY('bob-builder-body-2'):add_pack('utility-science-pack')
        TECHNOLOGY('bob-engineer-body'):add_pack('utility-science-pack')
        TECHNOLOGY('bob-prospector-body'):add_pack('utility-science-pack')

        RECIPE('bob-player-brain-2'):set_fields{ categories = {"data-array"} }:set_fields{energy_required = 30}
        RECIPE('bob-player-brain-2'):remove_ingredient('bob-superior-circuit-board'):remove_ingredient('bob-integrated-electronics'):remove_ingredient('bob-basic-electronic-components'):remove_ingredient('bob-electronic-components'):remove_ingredient('bob-processing-electronics')
        RECIPE('bob-player-brain-2'):add_ingredient({type = "item", name = "laboratory-grown-brain", amount = 1}):add_ingredient({type = "item", name = "strorix-unknown-sample", amount = 5})

        RECIPE('bob-player-boots-2'):set_fields{ categories = {"crafting-with-fluid"} }:set_fields{energy_required = 50}
        RECIPE('bob-player-boots-2'):remove_ingredient('titanium-plate'):remove_ingredient('rubber')
        RECIPE('bob-player-boots-2'):add_ingredient({type = "fluid", name = "flue-gas", amount = 200}):add_ingredient({type = "item", name = "skin", amount = 10}):add_ingredient({type = "item", name = "super-alloy", amount = 10})

        RECIPE('bob-player-head-2'):set_fields{ categories = {"bio-printer"} }:set_fields{energy_required = 60}
        RECIPE('bob-player-head-2'):remove_ingredient('titanium-plate')
        RECIPE('bob-player-head-2'):add_ingredient({type = "item", name = "bio-scafold", amount = 2})
        RECIPE('bob-player-head-2'):add_ingredient({type = "fluid", name = "psc", amount = 100}):add_ingredient({type = "fluid", name = "fetal-serum", amount = 100})

        RECIPE('bob-player-gloves-2'):set_fields{ categories = {"nano"} }:set_fields{energy_required = 70}
        RECIPE('bob-player-gloves-2'):remove_ingredient('titanium-plate'):remove_ingredient('small-parts-01')
        RECIPE('bob-player-gloves-2'):add_ingredient({type = "item", name = "nano-mesh", amount = 20}):add_ingredient({type = "item", name = "biofilm", amount = 10}):add_ingredient({type = "item", name = "aramid", amount = 10}):add_ingredient({type = "item", name = "kevlar", amount = 30}):add_ingredient({type = "item", name = "silver-foam", amount = 5}):add_ingredient({type = "item", name = "science-coating", amount = 2})

        RECIPE('bob-player-frame-2'):set_fields{ categories = {"nano"} }:set_fields{energy_required = 70}
        RECIPE('bob-player-frame-2'):remove_ingredient('titanium-plate'):remove_ingredient('advanced-circuit'):remove_ingredient('electric-engine-unit'):remove_ingredient('processing-unit')
        RECIPE('bob-player-frame-2'):add_ingredient({type = "item", name = "super-steel", amount = 15}):add_ingredient({type = "item", name = "red-wire", amount = 10}):add_ingredient({type = "item", name = "green-wire", amount = 10}):add_ingredient({type = "item", name = "tinned-cable", amount = 50}):add_ingredient({type = "item", name = "quantum-dots", amount = 10})

        RECIPE('bob-character-balanced-2'):set_fields{ categories = {"creature-chamber"} }:set_fields{energy_required = 120}
        RECIPE('bob-character-balanced-2'):remove_ingredient('assembling-machine-2')
        RECIPE('bob-character-balanced-2'):add_ingredient({type = "item", name = "scafold-free-bones", amount = 1}):add_ingredient({type = "item", name = "in-vitro-meat", amount = 1}):add_ingredient({type = "item", name = "bioartificial-guts", amount = 1}):add_ingredient({type = "item", name = "biomimetic-skin", amount = 1}):add_ingredient({type = "item", name = "tissue-engineered-fat", amount = 1})
        RECIPE('bob-character-balanced-2'):add_ingredient({type = "fluid", name = "fetal-serum", amount = 100}):add_ingredient({type = "fluid", name = "artificial-blood", amount = 50}):add_ingredient({type = "fluid", name = "tholins", amount = 100})

        RECIPE('bob-character-builder-2'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-builder-2'):remove_ingredient('bob-player-frame-2')
        RECIPE('bob-character-builder-2'):add_ingredient({type = "item", name = "bob-character-balanced-2", amount = 1}):add_ingredient({type = "item", name = "mechanical-parts-04", amount = 5})

        RECIPE('bob-character-engineer'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-engineer'):remove_ingredient('bob-player-frame-2'):remove_ingredient('electric-furnace'):remove_ingredient('assembling-machine-3')
        RECIPE('bob-character-engineer'):add_ingredient({type = "item", name = "bob-character-balanced-2", amount = 1}):add_ingredient({type = "item", name = "mechanical-parts-04", amount = 10}):add_ingredient({type = "item", name = "mega-drill-head", amount = 5})

        RECIPE('bob-character-fighter-2'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-fighter-2'):remove_ingredient('assembling-machine-2'):remove_ingredient('bob-exoskeleton-equipment-2'):remove_ingredient('bob-player-frame-2')
        RECIPE('bob-character-fighter-2'):add_ingredient({type = "item", name = "bob-character-balanced-2", amount = 1}):add_ingredient({type = "item", name = "exoskeleton-equipment", amount = 1}):add_ingredient({type = "fluid", name = "helium", amount = 100})
        -- the mk3 shield belongs to bobequipment, and everything else here to bobclasses
        if mods['bobequipment'] then
            RECIPE('bob-character-fighter-2'):add_ingredient({type = "item", name = "bob-energy-shield-mk3-equipment", amount = 1})
        end

        RECIPE('bob-character-miner-2'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-miner-2'):remove_ingredient('assembling-machine-2'):remove_ingredient('bob-electric-furnace-2'):remove_ingredient('bob-player-frame-2')
        RECIPE('bob-character-miner-2'):add_ingredient({type = "item", name = "bob-character-balanced-2", amount = 1}):add_ingredient({type = "item", name = "mega-drill-head", amount = 10}):add_ingredient({type = "fluid", name = "drilling-fluid-3", amount = 200})

        RECIPE('bob-character-prospector'):set_fields{ categories = {"biofactory"} }:set_fields{energy_required = 50}
        RECIPE('bob-character-prospector'):remove_ingredient('assembling-machine-2'):remove_ingredient('electric-furnace'):remove_ingredient('bob-player-frame-2')
        RECIPE('bob-character-prospector'):add_ingredient({type = "item", name = "bob-character-balanced-2", amount = 1}):add_ingredient({type = "item", name = "mega-drill-head", amount = 5})

        require('__AdminUnknownFixes__/prototypes/bobs-mods/prototypes/recipes/bodies')
    end
end

-- every recipe in there is crafted in a genlab out of pyalienlife's samples and fluids and
-- unlocked by bobtech's alien research, so bobenemies supplying the artifacts is only part
-- of what the file needs
if mods['bobenemies'] and mods['pyalienlife'] and mods['bobtech'] then
    require('__AdminUnknownFixes__/prototypes/bobs-mods/prototypes/recipes/alien')
end

if mods['bobtech'] then
    data.raw.lab['bob-lab-2'].allowed_effects = {"consumption", "speed", "productivity"}
    if mods['pyalienlife'] then
        table.insert(data.raw.lab["bob-lab-2"].inputs, 'py-science-pack-1')
        table.insert(data.raw.lab["bob-lab-2"].inputs, 'py-science-pack-2')
        table.insert(data.raw.lab["bob-lab-2"].inputs, 'py-science-pack-3')
        table.insert(data.raw.lab["bob-lab-2"].inputs, 'py-science-pack-4')

        data.raw.recipe['bob-advanced-logistic-science-pack'].categories = {'research'}

        if
            data.raw.item["bob-alien-artifact"]
            and data.raw.item["bob-alien-artifact-blue"]
            and data.raw.item["bob-alien-artifact-orange"]
            and data.raw.item["bob-alien-artifact-purple"]
            and data.raw.item["bob-alien-artifact-yellow"]
            and data.raw.item["bob-alien-artifact-green"]
            and data.raw.item["bob-alien-artifact-red"]
        then
            data.raw.recipe['bob-science-pack-gold'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack-blue'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack-orange'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack-purple'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack-yellow'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack-green'].categories = {'research'}
            data.raw.recipe['bob-alien-science-pack-red'].categories = {'research'}
        end
    end
end