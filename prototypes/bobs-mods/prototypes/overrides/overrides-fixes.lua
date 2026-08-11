
if mods['bobassembly'] then
    TECHNOLOGY('automation'):add_prereq('basic-automation')
    if mods['pyalternativeenergy'] then
        --[[
        data.raw["assembling-machine"]["centrifuge"].next_upgrade = nil
        data.raw["assembling-machine"]["bob-centrifuge-2"].next_upgrade = nil
        data.raw["assembling-machine"]["bob-centrifuge-3"].next_upgrade = nil
        ]]--
    end

end
if mods['bobplates'] then
    -- nitrogen is pyrawores', not bobplates'
    if data.raw.recipe['nitrogen'] then
        data.raw.recipe['nitrogen'].hidden = false
    end

    data.raw['assembling-machine']['assembling-machine-3'].allowed_effects = {"consumption", "speed", "productivity", "pollution"}

    fun.tech_merge('bob-fluid-canister-processing', 'plastics')
    TECHNOLOGY('plastics'):add_prereq('fluid-handling')
    if data.raw.technology['bob-gas-canisters'] then
        TECHNOLOGY('bob-gas-canisters'):add_prereq('bob-fluid-barrel-processing')
        TECHNOLOGY('bob-gas-canisters'):remove_pack('logistic-science-pack'):remove_pack('py-science-pack-1')
    end
    if mods['pyrawores'] then
        if not mods['angelspetrochem'] then
            fun.global_prereq_replacer('bob-electrolysis-1', 'electrolysis')
            fun.tech_merge_effects('bob-electrolysis-1', 'electrolysis')
            fun.tech_remove_recipe('electrolysis', 'electrolyser')
        end
        data.raw.technology['bob-electrolysis-1'] = nil

        RECIPE('ball-mill-mk01'):add_ingredient({type = "item", name = "bob-steel-bearing-ball", amount = 1000})
        RECIPE('ball-mill-mk02'):add_ingredient({type = "item", name = "bob-steel-bearing-ball", amount = 1000})
        RECIPE('ball-mill-mk03'):add_ingredient({type = "item", name = "bob-steel-bearing-ball", amount = 1000})
        RECIPE('ball-mill-mk04'):add_ingredient({type = "item", name = "bob-steel-bearing-ball", amount = 1000})
    end
    if mods['pyalienlife'] then
        TECHNOLOGY('vrauks'):remove_prereq('fluid-handling'):add_prereq('bob-fluid-barrel-processing')
    end
end

if mods['bobwarfare'] then
    if mods['pyalienlife'] then
        TECHNOLOGY('bob-rocket'):remove_pack("production-science-pack"):remove_pack("production-science-pack")
    end
end
