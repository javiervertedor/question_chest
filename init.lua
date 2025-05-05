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
dofile(minetest.get_modpath("question_chest") .. "/formspec.lua")

minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chests as a teacher",
    give_to_singleplayer = true
})

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
        meta:get_inventory():set_size("main", 8 * 1)
        meta:set_string("infotext", S("Question Chest"))
        meta:set_string("answered_players", minetest.serialize({}))
    end,

    can_dig = function(pos, player)
        return minetest.get_meta(pos):get_inventory():is_empty("main")
            and not minetest.is_protected(pos, player:get_player_name())
    end,

    on_rightclick = function(pos, _, clicker)
        local name = clicker:get_player_name()
        if not name or minetest.is_protected(pos, name) then return end

        local meta = minetest.get_meta(pos)
        local answered = minetest.deserialize(meta:get_string("answered_players")) or {}

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.show_formspec(name, "question_chest:teacher_config:" .. minetest.pos_to_string(pos),
                question_chest.formspec.teacher_config(pos))
        elseif answered[name] then
            minetest.show_formspec(name, "question_chest:access:" .. minetest.pos_to_string(pos),
                "size[8,4]label[0.3,1.5;You already answered correctly. You may access the chest.]")
        else
            minetest.show_formspec(name, "question_chest:student:" .. minetest.pos_to_string(pos),
                question_chest.formspec.student_question(pos))
        end
    end,

    on_blast = function() end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()

    -- Admin config
    if formname:match("^question_chest:teacher_config:") then
        local pos_str = formname:match("^question_chest:teacher_config:(.+)")
        local pos = minetest.string_to_pos(pos_str)
        if not pos then return end

        if fields.quit == "true" then return end

        if fields.qtype and not fields.save then
            minetest.show_formspec(name, formname, question_chest.formspec.teacher_config(pos, {
                question = fields.question,
                qtype = fields.qtype,
                answers = fields.answers,
                correct = fields.correct
            }))
            return
        end

        local question = (fields.question or ""):gsub("^%s*(.-)%s*$", "%1")
        local q_type = (fields.qtype == "mcq") and "mcq" or "open"
        local answers, correct = {}, {}

        for a in string.gmatch(fields.answers or "", "([^,]+)") do
            local clean = a:lower():gsub("^%s*(.-)%s*$", "%1")
            if clean ~= "" then table.insert(answers, clean) end
        end
        for c in string.gmatch(fields.correct or "", "([^,]+)") do
            local clean = c:lower():gsub("^%s*(.-)%s*$", "%1")
            if clean ~= "" then table.insert(correct, clean) end
        end

        if question == "" or #correct == 0 or (q_type == "mcq" and #answers == 0) then
            minetest.chat_send_player(name, "Please fill all required fields.")
            return
        end

        if q_type == "mcq" then
            for _, c in ipairs(correct) do
                local found = false
                for _, a in ipairs(answers) do
                    if c == a then found = true break end
                end
                if not found then
                    minetest.chat_send_player(name, "Correct answers must match options.")
                    return
                end
            end
        end

        local meta = minetest.get_meta(pos)
        meta:set_string("question_data", minetest.serialize({
            question = question,
            type = q_type,
            answers = answers,
            correct = correct
        }))
        meta:set_string("infotext", "Question Chest (configured)")
        minetest.chat_send_player(name, "Question saved successfully.")
        return
    end

    -- Student answers
    if formname:match("^question_chest:student:") then
        local pos_str = formname:match("^question_chest:student:(.+)")
        if not pos_str then return end
        local pos = minetest.string_to_pos(pos_str)
        if not pos then return end
    
        local meta = minetest.get_meta(pos)
        local data = minetest.deserialize(meta:get_string("question_data") or "") or {}
        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}

        if answered[name] then return end

        local correct = data.correct or {}
        local success = false

        if data.type == "open" then
            local response = (fields.answer or ""):lower():gsub("^%s*(.-)%s*$", "%1")
            for _, c in ipairs(correct) do
                if response == c then success = true break end
            end
        elseif data.type == "mcq" and data.answers then
            local selected = {}
            for i = 1, #data.answers do
                if fields["opt_" .. i] == "true" then
                    table.insert(selected, data.answers[i])
                end
            end
            if #selected == #correct then
                local match = true
                for _, c in ipairs(correct) do
                    local found = false
                    for _, s in ipairs(selected) do
                        if s == c then found = true break end
                    end
                    if not found then match = false break end
                end
                if match then success = true end
            end
        end

        if success then
            answered[name] = true
            meta:set_string("answered_players", minetest.serialize(answered))
            minetest.chat_send_player(name, "Correct! The chest is now unlocked for you.")
            minetest.show_formspec(name, "", "")
        else
            minetest.chat_send_player(name, "Incorrect answer. Try again.")
            minetest.after(0.1, function()
                minetest.show_formspec(name, "question_chest:student:" .. minetest.pos_to_string(pos),
                    question_chest.formspec.student_question(pos))
            end)
        end
    end
end)