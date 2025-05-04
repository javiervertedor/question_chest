-- Question Chest Luanti Mod for Teachers
-- By Francisco Vertedor
--
-- This mod adds a protected chest for educational use in Luanti. Teachers can configure
-- questions (open-ended or multiple choice) and associate rewards. Students must answer
-- correctly to receive items, promoting learning through gameplay.
--
-- Licensed under the GNU General Public License v3.0
-- See https://www.gnu.org/licenses/gpl-3.0.html

question_chest = question_chest or {}

local S = minetest.get_translator("question_chest")

minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chests as a teacher",
    give_to_singleplayer = true
})

dofile(minetest.get_modpath("question_chest") .. "/formspec.lua")

minetest.register_node("question_chest:chest", {
    description = S("Question Chest"),
    tiles = {
        "question_chest_top.png",
        "default_chest_bottom.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_front.png"
    },
    paramtype = "light",
    light_source = 4,
    paramtype2 = "facedir",
    is_ground_content = false,
    legacy_facedir_simple = true,
    groups = {dig_immediate = 2, unbreakable = 1},
    sounds = default.node_sound_wood_defaults(),

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 8 * 4)
        meta:set_string("infotext", S("Question Chest"))
    end,

    can_dig = function(pos, player)
        return minetest.get_meta(pos):get_inventory():is_empty("main")
            and not minetest.is_protected(pos, player:get_player_name())
    end,

    on_rightclick = function(pos, _, clicker)
        local name = clicker:get_player_name()
        if not name or minetest.is_protected(pos, name) then return end

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            local fs_name = "question_chest:teacher_config:" .. minetest.pos_to_string(pos)
            minetest.show_formspec(name, fs_name, question_chest.formspec.teacher_config(pos))
        else
            minetest.chat_send_player(name, "🧠 This chest will ask you a question before giving rewards.")
        end
    end,

    on_blast = function() end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname:match("^question_chest:teacher_config:") or fields.quit then return end

    local name = player:get_player_name()
    local pos_str = formname:match("^question_chest:teacher_config:(.+)")
    local pos = pos_str and minetest.string_to_pos(pos_str)
    if not pos then
        minetest.chat_send_player(name, "❌ Invalid chest position.")
        return
    end

    local question = (fields.question or ""):gsub("^%s*(.-)%s*$", "%1")
    local q_type = fields.qtype_mcq == "true" and "mcq" or "open"

    local answers = {}
    for a in string.gmatch(fields.answers or "", "([^,]+)") do
        local clean = a:lower():gsub("^%s*(.-)%s*$", "%1")
        if clean ~= "" then table.insert(answers, clean) end
    end

    local correct = {}
    for c in string.gmatch(fields.correct or "", "([^,]+)") do
        local clean = c:lower():gsub("^%s*(.-)%s*$", "%1")
        if clean ~= "" then table.insert(correct, clean) end
    end

    if question == "" then
        minetest.chat_send_player(name, "⚠️ Question is required.")
        return
    end

    if #answers == 0 then
        minetest.chat_send_player(name, "⚠️ You must enter at least one answer.")
        return
    end

    if #correct == 0 then
        minetest.chat_send_player(name, "⚠️ You must specify at least one correct answer.")
        return
    end

    local valid = true
    for _, c in ipairs(correct) do
        local found = false
        for _, a in ipairs(answers) do
            if c == a then
                found = true
                break
            end
        end
        if not found then
            valid = false
            break
        end
    end

    if not valid then
        minetest.chat_send_player(name, "⚠️ One or more correct answers do not match the answer options.")
        return
    end

    local meta = minetest.get_meta(pos)
    meta:set_string("question_data", minetest.serialize({
        question = question,
        type = q_type,
        answers = answers,
        correct = correct
    }))
    meta:set_string("infotext", "Question Chest (configured)")
    minetest.chat_send_player(name, "✅ Question saved successfully.")
end)
