-- DATA UPDATES STAGE OVERRIDES

if mods['angelsrefining'] then
    OV = angelsmods.functions.OV
    -- Angels 2.0 may rename/remove recipe categories; never reference a category that is not defined.
    local function add_crafting_category(entity_type, entity_name, category_name)
        local cat = data.raw["recipe-category"] and data.raw["recipe-category"][category_name]
        local ent = data.raw[entity_type] and data.raw[entity_type][entity_name]
        if cat and ent and ent.crafting_categories then
            table.insert(ent.crafting_categories, category_name)
        end
    end
    -- replace miner fluid
    if data.raw.fluid['angels-gas-synthesis'] ~= nil then
        if data.raw.resource['borax'] ~= nil then
            data.raw.resource['borax'].minable.required_fluid = 'angels-gas-synthesis'
        end
        if data.raw.resource['phosphate-rock'] ~= nil then
            data.raw.resource['phosphate-rock'].minable.required_fluid = 'angels-gas-synthesis'
        end
        if data.raw.resource['angels-nickel-ore'] ~= nil then
            data.raw.resource['angels-nickel-ore'].minable.required_fluid = 'angels-gas-synthesis'
        end
    end
    --merge angel's washers to py's
    add_crafting_category("assembling-machine", "washer", "angels-washing-plant")
    data.raw.recipe['angels-washing-plant'] = nil
    fun.remove_recipe_unlock('angels-washing-plant')
    --merge angels filters to py
    add_crafting_category("assembling-machine", "carbon-filter", "angels-filtering")
    data.raw.recipe['angels-filtration-unit'] = nil
    fun.remove_recipe_unlock('angels-filtration-unit')
    if mods['pyalienlife'] then TECHNOLOGY('soil-washing'):add_prereq('angels-water-washing-1') end
    -- change barreling machine
    if mods['pyindustry'] then
        data.raw.recipe['angels-barreling-pump'] = nil
        fun.remove_recipe_unlock('angels-barreling-pump')
        add_crafting_category("furnace", "barrel-machine-mk01", "angels-barreling-pump")
    end
    if mods['pyrawores'] then
        --mk02
        add_crafting_category("assembling-machine", "carbon-filter-mk02", "angels-filtering")
        add_crafting_category("assembling-machine", "carbon-filter-mk02", "angels-filtering-2")
        data.raw.recipe['angels-filtration-unit-2'] = nil
        fun.remove_recipe_unlock('angels-filtration-unit-2')
        --mk03
        add_crafting_category("assembling-machine", "carbon-filter-mk03", "angels-filtering")
        add_crafting_category("assembling-machine", "carbon-filter-mk03", "angels-filtering-2")
        add_crafting_category("assembling-machine", "carbon-filter-mk03", "angels-filtering-3")
        data.raw.recipe['angels-filtration-unit-3'] = nil
        fun.remove_recipe_unlock('angels-filtration-unit-3')
        --mk04
        add_crafting_category("assembling-machine", "carbon-filter-mk04", "angels-filtering")
        add_crafting_category("assembling-machine", "carbon-filter-mk04", "angels-filtering-2")
        add_crafting_category("assembling-machine", "carbon-filter-mk04", "angels-filtering-3")
        --merge angel's washers to py's
        --mk02
        add_crafting_category("assembling-machine", "washer-mk02", "angels-washing-plant")
        data.raw.recipe['angels-washing-plant-2'] = nil
        fun.remove_recipe_unlock('angels-washing-plant-2')
        if mods['ExtendedAngels'] then
            --mk03
            add_crafting_category("assembling-machine", "washer-mk03", "angels-washing-plant")
            data.raw.recipe['angels-washing-plant-3'] = nil
            fun.remove_recipe_unlock('angels-washing-plant-3')
            --mk04
            add_crafting_category("assembling-machine", "washer-mk04", "angels-washing-plant")
            data.raw.recipe['angels-washing-plant-4'] = nil
            fun.remove_recipe_unlock('angels-washing-plant-4')
        end
        -- merge angels flotation cell into pys cell
        -- mk01
        add_crafting_category("assembling-machine", "flotation-cell-mk01", "angels-ore-refining-t2")
        data.raw.recipe['angels-ore-floatation-cell'] = nil
        fun.remove_recipe_unlock('angels-ore-floatation-cell')
        -- mk02
        add_crafting_category("assembling-machine", "flotation-cell-mk02", "angels-ore-refining-t2")
        data.raw.recipe['angels-ore-floatation-cell-2'] = nil
        fun.remove_recipe_unlock('angels-ore-floatation-cell-2')
        -- mk03
        add_crafting_category("assembling-machine", "flotation-cell-mk03", "angels-ore-refining-t2")
        data.raw.recipe['angels-ore-floatation-cell-3'] = nil
        fun.remove_recipe_unlock('angels-ore-floatation-cell-3')
        -- add category to py mk04
        add_crafting_category("assembling-machine", "flotation-cell-mk04", "angels-ore-refining-t2")
        -- merge angels leaching stations into pys stati9ons
        -- mk01
        add_crafting_category("assembling-machine", "leaching-station-mk01", "angels-ore-refining-t3")
        data.raw.recipe['angels-ore-leaching-plant'] = nil
        fun.remove_recipe_unlock('angels-ore-leaching-plant')
        -- mk02
        add_crafting_category("assembling-machine", "leaching-station-mk02", "angels-ore-refining-t3")
        data.raw.recipe['angels-ore-leaching-plant-2'] = nil
        fun.remove_recipe_unlock('angels-ore-leaching-plant-2')
        -- mk03
        add_crafting_category("assembling-machine", "leaching-station-mk03", "angels-ore-refining-t3")
        data.raw.recipe['angels-ore-leaching-plant-3'] = nil
        fun.remove_recipe_unlock('angels-ore-leaching-plant-3')
        -- add category to py mk04
        add_crafting_category("assembling-machine", "leaching-station-mk04", "angels-ore-refining-t3")
        if mods['SeaBlock'] then goto skipseablock end
        if angelsmods.trigger.ores["lead"] then
            data.raw.resource['angels-lead-ore'] = nil
            data.raw['autoplace-control']['angels-lead-ore'] = nil
            data.raw.resource['angels-ore5'].category = 'basic-with-fluid'
            data.raw.resource['angels-ore5'].minable.fluid_amount = 100
            data.raw.resource['angels-ore5'].minable.required_fluid = 'acetylene'
            fun.tech_add_prerequisites('solder-mk01', 'angels-ore-crushing')
        end
        if angelsmods.trigger.ores["nickel"] then
            data.raw.resource['angels-nickel-ore'] = nil
            data.raw['autoplace-control']['angels-nickel-ore'] = nil
            fun.tech_add_prerequisites('nickel-mk01', 'angels-ore-crushing')
        end
        if angelsmods.trigger.ores["tin"] then
            data.raw.resource['angels-tin-ore'] = nil
            data.raw['autoplace-control']['angels-tin-ore'] = nil
            if data.raw.recipe['tin-plate-1'] then
                data.raw.recipe['tin-plate-1'].hidden = true
            end
            data.raw.resource['angels-ore6'].category = 'basic-with-fluid'
            data.raw.resource['angels-ore6'].minable.fluid_amount = 100
            data.raw.resource['angels-ore6'].minable.required_fluid = 'steam'
            fun.tech_add_prerequisites('solder-mk01', 'angels-ore-crushing')
        end
        if angelsmods.trigger.ores["zinc"] then
            data.raw.resource['angels-zinc-ore'] = nil
            data.raw['autoplace-control']['angels-zinc-ore'] = nil
            fun.tech_add_prerequisites('solder-mk01', 'angels-ore-crushing')
        end
        ::skipseablock::

        RECIPE('washer'):remove_ingredient('electronic-circuit')
        RECIPE('washer'):add_ingredient({type = "item", name = "small-parts-01", amount = 15})
        RECIPE('angels-seafloor-pump'):remove_ingredient('electronic-circuit')
        RECIPE('angels-seafloor-pump'):add_ingredient({type = "item", name = "small-parts-01", amount = 10})
    end
    if mods['pyhightech'] then
        if data.raw.technology["electronics"] and data.raw.technology["angels-water-treatment"] then
            TECHNOLOGY("angels-water-treatment"):add_prereq("electronics")
        end
    end
    if mods['pyalienlife'] then
        RECIPE('empty-planter-box'):remove_ingredient('stone-brick'):add_ingredient({type = "item", name = "stone-brick", amount = 2})
    end
    if mods['pyhardmode'] then
        data.raw.recipe['angels-stone-crushed'].enabled = false
        data.raw.recipe['angels-stone-crushed'].hidden = true

        RECIPE('hpf-stone-from-crush'):add_ingredient({type = "fluid", name = "carbolic-oil", amount = 10})

        data.raw.resource['angels-ore3'].minable.fluid_amount = 200
        data.raw.resource['angels-ore3'].minable.required_fluid = 'water'
    end
    if mods['pyblock'] then
        RECIPE('fawogae-to-iron'):set_fields{ results = {{type = "item", name = "angels-ore1", amount = 5}} }
    end
