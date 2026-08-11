-- Productivity for Py's creature/plant modules. Most belong to pyalienlife and numal to
-- pyalternativeenergy, both optional, and the setting that pulls this file in says nothing
-- about which of them is installed, so every module is looked up before it is touched.
-- Cadaveric arum is the one module carrying an -a suffix the others do not.
local sinners = {
    'tree', 'seaweed', 'moss', 'sap-tree', 'ulric', 'sea-sponge', 'ralesia', 'mukmoux',
    'arthurian', 'tuuphra', 'navens', 'yotoi', 'dhilmos', 'scrondrix', 'rennea', 'phadai',
    'auog', 'fish', 'yaedols', 'dingrits', 'kmauts', 'vonix', 'grod', 'phagnot', 'bhoddos',
    'xeno', 'trits', 'kicalk', 'vrauks', 'xyhiphoe', 'korlex', 'fawogae', 'moondrop',
    'cottongut', 'guar', 'arqad', 'simik', 'zungror', 'numal',
}

for tier, bonus in pairs({['mk03'] = 0.01, ['mk04'] = 0.02}) do
    for _, sinner in pairs(sinners) do
        local module = data.raw.module[sinner .. '-' .. tier]
        if module then
            module.effect.productivity = {bonus = bonus}
        end
    end

    local arum = data.raw.module['cadaveric-arum-' .. tier .. '-a']
    if arum then
        arum.effect.productivity = {bonus = bonus}
    end
end
