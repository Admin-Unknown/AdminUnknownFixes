-- DATA UPDATES for Clowns.
-- Belt and braces if something cleared oil-gathering without going through the
-- data.lua guard (or this mod loaded after that write). Same stub as the guard.

if mods['Clowns-Extended-Minerals'] and mods['pypetroleumhandling']
    and not data.raw.technology['oil-gathering'] then
    data.raw.technology['oil-gathering'] = {
        type = 'technology',
        name = 'oil-gathering',
        icon = '__base__/graphics/technology/oil-gathering.png',
        icon_size = 256,
        effects = {},
        prerequisites = {},
        unit = {
            count = 1,
            ingredients = {{'automation-science-pack', 1}},
            time = 1
        },
        hidden = true,
        hidden_in_factoriopedia = true,
    }
    _G.__auf_oil_gathering_stub = true
    log('AUF: recreated a stub oil-gathering technology for Clowns-Extended-Minerals after Py removed it')
end
