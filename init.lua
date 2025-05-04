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

question_chest = question_chest or {}  -- defines the global table
dofile(minetest.get_modpath("question_chest") .. "/formspec.lua")

local S = minetest.get_translator("question_chest")

-- Register teacher/admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chests as a teacher",
    give_to_singleplayer = true
})


-- Include formspec functions
dofile(minetest.get_modpath("question_chest") .. "/formspec.lua")

-- Glow level for soft visual effect
local glow_level = 4

-- Register the Question Chest Node
minetest.register_node("question_chest:chest", {
    description = S("Question Chest"),
    tiles = {
        "question_chest_top.png",     -- top
        "default_chest_bottom.png",   -- bottom
        "default_chest_side.png",     -- side1
        "default_chest_side.png",     -- side2
        "default_chest_side.png",     -- side3
        "default_chest_front.png"     -- front
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

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.show_formspec(name, "question_chest:teacher_config",
                question_chest.formspec.teacher_config(pos))
        else
            minetest.chat_send_player(name, "This chest will ask you a question before giving rewards.")
        end
    end,

    on_blast = function() end
})

-- Handle teacher form submission
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "question_chest:teacher_config" or not fields.save then return end

    local name = player:get_player_name()
    local pos = player:get_pos()
    local pointed = player:get_pointed_thing()
    if pointed and pointed.under then
        pos = pointed.under
    end

    local meta = minetest.get_meta(pos)

    local question = fields.question or ""
    local answers = {}
    for answer in string.gmatch(fields.answers or "", "([^,]+)") do
        table.insert(answers, answer:lower():gsub("^%s*(.-)%s*$", "%1"))
    end

    local correct = {}
    for ans in string.gmatch(fields.correct or "", "([^,]+)") do
        local val = ans:lower():gsub("^%s*(.-)%s*$", "%1")
        if tonumber(val) then
            table.insert(correct, tonumber(val))
        else
            table.insert(correct, val)
        end
    end

    local q_type = fields.type == "mcq" and "mcq" or "open"

    local store = {
        question = question,
        type = q_type,
        answers = answers,
        correct = correct
    }

    meta:set_string("question_data", minetest.serialize(store))
    meta:set_string("infotext", "Question Chest (configured)")
    minetest.chat_send_player(name, "Question saved!")
end)