end

if mods['angelspetrochem'] then
    if mods['pyindustry'] then
        for name, recipe in pairs(data.raw.recipe) do
            local is_chem_void = false
            if recipe.categories then
                for _, c in pairs(recipe.categories) do
                    if c == 'angels-chemical-void' then is_chem_void = true break end
                end
            elseif recipe.category == 'angels-chemical-void' then
                is_chem_void = true
            end
            if is_chem_void then
                recipe.categories = {'py-venting'}
                recipe.category = nil
            end
        end
    end
    if mods['pypetroleumhandling'] then
        data.raw.recipe['rocket-fuel'].ingredients = {}
        --RECIPE('rocket-fuel'):remove_ingredient('gas-oxygen'):remove_ingredient('kerosene')
        RECIPE('rocket-fuel'):add_ingredient({type = "item", name = "angels-rocket-fuel-capsule", amount = 10}):add_ingredient({type = "item", name = "angels-rocket-oxidizer-capsule", amount = 10})
        RECIPE('angels-rocket-fuel-capsule'):add_ingredient({type = "fluid", name = "kerosene", amount = 50})
        RECIPE('angels-rocket-oxidizer-capsule'):add_ingredient({type = "fluid", name = "gas-oxygen", amount = 75})
    end
    if mods['pyrawores'] then
        data.raw.recipe['angels-air-separation'] = nil
        fun.remove_recipe_unlock('angels-air-separation')
    end
    if mods['pyfusionenergy'] then
        fun.tech_remove_recipe('fluid-pressurization', 'pressured-air')
        RECIPE('angels-air-filter'):replace_ingredient('basic-circuit-board', 'small-parts-01')
        if mods['pyhightech'] then
            if data.raw.technology["angels-water-treatment"] then
                TECHNOLOGY("angels-water-treatment"):remove_prereq("angels-fluid-control")
            end
            if data.raw.technology["electronics"] then
                TECHNOLOGY("electronics"):add_prereq("angels-nitrogen-processing-1")
                if not mods["SeaBlock"] and data.raw.technology["angels-basic-chemistry"] then
                    TECHNOLOGY("angels-basic-chemistry"):add_prereq("electronics")
                end
            end
        end
    end
    if mods['pyhightech'] then
        if data.raw.technology["melamine"] then
            TECHNOLOGY("melamine"):add_prereq("angels-resins")
        end
        if data.raw.recipe["melamine-resin"] then
            RECIPE("melamine-resin"):add_ingredient({ type = "fluid", name = "saps", amount = 10 })
        end
        if data.raw.fluid["angels-gas-urea"] and data.raw.item["urea"] then
            require('__AdminUnknownFixes__/prototypes/angels-mods/prototypes/recipes/urea')
        end
    end
    if mods['pyalienlife'] then
        if data.raw.technology['angels-basic-chemistry-3'] then
            TECHNOLOGY('angels-basic-chemistry-3'):add_prereq('py-science-pack-mk01')
        end
        if data.raw.technology['angels-resin-1'] then
            TECHNOLOGY('angels-resin-1'):remove_prereq('angels-nitrogen-processing-2')
        end
        if data.raw.technology['melamine'] then
            TECHNOLOGY('melamine'):add_prereq('angels-resins')
        end

        RECIPE('angels-solid-resin'):set_fields{ results = {{type = "item", name = "saps", amount = 40}} }
    end
    if mods['pyhardmode'] then
        --This code is by NotNotMelon
        for _, void_machine in pairs{'angels-clarifier', 'angels-flare-stack'} do
            data.raw['assembling-machine'][void_machine] = data.raw.furnace[void_machine]
            data.raw['assembling-machine'][void_machine].type = 'assembling-machine'
            data.raw['assembling-machine'][void_machine].crafting_speed = 1
            data.raw['assembling-machine'][void_machine].energy_source = {
                type = 'electric',
                usage_priority = 'secondary-input',
                emissions_per_minute = {pollution = 0},
            }
            data.raw['assembling-machine'][void_machine].energy_usage = '100kW'
            data.raw.furnace[void_machine] = nil
        end

        for name, recipe in pairs(data.raw.recipe) do
            local is_water_void = false
            if recipe.categories then
                for _, c in pairs(recipe.categories) do
                    if c == 'angels-water-void' then is_water_void = true break end
                end
            elseif recipe.category == 'angels-water-void' then
                is_water_void = true
            end
            if is_water_void then
                if recipe ~= data.raw.recipe['angels-water-void-water-saline'] then
                    if recipe ~= data.raw.recipe['angels-water-void-water-purified'] then
                        data.raw.recipe[name] = nil
                    end
                end
            end
        end
        fun.tech_remove_recipe('angels-water-treatment', 'angels-clarifier')
    
        RECIPE('angels-clarifier'):add_unlock('angels-water-treatment-2')

        RECIPE('angels-water-void-water-saline'):add_ingredient({type = "item", name = "filtration-media", amount = 1}):add_unlock('angels-water-treatment-2')
        RECIPE('angels-water-void-water-purified'):add_ingredient({type = "item", name = "filtration-media", amount = 1}):add_unlock('angels-water-treatment-2')

        TECHNOLOGY('angels-water-treatment-2'):add_prereq('filtration')

        data.raw['assembling-machine']['angels-clarifier'].crafting_speed = 5
    end
