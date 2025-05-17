local M = {}

function M.get(pos, data)
    local question = data.question or "No question."
    local options = data.options or {}

    local formspec = "formspec_version[4]size[10.5,12]"
    formspec = formspec .. "label[0.3,0.2;" .. minetest.formspec_escape(question) .. "]"

    local y = 0.8
    for i, opt in ipairs(options) do
        local opt_label = minetest.formspec_escape(opt)
        formspec = formspec ..
            "checkbox[0.5," .. y .. ";opt_" .. i .. ";" .. opt_label .. ";false]"
        y = y + 0.6
    end

    formspec = formspec ..
        "button[3.8," .. (y + 0.5) .. ";3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"

    return formspec
end

return M
