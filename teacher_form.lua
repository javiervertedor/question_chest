local M = {}

function M.get(pos, data)
    local question = minetest.formspec_escape(data.question or "")
    local answers = minetest.formspec_escape(table.concat(data.answers or {}, ", "))
    local meta = minetest.get_meta(pos)

    -- Fetch answered player list (serialized table)
    local answered_raw = meta:get_string("answered_players")
    local answered = minetest.deserialize(answered_raw or "") or {}
    local answered_list = {}

    for player_name in pairs(answered) do
        table.insert(answered_list, player_name)
    end

    table.sort(answered_list)
    local player_list_label = "Answered by: " .. table.concat(answered_list, ", ")

    return
        "formspec_version[4]" ..
        "size[10.5,10.8]" ..
        "key_enter[submit]" ..
        "key_escape[close]" ..
        "label[0.3,0.3;TEACHER MODE]" ..
        "label[0.3,0.8;Enter a question:]" ..
        "textarea[0.3,1.1;9.5,1.5;question_input;;" .. question .. "]" .. -- Reduced height of textarea
        "label[0.3,2.8;Correct Answers (comma-separated):]" ..
        "field[0.3,3.1;9.5,0.8;correct_answers;;" .. answers .. "]" ..
        "button_exit[2.5,4.1;2.5,1;close;Close]" ..
        "button[5.0,4.1;2.5,1;submit;Save]" ..
        "label[0.3,5.4;Place reward items below:]" ..
        "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.3,5.8;8,1;]" ..
        "label[0.3,7.1;Your Inventory:]" ..
        "list[current_player;main;0.3,7.5;8,1;]" ..
        "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
        "listring[current_player;main]" ..
        "textarea[0.3,9.0;9.5,1.2;answered_list;;" .. minetest.formspec_escape(player_list_label) .. "]"
end

return M