end

if mods['angelssmelting'] then
    TECHNOLOGY('angels-metallurgy-2'):add_prereq('logistic-science-pack')
    if mods['pyfusionenergy'] then
        RECIPE('angels-mono-silicon-1'):set_fields{ categories = {"hpf"} }
        RECIPE('angels-mono-silicon-2'):set_fields{ categories = {"hpf"} }
    end
    if mods['pyrawores'] then
        RECIPE('angels-solder-mixture'):remove_ingredient('angels-plate-lead'):add_ingredient({type = "item", name = "angels-plate-lead", amount = 4})

        TECHNOLOGY('angels-solder-smelting-1'):add_prereq('acetylene')

        fun.tech_remove_recipe('solder-mk01', 'solder-0')
        fun.tech_remove_recipe('solder-mk01', 'lead-plate-1')

        fun.tech_add_recipe('angels-solder-smelting-1', 'lead-plate-1')

        data.raw.recipe['solder-0'] = nil

    end
    if mods['pyalienlife'] then
        TECHNOLOGY('angels-metallurgy-1'):add_prereq('hot-air-mk01')

        TECHNOLOGY('angels-metallurgy-1'):add_pack('py-science-pack-1'):add_prereq('py-science-pack-mk01')
        TECHNOLOGY('angels-copper-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-iron-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-lead-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-tin-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-solder-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-steel-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-manganese-smelting-1'):add_pack('py-science-pack-1')

        TECHNOLOGY('angels-stone-smelting-1'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-powder-metallurgy-1'):add_pack('py-science-pack-1')
    end
    if mods['pyalternativeenergy'] then
        fun.tech_remove_recipe('silicon-mk01', 'silicon')

        data.raw.recipe['silicon'] = nil

        TECHNOLOGY('angels-silicon-casting-2'):add_prereq('silicon-mk03')
        TECHNOLOGY('angels-silicon-casting-2'):add_pack('production-science-pack')
    end
end

if mods['angelsindustries'] then
    if mods['pyalternativeenergy'] then
        local function add_crafting_category(entity_type, entity_name, category_name)
            local cat = data.raw["recipe-category"] and data.raw["recipe-category"][category_name]
            local ent = data.raw[entity_type] and data.raw[entity_type][entity_name]
            if cat and ent and ent.crafting_categories then
                table.insert(ent.crafting_categories, category_name)
            end
        end
        add_crafting_category("assembling-machine", "centrifuge-mk02", "angels-centrifuging-2")
        add_crafting_category("assembling-machine", "centrifuge-mk03", "angels-centrifuging-2")
        add_crafting_category("assembling-machine", "centrifuge-mk03", "angels-centrifuging-3")
        add_crafting_category("assembling-machine", "centrifuge-mk04", "angels-centrifuging-2")
        add_crafting_category("assembling-machine", "centrifuge-mk04", "angels-centrifuging-3")
    end
end

if mods['angelsbioprocessing'] then
    if mods['pyhightech'] then
        if data.raw.technology["electronics"] and data.raw.technology["angels-bio-processing-green"] then
            TECHNOLOGY("angels-bio-processing-green"):add_prereq("electronics")
        end
        fun.tech_merge('angels-plastic-1', 'plastics-mk02')
        fun.tech_merge('angels-plastic-2', 'plastics-mk03')
        fun.tech_merge('angels-plastic-3', 'plastics-mk04')
    end

    if mods['pyalienlife'] then
        data.raw.recipe['angels-algae-green-simple'] = nil

        fun.remove_recipe_unlock('angels-algae-green-simple')

        if data.raw.recipe['angels-puffer-butchery-1'] then
            RECIPE('angels-puffer-butchery-1'):add_result({type = "item", name = "gas-bladder", amount = 1})
            data.raw.recipe['angels-puffer-butchery-1'].main_product = "gas-bladder"
        end
    end
    if mods['pyalternativeenergy'] then
        RECIPE('eg-si'):add_ingredient({type = "item", name = "angels-crystal-grindstone", amount = 1})
    end
end

if mods['angelsexploration'] then
    TECHNOLOGY('angels-turbo-bike'):remove_prereq('steel-processing'):add_prereq('engine')
    RECIPE('angels-turbo-bike'):remove_ingredient('steel-plate'):add_ingredient({type = "item", name = "engine-unit", amount = 2})
    if mods['pyalienlife'] then
        TECHNOLOGY('angels-automobilism'):add_prereq('py-science-pack-mk01')
    end
end

if mods['angelsaddons-storage'] then
    fun.tech_add_recipe('py-storage-tanks', 'angels-storage-tank-3')
    fun.tech_remove_recipe('fluid-handling', 'angels-storage-tank-3')
    TECHNOLOGY('angels-logistic-silos'):remove_pack("py-science-pack-2"):remove_pack("chemical-science-pack")
    TECHNOLOGY('angels-logistic-warehouses'):remove_pack("py-science-pack-2"):remove_pack("chemical-science-pack")
    if mods['bobtech'] then
        TECHNOLOGY('angels-logistic-silos'):remove_pack("bob-advanced-logistic-science-pack")
        TECHNOLOGY('angels-logistic-warehouses'):remove_pack("bob-advanced-logistic-science-pack")
    end  
    if mods['pyrawores'] then
        RECIPE('angels-storage-tank-3'):add_ingredient({type = "item", name = "pipe", amount = 15})
        RECIPE('angels-storage-tank-3'):add_ingredient({type = "item", name = "duralumin", amount = 10})
        RECIPE('angels-storage-tank-3'):add_ingredient({type = "item", name = "lead-plate", amount = 10})
    end
end
