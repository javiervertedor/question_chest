local chest_base = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")
local student_form = dofile(minetest.get_modpath("question_chest") .. "/mc_student_form.lua")
local teacher_form = dofile(minetest.get_modpath("question_chest") .. "/mc_teacher_form.lua")
local chest_open = dofile(minetest.get_modpath("question_chest") .. "/chest_open.lua")
local utils = dofile(minetest.get_modpath("question_chest") .. "/utils.lua")

-- Helper to shuffle choices
local function shuffle_options(options)
    local shuffled = {}
    for i, opt in ipairs(options) do
        table.insert(shuffled, {idx = i, text = opt})
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

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
            -- Shuffle options and create a label map
            local shuffled = shuffle_options(data.options or {})
            local label_map = {}
            local shuffled_options = {}

            for i, opt in ipairs(shuffled) do
                table.insert(shuffled_options, opt.text)
                label_map["opt_" .. i] = opt.text
            end

            -- Save the label map to player metadata
            clicker:get_meta():set_string("question_chest:label_map", minetest.write_json(label_map))

            -- Show the shuffled student form
            minetest.show_formspec(name, "question_chest:mc_student", student_form.get(pos, {
                question = data.question,
                options = shuffled_options
            }))
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

    -- Store checkbox values as player metadata on click (for all opt_# fields)
    for field, value in pairs(fields) do
        if field:match("^opt_%d+$") then
            local label_map = minetest.parse_json(pmeta:get_string("question_chest:label_map") or "{}") or {}
            local label = label_map[field]
            if label and value == "true" then
                pmeta:set_string("question_chest:selected_" .. field, label)
            elseif label then
                pmeta:set_string("question_chest:selected_" .. field, "")
            end
        end
    end

    -- === TEACHER MODE ===
    if formname == "question_chest:mc_teacher" and fields.submit then
        local question = (fields.question_input or ""):trim()
        local options_str = (fields.options_input or ""):trim()
        local answers_str = (fields.correct_answers or ""):trim()

        if question == "" or options_str == "" or answers_str == "" then
            minetest.chat_send_player(name, "Please fill in question, options, and correct answers.")
            return true
        end

        local options = utils.parse_quoted_string(options_str)
        local answers = utils.parse_quoted_string(answers_str)
        
        -- Convert options and answers to lowercase for comparison
        local options_lower = {}
        for _, opt in ipairs(options) do
            table.insert(options_lower, opt:lower())
        end
        
        -- Validate that all answers exist in options
        local invalid_answers = {}
        for _, answer in ipairs(answers) do
            local answer_lower = answer:lower()
            local found = false
            for _, opt in ipairs(options_lower) do
                if opt == answer_lower then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(invalid_answers, answer)
            end
        end

        -- If there are invalid answers, show error message and return
        if #invalid_answers > 0 then
            local error_msg = "Error: The following answers are not in the choices:\n"
            error_msg = error_msg .. table.concat(invalid_answers, ", ")
            error_msg = error_msg .. "\n\nPlease ensure all correct answers are among the choices."
            minetest.chat_send_player(name, error_msg)
            return true
        end

        -- Save the question data
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
        local correct_answers = data.answers or {}

        -- Retrieve the label map from player metadata
        local label_map = minetest.parse_json(pmeta:get_string("question_chest:label_map") or "{}") or {}
        local selected_answers = {}

        -- Collect selected answers from player metadata
        for field, _ in pairs(label_map) do
            local saved_answer = pmeta:get_string("question_chest:selected_" .. field)
            if saved_answer and saved_answer ~= "" then
                table.insert(selected_answers, saved_answer:lower():trim())
            end
        end

        -- Normalize correct answers
        local normalized_correct_answers = {}
        for _, answer in ipairs(correct_answers) do
            table.insert(normalized_correct_answers, answer:lower():trim())
        end

        table.sort(selected_answers)
        table.sort(normalized_correct_answers)

        local function arrays_equal(a, b)
            if #a ~= #b then return false end
            for i = 1, #a do
                if a[i] ~= b[i] then return false end
            end
            return true
        end

        if arrays_equal(selected_answers, normalized_correct_answers) then
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
        for field, _ in pairs(label_map) do
            pmeta:set_string("question_chest:selected_" .. field, "")
        end
        pmeta:set_string("question_chest:label_map", "")

        return true
    end

    return false
end)