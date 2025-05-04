-- Question Chest Luanti Mod for Teachers
-- By Francisco Vertedor
-- 
-- This mod adds a protected chest for educational use in Luanti. Teachers can configure
-- questions (open-ended or multiple choice) and associate rewards. Students must answer
-- correctly to receive items, promoting learning through gameplay.
--
-- Licensed under the GNU General Public License v3.0
-- You may copy, distribute and modify this code under the terms of the GPLv3.
-- See https://www.gnu.org/licenses/gpl-3.0.html for full license text.


local S = minetest.get_translator("question_chest")

-- Glow level for soft visual effect
local glow_level = 4

-- Register the Question Chest Node
minetest.register_node("question_chest:chest", {
    description = S("Question Chest"),
    tiles = {
        "question_chest_top.png",  -- top
        "default_chest_bottom.png",  -- bottom
        "default_chest_side.png", -- side1
        "default_chest_side.png", -- side2
        "default_chest_side.png", -- side3
        "default_chest_front.png" -- front
    },
    paramtype = "light",
    light_source = glow_level,
    paramtype2 = "facedir",
    is_ground_content = false,
    legacy_facedir_simple = true,
    groups = {dig_immediate = 2, unbreakable = 1},
    sounds = default.node_sound_wood_defaults(),

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 8 * 4) -- standard chest size
        meta:set_string("infotext", S("Question Chest"))
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        return meta:get_inventory():is_empty("main") and
            not minetest.is_protected(pos, player:get_player_name())
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        if not name then return end

        if minetest.is_protected(pos, name) then
            return
        end

        -- Placeholder for Phase 2: Teacher/student interaction
        minetest.chat_send_player(name, "🧠 This is a question chest. Questions coming soon!")
    end,

    on_blast = function() end
})
