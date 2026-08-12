if data.raw.fluid['angels-gas-urea'] and data.raw.fluid['angels-gas-compressed-air'] then
RECIPE {
    type = "recipe",
    name = "urea-gasification",
    -- A recipe borrows its icon from its single product, or from main_product when there is
    -- more than one. This has two and cannot name one (see below), so it has to carry its
    -- own. Taking Angel's gas urea icon rather than naming the file keeps it right if they
    -- redraw it.
    icons = table.deepcopy(data.raw.fluid['angels-gas-urea'].icons),
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
