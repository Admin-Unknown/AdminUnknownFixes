-- PyCoal + pypetroleumhandling clears technology oil-gathering in data-updates.
-- Clowns-Extended-Minerals then indexes it with no nil check and stops the load.
--
-- A proxy in front of data.raw.technology does not work: the game reads that table
-- with lua_next, which ignores __pairs, so every technology vanishes and the load
-- dies on the first shortcut that names one (construction-robotics / undo).
--
-- Instead the real technology table is left in place. oil-gathering is taken out of
-- it so that the write which clears it goes through __newindex; that write is turned
-- into a hidden stub rawset back onto the same table, where the engine can see it
-- and Clowns can still attach unlocks. overrides-updates moves those unlocks onto
-- oil-processing and deletes the stub for real.

if not (mods['Clowns-Extended-Minerals'] and mods['pypetroleumhandling']) then
    return
end

local technologies = data.raw.technology
if not technologies or not rawget(technologies, 'oil-gathering') then
    return
end

if _G.__auf_oil_gathering_guard then
    return
end
_G.__auf_oil_gathering_guard = true

local live = rawget(technologies, 'oil-gathering')
rawset(technologies, 'oil-gathering', nil)

local mt = {}
local existing = getmetatable(technologies)
if existing then
    for key, value in pairs(existing) do
        mt[key] = value
    end
end

local previous_index = mt.__index
local previous_newindex = mt.__newindex

local function kept_clowns_effects(previous)
    local kept = {}
    if not (previous and previous.effects) then
        return kept
    end
    for _, effect in pairs(previous.effects) do
        if effect.type == 'unlock-recipe' and type(effect.recipe) == 'string'
            and string.sub(effect.recipe, 1, 7) == 'clowns-' then
            kept[#kept + 1] = effect
        end
    end
    return kept
end

local function make_stub(previous)
    return {
        type = 'technology',
        name = 'oil-gathering',
        icon = previous and previous.icon or '__base__/graphics/technology/oil-gathering.png',
        icon_size = previous and previous.icon_size or 256,
        icons = previous and previous.icons or nil,
        effects = kept_clowns_effects(previous),
        prerequisites = {},
        unit = previous and previous.unit or {
            count = 1,
            ingredients = {{'automation-science-pack', 1}},
            time = 1
        },
        hidden = true,
        hidden_in_factoriopedia = true,
    }
end

mt.__index = function(t, key)
    if key == 'oil-gathering' then
        return live
    end
    if previous_index == nil then
        return nil
    end
    if type(previous_index) == 'function' then
        return previous_index(t, key)
    end
    return previous_index[key]
end

mt.__newindex = function(t, key, value)
    if key == 'oil-gathering' then
        if value == nil then
            live = make_stub(live)
            -- Real key again so lua_next / the engine still see a technology table entry.
            rawset(t, key, live)
            _G.__auf_oil_gathering_stub = true
            log('AUF: kept a stub oil-gathering technology so Clowns-Extended-Minerals can still attach unlocks after Py removed it')
            return
        end
        live = value
        rawset(t, key, value)
        return
    end

    if previous_newindex then
        return previous_newindex(t, key, value)
    end
    rawset(t, key, value)
end

setmetatable(technologies, mt)
