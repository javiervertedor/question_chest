-- init.lua
-- Basic Question Chest with texture and admin protection

-- 1. Register a new privilege for teacher/admin users
minetest.register_privilege("question_chest_admin", {
    description = "Allows editing and removing Question Chests",
    give_to_singleplayer = true  -- Singleplayer gets it by default
})

-- 2. Register the Question Chest node
minetest.register_node("question_chest:chest", {
    description = "Question Chest",

    tiles = {
        "question_chest_top.png",        -- top
        "default_chest_bottom.png",      -- bottom
        "default_chest_side.png",        -- right
        "default_chest_side.png",        -- left
        "default_chest_side.png",        -- back
        "default_chest_front.png",       -- front
    },

    groups = {choppy = 2, oddly_breakable_by_hand = 2},

    sounds = default.node_sound_wood_defaults(),

    -- Initialize metadata and inventory
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Question Chest (Unconfigured)")
        local inv = meta:get_inventory()
        inv:set_size("main", 8 * 4)
    end,

    -- Open a basic formspec on right-click
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        minetest.show_formspec(clicker:get_player_name(), "question_chest:basic",
            "size[8,9]" ..
            "label[0,0;Basic Chest: Inventory]" ..
            "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0,0.5;8,4;]" ..
            "list[current_player;main;0,5;8,4;]" ..
            "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
            "listring[current_player;main]"
        )
    end,

    -- 3. Protection logic: Only allow admins to dig
    can_dig = function(pos, player)
        if not player then return false end
        if minetest.check_player_privs(player, {question_chest_admin = true}) then
            return true
        end
        -- Non-admins can only dig if chest is empty (you can change this)
        return false
    end,
})
