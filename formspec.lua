question_chest = question_chest or {}
question_chest.formspec = {}

local function escape(str)
    return minetest.formspec_escape(str or "")
end

-- Teacher Configuration Form
function question_chest.formspec.teacher_config(pos, data)
    data = data or {}
    local qtype = data.type or data.qtype or "open"

    -- Safely handle answer/correct as either table or string
    local answers = ""
    if type(data.answers) == "table" then
        answers = escape(table.concat(data.answers, ", "))
    elseif type(data.answers) == "string" then
        answers = escape(data.answers)
    end

    local correct = ""
    if type(data.correct) == "table" then
        correct = escape(table.concat(data.correct, ", "))
    elseif type(data.correct) == "string" then
        correct = escape(data.correct)
    end

    local question = escape(data.question or "")

    local fs = {
        "formspec_version[4]",
        "size[13,12]",
        "label[0.4,0.3;Question Type:]",
        "dropdown[2.5,0.1;3.5,0.8;qtype;open,mcq;" .. (qtype == "mcq" and "2" or "1") .. "]",

        "label[0.4,1.3;Question:]",
        "field[2.5,1.2;9.5,1;question;;" .. question .. "]",

        "label[0.4,2.5;Correct Answer(s):]",
        "field[2.5,2.4;9.5,1;correct;;" .. correct .. "]"
    }

    if qtype == "mcq" then
        table.insert(fs, "label[0.4,3.7;MCQ Options (comma-separated):]")
        table.insert(fs, "field[2.5,3.6;9.5,1;answers;;" .. answers .. "]")
    end

    table.insert(fs, "label[0.4,4.9;Place rewards in chest below →]")
    table.insert(fs, "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.4,5.4;8,1;]")
    table.insert(fs, "list[current_player;main;0.4,7.2;8,4;]")
    table.insert(fs, "listring[]")

    table.insert(fs, "button[7.2,11.4;2.3,0.9;quit;Close]")
    table.insert(fs, "button[10.0,11.4;2.3,0.9;save;Save]")

    return table.concat(fs, "")
end

-- Student Question Form
function question_chest.formspec.student_question(pos)
    local meta = minetest.get_meta(pos)
    local data = minetest.deserialize(meta:get_string("question_data") or "") or {}
    local qtype = data.type or "open"
    local question = escape(data.question or "")
    local fs = {
        "formspec_version[4]",
        "size[10,8]",
        "label[0.4,0.3;" .. question .. "]"
    }

    if qtype == "open" then
        table.insert(fs, "field[0.6,1.5;9,1;answer;;]")
    elseif qtype == "mcq" and type(data.answers) == "table" then
        local y = 1.0
        for i, opt in ipairs(data.answers) do
            local escaped = escape(opt)
            table.insert(fs, "checkbox[0.6," .. y .. ";opt_" .. i .. ";" .. escaped .. ";false]")
            y = y + 0.8
        end
    end

    table.insert(fs, "button[7.2,7.3;2.5,0.9;submit_answer;Submit]")
    return table.concat(fs, "")
end
