-- A loop anywhere in the technology tree stops the load, and the message names the
-- technologies without saying which mod added which link, which is the part that takes the
-- time to work out. A loop is easy to arrive at here: each mod rearranges prerequisites
-- with only its own neighbours in view, and it takes two of them pointing opposite ways.
--
-- So the tree is walked at the end of the load. A loop is written to the log in full and
-- then broken, because a game that starts with one prerequisite missing beats one that does
-- not start at all. The cut is the link that closes the loop, which is not necessarily the
-- one that deserves to go, so anything reported here is worth a considered fix in the
-- override files rather than leaving to this.

local technologies = data.raw.technology

local sorted_names = {}
for name in pairs(technologies) do
    sorted_names[#sorted_names + 1] = name
end
-- the walk order decides which link a loop is cut at, and a cut that moves around between
-- loads would be worse than any particular choice of cut
table.sort(sorted_names)

local UNVISITED, ON_THE_PATH, DONE = nil, 1, 2
local state = {}
local path = {}

local function drop_prerequisite(technology, prerequisite)
    for index = #technology.prerequisites, 1, -1 do
        if technology.prerequisites[index] == prerequisite then
            table.remove(technology.prerequisites, index)
        end
    end
end

local function describe_loop(prerequisite)
    -- each step of the path needs the one after it, so the loop is the tail of the path from
    -- the name we have arrived back at, closed by naming it a second time
    local names = {}
    local started = false
    for _, name in ipairs(path) do
        if name == prerequisite then started = true end
        if started then names[#names + 1] = name end
    end
    names[#names + 1] = prerequisite
    return table.concat(names, ' needs ')
end

local function walk(name)
    local technology = technologies[name]
    if not technology or type(technology.prerequisites) ~= 'table' then
        state[name] = DONE
        return
    end

    state[name] = ON_THE_PATH
    path[#path + 1] = name

    -- by index and backwards, so that cutting a link does not skip the next one
    for index = #technology.prerequisites, 1, -1 do
        local prerequisite = technology.prerequisites[index]
        if type(prerequisite) == 'string' and technologies[prerequisite] then
            if state[prerequisite] == ON_THE_PATH then
                log('AUF: the technology tree loops back on itself: ' ..
                    describe_loop(prerequisite))
                log('AUF: ' .. name .. ' no longer needs ' .. prerequisite ..
                    ', which breaks the loop. Check whether that is the right place for it')
                drop_prerequisite(technology, prerequisite)
            elseif state[prerequisite] == UNVISITED then
                walk(prerequisite)
            end
        end
    end

    path[#path] = nil
    state[name] = DONE
end

for _, name in ipairs(sorted_names) do
    if state[name] == UNVISITED then
        walk(name)
    end
end
