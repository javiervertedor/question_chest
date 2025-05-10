-- Register admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chest",
    give_to_singleplayer = true,
})

-- Load UI modules
local teacher_form = dofile(minetest.get_modpath("question_chest") .. "/teacher_form.lua")
local student_form = dofile(minetest.get_modpath("question_chest") .. "/student_form.lua")
local reward_form  = dofile(minetest.get_modpath("question_chest") .. "/reward_form.lua")

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
        meta:get_inventory():set_size("main", 8)
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
        local pos_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
        clicker:set_attribute("question_chest:pos", minetest.pos_to_string(pos))

        local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
        local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "") or {}
        local has_answered = answered[name]

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.show_formspec(name, "question_chest:teacher_config", teacher_form.get(pos, data))
        elseif has_answered then
            minetest.chat_send_player(name, "You already answered this question correctly.")
            local detached_name = "question_chest:" .. pos_key .. ":" .. name
            local detached = minetest.create_detached_inventory(detached_name, {
                allow_take = function(_, _, _, stack) return stack:get_count() end
            })
            detached:set_size("main", 8)
            if reward_collected[name] then
                detached:set_list("main", {})
            else
                local reward_serialized = minetest.deserialize(meta:get_string("reward_items") or "")
                local reward_items = {}
                for i, str in ipairs(reward_serialized or {}) do
                    reward_items[i] = ItemStack(str)
                end
                detached:set_list("main", reward_items)
                reward_collected[name] = true
                meta:set_string("reward_collected", minetest.serialize(reward_collected))
            end

            minetest.show_formspec(name, "question_chest:chest_open", reward_form.get(name, detached_name))
        else
            minetest.show_formspec(name, "question_chest:student_form", student_form.get(pos, data))
        end
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local pos_string = player:get_attribute("question_chest:pos")
    local pos = minetest.string_to_pos(pos_string or "")
    if not pos then return false end
    local meta = minetest.get_meta(pos)

    -- TEACHER FORM
    if formname == "question_chest:teacher_config" then
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

            -- Save rewards as strings
            local reward_serialized = {}
            for _, stack in ipairs(meta:get_inventory():get_list("main")) do
                table.insert(reward_serialized, stack:to_string())
            end

            meta:set_string("data", minetest.write_json({question = question, answers = answers}))
            meta:set_string("reward_items", minetest.serialize(reward_serialized))
            meta:set_string("answered_players", minetest.serialize({}))
            meta:set_string("reward_collected", minetest.serialize({}))

            minetest.chat_send_player(name, "Question and rewards saved.")
            return true
        end
        return false
    end

    -- STUDENT FORM
    if formname == "question_chest:student_form" then
        if fields.submit_answer then
            local data = minetest.parse_json(meta:get_string("data") or "{}") or {}
            local submitted = (fields.student_answer or ""):lower():trim()

            for _, answer in ipairs(data.answers or {}) do
                if submitted == answer then
                    local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
                    local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "") or {}

                    answered[name] = true
                    meta:set_string("answered_players", minetest.serialize(answered))

                    local pos_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
                    local detached_name = "question_chest:" .. pos_key .. ":" .. name
                    local detached = minetest.create_detached_inventory(detached_name, {
                        allow_take = function(_, _, _, stack) return stack:get_count() end
                    })
                    detached:set_size("main", 8)

                    if not reward_collected[name] then
                        local reward_serialized = minetest.deserialize(meta:get_string("reward_items") or "")
                        local reward_items = {}
                        for i, str in ipairs(reward_serialized or {}) do
                            reward_items[i] = ItemStack(str)
                        end
                        detached:set_list("main", reward_items)
                        reward_collected[name] = true
                        meta:set_string("reward_collected", minetest.serialize(reward_collected))
                    else
                        detached:set_list("main", {})
                    end

                    minetest.chat_send_player(name, "Correct! You may collect your reward.")
                    minetest.show_formspec(name, "question_chest:chest_open", reward_form.get(name, detached_name))
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