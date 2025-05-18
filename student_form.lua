local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "No question set.")

    return
        "formspec_version[4]" ..
        "size[11,6]" ..
        "textarea[0.3,0.2;10,2;;;"
        .. question .. "]" ..
        "field[0.3,2;10,1;student_answer;;]" ..
        "button[4,3.6;3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"
end

return M
