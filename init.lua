-- Question Chest Luanti Mod for Teachers
-- By Francisco Vertedor
--
-- This mod adds a protected chest for educational use in Luanti. Teachers can configure
-- questions (open-ended or multiple choice) and associate rewards. Students must answer
-- correctly to receive items, promoting learning through gameplay.
--
-- Licensed under the GNU General Public License v3.0
-- See https://www.gnu.org/licenses/gpl-3.0.html


question_chest = question_chest or {}

-- Load UI form definitions
dofile(minetest.get_modpath("question_chest") .. "/formspec.lua")

-- Privilege
minetest.register_privilege("question_chest_admin", {
	description = "Can configure Question Chests as a teacher",
	give_to_singleplayer = true
})

-- Utilities
local function parse_csv(str)
	local t = {}
	for s in string.gmatch(str or "", "([^,]+)") do
		local clean = s:lower():gsub("^%s*(.-)%s*$", "%1")
		if clean ~= "" then table.insert(t, clean) end
	end
	return t
end

local function match_answers(a, b)
	if #a ~= #b then return false end
	table.sort(a)
	table.sort(b)
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- Question Chest Node
minetest.register_node("question_chest:chest", {
	description = "Question Chest",
	tiles = {
		"question_chest_top.png",
		"default_chest_bottom.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_front.png"
	},
	paramtype = "light",
	light_source = 4,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {dig_immediate = 2, unbreakable = 1},
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:get_inventory():set_size("main", 8)
		meta:set_string("infotext", "Question Chest")
		meta:set_string("answered_players", minetest.serialize({}))
		meta:set_string("reward_collected", minetest.serialize({}))
	end,

	can_dig = function(pos, player)
		return minetest.check_player_privs(player:get_player_name(), {question_chest_admin = true})
	end,

	allow_metadata_inventory_take = function(pos, _, _, stack, player)
		local name = player:get_player_name()
		local meta = minetest.get_meta(pos)
		local answered = minetest.deserialize(meta:get_string("answered_players") or "{}")
		return answered[name] and stack:get_count() or 0
	end,

	allow_metadata_inventory_put = function(pos, _, _, stack, player)
		return minetest.check_player_privs(player:get_player_name(), {question_chest_admin = true}) and stack:get_count() or 0
	end,

	on_rightclick = function(pos, _, clicker)
		local name = clicker:get_player_name()
		local meta = minetest.get_meta(pos)
		local answered = minetest.deserialize(meta:get_string("answered_players") or "{}")
		local formname = "question_chest:" .. minetest.pos_to_string(pos)

		if minetest.check_player_privs(name, {question_chest_admin = true}) then
			local data = minetest.deserialize(meta:get_string("question_data") or "") or {}
			minetest.show_formspec(name, formname .. ":teacher", question_chest.formspec.teacher_config(pos, data))
			return
		end

		if answered[name] then
			-- Allow chest access if answered correctly
			minetest.show_formspec(name, formname .. ":rewards",
				"formspec_version[4]size[10,8]" ..
				"label[0.5,0.4;You may take your reward.]" ..
				string.format("list[nodemeta:%d,%d,%d;main;0.5,1;8,1;]", pos.x, pos.y, pos.z) ..
				"list[current_player;main;0.5,3;8,1;]" ..
				"listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";main]" ..
				"listring[current_player;main]")
			return
		end

		-- Show question
		minetest.show_formspec(name, formname .. ":student", question_chest.formspec.student_question(pos))
	end,
})

-- Handle Form Responses
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	local pos_str = formname:match("^question_chest:([^:]+)")
	local mode = formname:match("^question_chest:[^:]+:(.+)$")
	if not pos_str or not mode then return end
	local pos = minetest.string_to_pos(pos_str)
	if not pos then return end
	local meta = minetest.get_meta(pos)

	-- === Student Form ===
	if mode == "student" and fields.submit_answer then
		local data = minetest.deserialize(meta:get_string("question_data") or "") or {}
		local answered = minetest.deserialize(meta:get_string("answered_players") or "{}")

		if answered[name] then return end

		local success = false
		local correct = data.correct or {}
		local qtype = data.type or "open"

		if qtype == "open" then
			local input = (fields.answer or ""):lower():gsub("^%s*(.-)%s*$", "%1")
			for _, c in ipairs(correct) do
				if input == c then
					success = true break
				end
			end
		elseif qtype == "mcq" then
			local selected = {}
			for i, option in ipairs(data.answers or {}) do
				if fields["opt_" .. i] == "true" then
					table.insert(selected, option:lower():gsub("^%s*(.-)%s*$", "%1"))
				end
			end
			success = match_answers(selected, correct)
		end

		if success then
			minetest.chat_send_player(name, "Correct! You may now open the chest.")
			answered[name] = true
			meta:set_string("answered_players", minetest.serialize(answered))
		else
			minetest.chat_send_player(name, "Incorrect answer. Try again.")
		end

		minetest.close_formspec(name, formname)
	end

	-- === Teacher Form ===
	if mode == "teacher" then
		-- Dynamic toggle
		if fields.qtype and not fields.save then
			local state = {
				question = fields.question or "",
				type = fields.qtype,
				answers = fields.answers or "",
				correct = fields.correct or ""
			}
			minetest.show_formspec(name, formname, question_chest.formspec.teacher_config(pos, state))
			return
		end

		if fields.save then
			local qtype = fields.qtype or "open"
			local question = fields.question or ""
			local answers = parse_csv(fields.answers or "")
			local correct = parse_csv(fields.correct or "")

			if question == "" or #correct == 0 or (qtype == "mcq" and #answers == 0) then
				minetest.chat_send_player(name, "Please fill out all fields.")
				return
			end

			if qtype == "mcq" then
				local options = {}
				for _, a in ipairs(answers) do options[a] = true end
				for _, c in ipairs(correct) do
					if not options[c] then
						minetest.chat_send_player(name, "Correct answers must match provided options.")
						return
					end
				end
			end

			local inv = meta:get_inventory()
			local rewards = {}
			for i = 1, inv:get_size("main") do
				local stack = inv:get_stack("main", i)
				if not stack:is_empty() then
					table.insert(rewards, stack:to_table())
				end
			end

			meta:set_string("question_data", minetest.serialize({
				type = qtype,
				question = question,
				answers = (qtype == "mcq") and answers or nil,
				correct = correct,
				rewards = rewards
			}))
			meta:set_string("infotext", "Question Chest (configured)")
			minetest.chat_send_player(name, "Question saved.")
		end
	end
end)
