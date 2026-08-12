-- A recipe shows the icon of what it makes. With one product that is settled, and with
-- several it is whichever main_product names. With several and no main_product there is
-- nothing to borrow and the recipe has to carry an icon of its own, or the load stops on it.
--
-- That is easy to walk into from here without writing a recipe at all, because adding a
-- result to somebody else's single-product recipe takes its icon away. So rather than only
-- fixing the recipes we write, anything left in that state at the end of the load is given
-- the icon of its first product, which is what the game would have used had we not added to
-- it. A wrong-looking icon is worth more than a game that will not start, and each one is
-- named in the log so it can be given a considered one later.

local function has_own(prototype, field)
    -- read past the pypostprocessing metatable: an absent field can come back as one of its
    -- helper methods, and a method is not an icon
    return rawget(prototype, field) ~= nil
end

local function icon_holder(result)
    if type(result) ~= 'table' then return nil end
    local name = result.name or result[1]
    if type(name) ~= 'string' then return nil end

    if result.type == 'fluid' then
        return data.raw.fluid and data.raw.fluid[name]
    end

    for _, prototypes in pairs(data.raw) do
        local candidate = prototypes[name]
        -- only an item carries stack_size, which keeps this off the entity of the same name
        if type(candidate) == 'table' and candidate.stack_size then
            return candidate
        end
    end
    return nil
end

for _, recipe in pairs(data.raw.recipe or {}) do
    local results = rawget(recipe, 'results')
    local main_product = rawget(recipe, 'main_product')
    local named_a_main_product = type(main_product) == 'string' and main_product ~= ''

    if type(results) == 'table' and #results ~= 1 and not named_a_main_product
        and not has_own(recipe, 'icon') and not has_own(recipe, 'icons') then
        local borrowed
        for _, result in ipairs(results) do
            borrowed = icon_holder(result)
            if borrowed and (borrowed.icon or borrowed.icons) then break end
            borrowed = nil
        end

        if borrowed then
            if borrowed.icons then
                recipe.icons = table.deepcopy(borrowed.icons)
            else
                recipe.icon = borrowed.icon
                recipe.icon_size = borrowed.icon_size
            end
            log('AUF: ' .. recipe.name .. ' makes ' .. #results .. ' things and names none of ' ..
                'them as the main one, so it has been given the icon of the first')
        else
            log('AUF: ' .. recipe.name .. ' makes ' .. #results .. ' things, names none of them ' ..
                'as the main one, and none of them has an icon to borrow')
        end
    end
end
