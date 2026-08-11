RECIPE {
    type = "recipe",
    name = "charcoal-from-pellets",
    categories = {"crafting"},
    energy_required = 1,
    ingredients = {
      	{type = "item", name = "bob-wood-pellets", amount = 2},
    },
    results = {
        {type = 'item', name = 'charcoal-briquette', amount = 3},
    },
}:add_unlock('energy-3')
