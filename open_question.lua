local chest_base    = dofile(minetest.get_modpath("question_chest") .. "/chest_base.lua")
local student_form  = dofile(minetest.get_modpath("question_chest") .. "/student_form.lua")
local teacher_form  = dofile(minetest.get_modpath("question_chest") .. "/teacher_form.lua")
local chest_open    = dofile(minetest.get_modpath("question_chest") .. "/chest_open.lua")
local utils        = dofile(minetest.get_modpath("question_chest") .. "/utils.lua")

local function normalize_answer(answer)
    -- Removes leading/trailing whitespace and converts to lowercase
    -- Preserve internal spaces and commas
    return answer:lower():match("^%s*(.-)%s*$")
end

local function parse_answer(str)
    if str:match('^"".*""$') then
        -- Double-quoted answer with potential commas - preserve as a single answer
        return str:sub(3, -3) -- Remove outer quotes
    elseif str:match('^".*"$') then
        -- Single-quoted answer - preserve as is
        return str:sub(2, -2) -- Remove outer quotes
    else
        -- Unquoted answer - preserve as is
        return str
    end
end

local function split_answers(answers_str)
    local answers = {}
    local current_pos = 1
    local len = string.len(answers_str)
    
    while current_pos <= len do
        -- Skip whitespace
        current_pos = string.find(answers_str, "[^%s]", current_pos) or (len + 1)
        if current_pos > len then break end

        if string.sub(answers_str, current_pos, current_pos + 1) == '""' then
            -- Find the end of the double-quoted block
            local _, end_pos = string.find(answers_str, '""[^"]*""', current_pos)
            if end_pos then
                local item = string.sub(answers_str, current_pos, end_pos)
                table.insert(answers, item)
                current_pos = end_pos + 1
            else
                break
            end
        elseif string.sub(answers_str, current_pos, current_pos) == '"' then
            -- Find the end of the single-quoted token
            local _, end_pos = string.find(answers_str, '"[^"]*"', current_pos)
            if end_pos then
                local item = string.sub(answers_str, current_pos, end_pos)
                table.insert(answers, item)
                current_pos = end_pos + 1
            else
                break
            end
        else
            -- Unquoted item until next comma
            local end_pos = string.find(answers_str, ",", current_pos) or (len + 1)
            local item = string.sub(answers_str, current_pos, end_pos - 1)
            if item and item:match("%S") then
                table.insert(answers, item)
            end
            current_pos = end_pos + 1
        end
    end
    
    return answers
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
            minetest.show_formspec(name, "question_chest:open_teacher", teacher_form.get(pos, data))
        elseif answered[name] then
            minetest.chat_send_player(name, "You already answered this question correctly.")
            chest_open.show(pos, name, meta)
        else
            minetest.show_formspec(name, "question_chest:open_student", student_form.get(pos, data))
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos_string = player:get_meta():get_string("question_chest:pos")
    local pos = minetest.string_to_pos(pos_string or "")
    if not pos then return false end
    local meta = minetest.get_meta(pos)

    -- Open-ended TEACHER FORM
    if formname == "question_chest:open_teacher" and fields.submit then
        local question = (fields.question_input or ""):trim()
        local answers_str = (fields.correct_answers or ""):trim()

        if question == "" or answers_str == "" then
            minetest.chat_send_player(name, "Please enter a question and at least one correct answer.")
            return true
        end

        -- Split answers preserving quoted phrases
        local answers = split_answers(answers_str)
        
        if #answers == 0 then 
            minetest.chat_send_player(name, "Please provide at least one valid answer.")
            return true
        end

        -- Store both the original format and normalized version for each answer
        local answer_data = {}
        for _, answer in ipairs(answers) do
            local parsed = parse_answer(answer)
            table.insert(answer_data, {
                original = answer,
                normalized = normalize_answer(parsed)
            })
        end

        local reward_serialized = {}
        for _, stack in ipairs(meta:get_inventory():get_list("main")) do
            table.insert(reward_serialized, stack:to_string())
        end

        meta:set_string("data", minetest.write_json({
            question = question, 
            answers = answer_data
        }))
        meta:set_string("reward_items", minetest.serialize(reward_serialized))
        meta:set_string("answered_players", minetest.serialize({}))
        meta:set_string("reward_collected", minetest.serialize({}))

        minetest.chat_send_player(name, "Question and rewards saved.")
        return true
    end

    -- Open-ended STUDENT FORM
    if formname == "question_chest:open_student" and fields.submit_answer then
        local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
        local submitted = fields.student_answer or ""

        -- Try different formats of the student's answer
        local submitted_formats = {
            submitted,                              -- As typed
            '"' .. submitted .. '"',               -- Single quoted
            '""' .. submitted .. '""',             -- Double quoted
            normalize_answer(submitted)             -- Normalized
        }

        -- Check if any format of the submission matches any normalized answer
        local is_correct = false
        for _, format in ipairs(submitted_formats) do
            local norm_format = normalize_answer(parse_answer(format))
            for _, answer in ipairs(data.answers or {}) do
                if norm_format == answer.normalized then
                    is_correct = true
                    break
                end
            end
            if is_correct then break end
        end

        if is_correct then
            minetest.chat_send_player(name, "Correct! You may collect your reward.")
            -- Update answered players list
            local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
            answered[name] = true
            meta:set_string("answered_players", minetest.serialize(answered))
            
            chest_open.show(pos, name, meta)
            return true
        end

        minetest.chat_send_player(name, "Incorrect. Try again.")
        minetest.close_formspec(name, formname)
        return true
    end

    return false
end)
