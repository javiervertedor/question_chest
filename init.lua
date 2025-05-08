-- Register the admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chest",
    give_to_singleplayer = true,
})

-- Load modular UI files
local modpath = minetest.get_modpath("question_chest")
local teacher_form = dofile(modpath .. "/teacher_form.lua")
local student_form = dofile(modpath .. "/student_form.lua")

-- Register the Question Chest node
minetest.register_node("question_chest:chest", {
    description = "Question Chest",
    tiles = {
        "question_chest_top.png",
        "default_chest_bottom.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_side.png",
        "default_chest_front.png"
    },
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    is_ground_content = false,
    sounds = default.node_sound_wood_defaults(),

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 4)
        meta:set_string("infotext", "Question Chest")
        meta:set_string("data", "{}")
    end,

    can_dig = function(pos, player)
        return minetest.check_player_privs(player, {question_chest_admin = true})
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        if not minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.chat_send_player(name, "You do not have permission to configure this chest.")
            return
        end

        -- Store position for form handlers
        clicker:set_attribute("question_chest:pos", minetest.pos_to_string(pos))

        local meta = minetest.get_meta(pos)
        local raw_data = meta:get_string("data")
        local current_data = minetest.parse_json(raw_data) or {}

        minetest.show_formspec(name, "question_chest:teacher_config", teacher_form.get(pos, current_data))
    end,
})

-- Handle teacher form submission
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "question_chest:teacher_config" then return false end

    local name = player:get_player_name()
    local pos_string = player:get_attribute("question_chest:pos")
    if not pos_string then return true end

    local pos = minetest.string_to_pos(pos_string)
    if not pos then return true end

    local meta = minetest.get_meta(pos)
    if not minetest.check_player_privs(name, {question_chest_admin = true}) then
        return true
    end

    if fields.save then
        local question = (fields.question_input or ""):trim()
        local answers_str = (fields.correct_answers or ""):trim()

        if question == "" or answers_str == "" then
            minetest.chat_send_player(name, "Please enter a question and at least one correct answer.")
            return true
        end

        local answers = {}
        for answer in answers_str:gmatch("[^,]+") do
            table.insert(answers, answer:lower():trim())
        end

        local data = {
            question = question,
            answers = answers
        }

        meta:set_string("data", minetest.write_json(data))
        minetest.chat_send_player(name, "Question and answers saved.")
        return true
    end

    return false
end)
