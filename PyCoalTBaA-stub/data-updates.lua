-- Every mod's data-updates runs before every mod's data-final-fixes, so this is
-- the one hook that is guaranteed to land before pycoalprocessing's has_category
-- checks no matter how the mods happen to be ordered.
require("recipe-call-shims")("data-updates")
