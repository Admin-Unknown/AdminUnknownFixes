-- Putting the recipes into shape only helps if it happens before somebody walks them, and
-- the walking is done by Angel's OV.execute, which any Angel's mod may call at any point in
-- any stage. Running the pass at the end of our own files is a guess at when that will be,
-- and the guess was wrong: angelsaddons-storage walks them in data-updates, and this mod
-- loads after it, so nothing we do in that stage arrives in time.
--
-- Angel's keeps that walk in a field of a table it leaves lying about in the global state, and
-- every mod that uses it reads the field at the moment it calls, so putting our own function
-- there makes the pass run immediately before each walk, whoever starts it and whenever. No
-- load order to get right, and nothing to keep in step with as mods are turned on and off.
--
-- The walk itself is then run exactly as it was. This is not a replacement for it.

local normalise = require('prototypes/compatibility/normalise-recipe-items')

if _G.__auf_angels_walk_tidied then return end

local OV = angelsmods and angelsmods.functions and angelsmods.functions.OV

if type(OV) ~= 'table' or type(OV.execute) ~= 'function' then
    -- no Angel's, or a version that keeps its overrides somewhere else. Either way the pass
    -- still runs at the end of each of our stages, which is where it started
    return
end

local walk = OV.execute

OV.execute = function(...)
    normalise()
    return walk(...)
end

_G.__auf_angels_walk_tidied = true

log('AUF: every ingredient and result will be put into the form the game takes just before ' ..
    'each of Angel\'s override passes reads them')
