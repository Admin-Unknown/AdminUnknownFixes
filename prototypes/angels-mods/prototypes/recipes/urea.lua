if data.raw.fluid['angels-gas-urea'] and data.raw.fluid['angels-gas-compressed-air'] then
RECIPE {
    type = "recipe",
    name = "urea-gasification",
    categories = {"gasifier"},
    enabled = false,
    energy_required = 3,
    ingredients = {
      	{type = 'item', name = 'urea', amount = 10},
        {type = 'fluid', name = 'angels-gas-compressed-air', amount = 50},
    },
    results = {
        {type = 'fluid', name = 'angels-gas-urea', amount = 200},
        {type = 'item', name = 'ash', amount = 2},
    },
    -- Do not set main_product to a fluid name: pypostprocessing data-final-fixes uses ITEM(main_product) and errors.
}:add_unlock('angels-resin-1')
end
