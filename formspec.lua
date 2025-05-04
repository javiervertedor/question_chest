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
        "size[10,7.5]",
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

    table.insert(fs, "label[0.3,6.1;Place reward items directly into chest inventory below.]")
    table.insert(fs, "button[2.5,6.6;2.5,1;save;Save]")
    table.insert(fs, "button_exit[5.2,6.6;2.5,1;cancel;Cancel]")
    return table.concat(fs, "")
end
