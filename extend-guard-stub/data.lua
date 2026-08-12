-- Factorio reads the numbered entries of the list handed to data:extend and ignores
-- everything else, so a mod that leaves a stray field at the top level of that list has
-- always been quietly forgiven. pypostprocessing replaces data.extend with one that walks
-- every key in order to attach its metatables, and a stray field is then read as though it
-- were a prototype. The load stops inside the mod that wrote it, naming pypostprocessing.
--
-- bobpower 3.0.0 does exactly this: in prototypes/item/fluid-generator.lua the hydrazine
-- generator item closes one line early, leaving its weight in the list beside it.
--
-- This lives in its own mod because AdminUnknownFixes cannot be early enough. It requires
-- pycoalprocessing, which sorts after bobpower, so it is held behind bobpower no matter what
-- its own name is. This mod requires nothing and its name begins with a zero, so it runs
-- first, before any mod has had the chance to hand anything to data:extend.
--
-- Running first means pypostprocessing wraps data.extend after us rather than before, and a
-- plain wrapper would end up underneath it and never see the list. So instead of holding a
-- function in the field, we answer for the field itself: reads get ours, writes are kept as
-- what ours should call. Whoever wraps it later ends up inside us rather than around us.

-- the field ordinarily, or through a metatable if the game ever provides it that way
local real_extend = rawget(data, 'extend')
if type(real_extend) ~= 'function' then real_extend = data.extend end
if type(real_extend) ~= 'function' then
    log('AUF: data:extend is not a function, so there is nothing here to stand in front of. ' ..
        'The guard is doing nothing this load')
    return
end

local function only_the_numbered_entries(prototypes)
    if type(prototypes) ~= 'table' then return prototypes end

    local numbered = #prototypes
    local total = 0
    for _ in pairs(prototypes) do total = total + 1 end
    -- the ordinary case, handed on exactly as it came so that the walker still sees the very
    -- tables the game is about to store
    if total == numbered then return prototypes end

    if numbered > 0 then
        local stray = {}
        for key in pairs(prototypes) do
            if type(key) ~= 'number' or key < 1 or key > numbered or key % 1 ~= 0 then
                stray[#stray + 1] = tostring(key)
            end
        end
        log('AUF: data:extend was handed ' .. table.concat(stray, ', ') ..
            ' outside of any prototype. The game would ignore that, so we have too')
    end

    local cleaned = {}
    for index = 1, numbered do
        cleaned[index] = prototypes[index]
    end
    return cleaned
end

-- whatever ours should call: the game's own to begin with, and then whichever wrapper was
-- most recently written into the field
local innermost = real_extend
local inside = false

local function guard(self, prototypes)
    -- data:extend and data.extend are both allowed
    if self ~= prototypes and prototypes == nil then
        prototypes = self
    end

    -- a wrapper calls back into whatever it found in the field, which is us. That inner call
    -- is the one that stores the prototypes, and its list has already been through the
    -- cleaning above, so it goes straight to the game.
    if inside then
        return real_extend(self, prototypes)
    end

    inside = true
    local result = innermost(self, only_the_numbered_entries(prototypes))
    inside = false
    return result
end

-- An earlier version stood aside if anything already answered for the data table, on the
-- grounds that combining the two was guesswork. That turned the whole mod into a silent
-- no-op in exactly the case nobody would think to check, so now it goes underneath instead
-- and every key but extend is passed straight through to whatever was there before.
local underneath = getmetatable(data)
if underneath then
    log('AUF: something already answers for the data table. The guard has gone underneath it ' ..
        'and passes everything but extend straight through')
end

local function ask_underneath(key)
    local answer = underneath and underneath.__index
    if type(answer) == 'function' then return answer(data, key) end
    if type(answer) == 'table' then return answer[key] end
    return nil
end

local function tell_underneath(key, value)
    local listener = underneath and underneath.__newindex
    if type(listener) == 'function' then return listener(data, key, value) end
    if type(listener) == 'table' then listener[key] = value return end
    rawset(data, key, value)
end

setmetatable(data, {
    __index = function(_, key)
        if key == 'extend' then return guard end
        return ask_underneath(key)
    end,
    __newindex = function(_, key, value)
        -- pypostprocessing installs its wrapper once for each mod that pulls in its library,
        -- and each one does the same work as the last, so keeping only the newest costs
        -- nothing. A wrapper that did something of its own would need more care than this.
        if key == 'extend' then
            innermost = value
            _G.__auf_extend_guard_writes = (_G.__auf_extend_guard_writes or 0) + 1
        else
            tell_underneath(key, value)
        end
    end,
})
rawset(data, 'extend', nil)

-- 0.0.1 installed without a word and, on at least one setup, still did not end up in the
-- chain: the load stopped in pypostprocessing exactly as though the guard were not there,
-- with no frame from this file between the two. Nothing in the base game's dataloader or in
-- any mod checked writes over the field the way that would need, so rather than guess at it
-- again, the install now says what it did and whether it took.
if data.extend == guard then
    log('AUF: the extend guard is in place. Whatever wraps data:extend from here on runs inside it')
else
    log('AUF: the extend guard did not take the field. data:extend still answers with ' ..
        tostring(data.extend) .. ', so the load will stop the same way it did without this mod')
end

-- AdminUnknownFixes carries the same repair for when this mod is not installed. Two of them
-- would be one too many: its wrapper would read the field, find ours, and put itself between
-- us and pypostprocessing, which would leave pypostprocessing's metatables unattached.
_G.__auf_extend_guard = true
