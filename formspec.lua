question_chest = question_chest or {}
question_chest.formspec = {}

local esc = minetest.formspec_escape

-- STUDENT FORM
function question_chest.formspec.student_question(pos)
	local meta = minetest.get_meta(pos)
	local data = minetest.deserialize(meta:get_string("question_data") or "") or {}
	local qtype = data.type or "open"
	local question = esc(data.question or "")
	local answers = data.answers or {}

	local fs = "formspec_version[4]size[10,8]"
	fs = fs .. "label[0.5,0.4;" .. question .. "]"

	if qtype == "open" then
		fs = fs .. "field[0.5,1.5;9,1;answer;Your answer;]"
		fs = fs .. "field_close_on_enter[answer;false]"
	else
		fs = fs .. "field[hidden_selected;selected_choices;]"
		for i, option in ipairs(answers) do
			fs = fs .. string.format("checkbox[0.5,%f;opt_%d;%s;false]", 1.2 + i * 0.6, i, esc(option))
		end
	end

	fs = fs .. "button[7.5,6.6;2,1;submit_answer;Submit]"
	fs = fs .. "button_exit[5.2,6.6;2,1;cancel;Close]"
	fs = fs .. "key_enter[submit_answer]"
	fs = fs .. "key_escape[cancel]"
	return fs
end

-- TEACHER FORM
function question_chest.formspec.teacher_config(pos, data)
	data = data or {}

	local question = esc(data.question or "")
	local qtype = data.type or "open"
	local answers = type(data.answers) == "table" and table.concat(data.answers, ", ") or esc(data.answers or "")
	local correct = type(data.correct) == "table" and table.concat(data.correct, ", ") or esc(data.correct or "")

	local fs = "formspec_version[4]size[10,11]"
	fs = fs .. "label[0.5,0.2;Configure Question Chest]"

	fs = fs .. "label[0.5,0.7;Question:]"
	fs = fs .. "field[2.5,0.7;7,1;question;;" .. question .. "]"
	fs = fs .. "field_close_on_enter[question;false]"

	fs = fs .. "label[0.5,1.5;Question Type:]"
	fs = fs .. "dropdown[2.5,1.4;4;qtype;open,mcq;" .. (qtype == "mcq" and 2 or 1) .. "]"

	if qtype == "mcq" then
		fs = fs .. "label[0.5,2.3;Correct Answers (comma-separated):]"
		fs = fs .. "field[0.5,2.9;9,1;correct;;" .. correct .. "]"
		fs = fs .. "field_close_on_enter[correct;false]"
		fs = fs .. "label[0.5,3.5;MCQ Options (comma-separated):]"
		fs = fs .. "field[0.5,4.1;9,1;answers;;" .. answers .. "]"
		fs = fs .. "field_close_on_enter[answers;false]"
	else
		fs = fs .. "label[0.5,2.3;Open-ended question. No options needed.]"
	end

	fs = fs .. "label[0.5,5.0;Place rewards in the chest inventory below:]"
	fs = fs .. string.format("list[nodemeta:%d,%d,%d;main;0.5,5.5;8,1;]", pos.x, pos.y, pos.z)
	fs = fs .. "list[current_player;main;0.5,7.2;8,1;]"
	fs = fs .. "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]"
	fs = fs .. "listring[current_player;main]"

	fs = fs .. "button[6.5,9.4;2.5,1;save;Save]"
	fs = fs .. "button_exit[3.5,9.4;2,1;quit;Close]"
	fs = fs .. "key_enter[save]"
	fs = fs .. "key_escape[quit]"

	return fs
end
