-- pycoalprocessing's data-final-fixes calls recipe:has_category() on every entry
-- of data.raw.recipe. That helper is not a field on the prototype, it comes from
-- a metatable pypostprocessing binds when its lib first loads and inside its
-- data.extend wrapper, so a prototype that reaches data.raw any other way has no
-- has_category at all and aborts the load.
--
-- Load order gives us nowhere to stand: everything that runs between us and
-- pycoalprocessing's data-final-fixes is a mod we cannot hook, and pypostprocessing
-- refuses to re-run its lib once the py global exists. So rather than trying to
-- heal at the right moment, hook the table every caller shares. data.raw.recipe is
-- one table for the whole data stage, so a __pairs metamethod on it runs inside
-- pycoalprocessing's own loop, immediately before it touches any prototype.
--
-- Helpers must never be copied onto a prototype as an own field: Factorio aborts
-- the load with "Cannot serialise ttype=function". Metatables only.

local guard = {}

local RECIPE_PROBE = "has_category"
local TECHNOLOGY_PROBE = "add_prereq"
local MARKER = "__auf_recipe_helpers"

-- The PyCoalTBaA stub requires this file too. Share one helper table between the
-- copies so a prototype healed by one is recognised as healthy by the other.
local shared = rawget(_G, "__auf_pypp_recipe_guard")
if not shared then
    shared = {}
    rawset(_G, "__auf_pypp_recipe_guard", shared)
end
shared.helpers = shared.helpers or {[MARKER] = true}
shared.meta = shared.meta or {__index = shared.helpers}

local recipe_helpers = shared.helpers
local recipe_meta = shared.meta

-- The stamps below are callable tables rather than functions on purpose: a plain
-- field is the only thing that reliably survives from data-updates into another
-- mod's data-final-fixes, and Factorio refuses to serialise a function field
-- ("Cannot serialise ttype=function") while an unknown table field is ignored.
-- The PyCoalTBaA stub builds the same pair, so whichever mod loads first wins and
-- both recognise the result as their own.
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

local stamped_has_category = shared.call_shims.has_category
local stamped_has_categories = shared.call_shims.has_categories

local function index_table_of(prototype)
    local mt = getmetatable(prototype)
    local index = mt and mt.__index
    return type(index) == "table" and index or nil
end

local function has_helper(prototype, probe)
    local index = index_table_of(prototype)
    return index ~= nil and type(index[probe]) == "function"
end

---Locate pypostprocessing's own method table for a data.raw sub-table.
---Our own helper tables are skipped so the fallbacks below cannot recurse into themselves.
local function find_pypp_helpers(raw, probe)
    for _, prototype in next, raw or {}, nil do
        if type(prototype) == "table" then
            local index = index_table_of(prototype)
            if index and not rawget(index, MARKER) and type(rawget(index, probe)) == "function" then
                return index
            end
        end
    end
    return nil
end

local pypp_recipe_helpers
local function get_pypp_recipe_helpers()
    if pypp_recipe_helpers then return pypp_recipe_helpers end

    pypp_recipe_helpers = find_pypp_helpers(data.raw.recipe, RECIPE_PROBE)

    -- RECIPE(name) binds the metatable as a side effect, which gives us a
    -- template even when every prototype has already lost it.
    if not pypp_recipe_helpers and type(RECIPE) == "table" then
        local name = next(data.raw.recipe or {})
        if name and pcall(RECIPE, name) then
            local index = index_table_of(data.raw.recipe[name])
            if index and not rawget(index, MARKER) then pypp_recipe_helpers = index end
        end
    end

    return pypp_recipe_helpers
end

-- Anything we do not implement is forwarded to pypostprocessing, so a healed
-- prototype still answers replace_ingredient, add_unlock, standardize and friends.
setmetatable(recipe_helpers, {
    __index = function(_, key)
        local helpers = get_pypp_recipe_helpers()
        return helpers and helpers[key] or nil
    end
})

