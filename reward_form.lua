local M = {}

function M.get(name, detached_name)
    return
        "formspec_version[4]" ..
        "size[10.5,9]" ..
        "label[0.3,0.3;This is your personal reward chest.]" ..
        "list[detached:" .. detached_name .. ";main;0.3,1;8,1;]" ..
        "list[current_player;main;0.3,3;8,4;]" ..
        "listring[detached:" .. detached_name .. ";main]" ..
        "listring[current_player;main]"
end

return M