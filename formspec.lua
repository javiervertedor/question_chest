question_chest = question_chest or {}
question_chest.formspec = {}

function question_chest.formspec.teacher_config(pos)
    local meta = minetest.get_meta(pos)
    local stored = minetest.deserialize(meta:get_string("question_data")) or {}
    local question = stored.question or ""
    local type_idx = stored.type == "mcq" and 2 or 1
    local answers = stored.answers and table.concat(stored.answers, ", ") or ""
    local correct = stored.correct and table.concat(stored.correct, ", ") or ""

    return "size[8,8]" ..
        "label[0,0;Configure Question Chest]" ..
        "textarea[0.3,0.5;7.5,2;question;Question:;" .. minetest.formspec_escape(question) .. "]" ..
        "dropdown[0.3,2.8;4;type;open-ended,mcq;" .. type_idx .. "]" ..
        "field[0.3,3.9;7.5,1;answers;Answer options (comma-separated):;" .. minetest.formspec_escape(answers) .. "]" ..
        "field[0.3,4.9;7.5,1;correct;Correct answer(s): (index or text);" .. minetest.formspec_escape(correct) .. "]" ..
        "label[0.3,6.1;Place reward items directly into chest inventory]" ..
        "button_exit[3,7;2,1;save;Save]"
end