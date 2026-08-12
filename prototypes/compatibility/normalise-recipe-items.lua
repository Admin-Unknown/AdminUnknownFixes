-- Angel's walks every recipe in the game and reads each ingredient and each result as a table
-- with a name in it. Anything else in there and the walk stops, which is what happens in
-- angelsaddons-storage: "table index is nil" in adjust_subtable, from indexing something that
-- has no name and using the nothing it got back as a key.
--
-- Factorio 2.0 wants ingredients and results written out in full, and the shorthand pair that
-- 1.1 allowed is gone. Most mods have been through their own files and fixed that, but the
-- shorthand still turns up in what mods write to each other's recipes at load time, and the
-- game does not look at any of it until long after Angel's has walked it.
--
-- So everything that names an item or a fluid is put in the form the game asks for, before
-- anybody walks it. Nothing here is a matter of taste: an entry the game would refuse is
-- rewritten as the entry it would accept, and an entry that names nothing at all is dropped,
-- because there is no way to guess what it was meant to be. Every change is named in the log
-- with the recipe it came from, so whoever wrote it can be told.
--
-- This is handed back rather than run on sight so that it can be called more than once, and
-- so the extend guard can call it too. That matters: the guard loads before every other mod,
-- and its data-updates is the first of the stage, which is the last moment before Angel's
-- looks. This mod loads after Angel's and cannot get there in time on its own.

local function fluid_exists(name)
    return data.raw.fluid ~= nil and data.raw.fluid[name] ~= nil
end

local function item_exists(name)
    for _, prototypes in pairs(data.raw) do
        local prototype = prototypes[name]
        -- read past the pypostprocessing metatable, which answers for absent fields with its
        -- own helpers and would make an item of everything. stack_size is what every item has
        -- and nothing else does, which saves listing the twenty-odd types that count as one
        if type(prototype) == 'table' and rawget(prototype, 'stack_size') then return true end
    end
    return false
end

local function kind_of(name)
    return fluid_exists(name) and 'fluid' or 'item'
end

local function describe(entry)
    if type(entry) ~= 'table' then
        return type(entry) .. ' ' .. tostring(entry)
    end
    local parts = {}
    for key, value in pairs(entry) do
        if type(value) ~= 'table' then
            parts[#parts + 1] = tostring(key) .. '=' .. tostring(value)
        end
    end
    table.sort(parts)
    return '{' .. table.concat(parts, ', ') .. '}'
end

-- An entry can name something real and still call it the wrong thing, and the game does not
-- look until the end of the load, where it says only that a fluid of that name does not exist
-- and leaves the recipe that asked to be found by hand. Where the name is not the kind it is
-- called but is plainly the other, it is read as the other. Both kinds have to be settled
-- before this can be told apart from a thing not defined yet, so it is only done in
-- data-final-fixes, once every mod has put everything it has into the game.
local function correct_kind(entry, where)
    if entry.type == 'fluid' and not fluid_exists(entry.name) and item_exists(entry.name) then
        entry.type = 'item'
        log('AUF: ' .. where .. ' asks for ' .. entry.name .. ' as a fluid, and the only ' ..
            entry.name .. ' there is is an item. Read as an item')
        return true
    end
    if entry.type == 'item' and not item_exists(entry.name) and fluid_exists(entry.name) then
        entry.type = 'fluid'
        log('AUF: ' .. where .. ' asks for ' .. entry.name .. ' as an item, and the only ' ..
            entry.name .. ' there is is a fluid. Read as a fluid')
        return true
    end
    return false
end

local function tidy(list, recipe_name, field, correct_types)
    local where = recipe_name .. ' ' .. field
    local changed = false

    -- one entry written without the list around it. Angel's reads the fields of that entry as
    -- though each were an entry of its own, and the first one that is a word rather than a
    -- table is where it stops
    if list.name ~= nil or (list.type ~= nil and list[1] == nil) then
        log('AUF: ' .. where .. ' is a single entry with no list around it. Wrapped')
        list = { list }
        changed = true
    end

    -- the order of ingredients and results is what the player sees and what the game reads a
    -- main product out of, so the numbered entries are taken in their own order rather than
    -- whatever order pairs happens to hand them over in. Anything not numbered is not an entry
    local numbered = {}
    for key in pairs(list) do
        if type(key) == 'number' then
            numbered[#numbered + 1] = key
        else
            log('AUF: ' .. where .. ' has a stray ' .. tostring(key) .. ' sitting beside the ' ..
                'entries rather than among them. Taken out')
            changed = true
        end
    end
    table.sort(numbered)

    local tidied = {}
    for _, key in ipairs(numbered) do
        local entry = list[key]
        if type(entry) == 'string' then
            -- a bare name, which reads as an entry with nothing in it
            tidied[#tidied + 1] = { type = kind_of(entry), name = entry, amount = 1 }
            log('AUF: ' .. where .. ' names ' .. entry .. ' on its own. Written out in full')
            changed = true
        elseif type(entry) ~= 'table' then
            log('AUF: ' .. where .. ' has a ' .. describe(entry) .. ' among its entries. Taken out')
            changed = true
        elseif entry.type == 'research-progress' then
            -- the one entry the game allows without a name. Angel's will still stop on it, but
            -- guessing a name for it would be worse than leaving it where its author put it
            tidied[#tidied + 1] = entry
        elseif entry.name ~= nil then
            if entry.type == nil then
                entry.type = kind_of(entry.name)
                log('AUF: ' .. where .. ' asks for ' .. tostring(entry.name) ..
                    ' without saying whether it is an item or a fluid. Read as ' .. entry.type)
                changed = true
            elseif correct_types and correct_kind(entry, where) then
                changed = true
            end
            tidied[#tidied + 1] = entry
        elseif type(entry[1]) == 'string' then
            -- the 1.1 shorthand, which the game stopped taking in 2.0
            local name = entry[1]
            tidied[#tidied + 1] = { type = kind_of(name), name = name, amount = entry[2] or 1 }
            log('AUF: ' .. where .. ' asks for ' .. name .. ' the way 1.1 allowed. Written out in full')
            changed = true
        else
            log('AUF: ' .. where .. ' has an entry naming nothing at all, ' .. describe(entry) ..
                '. Taken out, because there is no telling what it was meant to be')
            changed = true
        end
    end

    return tidied, changed
end

-- options.correct_types asks for the item-called-a-fluid check as well, which only means
-- anything once every mod has finished adding items and fluids
return function(options)
    local correct_types = options ~= nil and options.correct_types == true
    local repaired = 0

    for name, recipe in pairs(data.raw.recipe or {}) do
        for _, field in ipairs { 'ingredients', 'results' } do
            -- read past the pypostprocessing metatable, which answers for absent fields with
            -- its own helpers, and a helper is not a list of ingredients
            local list = rawget(recipe, field)
            if type(list) == 'table' then
                local tidied, changed = tidy(list, name, field, correct_types)
                if changed then
                    recipe[field] = tidied
                    repaired = repaired + 1
                end
            end
        end
    end

    if repaired > 0 then
        log('AUF: ' .. repaired .. ' recipe ingredient or result list(s) were not in the form ' ..
            'the game takes, and have been put into it')
    end
end
