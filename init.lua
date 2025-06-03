-- Question Chest Luanti Mod for Teachers
-- By Francisco Vertedor
--
-- This mod adds a protected chest for educational use in Luanti. Teachers can configure
-- questions (open-ended or multiple choice) and associate rewards. Students must answer
-- correctly to receive items, promoting learning through gameplay.
--
-- Licensed under the GNU General Public License v3.0
-- See https://www.gnu.org/licenses/gpl-3.0.html


-- Register admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chest",
    give_to_singleplayer = true,
})

-- Load base chest registration function
local chest_base = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")

-- Load chest types
dofile(minetest.get_modpath("question_chest") .. "/open_question.lua")
dofile(minetest.get_modpath("question_chest") .. "/mc_question.lua")
