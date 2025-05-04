minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "question_chest:teacher_config" or not fields.save then return end

    local pos = player:get_pos()
    -- Use pointed node's position if available
    local pointed = player:get_pointed_thing()
    if pointed and pointed.under then
        pos = pointed.under
    end

    local meta = minetest.get_meta(pos)

    local question = fields.question or ""
    local answers = {}
    for answer in string.gmatch(fields.answers or "", "([^,]+)") do
        table.insert(answers, answer:lower():gsub("^%s*(.-)%s*$", "%1")) -- trim spaces
    end

    local correct = {}
    for ans in string.gmatch(fields.correct or "", "([^,]+)") do
        local val = ans:lower():gsub("^%s*(.-)%s*$", "%1")
        if tonumber(val) then
            table.insert(correct, tonumber(val))
        else
            table.insert(correct, val)
        end
    end

    local q_type = fields.type == "mcq" and "mcq" or "open"

    local store = {
        question = question,
        type = q_type,
        answers = answers,
        correct = correct
    }

    meta:set_string("question_data", minetest.serialize(store))
    meta:set_string("infotext", "Question Chest (configured)")
    minetest.chat_send_player(player:get_player_name(), "✅ Question saved!")
end)