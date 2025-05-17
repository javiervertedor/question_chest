local chest_base = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")
local student_form = dofile(minetest.get_modpath("question_chest") .. "/mc_student_form.lua")
local teacher_form = dofile(minetest.get_modpath("question_chest") .. "/mc_teacher_form.lua")
local chest_open = dofile(minetest.get_modpath("question_chest") .. "/chest_open.lua")

chest_base.register_chest("question_chest:mc_chest", {
    description = "Multiple Choice Question Chest",
    tiles = {
        "mc_question_chest_top.png",
        "default_chest_bottom.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_front.png"
    },

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 8)
        meta:set_string("infotext", "MC Question Chest")
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
            minetest.show_formspec(name, "question_chest:mc_teacher", teacher_form.get(pos, data))
        elseif answered[name] then
            chest_open.show(pos, name, meta)
        else
            minetest.show_formspec(name, "question_chest:mc_student", student_form.get(pos, data))
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos_string = player:get_meta():get_string("question_chest:pos")
    local pos = minetest.string_to_pos(pos_string or "")
    if not pos then return false end
    local meta = minetest.get_meta(pos)
    local pmeta = player:get_meta()

    -- Handle checkbox toggles and save to metadata
    if formname == "question_chest:mc_student" then
        for field, value in pairs(fields) do
            if field:match("^opt_%d+$") then
                pmeta:set_string("question_chest:" .. field, value)
            end
        end
    end

    -- === TEACHER FORM ===
    if formname == "question_chest:mc_teacher" and fields.submit then
        local question = (fields.question_input or ""):trim()
        local options_str = (fields.options_input or ""):trim()
        local answers_str = (fields.correct_answers or ""):trim()

        if question == "" or options_str == "" or answers_str == "" then
            minetest.chat_send_player(name, "Please fill in question, options, and correct answers.")
            return true
        end

        local options = {}
        for item in options_str:gmatch("[^,]+") do
            table.insert(options, item:trim())
        end

        local answers = {}
        for item in answers_str:gmatch("[^,]+") do
            table.insert(answers, item:lower():trim())
        end

        local reward_serialized = {}
        for _, stack in ipairs(meta:get_inventory():get_list("main")) do
            table.insert(reward_serialized, stack:to_string())
        end

        meta:set_string("data", minetest.write_json({
            question = question,
            options = options,
            answers = answers
        }))
        meta:set_string("reward_items", minetest.serialize(reward_serialized))
        meta:set_string("answered_players", minetest.serialize({}))
        meta:set_string("reward_collected", minetest.serialize({}))

        minetest.chat_send_player(name, "MCQ saved successfully.")
        return true
    end

    -- === STUDENT SUBMISSION ===
    if formname == "question_chest:mc_student" and fields.submit_answer then
        local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
        local options = data.options or {}

        local selected = {}
        for i, option in ipairs(options) do
            local key = "question_chest:opt_" .. i
            local value = pmeta:get_string(key)
            if value == "true" then
                table.insert(selected, option:lower():trim())
            end
        end

        local correct = {}
        for _, a in ipairs(data.answers or {}) do
            table.insert(correct, a:lower():trim())
        end

        table.sort(selected)
        table.sort(correct)

        local function arrays_equal(a, b)
            if #a ~= #b then return false end
            for i = 1, #a do
                if a[i] ~= b[i] then return false end
            end
            return true
        end

        if arrays_equal(selected, correct) then
            minetest.chat_send_player(name, "Correct! You may collect your reward.")
            chest_open.show(pos, name, meta)
            local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
            answered[name] = true
            meta:set_string("answered_players", minetest.serialize(answered))
        else
            minetest.chat_send_player(name, "Incorrect. Try again.")
            minetest.close_formspec(name, formname)
        end

        -- Clear metadata
        for i = 1, #options do
            pmeta:set_string("question_chest:opt_" .. i, "")
        end

        return true
    end

    return false
end)
