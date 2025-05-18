local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "")
    local options = minetest.formspec_escape(table.concat(data.options or {}, ", "))
    local answers = minetest.formspec_escape(table.concat(data.answers or {}, ", "))
    local meta = minetest.get_meta(pos)

    -- Load list of players who answered
    local answered_raw = meta:get_string("answered_players")
    local answered = minetest.deserialize(answered_raw or "") or {}
    local answered_list = {}

    for name in pairs(answered) do
        table.insert(answered_list, name)
    end
    table.sort(answered_list)
    local player_list_label = "Answered by: " .. table.concat(answered_list, ", ")

    return
        "formspec_version[4]" ..
        "size[10.5,11.5]" .. 
        "key_enter[submit]" ..
        "key_escape[close]" ..
        "label[0.3,0.3;MC TEACHER MODE]" ..
        "label[0.3,0.8;Enter your multiple choice question:]" ..
        "textarea[0.3,1.1;9.5,1.5;question_input;;" .. question .. "]" ..
        "label[0.3,2.8;Options (comma-separated):]" ..
        "field[0.3,3.1;9.5,0.8;options_input;;" .. options .. "]" ..
        "label[0.3,4.1;Correct Answers (comma-separated):]" ..
        "field[0.3,4.4;9.5,0.8;correct_answers;;" .. answers .. "]" ..
        "button[5.2,5.3;2.5,1;submit;Save]" ..
        "button_exit[2.2,5.3;2.5,1;close;Close]" ..
        "label[0.3,6.7;Reward items below:]" .. 
        "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.3,6.9;8,1;]" .. -- Moved down from 6.6 to 6.7
        "label[0.3,8.2;Your Inventory:]" .. 
        "list[current_player;main;0.3,8.6;8,1;]" .. 
        "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
        "listring[current_player;main]" ..
        "textarea[0.3,10.0;9.5,1.2;answered_list;;" .. minetest.formspec_escape(player_list_label) .. "]" -- Moved down from 9.8 to 10.0
end

return M
