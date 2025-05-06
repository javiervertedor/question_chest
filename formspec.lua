local function esc(str)
	return minetest.formspec_escape(str or "")
end

local function table_to_csv(tbl)
	if type(tbl) ~= "table" then return "" end
	return table.concat(tbl, ", ")
end

local M = {}

-- === Teacher Form ===
function M.teacher_config(pos)
	local meta = minetest.get_meta(pos)
	local qtype = meta:get_string("question_type") or "open"
	local question = meta:get_string("question") or ""
	local open_answers = meta:get_string("open_answers") or ""
	local mcq_answers = meta:get_string("mcq_answers") or ""
	local mcq_options = minetest.deserialize(meta:get_string("mcq_options") or "") or {}

	local fs = "formspec_version[4]size[10,11]" ..
		"bgcolor[#1e1e1eBB;true]" ..
		"key_enter[save]" ..
		"key_escape[cancel]" ..
		"label[0.2,0.3;Question:]" ..
		"field[2.5,0.3;7,1;question;;" .. esc(question) .. "]" ..
		"label[0.2,1.2;Question Type:]" ..
		"dropdown[2.5,1.2;3.5,1;question_type;open,mcq;" .. (qtype == "mcq" and 2 or 1) .. "]"

	if qtype == "open" then
		fs = fs ..
			"label[0.2,2.2;Correct Answers (comma-separated):]" ..
			"field[0.2,2.7;9.5,1;open_answers;;" .. esc(open_answers) .. "]"
	else
		fs = fs ..
			"label[0.2,2.2;MCQ Options (comma-separated):]" ..
			"field[0.2,2.7;9.5,1;mcq_options;;" .. esc(table_to_csv(mcq_options)) .. "]" ..
			"label[0.2,3.6;Correct Answers (comma-separated):]" ..
			"field[0.2,4.1;9.5,1;mcq_answers;;" .. esc(mcq_answers) .. "]"
	end

	fs = fs ..
		"label[0.2,5.1;Place reward items below:]" ..
		string.format("list[nodemeta:%d,%d,%d;main;0.2,5.6;8,1;]", pos.x, pos.y, pos.z) ..
		"label[0.2,7;Your Inventory:]" ..
		"list[current_player;main;0.2,7.5;8,4;]" ..
		"listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
		"listring[current_player;main]" ..
		"button[2.5,10.3;2,1;cancel;Close]" ..
		"button[5.1,10.3;2.5,1;save;Save]"

	return fs
end

-- === Student: Open-Ended ===
function M.open(question)
	return "formspec_version[4]size[8,5.5]" ..
		"bgcolor[#1e1e1eBB;true]" ..
		"key_enter[submit_answer]" ..
		"key_escape[cancel]" ..
		"label[0.3,0.5;" .. esc(question) .. "]" ..
		"field[0.3,1.5;7.4,1;answer;;]" ..
		"button[3,3.5;2,1;submit_answer;Submit]"
end

-- === Student: MCQ ===
function M.mcq(question, options)
	local fs = "formspec_version[4]size[8,6]" ..
		"bgcolor[#1e1e1eBB;true]" ..
		"key_enter[submit_answer]" ..
		"key_escape[cancel]" ..
		"label[0.3,0.3;" .. esc(question) .. "]"

	for i, opt in ipairs(options) do
		fs = fs .. string.format("checkbox[0.4,%0.8f;opt%d;%s;false]", 0.8 + i * 0.6, i, esc(opt))
	end

	fs = fs .. "button[3,5;2,1;submit_answer;Submit]"
	return fs
end

return M
