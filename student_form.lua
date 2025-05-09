local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "No question set.")
    return
        "formspec_version[4]" ..
        "size[10,9]" ..
        "label[0.3,0.3;" .. question .. "]" ..
        "field[0.3,1.2;8,1;student_answer;;]" ..
        "button[3.2,3;3,1;submit_answer;Submit]" ..
        "key_escape[cancel]"
end

return M
