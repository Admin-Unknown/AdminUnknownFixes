-- DATA FINAL FIXES for Clowns. See oil-gathering-stub.lua for why the stub exists.

if not _G.__auf_oil_gathering_stub then
    return
end

local oil = data.raw.technology['oil-gathering']
if not oil then
    _G.__auf_oil_gathering_stub = nil
    return
end

local target = data.raw.technology['oil-processing']
if target and oil.effects then
    target.effects = target.effects or {}
    for _, effect in pairs(oil.effects) do
        if effect.type == 'unlock-recipe' and type(effect.recipe) == 'string'
            and string.sub(effect.recipe, 1, 7) == 'clowns-' then
            table.insert(target.effects, effect)
        end
    end
    log('AUF: moved Clowns unlocks from stub oil-gathering onto oil-processing')
end

-- Stub is a real key again after the guard rawsets it, so clear with rawset.
rawset(data.raw.technology, 'oil-gathering', nil)
_G.__auf_oil_gathering_stub = nil

for _, tech in pairs(data.raw.technology) do
    local pre = tech.prerequisites
    if pre then
        for i = #pre, 1, -1 do
            if pre[i] == 'oil-gathering' then
                table.remove(pre, i)
            end
        end
    end
end
