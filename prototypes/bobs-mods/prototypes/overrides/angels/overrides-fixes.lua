-- Bob's + Angel's cross-fixes (data-final-fixes), loaded only when mods['angelsrefining'].

-- Angel's Refining removes the bob-quartz resource/entity; AAI Industry (and similar) may still
-- leave sand-processing gated on mining bob-quartz, which crashes assignID.
local BOB_QUARTZ = "bob-quartz"

local function prototype_exists_for_mine_trigger(name)
    if not name then
        return false
    end
    -- data stage has no data.raw.entity; mine triggers use resource (or other typed) prototypes.
    return data.raw.resource and data.raw.resource[name] ~= nil
end

local function pick_quartz_mining_replacement()
    for _, name in ipairs({ "ore-quartz", "quartz" }) do
        if prototype_exists_for_mine_trigger(name) then
            return name
        end
    end
    return nil
end

local function replace_bob_quartz_in_research_trigger(node, replacement)
    if type(node) ~= "table" or not replacement then
        return
    end
    for k, v in pairs(node) do
        if type(v) == "table" then
            replace_bob_quartz_in_research_trigger(v, replacement)
        elseif (k == "entity" or k == "resource" or k == "default_entity") and v == BOB_QUARTZ then
            node[k] = replacement
        elseif type(k) == "number" and v == BOB_QUARTZ then
            -- 2.1 mine-entity triggers hold their entities in a list, so the name we are
            -- after can be a numbered entry rather than a named field
            node[k] = replacement
        end
    end
end

if mods["angelsrefining"] and not prototype_exists_for_mine_trigger(BOB_QUARTZ) then
    local tech = data.raw.technology["sand-processing"]
    if tech and tech.research_trigger then
        local rep = pick_quartz_mining_replacement()
        if rep then
            replace_bob_quartz_in_research_trigger(tech.research_trigger, rep)
        elseif data.raw.item["sand"] then
            -- a craft-item trigger counts with "count"; "amount" is simply not read
            tech.research_trigger = { type = "craft-item", item = "sand", count = 1 }
        end
    end
end
