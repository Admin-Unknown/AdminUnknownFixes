-- Nothing to do here. This runs once every mod's data.lua has been and gone, which makes it
-- the one place that can say whether the guard held for the whole of that stage, and how
-- many wrappers were laid over it while it did. If the load ever stops in pypostprocessing
-- again, these two lines are what say whether the guard was still answering for the field.

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
