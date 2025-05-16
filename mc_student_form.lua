local M = {}

-- Wrap long questions into multiple label[] lines
function M.wrap_label(text, max_chars_per_line, start_x, start_y)
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        while #line > max_chars_per_line do
            table.insert(lines, line:sub(1, max_chars_per_line))
            line = line:sub(max_chars_per_line + 1)
        end
        table.insert(lines, line)
    end

    local label_formspec = ""
    for i, line in ipairs(lines) do
        label_formspec = label_formspec ..
            "label[" .. start_x .. "," .. (start_y + (i - 1) * 0.5) .. ";" .. minetest.formspec_escape(line) .. "]"
    end

    return label_formspec, #lines * 0.5
end

function M.get(pos, data)
    local question = data.question or "No question."
    local original_options = data.options or {}
    local shuffled_options = table.copy(original_options)

    -- Shuffle options (for students)
    for i = #shuffled_options, 2, -1 do
        local j = math.random(i)
        shuffled_options[i], shuffled_options[j] = shuffled_options[j], shuffled_options[i]
    end

    -- Store the shuffled version in metadata (to identify checkbox mapping later)
    local player = minetest.get_player_by_name(minetest.localplayer and minetest.localplayer:get_name())
    if player then
        local meta = player:get_meta()
        meta:set_string("question_chest:shuffled", minetest.write_json(shuffled_options))
    end

    local formspec = "formspec_version[4]" .. "size[10.5,12]"
    local question_label, label_height = M.wrap_label(question, 60, 0.3, 0.2)
    formspec = formspec .. question_label

    -- Checkboxes
    local y = 0.2 + label_height + 0.3
    for i, opt in ipairs(shuffled_options) do
        local opt_label = minetest.formspec_escape(opt)
        formspec = formspec ..
            "checkbox[0.5," .. y .. ";opt_" .. i .. ";" .. opt_label .. ";false]"
        y = y + 0.6
    end

    -- Submit button only
    formspec = formspec ..
        "button[3.8," .. (y + 0.5) .. ";3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"

    return formspec
end

return M
