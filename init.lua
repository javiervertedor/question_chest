-- Register admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chest",
    give_to_singleplayer = true,
})

-- Load base chest registration function
local chest_base = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")

-- Load chest types
dofile(minetest.get_modpath("question_chest") .. "/open_question.lua")
-- dofile(minetest.get_modpath("question_chest") .. "/mc_question.lua") -- coming soon
