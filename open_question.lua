local chest_base    = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")
local student_form  = dofile(minetest.get_modpath("question_chest") .. "/student_form.lua")
local teacher_form  = dofile(minetest.get_modpath("question_chest") .. "/teacher_form.lua")
local chest_open    = dofile(minetest.get_modpath("question_chest") .. "/chest_open.lua")

local function get_chest_key(pos)
    return minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
end

chest_base.register_chest("question_chest:chest", {
    description = "Question Chest",
    tiles = {
        "question_chest_top.png",
        "default_chest_bottom.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_front.png"
    },

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 8)
        meta:set_string("infotext", "Question Chest")
        meta:set_string("data", "{}")
    end,

    on_rightclick = function(pos, node, player)
        if minetest.check_player_privs(player, {question_chest_admin = true}) then
            -- Teacher mode
            local meta = minetest.get_meta(pos)
            local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
            local formspec = teacher_form.get(pos, data)
            player:get_meta():set_string("question_chest:pos", minetest.pos_to_string(pos))
            minetest.show_formspec(player:get_player_name(), "question_chest:teacher", formspec)
        else
            -- Student mode
            local meta = minetest.get_meta(pos)
            local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
            local formspec = student_form.get(pos, data)
            player:get_meta():set_string("question_chest:pos", minetest.pos_to_string(pos))
            minetest.show_formspec(player:get_player_name(), "question_chest:student", formspec)
        end
    end,

    can_dig = function(pos, player)
        return minetest.check_player_privs(player, {question_chest_admin = true}) and
            minetest.get_meta(pos):get_inventory():is_empty("main")
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos_string = player:get_meta():get_string("question_chest:pos")
    local pos = minetest.string_to_pos(pos_string or "")
    if not pos then return false end
    local meta = minetest.get_meta(pos)

    -- === TEACHER MODE ===
    if formname == "question_chest:teacher" and fields.submit then
        local question = (fields.question_input or ""):trim()
        local answers = {}
        for answer in (fields.answers_input or ""):gmatch("[^,]+") do
            answer = answer:match("^%s*(.-)%s*$"):lower()
            if answer ~= "" then
                table.insert(answers, answer)
            end
        end

        if question == "" or #answers == 0 then
            minetest.chat_send_player(name, "Please fill in both question and answers.")
            return true
        end

        -- Serialize reward items
        local reward_serialized = {}
        for _, stack in ipairs(meta:get_inventory():get_list("main")) do
            table.insert(reward_serialized, stack:to_string())
        end

        meta:set_string("data", minetest.write_json({
            question = question,
            answers = answers
        }))
        meta:set_string("reward_items", minetest.serialize(reward_serialized))
        meta:set_string("answered_players", minetest.serialize({}))
        meta:set_string("reward_collected", minetest.serialize({}))  -- Initialize empty collection tracking

        minetest.chat_send_player(name, "Question saved successfully.")
        return true
    end

    -- === STUDENT MODE ===
    if formname == "question_chest:student" and fields.submit then
        local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
        local correct_answers = data.answers or {}
        local answer = (fields.answer_input or ""):lower():trim()

        -- Check if answer matches any of the correct answers
        local is_correct = false
        for _, correct in ipairs(correct_answers) do
            if answer == correct then
                is_correct = true
                break
            end
        end

        if is_correct then
            minetest.chat_send_player(name, "Correct! You may collect your reward.")
            chest_open.show(pos, name, meta)
            local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
            answered[name] = true
            meta:set_string("answered_players", minetest.serialize(answered))
        else
            minetest.chat_send_player(name, "Incorrect. Try again.")
            minetest.close_formspec(name, formname)
        end
        return true
    end
    return false
end)
