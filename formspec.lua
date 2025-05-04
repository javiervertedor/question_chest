question_chest = question_chest or {}
question_chest.formspec = {}

function question_chest.formspec.teacher_config(pos, qtype_override)
    local meta = minetest.get_meta(pos)
    local stored = minetest.deserialize(meta:get_string("question_data")) or {}
    local question = stored.question or ""
    local answers = stored.answers and table.concat(stored.answers, ", ") or ""
    local correct = stored.correct and table.concat(stored.correct, ", ") or ""
    local qtype = qtype_override or stored.type or "open"

    return table.concat({
        "formspec_version[4]",
        "size[10,8]",
        "label[0.4,0.2;Configure Question Chest]",
        "textarea[0.3,0.6;9.5,2.2;question;Question:;" .. minetest.formspec_escape(question) .. "]",
        "button[0.3,3;4,1;qtype_open;Open-ended]",
        "button[5.2,3;4,1;qtype_mcq;Multiple Choice]",
        "field[0.3,4.2;9.5,1;answers;Answer options (comma-separated):;" .. minetest.formspec_escape(answers) .. "]",
        "field[0.3,5.2;9.5,1;correct;Correct answer(s) (comma-separated):;" .. minetest.formspec_escape(correct) .. "]",
        "label[0.3,6.5;Place reward items directly into chest inventory below.]",
        "button[2.5,7.2;2.5,1;save;Save]",
        "button_exit[5.2,7.2;2.5,1;cancel;Cancel]",
        "field[hidden_qtype;;" .. qtype .. "]"
    }, "")
end
