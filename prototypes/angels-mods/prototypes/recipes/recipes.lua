if mods['angelsrefining'] then
	RECIPE {
    	type = "recipe",
    	name = "hpf-stone-from-crush",
    	categories = {"hpf"},
    	energy_required = 1,
    	ingredients = {
      		{type = "item", name = "stone-crushed", amount = 2}
    	},
    	results = {
        	{type = 'item', name = 'stone', amount = 5},
    	},
    }:add_unlock('coal-processing-1')
end
if mods['angelsbioprocessing']
    and data.raw.item['angels-algae-green']
    and data.raw.item['angels-algae-brown'] then
	RECIPE {
    	type = "recipe",
    	name = "coalgas-from-seaweed",
    	categories = {"bio-processing"},
    	subgroup = "bio-processing-green",
    	order = "a",
    	energy_required = 1,
    	ingredients = {
      		{type = 'item', name = 'seaweed', amount = 35 }
    	},
    	results = {
        	{type = 'item', name = 'angels-algae-green', amount = 25},
        	{type = 'item', name = 'angels-algae-brown', amount = 5},
        	{type = 'item', name = 'coal', amount = 10},
    	},
    	main_product = "angels-algae-green",
    	icon = "__AdminUnknownFixes__/graphics/icons/coalgas-from-seaweed.png",
    	icon_size = 64,
    }:add_unlock('angels-bio-processing-brown')
end
