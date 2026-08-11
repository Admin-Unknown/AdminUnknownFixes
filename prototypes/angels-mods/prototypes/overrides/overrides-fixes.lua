-- DATA FINAL FIXES STAGE OVERRIDES
-- Factorio 2.0: TechnologyUnit.ingredients are ResearchIngredient = { ItemID, uint16 }, not IngredientPrototype tables.
local function set_to_py1(techname)
    if not data.raw.technology[techname] then return end 
    data.raw.technology[techname].unit.ingredients = {
        {"automation-science-pack", 2},
        {"py-science-pack-1", 1}
    }
end

-- PyCoalProcessing removes tech oil-gathering; Angel's (and others) may still list it as a prerequisite.
local function remove_missing_prereq_from_all_technologies(prereq_name)
    if not prereq_name or data.raw.technology[prereq_name] then
        return
    end
    for _, tech in pairs(data.raw.technology) do
        local pre = tech.prerequisites
        if pre then
            for i = #pre, 1, -1 do
                if pre[i] == prereq_name then
                    table.remove(pre, i)
                end
            end
        end
    end
end
remove_missing_prereq_from_all_technologies("oil-gathering")

if mods['angelsrefining'] then
    if mods['pyalienlife'] then
        set_to_py1('angels-ore-floatation')
        set_to_py1('angels-water-treatment-2')
    end
end

if mods['angelssmelting'] then
    data.raw.recipe['steel-plate'].hidden = false
    RECIPE('steel-plate'):add_unlock('steel-processing'):remove_ingredient('gas-oxygen')

    if mods['pyrawores'] then
        TECHNOLOGY('angels-solder-smelting-1'):add_prereq('acetylene')

        fun.global_prereq_replacer('solder-mk01', 'angels-solder-smelting-1')

        data.raw.technology['solder-mk01'].hidden = true
        data.raw.technology['solder-mk01'].enabled = false
        data.raw.technology['solder-mk01'].effects = {}

        TECHNOLOGY('steel-processing'):add_prereq('angels-water-washing-1')

        fun.tech_remove_recipe('coal-processing-1', 'extract-limestone-01')

        data.raw.recipe['extract-limestone-01'].enabled = false
        data.raw.recipe['extract-limestone-01'].hidden = true
    end
    if mods['pyalternativeenergy'] then
        fun.tech_add_prerequisites('silicon-mk01', 'angels-silicon-smelting-1')
    end
end

if mods['angelspetrochem'] then
    if mods['pyhightech'] then
        TECHNOLOGY('angels-nitrogen-processing-1'):remove_prereq('angels-basic-chemistry')
        if data.raw.technology["electronics"] then
            TECHNOLOGY("electronics"):add_prereq("angels-nitrogen-processing-1")
        end
    end
    if mods['pyalienlife'] then
        local chem3 = data.raw.technology['angels-basic-chemistry-3']
        if chem3 and chem3.unit and chem3.unit.ingredients then
            for i, ingredient in pairs(chem3.unit.ingredients) do
                local pack = ingredient[1] or ingredient.name
                if pack == "logistic-science-pack" then
                    chem3.unit.ingredients[i] = nil
                end
            end
        end

        set_to_py1('angels-advanced-chemistry-1')
        set_to_py1('angels-basic-chemistry-3')
        set_to_py1('angels-resins')
        set_to_py1('angels-resin-1')
        if mods['pypetroleumhandling'] then
            TECHNOLOGY('angels-nitrogen-processing-4'):remove_prereq('angels-advanced-chemistry-5'):remove_pack('utility-science-pack')
            TECHNOLOGY('angels-nitrogen-processing-4'):add_prereq('py-science-pack-3')
        end
    end
end

if mods['angelsbioprocessing'] then
    local function set_artifact_tech_unit_ingredients(tech_name, item_name)
        local t = data.raw.technology[tech_name]
        if t and t.unit then
            t.unit.ingredients = {
                { item_name, 1 },
            }
        end
    end

    set_artifact_tech_unit_ingredients("angels-alien-artifact-red", "alien-artifact-red-tool")
    set_artifact_tech_unit_ingredients("angels-alien-artifact-orange", "alien-artifact-orange-tool")
    set_artifact_tech_unit_ingredients("angels-alien-artifact-yellow", "alien-artifact-yellow-tool")
    set_artifact_tech_unit_ingredients("angels-alien-artifact-green", "alien-artifact-green-tool")
    set_artifact_tech_unit_ingredients("angels-alien-artifact-blue", "alien-artifact-blue-tool")
    set_artifact_tech_unit_ingredients("angels-alien-artifact-purple", "alien-artifact-purple-tool")
    set_artifact_tech_unit_ingredients("angels-alien-artifact", "alien-artifact-tool")
    if mods['pyalienlife'] then
        set_to_py1('angels-bio-fermentation')
        set_to_py1('angels-bio-arboretum-temperate-1')
    end
    if mods['pyalternativeenergy'] then
        TECHNOLOGY('silicon-mk01'):add_prereq('angels-bio-processing-crystal-splinter-1')
    end
end

if mods['angelsaddons-storage'] then
    if mods['pyalternativeenergy'] then
        TECHNOLOGY('angels-pressure-tanks'):add_prereq('intermetallics-mk02'):add_pack("py-science-pack-2")
        RECIPE('angels-pressure-tank-1'):remove_ingredient("steel-plate"):add_ingredient({type = "item", name = "self-assembly-monolayer", amount = 10})
    elseif mods['pyalienlife'] then
        TECHNOLOGY("angels-pressure-tanks"):add_prereq("py-science-pack-mk01")
        fun.removescipack('angels-pressure-tanks', 'logistic-science-pack')
    end
    if mods['pyindustry'] then
        RECIPE('angels-pressure-tank-1'):replace_ingredient("pipe", "niobium-pipe")
    end
    if mods['pyfusionenergy'] then
        RECIPE('angels-pressure-tank-1'):set_fields{ categories = {'crafting-with-fluid'} }
        RECIPE('angels-pressure-tank-1'):add_ingredient({type = "item", name = "vacuum-pump-mk01", amount = 5}):add_ingredient({type = "item", name = "advanced-circuit", amount = 1}):add_ingredient({type = "fluid", name = "vacuum", amount = 200})
    end
    if mods['pyrawores'] then
        RECIPE('angels-pressure-tank-1'):replace_ingredient("stone-brick", "stainless-steel")
    end
end
