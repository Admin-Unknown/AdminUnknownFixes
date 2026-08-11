-- Factorio 2.1 changed the mine-entity research trigger: where it took one entity it now
-- takes a list of them, any one of which finishes the research. A trigger written the old
-- way fails with a missing "entities" key, reported against the technology rather than the
-- line that wrote it, which is the same shape of report as the recipe category change.
--
-- bobplates still writes the old form for sand-processing, and the Angel's fix beside this
-- one rewrites the entity in place without changing the shape, so we arrive at it too.

local function entity_exists(name)
    for _, prototypes in pairs(data.raw) do
        local prototype = prototypes[name]
        -- an entity is the thing that has a collision box or can be mined; checking every
        -- type this way is what avoids having to list them
        if type(prototype) == 'table' and (prototype.collision_box or prototype.minable) then
            return true
        end
    end
    return false
end

for _, technology in pairs(data.raw.technology or {}) do
    local trigger = technology.research_trigger
    if type(trigger) == 'table' and trigger.type == 'mine-entity' then
        if type(trigger.entity) == 'string' and not trigger.entities then
            trigger.entities = { trigger.entity }
            trigger.entity = nil
        end

        if type(trigger.entities) == 'table' then
            local present, missing = {}, {}
            for _, name in ipairs(trigger.entities) do
                if entity_exists(name) then
                    present[#present + 1] = name
                else
                    missing[#missing + 1] = name
                end
            end
            -- an empty list is as invalid as a name that resolves to nothing, so the list is
            -- only narrowed when something is left to mine
            if #missing > 0 and #present > 0 then
                log('AUF: ' .. technology.name .. ' is researched by mining ' ..
                    table.concat(missing, ', ') .. ', which nothing installed provides. ' ..
                    'Left with ' .. table.concat(present, ', '))
                trigger.entities = present
            elseif #missing > 0 then
                log('AUF: ' .. technology.name .. ' is researched by mining ' ..
                    table.concat(missing, ', ') .. ', and nothing installed provides any of ' ..
                    'them. That needs deciding rather than guessing at, so it is left alone')
            end
        end
    end
end
