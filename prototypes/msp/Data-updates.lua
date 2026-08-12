-- Each science pack gains the three More Science Packs items that sit at its tier. This was
-- written as {"name", 1}, which is how 1.1 took an ingredient and how nothing takes one now:
-- pypostprocessing reads the name out of the table, finds nothing there, and stops the load
-- trying to say so. The pack a tier belongs to is named once and the three items are added in
-- a loop, which is the same work with the names in one place rather than forty.
local tiers = {
	{ packs = { 'py-science-pack-1', 'py-science-pack-1-turd' }, first = 1 },
	{ packs = { 'logistic-science-pack' }, first = 4 },
	{ packs = { 'military-science-pack' }, first = 7 },
	{ packs = { 'py-science-pack-2', 'py-science-pack-2-turd' }, first = 10 },
	{ packs = { 'chemical-science-pack' }, first = 13 },
	{ packs = { 'py-science-pack-3', 'py-science-pack-3-turd' }, first = 16 },
	{ packs = { 'production-science-pack' }, first = 19 },
	{ packs = { 'py-science-pack-4', 'py-science-pack-4-turd' }, first = 22 },
	{ packs = { 'utility-science-pack' }, first = 25 },
	{ packs = { 'space-science-pack' }, first = 28 },
}

if mods['pyalienlife'] then
	for _, tier in pairs(tiers) do
		for _, pack in pairs(tier.packs) do
			for offset = 0, 2 do
				RECIPE(pack):add_ingredient({
					type = 'item',
					name = 'more-science-pack-' .. (tier.first + offset),
					amount = 1,
				})
			end
		end
	end
end

--this code is by Honktown
-- The labs are told to stop taking the More Science Packs items, since the packs themselves
-- now carry them. Clearing each entry in place left a hole in the middle of the list, and a
-- list with a hole in it is only half a list to everything that reads it afterwards, so what
-- is kept is gathered into a new one instead.
for _, lab in pairs(data.raw.lab) do
	local kept = {}
	for _, input in pairs(lab.inputs or {}) do
		if not string.find(input, 'more-science-pack-', 1, 'plain') then
			kept[#kept + 1] = input
		end
	end
	lab.inputs = kept
end
