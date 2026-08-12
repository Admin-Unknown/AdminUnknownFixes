if mods['angelsindustries'] then
    RECIPE('soil-extractormk01'):remove_ingredient('block-electronics-1'):add_ingredient({type = "item", name = "block-electronics-0", amount = 1}):remove_ingredient('construction-frame-1'):add_ingredient({type = "item", name = "construction-frame-1", amount = 5})
    RECIPE('collector'):replace_ingredient('block-electronics-1', 'block-electronics-0'):remove_ingredient('construction-frame-1')
    RECIPE('hpf'):replace_ingredient('block-electronics-1', 'block-electronics-0')
    RECIPE('distilator'):replace_ingredient('block-electronics-1', 'block-electronics-0')
    RECIPE('wpu'):remove_ingredient('cable-harness-1'):add_ingredient({type = "item", name = "cable-harness-1", amount = 10})
    RECIPE('car'):replace_ingredient('motor-2', 'motor-1')
    if mods['pypetroleumhandling'] then
        RECIPE('mechanical-parts-gear'):replace_ingredient('mechanical-parts', 'small-parts-01')
    end

    TECHNOLOGY('angels-automobilism'):add_prereq('angels-components-mechanical-1')
    if mods['pyhightech'] and angelsmods.industries.components == true then
        for _, v in pairs(data.raw.technology['tech-red-circuit'].effects) do
            table.insert(data.raw.technology['electronics'].effects, v)
        end
        fun.global_prereq_replacer('tech-red-circuit', 'electronics')

        data.raw.technology['tech-red-circuit'].hidden = true
        data.raw.technology['tech-red-circuit'].enabled = false
        data.raw.technology['tech-red-circuit'].effects = {}

        data.raw.recipe['electronic-circuit'].enabled = true
        data.raw.recipe['electronic-circuit'].hidden = false

        data.raw.recipe['circuit-red-loaded'].enabled = false
        data.raw.recipe['circuit-red-loaded'].hidden = true

        data.raw.recipe['circuit-red'].enabled = false
        data.raw.recipe['circuit-red'].hidden = true

        fun.tech_remove_recipe('electronics', 'circuit-red-loaded')
        fun.tech_remove_recipe('electronics', 'circuit-red')

        fun.tech_add_recipe('electronics', 'electronic-circuit')

        RECIPE('circuit-red-board'):add_ingredient({type = "item", name = "formica", amount = 2})
        RECIPE('pcb1'):add_ingredient({type = "item", name = "circuit-red-board", amount = 1}):remove_ingredient('formica')
        RECIPE('electronic-circuit'):add_ingredient({type = "item", name = "circuit-resistor", amount = 2})
    end
    OV.remove_science_pack({'angels-rocket', 'angels-rocket-fusion-reactor', 'angels-rocket-hull', 'angels-rocket-ion-thruster', 'angels-rocket-shield-array'}, 'utility-science-pack')
    OV.remove_science_pack({'angels-rocket', 'angels-rocket-fusion-reactor', 'angels-rocket-hull', 'angels-rocket-ion-thruster', 'angels-rocket-shield-array'}, 'py-science-pack-4')
    OV.remove_science_pack({'angels-rocket', 'angels-rocket-fusion-reactor', 'angels-rocket-hull', 'angels-rocket-ion-thruster', 'angels-rocket-shield-array'}, 'production-science-pack')

    -- the pack is pyalienlife's; angelsindustries does not require it
    if mods['pyalienlife'] then
        TECHNOLOGY('angels-rocket'):add_pack("py-science-pack-3")
        TECHNOLOGY('angels-rocket-hull'):add_pack("py-science-pack-3")
        TECHNOLOGY('angels-rocket-ion-thruster'):add_pack("py-science-pack-3")
        TECHNOLOGY('angels-rocket-shield-array'):add_pack("py-science-pack-3")
        TECHNOLOGY('angels-rocket-fusion-reactor'):add_pack("py-science-pack-3")
    end

    OV.add_prereq('rocket-silo', {'angels-rocket-fusion-reactor', 'angels-rocket-hull', 'angels-rocket-ion-thruster', 'angels-rocket-shield-array'})
    OV.remove_prereq('rocket-silo', {'low-density-stucture', 'rocket-control-unit', 'rocket-fuel'})

    OV.add_prereq('angels-rocket-fusion-reactor', 'nuclear-power')
    OV.remove_prereq('angels-rocket-fusion-reactor', 'angels-fusion-power-1')

    RECIPE('angels-rocket-fusion-reactor'):replace_ingredient('angels-deuterium-fuel-cell', 'uranium-fuel-cell')
    if mods['pyalienlife'] then
        TECHNOLOGY('angels-components-construction-2'):add_pack('py-science-pack-1')
        TECHNOLOGY('angels-components-batteries-1'):add_pack('py-science-pack-1')
    end

    RECIPE('py-burner'):remove_ingredient('construction-frame-4')
end