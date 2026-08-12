-- Py is normally installed whole, so a mod that wants to cost its research in py science
-- checks for one py mod and then names a pack from another. py-science-pack-1 through 4 all
-- come from pyalienlife alone, and a game with the rest of Py but not that one is a game
-- where those names lead nowhere. The load then stops on the technology, naming the mod that
-- wrote it and pypostprocessing, neither of which is where the assumption was made.
--
-- jetpack 0.5.1 does this to jetpack-1, and it only showed up on turning pypetroleumhandling
-- on, which says how little the mod that breaks has to do with the mod that is missing. So
-- rather than naming the technologies, every one of them is looked over at the end of the
-- load and anything it asks for that nothing provides is taken out.
--
-- A technology that ends up costing nothing would be researched instantly, so the last pack
-- is replaced rather than removed. Cheaper research is a poor outcome and a working game is
-- better than neither, and each one is named in the log so the cost can be set deliberately.

-- every item there is, gathered once. A science pack is a tool and a tool is an item, and
-- stack_size is what every item has and nothing else does, which saves listing the twenty-odd
-- types that count as one.
local items = {}
for _, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
        -- read past the pypostprocessing metatable, which answers for absent fields with its
        -- own helpers and would make an item of everything
        if type(prototype) == 'table' and rawget(prototype, 'stack_size') then items[name] = true end
    end
end

local function item_exists(name)
    return items[name] == true
end

-- an ingredient is written either as a pair or as a table with names for its parts
local function ingredient_name(ingredient)
    if type(ingredient) ~= 'table' then return nil end
    local name = ingredient.name or ingredient[1]
    return type(name) == 'string' and name or nil
end

local function ingredient_count(ingredient)
    return ingredient.amount or ingredient[2] or 1
end

local fallback = item_exists('automation-science-pack') and 'automation-science-pack' or nil

for _, technology in pairs(data.raw.technology or {}) do
    local unit = rawget(technology, 'unit')
    local ingredients = type(unit) == 'table' and unit.ingredients

    if type(ingredients) == 'table' then
        local kept, missing = {}, {}
        for _, ingredient in ipairs(ingredients) do
            local name = ingredient_name(ingredient)
            if name and not item_exists(name) then
                missing[#missing + 1] = ingredient
            else
                kept[#kept + 1] = ingredient
            end
        end

        if #missing > 0 then
            local names = {}
            for _, ingredient in ipairs(missing) do names[#names + 1] = ingredient_name(ingredient) end

            if #kept > 0 then
                log('AUF: ' .. technology.name .. ' is researched with ' ..
                    table.concat(names, ', ') .. ', which nothing installed provides. ' ..
                    'Taken out, leaving the rest of its cost as it was')
                unit.ingredients = kept
            elseif fallback then
                -- the count comes from what it was asking for, so a technology that wanted
                -- thirty of something still wants thirty of something
                log('AUF: ' .. technology.name .. ' is researched only with ' ..
                    table.concat(names, ', ') .. ', which nothing installed provides. ' ..
                    'It costs ' .. fallback .. ' instead, which is a guess worth revisiting')
                unit.ingredients = { { fallback, ingredient_count(missing[1]) } }
            else
                log('AUF: ' .. technology.name .. ' is researched only with ' ..
                    table.concat(names, ', ') .. ', which nothing installed provides, and ' ..
                    'there is nothing to put in their place')
            end
        end
    end
end

-- A lab listing a pack that does not exist stops the load the same way, and the labs in this
-- modpack are handed their inputs by whichever mods are present.
for _, lab in pairs(data.raw.lab or {}) do
    local inputs = rawget(lab, 'inputs')
    if type(inputs) == 'table' then
        local kept, missing = {}, {}
        for _, name in ipairs(inputs) do
            if type(name) == 'string' and not item_exists(name) then
                missing[#missing + 1] = name
            else
                kept[#kept + 1] = name
            end
        end
        if #missing > 0 then
            log('AUF: the ' .. lab.name .. ' took ' .. table.concat(missing, ', ') ..
                ', which nothing installed provides, so it no longer does')
            lab.inputs = kept
        end
    end
end
