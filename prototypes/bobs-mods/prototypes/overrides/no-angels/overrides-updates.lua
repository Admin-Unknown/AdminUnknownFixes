if mods['bobrevamp'] then
	if mods['pyalienlife'] then
		RECIPE('bio-oil-4'):replace_result('petroleum-gas', 'bob-sour-gas')
	end
end

if mods['bobplates'] then
	if mods['pyrawores'] then

		fun.remove_recipe_unlock('salt')

		data.raw.recipe['salt'] = nil

		if mods['bobores'] then
			--zinc
            data.raw.resource['ore-zinc'] = nil
            data.raw['autoplace-control']['ore-zinc'] = nil
            data.raw.resource['bob-zinc-ore'].minable.fluid_amount = 40
            data.raw.resource['bob-zinc-ore'].minable.required_fluid = 'aromatics'
            --lead
            data.raw.resource['ore-lead'] = nil
            data.raw['autoplace-control']['ore-lead'] = nil
            --aluminuminum
            data.raw.resource['bob-bauxite-ore'] = nil
            data.raw['autoplace-control']['bob-bauxite-ore'] = nil
            data.raw.resource['ore-aluminium'].minable.fluid_amount = 100
        	data.raw.resource['ore-aluminium'].minable.required_fluid = "coal-gas"
            --nickel
            data.raw.resource['ore-nickel'] = nil
            data.raw['autoplace-control']['ore-nickel'] = nil
            data.raw.resource['bob-nickel-ore'].minable.fluid_amount = 40
            data.raw.resource['bob-nickel-ore'].minable.required_fluid = "syngas"
            --titanium
            data.raw.resource['ore-titanium'] = nil
            data.raw['autoplace-control']['ore-titanium'] = nil
            data.raw.resource['bob-rutile-ore'].minable.fluid_amount = 40
            data.raw.resource['bob-rutile-ore'].minable.required_fluid = (mods["pyfusionenergy"] and "acetylene" or "syngas")
            --tin
            data.raw.resource['ore-tin'] = nil
            data.raw['autoplace-control']['ore-tin'] = nil
            data.raw.resource['bob-tin-ore'].minable.fluid_amount = 100
            data.raw.resource['bob-tin-ore'].minable.required_fluid = "steam"
		end

		data.raw.recipe['bob-silver-plate'].enabled = false
    	data.raw.recipe['bob-silver-plate'].hidden = true

    	RECIPE('silver-plate-1'):add_ingredient({type = "item", name = "bob-silver-ore", amount = 18})
    	RECIPE('slz-pulp-01'):add_ingredient({type = "item", name = "bob-silver-ore", amount = 4})
    	RECIPE('sl-01-2'):add_ingredient({type = "item", name = "bob-silver-ore", amount = 6})
    	RECIPE('molten-silver-01'):add_ingredient({type = "item", name = "bob-silver-ore", amount = 4})

        TECHNOLOGY('bob-lead-processing'):add_prereq('silver-mk01')

        RECIPE('bob-gold-plate'):remove_ingredient('bob-gold-ore')
        RECIPE('bob-gold-plate'):add_ingredient({type = "item", name = "bob-gold-ore", amount = 10})

        RECIPE('gold-precipitate'):add_ingredient({type = "item", name = "bob-gold-ore", amount = 5})

        TECHNOLOGY('nickel-mk01'):add_prereq('bob-nickel-processing')

        TECHNOLOGY('bob-invar-processing'):remove_prereq('logistic-science-pack')
        TECHNOLOGY('bob-invar-processing'):remove_pack('logistic-science-pack')
	end
    -- ceramic is pyhightech's, and nothing about bobplates guarantees that mod
    if mods['pyhightech'] then
        RECIPE('bob-silicon-nitride'):add_ingredient({type = "item", name = "ceramic", amount = 5})
    end

    if settings.startup["bobmods-plates-purewater"].value and settings.startup["bobmods-assembly-distilleries"].value then
        for i, machine in pairs(data.raw['assembling-machine']) do
            for c, machinecat in pairs(machine.crafting_categories) do
                if machinecat == 'bob-distillery' then
                    machine.crafting_categories[c] = nil
                end
            end
        end

        -- Bob's 2.x renamed the category and made the distilleries furnaces rather than
        -- assembling machines, so keep the category on them after the sweep above
        for _, distillery in pairs({'bob-distillery', 'bob-distillery-2', 'bob-distillery-3', 'bob-distillery-4', 'bob-distillery-5'}) do
            bobmods.lib.machine.add_category(data.raw.furnace[distillery], 'bob-distillery')
        end

        data.raw.furnace['bob-distillery'].allowed_effects = {"speed", "consumption"}
        data.raw.furnace['bob-distillery-2'].allowed_effects = {"speed", "consumption"}
        data.raw.furnace['bob-distillery-3'].allowed_effects = {"speed", "consumption"}
        data.raw.furnace['bob-distillery-4'].allowed_effects = {"speed", "consumption"}
        data.raw.furnace['bob-distillery-5'].allowed_effects = {"speed", "consumption"}
    end
