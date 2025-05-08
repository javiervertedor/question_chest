-- Register admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chest",
    give_to_singleplayer = true,
})

-- Load form modules
local teacher_form = dofile(minetest.get_modpath("question_chest") .. "/teacher_form.lua")
local student_form = dofile(minetest.get_modpath("question_chest") .. "/student_form.lua")

-- Register the Question Chest
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
        if not minetest.check_player_privs(player, {question_chest_admin = true}) then
            return false
        end
        return minetest.get_meta(pos):get_inventory():is_empty("main")
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        clicker:set_attribute("question_chest:pos", minetest.pos_to_string(pos))

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            local raw_data = meta:get_string("data")
            local data = minetest.parse_json(raw_data) or {}
            minetest.show_formspec(name, "question_chest:teacher_config", teacher_form.get(pos, data))
        else
            local raw_data = meta:get_string("data")
            local data = minetest.parse_json(raw_data)
            if type(data) ~= "table" then
                data = { question = "Error: No question." }
            end
            minetest.show_formspec(name, "question_chest:student_form", student_form.get(pos, data))
        end
    end,
})

-- Handle form submissions
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos_string = player:get_attribute("question_chest:pos")
    if not pos_string then return false end
    local pos = minetest.string_to_pos(pos_string)
    if not pos then return false end
    local meta = minetest.get_meta(pos)

    -- TEACHER form
    if formname == "question_chest:teacher_config" then
        if not minetest.check_player_privs(name, {question_chest_admin = true}) then return true end

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

            meta:set_string("data", minetest.write_json({
                question = question,
                answers = answers
            }))
            minetest.chat_send_player(name, "Question and answers saved.")
            return true
        end
        return false
    end

    -- STUDENT form
    if formname == "question_chest:student_form" then
        if fields.quit or fields.cancel then
            return true -- ESC pressed
        end

        if fields.submit_answer then
            local raw_data = meta:get_string("data")
            local data = minetest.parse_json(raw_data)
            if type(data) ~= "table" then return true end

            local submitted = (fields.student_answer or ""):lower():trim()
            for _, answer in ipairs(data.answers or {}) do
                if submitted == answer then
                    minetest.chat_send_player(name, "Correct! You may collect your reward.")

                    minetest.show_formspec(name, "question_chest:chest_open",
                        "formspec_version[4]" ..
                        "size[10,9]" ..
                        "label[0.3,0.3;You may now access the reward chest.]" ..
                        "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;1,1;4,1;]" ..
                        "list[current_player;main;0.5,3.0;8,4;]" ..
                        "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
                        "listring[current_player;main]"
                    )
                    return true
                end
            end

            minetest.chat_send_player(name, "Incorrect. Try again.")
            minetest.close_formspec(name, formname)
            return true
        end
    end

    return false
end)