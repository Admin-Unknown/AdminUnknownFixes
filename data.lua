fun = require("functions/functions")
--log(serpent.block(fun))

require('prototypes/recipe-category')

if settings.startup['prod-for-sinners'].value then
	require('functions/sinners-prod')
end

--multi-mod
--aka stuff many mods need
--require('prototypes/multi-mod/Data')

--angel mods
require('prototypes/angels-mods/Data')

--aai
require('prototypes/aai/Data')

--bobs mods
require('prototypes/bobs-mods/Data')

--omni mods
--require("prototypes/omni-mods/Data")

--madclown mods
require('prototypes/madclowns-mods/data')

--msp
if mods['MoreSciencePacks-for1_1'] then
	require('prototypes/msp/Data')
end

--apm mods
require('prototypes/apm-mods/Data')

-- Keeps pypostprocessing's recipe/technology helpers (has_category,
-- replace_ingredient, add_prereq, ...) reachable on every prototype, including
-- ones that reached data.raw without going through data:extend. Installs a hook
-- on data.raw.recipe itself, so mods we cannot order ourselves against — most of
-- all pycoalprocessing's data-final-fixes — heal as they iterate.
require('functions/pypp-recipe-meta-guard')

-- No-op TECHNOLOGY() for optional Bob's techs that pypostprocessing touches without guards.
require('functions/pypp-technology-missing-shim')
