-- chest_open.lua
local reward_form = dofile(minetest.get_modpath("question_chest") .. "/reward_form.lua")

local M = {}

function M.show(pos, player_name, meta)
    local pos_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
    local detached_name = "question_chest:" .. pos_key .. ":" .. player_name

    local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
    local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "{}") or {}

    answered[player_name] = true
    meta:set_string("answered_players", minetest.serialize(answered))

    -- Get or initialize reward collection tracking
    reward_collected[player_name] = reward_collected[player_name] or {}

    -- Get the original reward items
    local reward_items = minetest.deserialize(meta:get_string("reward_items") or "{}") or {}
    
    -- Create player's detached inventory if it doesn't exist
    local inv_name = "question_chest_reward_" .. player_name .. "_" .. minetest.pos_to_string(pos)
    local inv = minetest.get_inventory({type="detached", name=inv_name})
    
    if not inv then
        inv = minetest.create_detached_inventory(inv_name, {
            allow_move = function() return 0 end,
            allow_put = function() return 0 end,
            allow_take = function(inv, listname, index, stack, player)
                if player:get_player_name() ~= player_name then return 0 end
                
                -- Mark item as collected
                reward_collected[player_name][index] = true
                meta:set_string("reward_collected", minetest.serialize(reward_collected))
                
                return stack:get_count()
            end,
        })
        inv:set_size("main", 8)
        
        -- Only populate with uncollected items
        for i, item_str in ipairs(reward_items) do
            if not reward_collected[player_name][i] then
                inv:set_stack("main", i, ItemStack(item_str))
            end
        end
    end

    -- Show formspec
    local formspec = reward_form.get(pos, player_name)
    minetest.show_formspec(player_name, "question_chest:reward_" .. minetest.pos_to_string(pos), formspec)
end

return M
