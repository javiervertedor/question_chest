local M = {}

function M.get(pos, playername)
    local inv_name = "question_chest_reward_" .. playername .. "_" .. minetest.pos_to_string(pos)
    
    -- Get collection status
    local meta = minetest.get_meta(pos)
    local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "{}") or {}
    local player_collected = reward_collected[playername] or {}
    
    local formspec = "formspec_version[4]" ..
        "size[10.5,9]" ..
        "label[0.3,0.3;Collect your rewards:]" ..
        "list[detached:" .. inv_name .. ";main;0.3,0.8;8,1;]" ..
        "list[current_player;main;0.3,2.5;8,4;]" ..
        "listring[detached:" .. inv_name .. ";main]" ..
        "listring[current_player;main]"

    -- Add collection status
    local total_items = 0
    local collected_items = 0
    for i in pairs(minetest.deserialize(meta:get_string("reward_items") or "{}") or {}) do
        total_items = total_items + 1
        if player_collected[i] then
            collected_items = collected_items + 1
        end
    end
    
    formspec = formspec .. 
        "label[0.3,7.5;Collection progress: " .. collected_items .. "/" .. total_items .. " items]"

    return formspec
end

return M