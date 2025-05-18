local M = {}

function M.get(pos, data)
    local question = data.question or "No question."
    local original_options = data.options or {}

    -- Create a shuffled copy
    local options = {}
    for _, v in ipairs(original_options) do table.insert(options, v) end
    math.randomseed(os.time())
    for i = #options, 2, -1 do
        local j = math.random(i)
        options[i], options[j] = options[j], options[i]
    end

    -- Save label map to player metadata
    local player_list = minetest.get_connected_players()
    for _, player in ipairs(player_list) do
        local meta = player:get_meta()
        local label_map = {}
        for i, opt in ipairs(options) do
            label_map["opt_" .. i] = opt
        end
        meta:set_string("question_chest:label_map", minetest.write_json(label_map))
    end

    local formspec = "formspec_version[4]size[10.5,6]"
    formspec = formspec .. "textarea[0.3,0.3;10,2;;;" .. minetest.formspec_escape(question) .. "]"

    local y = 1.5
    for i, opt in ipairs(options) do
        local opt_label = minetest.formspec_escape(opt)
        formspec = formspec .. "checkbox[0.5," .. y .. ";opt_" .. i .. ";" .. opt_label .. ";false]"
        y = y + 0.6
    end

    formspec = formspec ..
        "button[3.8," .. (y + 0.5) .. ";3,1;submit_answer;Submit]" ..
        "key_enter[submit_answer]" ..
        "key_escape[cancel]"

    return formspec
end

return M