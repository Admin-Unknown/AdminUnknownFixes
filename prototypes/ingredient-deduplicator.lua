-- Ingredient Deduplicator
-- Removes duplicate ingredients from recipes after global item replacement

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
            if name and find_item(name) and not seen[name] then
                seen[name] = true
                clean[#clean + 1] = ing
            end
        end
        recipe.ingredients = clean
    end
end
