local chest_base    = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")
local student_form  = dofile(minetest.get_modpath("question_chest") .. "/student_form.lua")
local teacher_form  = dofile(minetest.get_modpath("question_chest") .. "/teacher_form.lua")
local chest_open    = dofile(minetest.get_modpath("question_chest") .. "/chest_open.lua")

local function get_chest_key(pos)
    return minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
end

chest_base.register_chest("question_chest:chest", {
    description = "Open Question Chest",
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

    can_dig = function(pos, player)
        return minetest.check_player_privs(player, {question_chest_admin = true}) and
            minetest.get_meta(pos):get_inventory():is_empty("main")
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        clicker:get_meta():set_string("question_chest:pos", minetest.pos_to_string(pos))

        local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.show_formspec(name, "question_chest:teacher_config", teacher_form.get(pos, data))
        elseif answered[name] then
            minetest.chat_send_player(name, "You already answered this question correctly.")
            chest_open.show(pos, name, meta)
        else
            minetest.show_formspec(name, "question_chest:student_form", student_form.get(pos, data))
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "question_chest:teacher_config" then return false end

    local name = player:get_player_name()
    local pos_string = player:get_meta():get_string("question_chest:pos")
    local pos = minetest.string_to_pos(pos_string or "")
    if not pos then return false end
    local meta = minetest.get_meta(pos)

    if fields.submit then
        local question = (fields.question_input or ""):trim()
        local answers_str = (fields.correct_answers or ""):trim()

        if question == "" or answers_str == "" then
            minetest.chat_send_player(name, "Please enter a question and at least one correct answer.")
            return true
        end

        local answers = {}
        for answer in answers_str:gmatch("[^,]+") do
            table.insert(answers, answer:lower():trim())
        end

        local reward_serialized = {}
        for _, stack in ipairs(meta:get_inventory():get_list("main")) do
            table.insert(reward_serialized, stack:to_string())
        end

        meta:set_string("data", minetest.write_json({question = question, answers = answers}))
        meta:set_string("reward_items", minetest.serialize(reward_serialized))
        meta:set_string("answered_players", minetest.serialize({}))
        meta:set_string("reward_collected", minetest.serialize({}))

        minetest.chat_send_player(name, "Question and rewards saved.")
        return true
    end

    return false
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "question_chest:student_form" then
        local name = player:get_player_name()
        local pos_string = player:get_meta():get_string("question_chest:pos")
        local pos = minetest.string_to_pos(pos_string or "")
        if not pos then return false end

        local meta = minetest.get_meta(pos)
        local data = minetest.parse_json(meta:get_string("data") or "{}") or {}

        local submitted = (fields.student_answer or ""):lower():trim()
        for _, answer in ipairs(data.answers or {}) do
            if submitted == answer then
                minetest.chat_send_player(name, "Correct! You may collect your reward.")
                local chest_open = dofile(minetest.get_modpath("question_chest") .. "/chest_open.lua")
                chest_open.show(pos, name, meta)
                return true
            end
        end

        minetest.chat_send_player(name, "Incorrect. Try again.")
        minetest.close_formspec(name, formname)
        return true
    end
end)