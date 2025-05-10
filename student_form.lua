local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "No question set.")
    return
        "formspec_version[4]" ..
        "size[9.5,5]" ..
        "label[0.3,0.4;" .. question .. "]" ..
        "field[0.3,1.2;8.9,1;student_answer;;]" ..
        "button[3.5,2.6;3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"
end

return M