-- Register admin privilege
minetest.register_privilege("question_chest_admin", {
    description = "Can configure Question Chest",
    give_to_singleplayer = true,
})

-- Load UI modules
local teacher_form = dofile(minetest.get_modpath("question_chest") .. "/teacher_form.lua")
local student_form = dofile(minetest.get_modpath("question_chest") .. "/student_form.lua")

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
        if not minetest.check_player_privs(player, {question_chest_admin = true}) then
            return false
        end
        return minetest.get_meta(pos):get_inventory():is_empty("main")
    end,

    on_rightclick = function(pos, node, clicker)
        local name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        clicker:set_attribute("question_chest:pos", minetest.pos_to_string(pos))

        local raw_data = meta:get_string("data")
        local data = minetest.parse_json(raw_data)
        if type(data) ~= "table" then data = {} end

        local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
        local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "") or {}
        local has_answered = answered[name]

        if minetest.check_player_privs(name, {question_chest_admin = true}) then
            minetest.show_formspec(name, "question_chest:teacher_config", teacher_form.get(pos, data))
        elseif has_answered then
            minetest.chat_send_player(name, "You already answered this question correctly.")

            -- Recreate detached inventory (empty or personal copy)
            local chest_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
            local detached_name = "question_chest:" .. chest_key .. ":" .. name
            local detached = minetest.create_detached_inventory(detached_name, {
                allow_take = function(inv, listname, index, stack, player2)
                    return stack:get_count()
                end
            })
            detached:set_size("main", 4)

            if not reward_collected[name] then
                -- refill (this shouldn't happen, but fallback safe)
                local reward_serialized = minetest.deserialize(meta:get_string("reward_items") or "")
                local reward_items = {}
                for i, str in ipairs(reward_serialized or {}) do
                    reward_items[i] = ItemStack(str)
                end
                detached:set_list("main", reward_items)
                reward_collected[name] = true
                meta:set_string("reward_collected", minetest.serialize(reward_collected))
            else
                detached:set_list("main", {}) -- already claimed
            end

            minetest.show_formspec(name, "question_chest:chest_open",
                "formspec_version[4]" ..
                "size[9,8.5]" ..
                "label[0.3,0.3;This is your personal reward chest.]" ..
                "list[detached:" .. detached_name .. ";main;1,1;4,1;]" ..
                "list[current_player;main;0.5,3.0;8,4;]" ..
                "listring[detached:" .. detached_name .. ";main]" ..
                "listring[current_player;main]"
            )
        else
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

    -- TEACHER FORM
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

            -- Serialize inventory
            local inv = meta:get_inventory()
            local reward_raw = inv:get_list("main")
            local reward_serialized = {}
            for i, stack in ipairs(reward_raw) do
                reward_serialized[i] = stack:to_string()
            end
            meta:set_string("reward_items", minetest.serialize(reward_serialized))

            meta:set_string("data", minetest.write_json({
                question = question,
                answers = answers
            }))
            meta:set_string("answered_players", minetest.serialize({}))
            meta:set_string("reward_collected", minetest.serialize({}))

            minetest.chat_send_player(name, "Question, answers and rewards saved.")
            return true
        end
        return false
    end

    -- STUDENT FORM
    if formname == "question_chest:student_form" then
        if fields.quit or fields.cancel then return true end

        if fields.submit_answer then
            local raw_data = meta:get_string("data")
            local data = minetest.parse_json(raw_data)
            if type(data) ~= "table" then return true end

            local submitted = (fields.student_answer or ""):lower():trim()
            for _, answer in ipairs(data.answers or {}) do
                if submitted == answer then
                    -- Mark as answered
                    local answered = minetest.deserialize(meta:get_string("answered_players") or "") or {}
                    local reward_collected = minetest.deserialize(meta:get_string("reward_collected") or "") or {}
                    answered[name] = true
                    meta:set_string("answered_players", minetest.serialize(answered))

                    -- Detached inventory per player
                    local chest_key = minetest.pos_to_string(pos):gsub("[%s%,%(%)]", "_")
                    local detached_name = "question_chest:" .. chest_key .. ":" .. name
                    local detached = minetest.create_detached_inventory(detached_name, {
                        allow_take = function(inv, listname, index, stack, player2)
                            return stack:get_count()
                        end
                    })
                    detached:set_size("main", 4)

                    if not reward_collected[name] then
                        -- refill
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

                    -- Show reward
                    minetest.chat_send_player(name, "Correct! You may collect your reward.")
                    minetest.show_formspec(name, "question_chest:chest_open",
                        "formspec_version[4]" ..
                        "size[9,8.5]" ..
                        "label[0.3,0.3;This is your personal reward chest.]" ..
                        "list[detached:" .. detached_name .. ";main;1,1;4,1;]" ..
                        "list[current_player;main;0.5,3.0;8,4;]" ..
                        "listring[detached:" .. detached_name .. ";main]" ..
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