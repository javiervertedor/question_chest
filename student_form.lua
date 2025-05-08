local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "No question set.")
    return
        "formspec_version[4]" ..
        "size[9,10]" ..
        "label[0.3,0.3;" .. question .. "]" ..
        "field[0.3,1.2;8,1;student_answer;;]" ..
        "button[3.2,2.2;3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"
end

return M
