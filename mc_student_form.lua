local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "No question.")

    -- Make a copy of options and shuffle them
    local original_options = data.options or {}
    local options = table.copy(original_options)
    for i = #options, 2, -1 do
        local j = math.random(i)
        options[i], options[j] = options[j], options[i]
    end

    local formspec =
        "formspec_version[4]" ..
        "size[10.5,10]" ..
        "textarea[0.3,0.3;10,2;;;" .. question .. "]"

    local y = 1.8
    for i, opt in ipairs(options) do
        local opt_label = minetest.formspec_escape(opt)
        formspec = formspec ..
            "checkbox[0.5," .. y .. ";option_" .. i .. ";" .. opt_label .. ";false]" ..
            "field_close_on_enter[option_" .. i .. ";false]"
        y = y + 0.6
    end

    -- Submit button only submits manually
    formspec = formspec ..
        "button[3.8," .. y .. ";3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"

    return formspec
end

return M