end

if mods['bobelectronics'] then
	if mods['pycoalprocessing'] then
		if data.raw.recipe['bob-ferric-chloride-solution'] then
            RECIPE('bob-ferric-chloride-solution'):add_unlock('sulfur-processing')
            RECIPE('bob-ferric-chloride-solution'):set_fields{ categories = {"chemistry"} }:set_fields{energy_required = 3}
            RECIPE('bob-ferric-chloride-solution'):remove_ingredient('iron-ore')
            RECIPE('bob-ferric-chloride-solution'):add_ingredient({type = "fluid", name = "acidgas", amount = 5}):add_ingredient({type = "item", name = "iron-ore", amount = 10})
            table.insert(data.raw.recipe['bob-ferric-chloride-solution'].results, {type = "fluid", name = "acidgas", amount = 6, probability = 0.5})
        end
	end

    if mods['pyrawores'] then
        --data.raw.recipe['tinned-copper-cable'].hidden = true
    end

	if mods['pypetroleumhandling'] then
		RECIPE('bob-synthetic-wood'):add_unlock('heavy-oil-mk01')
		RECIPE('bob-synthetic-wood'):remove_unlock('plastics')
		RECIPE('bob-resin-oil'):add_unlock('heavy-oil-mk01')
	end

	if mods['pyhightech'] then

		data.raw.recipe['module-processer-board-3'] = nil
        data.raw.recipe['multi-layer-circuit-board'] = nil
        data.raw.recipe['bob-processing-electronics'] = nil
        data.raw.recipe['bob-advanced-processing-unit'] = nil

        fun.global_prereq_replacer('bob-advanced-processing-unit', 'nano-tech')

        data.raw.technology['bob-advanced-processing-unit'] = nil

        RECIPE('pcb4'):add_ingredient({type = "fluid", name = "bob-ferric-chloride-solution", amount = 100})

        -- these belong to bobmining, bobpower, bobtech and friends, none of which
        -- bobelectronics brings along, and TECHNOLOGY() on a missing tech is fatal
        for _, tech in pairs({
            'bob-repair-pack-3', 'bob-drills-2', 'bob-area-drills-2',
            'bob-vehicle-shield-equipment-1', 'bob-personal-roboport-modular-equipment-1',
            'bob-fluid-generator-2', 'bob-vehicle-roboport-modular-equipment-1',
            'bob-electronics-machine-2', 'bob-electric-energy-accumulators-2',
            'bob-electric-substation-2', 'bob-advanced-research',
            'bob-vehicle-laser-defense-equipment-2',
        }) do
            if data.raw.technology[tech] then
                TECHNOLOGY(tech):add_prereq('basic-electronics'):remove_prereq('advanced-circuit')
            end
        end
	end

	if mods['pyalienlife'] then
		RECIPE('bob-resin-oil'):remove_ingredient('heavy-oil'):add_ingredient({type = "fluid", name = "heavy-oil", amount = 1}):replace_result('saps', {'saps', amount = 2})
	end
end

if mods['bobrevamp'] then
    if bobmods.plates and settings.startup["bobmods-revamp-rtg"].value and settings.startup["bobmods-revamp-hardmode"].value then
        bobmods.lib.recipe.remove_result('bob-ammoniated-brine', 'bob-ammoniated-brine')
        bobmods.lib.recipe.add_result("bob-ammoniated-brine", { type = "fluid", name = "bob-ammoniated-brine", amount = 35 })
        if mods['pyalternativeenergy'] then
            require('__AdminUnknownFixes__/prototypes/bobs-mods/prototypes/recipes/sodium-carbonate')
            bobmods.lib.recipe.remove_result('bob-ammonium-chloride-reprocessing', 'ammonia')
                bobmods.lib.recipe.add_result("bob-ammonium-chloride-reprocessing", { type = "fluid", name = "ammonia", amount = 30 })

            bobmods.lib.tech.add_prerequisite('nuclear-power-mk02', 'bob-rtg')
            bobmods.lib.tech.add_prerequisite('spidertron', 'nuclear-power-mk02')

            fun.tech_remove_recipe('bob-rtg', 'bob-rtg')
        end
    end
end