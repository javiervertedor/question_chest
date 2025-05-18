-- chest_base.lua
local M = {}

function M.register_chest(name, def)
    minetest.register_node(name, {
        description = def.description or "Question Chest",
        tiles = def.tiles or {
            "question_chest_top.png",
            "default_chest_bottom.png",
            "default_chest_side.png",
            "default_chest_side.png",
            "default_chest_side.png",
            "default_chest_front.png"
        },
        paramtype2 = "facedir",
        groups = def.groups or {choppy = 2, oddly_breakable_by_hand = 2},
        is_ground_content = false,
        sounds = default.node_sound_wood_defaults(),

        on_construct = def.on_construct,
        can_dig = def.can_dig,
        on_rightclick = def.on_rightclick,

        -- Prevent inserting items into reward inventories
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
            if listname:sub(1, 7) == "reward_" then
                return 0  -- Disallow insertion
            end
            return stack:get_count()
        end,
    })
end

return M