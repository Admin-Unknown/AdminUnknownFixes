-- next_upgrade is only accepted when the two entities agree on their bounding box, their
-- collision mask and their fast replaceable group, and when the target is minable, is not
-- flagged not-upgradable, and is built by an item that is not hidden. Break any of those
-- and the load stops on the entity that holds the link.
--
-- Every one of those conditions is a pair, so two mods that are each internally consistent
-- can still fail together. Py replaces the vanilla lab with a five by five one and Bob's
-- chains that lab to its own three by three bob-lab-2 and its burner lab to the lab, so
-- both links break the moment the two are installed side by side. Neither could have known.
--
-- Resizing a building would move its graphics off its footprint, so the link is what goes.
-- The cost is one step in the upgrade planner; nothing that is already built changes.

local function corners(box)
    -- an unset box is the origin as far as the comparison goes, and either corner may be
    -- written as a pair or as named fields
    if not box then return 0, 0, 0, 0 end
    local top_left = box.left_top or box[1]
    local bottom_right = box.right_bottom or box[2]
    if not top_left or not bottom_right then return 0, 0, 0, 0 end
    return top_left.x or top_left[1], top_left.y or top_left[2],
        bottom_right.x or bottom_right[1], bottom_right.y or bottom_right[2]
end

local function same_box(a, b)
    local a_x1, a_y1, a_x2, a_y2 = corners(a)
    local b_x1, b_y1, b_x2, b_y2 = corners(b)
    return a_x1 == b_x1 and a_y1 == b_y1 and a_x2 == b_x2 and a_y2 == b_y2
end

local function same_mask(a, b)
    -- an absent mask means the default for that entity type, which is not written down
    -- anywhere we can read, so a pair we cannot compare is left alone rather than guessed at
    if type(a) ~= 'table' or type(b) ~= 'table' then return true end
    local a_layers, b_layers = a.layers or {}, b.layers or {}
    for layer in pairs(a_layers) do
        if not b_layers[layer] then return false end
    end
    for layer in pairs(b_layers) do
        if not a_layers[layer] then return false end
    end
    return true
end

local function has_flag(prototype, flag)
    if not prototype.flags then return false end
    for _, set in pairs(prototype.flags) do
        if set == flag then return true end
    end
    return false
end

local function is_hidden_item(name)
    for _, prototypes in pairs(data.raw) do
        local item = prototypes[name]
        -- only an item carries stack_size, which keeps this away from the entity of the
        -- same name that almost always exists alongside it
        if type(item) == 'table' and item.stack_size then
            return item.hidden == true or has_flag(item, 'hidden')
        end
    end
    return false
end

-- an entity is buildable only through an item that places it, and the replacer earlier in
-- final-fixes hides items whose duplicates it has merged away
local placed_by_a_visible_item = {}
for _, prototypes in pairs(data.raw) do
    for _, prototype in pairs(prototypes) do
        if type(prototype) == 'table' and type(prototype.place_result) == 'string'
            and prototype.stack_size
            and not (prototype.hidden == true or has_flag(prototype, 'hidden')) then
            placed_by_a_visible_item[prototype.place_result] = true
        end
    end
end

local function mines_a_hidden_item(prototype)
    local minable = prototype.minable
    if type(minable) ~= 'table' then return false end
    if type(minable.result) == 'string' and is_hidden_item(minable.result) then return true end
    for _, result in pairs(minable.results or {}) do
        local name = type(result) == 'table' and (result.name or result[1]) or nil
        if type(name) == 'string' and is_hidden_item(name) then return true end
    end
    return false
end

-- the reason a link cannot stand, or nil when it can
local function why_not(source, target)
    if not target then return 'it does not exist' end
    if not same_box(source.collision_box, target.collision_box) then return 'they are different sizes' end
    if not same_mask(source.collision_mask, target.collision_mask) then return 'they collide with different things' end
    if source.fast_replaceable_group ~= target.fast_replaceable_group then
        return 'they are in different fast replaceable groups'
    end
    if not target.minable then return 'it cannot be mined' end
    if has_flag(target, 'not-upgradable') then return 'it is flagged not-upgradable' end
    if not placed_by_a_visible_item[target.name] then return 'no visible item builds it' end
    if mines_a_hidden_item(source) or mines_a_hidden_item(target) then return 'one of them mines a hidden item' end
    return nil
end

for _, prototypes in pairs(data.raw) do
    for _, prototype in pairs(prototypes) do
        -- read through a pypostprocessing metatable and an unset field can come back as one
        -- of its helper methods, so only an actual name counts as an upgrade target
        local target_name = type(prototype) == 'table' and prototype.next_upgrade
        if type(target_name) == 'string' then
            -- an upgrade target is always the same type as the thing it upgrades
            local reason = why_not(prototype, prototypes[target_name])
            if reason then
                log('AUF: ' .. prototype.name .. ' no longer upgrades to ' .. target_name .. ' because ' .. reason)
                prototype.next_upgrade = nil
            end
        end
    end
end
