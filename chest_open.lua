-- chest_open.lua
local reward_form = dofile(minetest.get_modpath("question_chest") .. "/reward_form.lua")

local M = {}

-- Track detached inventories to ensure cleanup
local active_detached = {}

-- Clean up detached inventories when they're no longer needed
local function cleanup_detached(player_name)
    if active_detached[player_name] then
        for detached_name, _ in pairs(active_detached[player_name]) do
            minetest.remove_detached_inventory(detached_name)
        end
        active_detached[player_name] = nil
    end
end

-- Handle player leave/quit to clean up their detached inventories
minetest.register_on_leaveplayer(cleanup_detached)

function M.show(pos, player_name, meta)
    local pos_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
    local detached_name = "question_chest:" .. pos_key .. ":" .. player_name

    local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
    local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "") or {}
    
    -- Store remaining items per player
    local remaining_items = minetest.deserialize(meta:get_string("remaining_items") or "") or {}
    remaining_items[player_name] = remaining_items[player_name] or {}

    answered[player_name] = true
    meta:set_string("answered_players", minetest.serialize(answered))

    -- Initialize active_detached for this player if needed
    active_detached[player_name] = active_detached[player_name] or {}

    -- Remove old detached inventory if it exists
    if active_detached[player_name][detached_name] then
        minetest.remove_detached_inventory(detached_name)
    end

    -- Create new detached inventory
    local detached = minetest.create_detached_inventory(detached_name, {
        allow_take = function(inv, listname, index, stack, player)
            -- Track which items were taken
            local player_name = player:get_player_name()
            local remaining = inv:get_list("main")
            local updated_remaining = {}

            -- After taking this item, update what's left
            for i, item in ipairs(remaining) do
                if i == index then
                    -- This is the slot being taken from
                    if not item:is_empty() and item:get_count() > stack:get_count() then
                        -- Only part of the stack is being taken
                        local remaining_item = ItemStack(item)
                        remaining_item:take_item(stack:get_count())
                        updated_remaining[i] = remaining_item:to_string()
                    end
                else
                    -- Other slots remain unchanged
                    if not item:is_empty() then
                        updated_remaining[i] = item:to_string()
                    end
                end
            end

            -- Store updated remaining items
            remaining_items[player_name] = updated_remaining
            meta:set_string("remaining_items", minetest.serialize(remaining_items))
            
            -- Update collection status
            local has_items = false
            for _, item in pairs(updated_remaining) do
                if item then
                    has_items = true
                    break
                end
            end
            
            reward_collected[player_name] = not has_items
            meta:set_string("reward_collected", minetest.serialize(reward_collected))
            
            return stack:get_count()
        end,
        allow_put = function() return 0 end, -- Prevent inserting items
        on_take = function(inv, listname, index, stack, player)
            -- Check if inventory is empty after take
            local remaining = inv:get_list("main")
            local has_items = false
            for _, item in ipairs(remaining) do
                if not item:is_empty() then
                    has_items = true
                    break
                end
            end
            if not has_items then
                minetest.after(0.1, function()
                    local player_name = player:get_player_name()
                    cleanup_detached(player_name)
                    minetest.close_formspec(player_name, "question_chest:chest_open")
                end)
            end
        end
    })
    
    -- Track this detached inventory
    active_detached[player_name][detached_name] = true
    
    detached:set_size("main", 8)

    -- Load remaining or initial items
    if not reward_collected[player_name] then
        if #(remaining_items[player_name] or {}) > 0 then
            -- Load previously remaining items
            local items = {}
            for i, item_str in pairs(remaining_items[player_name]) do
                items[i] = ItemStack(item_str)
            end
            detached:set_list("main", items)
        else
            -- First time opening, load initial rewards
            local reward_serialized = minetest.deserialize(meta:get_string("reward_items") or "")
            if reward_serialized then
                local reward_items = {}
                for i, str in ipairs(reward_serialized) do
                    reward_items[i] = ItemStack(str)
                    remaining_items[player_name][i] = str
                end
                detached:set_list("main", reward_items)
                -- Store initial remaining items
                meta:set_string("remaining_items", minetest.serialize(remaining_items))
            end
        end
    else
        detached:set_list("main", {})
    end

    minetest.show_formspec(player_name, "question_chest:chest_open", reward_form.get(player_name, detached_name))
end

-- Export the cleanup function so it can be called from other files if needed
M.cleanup_detached = cleanup_detached

return M
