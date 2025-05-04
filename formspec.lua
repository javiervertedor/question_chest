question_chest = question_chest or {}
question_chest.formspec = {}

function question_chest.formspec.teacher_config(pos)
    local meta = minetest.get_meta(pos)
    local stored = minetest.deserialize(meta:get_string("question_data")) or {}
    local question = stored.question or ""
    local qtype = stored.type or "open"
    local answers = stored.answers and table.concat(stored.answers, ", ") or ""
    local correct = stored.correct and table.concat(stored.correct, ", ") or ""

    local open_checked = qtype == "open" and "true" or "false"
    local mcq_checked = qtype == "mcq" and "true" or "false"

    return table.concat({
        "formspec_version[4]",
        "size[10,8]",
        "label[0.4,0.2;Configure Question Chest]",
        "textarea[0.3,0.6;9.5,2.2;question;Question:;" .. minetest.formspec_escape(question) .. "]",
        "checkbox[0.3,2.9;qtype_open;Use open-ended question;" .. open_checked .. "]",
        "checkbox[5,2.9;qtype_mcq;Use multiple-choice question;" .. mcq_checked .. "]",
        "field[0.3,3.9;9.5,1;answers;Answer options (comma-separated):;" .. minetest.formspec_escape(answers) .. "]",
        "field[0.3,4.9;9.5,1;correct;Correct answer(s) (comma-separated):;" .. minetest.formspec_escape(correct) .. "]",
        "label[0.3,6.1;Place reward items directly into chest inventory below.]",
        "button[2.5,7.2;2.5,1;save;Save]",
        "button_exit[5.2,7.2;2.5,1;cancel;Cancel]"
    }, "")
end
