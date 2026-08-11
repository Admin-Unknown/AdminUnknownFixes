-- Factorio reads the numbered entries of the list handed to data:extend and ignores
-- everything else, so a mod that leaves a stray field at the top level of that list has
-- always been quietly forgiven. pypostprocessing replaces data.extend with one that walks
-- every key to attach its metatables, and a stray field is then read as though it were a
-- prototype. The load stops inside the mod that wrote it, naming pypostprocessing.
--
-- bobpower 3.0.0 does exactly this: in prototypes/item/fluid-generator.lua the hydrazine
-- generator item closes one line early, leaving its weight sitting in the list beside it.
-- The mod is correct as far as the game is concerned and cannot be fixed from here, so what
-- we can do is hand the walker only the entries the game itself would have used.
--
-- This only helps a mod that loads after us, and we are later than we look: requiring
-- pycoalprocessing holds us behind everything that sorts before it, bobpower included. The
-- 0-auf-extend-guard companion mod exists for those, and when it is installed it has already
-- answered for the field and we must keep out of it. Wrapping on top of it would put us
-- between it and pypostprocessing, whose metatables would then stop being attached.
if _G.__auf_extend_guard then return end

local function only_the_numbered_entries(prototypes)
    if type(prototypes) ~= 'table' then return prototypes end

    local numbered = #prototypes
    local total = 0
    for _ in pairs(prototypes) do total = total + 1 end
    -- the ordinary case, left exactly as it came so that the walker still sees the very
    -- tables the game is about to store
    if total == numbered then return prototypes end

    if numbered > 0 then
        local stray = {}
        for key in pairs(prototypes) do
            if type(key) ~= 'number' or key < 1 or key > numbered or key % 1 ~= 0 then
                stray[#stray + 1] = tostring(key)
            end
        end
        log('AUF: data:extend was handed ' .. table.concat(stray, ', ') ..
            ' outside of any prototype. The game would ignore that, so we have too')
    end

    local cleaned = {}
    for index = 1, numbered do
        cleaned[index] = prototypes[index]
    end
    return cleaned
end

-- pypostprocessing installs its wrapper once per data stage, and ours has to sit outside
-- whatever is there now rather than under it, so this is checked again each stage
if data.extend ~= _G.__auf_forgiving_extend then
    local wrapped = data.extend

    local forgiving = function(self, prototypes)
        -- data:extend and data.extend are both allowed
        if self ~= prototypes and prototypes == nil then
            prototypes = self
        end
        return wrapped(self, only_the_numbered_entries(prototypes))
    end

    _G.__auf_forgiving_extend = forgiving
    data.extend = forgiving
end
