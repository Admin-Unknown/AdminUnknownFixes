-- Two jobs, both about recipes asking for things that are not there.
--
-- The first is why this file exists: merging two mods' versions of the same item leaves the
-- recipes that used both asking for the survivor twice, so the second mention is dropped.
--
-- The second is the same question asked of results. A recipe naming something that does not
-- exist stops the load, and the ingredients have always been cleared of that here as a side
-- effect of the merge, quietly. The results never were, and a mod that builds one recipe out
-- of another copies the whole list across without knowing whether any of it is real.
-- factory-3-recycling is where that showed: Factorissimo asks factory-3 for a nexelit
-- substation, which comes from pyalternativeenergy alone, and the recycler mod had already
-- copied the ingredient list into its results by the time this file took it out of factory-3.
-- The recipe that broke was the copy, which named a mod nobody had.
--
-- Everything dropped is named in the log now, on both sides. A recipe quietly losing an
-- ingredient is a balance change nobody asked for, and it should at least be findable.

local function find_item(name)
    if data.raw.item[name] or data.raw.fluid[name] then return true end
    for prototype in pairs(defines.prototypes.item) do
        if data.raw[prototype] and data.raw[prototype][name] then return true end
    end
    return false
end

for _, recipe in pairs(data.raw.recipe) do
    if recipe.ingredients then
        local seen = {}
        local clean = {}
        for _, ing in pairs(recipe.ingredients) do
            local name = ing.name
            if not name then
                -- shape is not this file's business: normalise-recipe-items has been over
                -- these already and leaves behind only the one entry the game allows without
                -- a name, which is not ours to throw away
                clean[#clean + 1] = ing
            elseif not find_item(name) then
                log('AUF: ' .. recipe.name .. ' is made from ' .. name ..
                    ', which nothing installed provides. Taken out')
            elseif seen[name] then
                log('AUF: ' .. recipe.name .. ' asks for ' .. name ..
                    ' twice, which is what merging two mods\' versions of it leaves behind. ' ..
                    'Asked for once')
            else
                seen[name] = true
                clean[#clean + 1] = ing
            end
        end
        recipe.ingredients = clean
    end

    if recipe.results then
        local had = #recipe.results
        local clean = {}
        for _, result in pairs(recipe.results) do
            local name = result.name
            if not name then
                clean[#clean + 1] = result
            elseif not find_item(name) then
                log('AUF: ' .. recipe.name .. ' makes ' .. name ..
                    ', which nothing installed provides. Taken out')
            else
                clean[#clean + 1] = result
            end
        end
        recipe.results = clean

        -- a recipe that makes nothing is allowed, and is how the void recipes work, so this
        -- is worth saying rather than acting on
        if #clean == 0 and had > 0 then
            log('AUF: ' .. recipe.name .. ' now makes nothing at all')
        end

        -- a recipe points at one of its results as the main one, for its name and its icon.
        -- If that was the result just taken out, the pointer is now at nothing, so it goes
        -- too, and the icon pass later on gives the recipe an icon of its own
        local main = rawget(recipe, 'main_product')
        if type(main) == 'string' and main ~= '' then
            local still_made = false
            for _, result in pairs(clean) do
                if result.name == main then still_made = true break end
            end
            if not still_made then
                log('AUF: ' .. recipe.name .. ' called ' .. main .. ' the thing it is for, and ' ..
                    'no longer makes it. It is for whatever is left')
                recipe.main_product = nil
            end
        end
    end
end
