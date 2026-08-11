
if mods['boblogistics'] then
   fun.ingredient_replace('borax-mine','transport-belt','bob-basic-transport-belt')
   TECHNOLOGY("bob-fluid-handling-2"):add_prereq("logistic-science-pack")
   if mods['pyindustry'] then
      fun.tech_add_recipe('py-storage-tanks', 'bob-storage-tank-all-corners')
      --change valves
      fun.remove_recipe_unlock('bob-valve')
      fun.remove_recipe_unlock('bob-overflow-valve')
      fun.remove_recipe_unlock('bob-topup-valve')
      --robots
      fun.remove_recipe_unlock('construction-robot')
   end
   if mods['pyalienlife'] then
        TECHNOLOGY("bob-drills-2"):add_pack("py-science-pack-1"):add_prereq("electric-mining-drill"):remove_prereq("electronics")
        TECHNOLOGY("bob-area-drills-2"):add_pack("py-science-pack-1"):add_prereq("electric-mining-drill"):remove_prereq("electronics")
   end
   if mods['pyrawores'] then
      fun.ingredient_replace('bob-storage-tank-all-corners','iron-plate','lead-plate')
      fun.ingredient_replace('bob-storage-tank-all-corners','pipe', 'duralumin')
   end
end

if mods['bobgreenhouse'] then
   if mods['pyalienlife'] then
      if data.raw.technology["bob-greenhouse"] then
         TECHNOLOGY("bob-greenhouse"):add_prereq("glass")
      end
      if data.raw.item["bob-wood-pellets"] then
         data.raw.item["bob-wood-pellets"].fuel_category = "biomass"
      end
      if data.raw.item["bob-seedling"] then
         data.raw.item["bob-seedling"].fuel_category = "biomass"
      end
   end
end