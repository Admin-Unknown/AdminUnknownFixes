-- This runs once every mod's data.lua has been and gone, and before any other mod's
-- data-updates, which is the whole reason for doing anything here.
--
-- Angel's walks every recipe in the game early in this stage and reads each ingredient and
-- each result as a table with a name in it. Anything else and the walk stops, which is what
-- "table index is nil" in angelsrefining's adjust_subtable means. AdminUnknownFixes carries
-- the pass that puts those entries into the form the game itself asks for, but it loads after
-- Angel's and so cannot run it in time. This is the last moment before Angel's looks, so the
-- pass is called from here. The code stays in the one place it is written, because two copies
-- of it would be one copy too many.
if mods['AdminUnknownFixes'] then
    local found, normalise = pcall(require, '__AdminUnknownFixes__/prototypes/compatibility/normalise-recipe-items')
    if found and type(normalise) == 'function' then
        normalise()
    else
        log('AUF: the recipe shape pass could not be read out of AdminUnknownFixes, so the ' ..
            'recipes go into this stage as they are: ' .. tostring(normalise))
    end
end

-- The rest of this file says whether the guard held for the whole of the data stage, and how
-- many wrappers were laid over it while it did. If the load ever stops in pypostprocessing
-- again, these lines are what say whether the guard was still answering for the field.

local writes = _G.__auf_extend_guard_writes or 0

if not _G.__auf_extend_guard then
    log('AUF: the extend guard never installed, so data:extend went through the whole data ' ..
        'stage unguarded')
elseif rawget(data, 'extend') ~= nil then
    log('AUF: something put a function back into data:extend directly rather than through the ' ..
        'guard, which takes the guard out of the chain. That is what to look at')
else
    log('AUF: the extend guard held for the whole data stage, with ' .. writes ..
        ' wrapper(s) laid over it')
end
