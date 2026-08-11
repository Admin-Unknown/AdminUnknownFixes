-- pycoalprocessing's data-final-fixes calls recipe:has_category() on every entry
-- of data.raw.recipe. That helper comes from a metatable pypostprocessing binds,
-- and something in a large Angel's/Bob's/Py load order leaves prototypes without
-- it, which aborts the load.
--
-- This file is deliberately self-contained: AdminUnknownFixes carries the same
-- logic, but this mod must still work when AdminUnknownFixes is not loaded, and
-- being independent means one broken assumption cannot take out both copies.
--
-- Two properties matter here. First, the stamp goes on in data-updates, because
-- Factorio runs every mod's data-updates before any mod's data-final-fixes, which
-- is the only ordering guarantee available to us. Second, the stamp is a callable
-- table rather than a function: a function field fails serialisation with
-- "Cannot serialise ttype=function", while an unrecognised table field is ignored.

local shared = rawget(_G, "__auf_pypp_recipe_guard")
if not shared then
    shared = {}
    rawset(_G, "__auf_pypp_recipe_guard", shared)
end

-- AdminUnknownFixes builds an identical pair, so whichever mod gets here first
-- wins and both then treat the result as their own.
if not shared.call_shims then
    local function has_category(self, category_name)
        if not (data.raw["recipe-category"] or {})[category_name] then return false end
        local categories = self.categories
        if category_name == "crafting" and (not categories or #categories == 0) then
            return self, true
        end
        for _, category in pairs(categories or {}) do
            if category == category_name then return true end
        end
        return false
    end

    local function has_categories(self, category_names, all)
        for _, category_name in pairs(category_names or {}) do
            local found = has_category(self, category_name)
            if found and not all then return true end
            if not found and all then return false end
        end
        return all == true
    end

    shared.call_shims = {
        has_category = setmetatable({}, {
            __call = function(_, self, category_name) return has_category(self, category_name) end
        }),
        has_categories = setmetatable({}, {
            __call = function(_, self, category_names, all) return has_categories(self, category_names, all) end
        })
    }
end

local shims = shared.call_shims

return function(stage)
    local stamped, total = 0, 0
    for _, recipe in next, data.raw.recipe or {}, nil do
        if type(recipe) == "table" then
            total = total + 1
            if rawget(recipe, "has_category") ~= shims.has_category then
                recipe.has_category = shims.has_category
                recipe.has_categories = shims.has_categories
                stamped = stamped + 1
            end
        end
    end
    log("[PyCoalTBaA stub] " .. stage .. ": has_category stamped on " .. stamped .. " of " .. total .. " recipes")
end
