local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "")
    local answers = minetest.formspec_escape(table.concat(data.answers or {}, ", "))
    return
        "size[10,9.5]" ..
        "label[0.3,0.1;TEACHER MODE]" ..
        "label[0.3,0.9;Enter a question:]" ..
        "field[0.3,1.6;9.5,0.8;question_input;;" .. question .. "]" ..
        "label[0.3,2.5;Correct Answers (comma-separated):]" ..
        "field[0.3,3.2;9.5,0.8;correct_answers;;" .. answers .. "]" ..
        "button_exit[2.5,4.2;2.5,1;close;Close]" ..
        "button[5.0,4.2;2.5,1;save;Save]" ..
        "label[0.3,5.4;Place reward items below:]" ..
        "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.3,6.0;4,1;]" ..
        "list[current_player;main;0.3,7.3;8,1;]" ..
        "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
        "listring[current_player;main]"
end

return M
