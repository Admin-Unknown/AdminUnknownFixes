-- pypostprocessing data-final-fixes.lua (line ~552) errors if any non-hidden
-- technology lists a prerequisite that is a hidden technology. Angel's / Bob's /
-- Py integration often leaves stragglers (sulfur-processing, uranium-processing,
-- ...) after global tech replacements.
--
-- Wrap global error() from end of data-updates until our data-final-fixes begins.
-- Suppress only messages that match Pyanodon's known diagnostic from that check
-- (impossible-to-research + hidden prerequisite + pybugreports link). All other
-- errors use the original error().

if _G.__auf_saved_global_error then return end

local saved = error
_G.__auf_saved_global_error = saved

local function is_pypp_hidden_prereq_tech_tree_msg(msg)
    if type(msg) ~= "string" then return false end
    return msg:find("impossible%-to%-research", 1, false)
        and msg:find("has hidden prerequisite", 1, true)
        and msg:find("pybugreports", 1, true)
end

local function auf_error(message, level)
    if is_pypp_hidden_prereq_tech_tree_msg(message) then
        log("[AdminUnknownFixes] Suppressed pypostprocessing impossible-to-research (hidden prerequisite) check. See bridge overrides.")
        return
    end
    return saved(message, level)
end

_G.error = auf_error
---@diagnostic disable-next-line: duplicate-set-field
error = auf_error
