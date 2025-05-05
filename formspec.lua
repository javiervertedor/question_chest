question_chest = question_chest or {}
question_chest.formspec = {}

function question_chest.formspec.teacher_config(pos, data)
    local meta = minetest.get_meta(pos)
    local stored = minetest.deserialize(meta:get_string("question_data")) or {}
    local d = data or {}

    local question = minetest.formspec_escape(d.question or stored.question or "")
    local qtype = d.qtype or stored.type or "open"
    local answers = minetest.formspec_escape(d.answers or (stored.answers and table.concat(stored.answers, ", ")) or "")
    local correct = minetest.formspec_escape(d.correct or (stored.correct and table.concat(stored.correct, ", ")) or "")
    local qtype_index = qtype == "mcq" and 2 or 1

    local fs = {
        "formspec_version[4]",
        "size[10,9.5]",
        "label[0.3,0.2;Configure Question Chest]",
        "textarea[0.3,0.5;9.4,2.2;question;Question:;" .. question .. "]",
        "dropdown[0.3,2.9;4.5;qtype;open-ended,mcq;" .. qtype_index .. "]"
    }

    if qtype == "mcq" then
        table.insert(fs, "field[0.3,3.9;9.4,1;answers;Answer options (comma-separated):;" .. answers .. "]")
        table.insert(fs, "field[0.3,4.9;9.4,1;correct;Correct option(s): (comma-separated):;" .. correct .. "]")
    else
        table.insert(fs, "field[0.3,3.9;9.4,1;correct;Correct answer(s): (comma-separated):;" .. correct .. "]")
    end

    table.insert(fs, "label[0.3,5.6;Reward inventory:]")
    table.insert(fs, "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.3,5.8;8,1;]")
    table.insert(fs, "label[0.3,6.8;Your inventory:]")
    table.insert(fs, "list[current_player;main;0.3,7.2;8,1;]")
    table.insert(fs, "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]")
    table.insert(fs, "listring[current_player;main]")
    table.insert(fs, "button[2.5,8.4;2.5,1;save;Save]")
    table.insert(fs, "button_exit[5.2,8.4;2.5,1;cancel;Close]")

    return table.concat(fs, "")
end

function question_chest.formspec.student_question(pos)
    local meta = minetest.get_meta(pos)
    local data = minetest.deserialize(meta:get_string("question_data") or "") or {}

    local fs = {
        "formspec_version[4]",
        "size[8,6]",
        "label[0.3,0.2;" .. minetest.formspec_escape(data.question or "No question set.") .. "]"
    }

    if data.type == "mcq" and data.answers then
        for i, option in ipairs(data.answers) do
            table.insert(fs, "checkbox[0.5," .. (0.8 + i * 0.6) .. ";opt_" .. i .. ";" .. option .. ";false]")
        end
    else
        table.insert(fs, "field[0.3,1.5;7.5,1;answer;Your answer:;" .. "]")
    end

    table.insert(fs, "button[2.5,5.2;3,1;submit_answer;Submit]")
    return table.concat(fs, "")
end