recipe_helpers.has_category = function(self, category_name)
    local helpers = get_pypp_recipe_helpers()
    if helpers then return helpers.has_category(self, category_name) end

    if not (data.raw["recipe-category"] or {})[category_name] then return false end
    local categories = self.categories
    if category_name == "crafting" and (not categories or #categories == 0) then return true end
    for _, category in pairs(categories or {}) do
        if category == category_name then return true end
    end
    return false
end

recipe_helpers.has_categories = function(self, category_names, all)
    local helpers = get_pypp_recipe_helpers()
    if helpers then return helpers.has_categories(self, category_names, all) end

    for _, category_name in pairs(category_names or {}) do
        local found = recipe_helpers.has_category(self, category_name)
        if found and not all then return true end
        if not found and all then return false end
    end
    return all == true
end

-- Own fields are the only thing we can be certain survives from data-updates to
-- another mod's data-final-fixes: a metatable can be replaced by any mod in
-- between (including ones outside this repo's dependency snapshot), and Factorio's
-- pairs() is a custom deterministic implementation that may not honour __pairs.
-- Factorio cannot serialise a function field, so every stamp is removed again in
-- AdminUnknownFixes' data-final-fixes, which our hard dependency on
-- pycoalprocessing guarantees runs after the check that needs them.
function guard.stamp_recipes()
    local stamped = 0
    for _, prototype in next, data.raw.recipe or {}, nil do
        if type(prototype) == "table" and rawget(prototype, "has_category") ~= stamped_has_category then
            prototype.has_category = stamped_has_category
            prototype.has_categories = stamped_has_categories
            stamped = stamped + 1
        end
    end
    log("[AdminUnknownFixes] stamped has_category on " .. stamped .. " recipe(s) for mods that run before our data-final-fixes")
    return stamped
end

---Remove our stamps and any function-valued field so nothing odd reaches serialisation.
function guard.strip_function_fields()
    local stripped = 0
    for _, prototypes in next, data.raw, nil do
        if type(prototypes) == "table" then
            for _, prototype in next, prototypes, nil do
                if type(prototype) == "table" then
                    local doomed
                    for key, value in next, prototype, nil do
                        if type(value) == "function"
                            or value == stamped_has_category
                            or value == stamped_has_categories then
                            doomed = doomed or {}
                            doomed[#doomed + 1] = key
                        end
                    end
                    for _, key in next, doomed or {}, nil do
                        prototype[key] = nil
                        stripped = stripped + 1
                    end
                end
            end
        end
    end
    log("[AdminUnknownFixes] removed " .. stripped .. " helper field(s) from prototypes before serialisation")
    return stripped
end

local healing = false

local function report(broken, names)
    if broken == 0 then return end
    local shown = table.concat(names, ", ")
    if broken > #names then shown = shown .. ", ..." end
    log("[AdminUnknownFixes] rebound pypostprocessing recipe helpers on " .. broken .. " prototype(s): " .. shown)
end

function guard.heal_recipes()
    if healing then return 0 end
    healing = true

    local broken, names = 0, {}
    for name, prototype in next, data.raw.recipe or {}, nil do
        if type(prototype) == "table" then
            -- Drop foreign function fields (older AdminUnknownFixes builds left
            -- some behind); our own stamps are removed in data-final-fixes.
            local own = rawget(prototype, "has_category")
            if type(own) == "function" and own ~= stamped_has_category then
                prototype.has_category = nil
            end
            if not has_helper(prototype, RECIPE_PROBE) then
                broken = broken + 1
                if #names < 10 then names[#names + 1] = tostring(name) end
                setmetatable(prototype, recipe_meta)
            end
        end
    end

    healing = false
    report(broken, names)
    return broken
end

function guard.heal_technologies()
    local helpers = find_pypp_helpers(data.raw.technology, TECHNOLOGY_PROBE)
    if not helpers then return 0 end

    local meta = {__index = helpers}
    local broken = 0
    for _, prototype in next, data.raw.technology or {}, nil do
        if type(prototype) == "table" and not has_helper(prototype, TECHNOLOGY_PROBE) then
            broken = broken + 1
            setmetatable(prototype, meta)
        end
    end
    return broken
end

function guard.heal()
    guard.heal_recipes()
    guard.heal_technologies()
end

local function metatable_of(t)
    local mt = getmetatable(t)
    if not mt then
        mt = {}
        setmetatable(t, mt)
    end
    return mt
end

---Attach the heal to data.raw.recipe itself so it fires inside other mods' loops.
function guard.install()
    if not data.raw.recipe then return end

    local mt = metatable_of(data.raw.recipe)
    if mt.__auf_recipe_guard then return end
    mt.__auf_recipe_guard = true

    mt.__pairs = function(t)
        guard.heal_recipes()
        return next, t, nil
    end

    -- Catches prototypes assigned straight into data.raw.recipe rather than
    -- through data:extend, at the moment they are added.
    local inherited_newindex = rawget(mt, "__newindex")
    mt.__newindex = function(t, key, value)
        if inherited_newindex then
            inherited_newindex(t, key, value)
        else
            rawset(t, key, value)
        end
        if type(value) == "table" and not has_helper(value, RECIPE_PROBE) then
            setmetatable(value, recipe_meta)
        end
    end
end

guard.install()
guard.heal()

return guard
