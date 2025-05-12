-- chest_open.lua
local reward_form = dofile(minetest.get_modpath("question_chest") .. "/reward_form.lua")

local M = {}

function M.show(pos, player_name, meta)
    local pos_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
    local detached_name = "question_chest:" .. pos_key .. ":" .. player_name

    local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
    local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "") or {}

    answered[player_name] = true
    meta:set_string("answered_players", minetest.serialize(answered))

    local detached = minetest.create_detached_inventory(detached_name, {
        allow_take = function(_, _, _, stack) return stack:get_count() end
    })
    detached:set_size("main", 8)

    if not reward_collected[player_name] then
        local reward_serialized = minetest.deserialize(meta:get_string("reward_items") or "")
        local reward_items = {}
        for i, str in ipairs(reward_serialized or {}) do
            reward_items[i] = ItemStack(str)
        end
        detached:set_list("main", reward_items)
        reward_collected[player_name] = true
        meta:set_string("reward_collected", minetest.serialize(reward_collected))
    else
        detached:set_list("main", {})
    end

    minetest.show_formspec(player_name, "question_chest:chest_open", reward_form.get(player_name, detached_name))
end

return M
