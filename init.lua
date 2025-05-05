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

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local name = player:get_player_name()
        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            return stack:get_count()
        end

        local meta = minetest.get_meta(pos)
        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
        if answered[name] then
            return stack:get_count()
        end
        return 0
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if minetest.check_player_privs(player:get_player_name(), {question_chest_admin = true}) then
            return stack:get_count()
        end
        return 0
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if minetest.check_player_privs(player:get_player_name(), {question_chest_admin = true}) then
            return count
        end
        return 0
    end,

    on_rightclick = function(pos, _, clicker)
        local name = clicker:get_player_name()
        if not name or minetest.is_protected(pos, name) then return end

        local meta = minetest.get_meta(pos)
        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.show_formspec(name, "question_chest:teacher_config:" .. minetest.pos_to_string(pos),
                question_chest.formspec.teacher_config(pos))
        elseif answered[name] then
            -- Open real chest
            minetest.show_formspec(name,
                "question_chest:real:" .. minetest.pos_to_string(pos),
                "formspec_version[4]size[10,9]" ..
                "label[0.2,0.3;Rewards for correctly answering]" ..
                "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.2,0.8;8,1;]" ..
                "list[current_player;main;0.2,2.5;8,4;]" ..
                "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
                "listring[current_player;main]"
            )
        else
            -- Show question form
            minetest.show_formspec(name,
                "question_chest:student:" .. minetest.pos_to_string(pos),
                question_chest.formspec.student_question(pos))
        end
    end,

    on_blast = function() end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()

    if formname:match("^question_chest:teacher_config:") then
        local pos_str = formname:match("^question_chest:teacher_config:(.+)")
        if not pos_str then return end
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
        local inv = meta:get_inventory()
        local rewards = {}
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                table.insert(rewards, stack:to_table())
            end
        end

        meta:set_string("question_data", minetest.serialize({
            question = question,
            type = q_type,
            answers = answers,
            correct = correct,
            rewards = rewards
        }))
        meta:set_string("infotext", "Question Chest (configured)")
        minetest.chat_send_player(name, "Question and reward saved successfully.")
        return
    end

    if formname:match("^question_chest:student:") and fields.submit_answer then
        local pos_str = formname:match("^question_chest:student:(.+)")
        if not pos_str then return end
        local pos = minetest.string_to_pos(pos_str)
        if not pos then return end

        local meta = minetest.get_meta(pos)
        local data = minetest.deserialize(meta:get_string("question_data") or "") or {}
        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}

        if answered[name] then
            minetest.after(0.1, function()
                minetest.close_formspec(name, formname)
            end)
            return
        end

        local correct = data.correct or {}
        local success = false

        if data.type == "open" then
            local response = (fields.answer or ""):lower():gsub("^%s*(.-)%s*$", "%1")
            for _, c in ipairs(correct) do
                if response == c then
                    success = true
                    break
                end
            end
        elseif data.type == "mcq" and data.answers then
            local selected = {}
            for i = 1, #data.answers do
                if fields["opt_" .. i] == "true" then
                    local label = data.answers[i]:lower():gsub("^%s*(.-)%s*$", "%1")
                    table.insert(selected, label)
                end
            end
            if #selected == #correct then
                local match = true
                for _, c in ipairs(correct) do
                    local c_trimmed = c:lower():gsub("^%s*(.-)%s*$", "%1")
                    local found = false
                    for _, s in ipairs(selected) do
                        if s == c_trimmed then
                            found = true
                            break
                        end
                    end
                    if not found then
                        match = false
                        break
                    end
                end
                if match then success = true end
            end
        end

        if success then
            answered[name] = true
            meta:set_string("answered_players", minetest.serialize(answered))
            minetest.chat_send_player(name, "Correct! You may now open the chest.")
        else
            minetest.chat_send_player(name, "Incorrect answer. Keep trying.")
        end

        minetest.after(0.1, function()
            minetest.close_formspec(name, formname)
        end)
    end
end)
