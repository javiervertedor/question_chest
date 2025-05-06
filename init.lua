-- Question Chest Luanti Mod for Teachers
-- By Francisco Vertedor
--
-- This mod adds a protected chest for educational use in Luanti. Teachers can configure
-- questions (open-ended or multiple choice) and associate rewards. Students must answer
-- correctly to receive items, promoting learning through gameplay.
--
-- Licensed under the GNU General Public License v3.0
-- See https://www.gnu.org/licenses/gpl-3.0.html

question_chest = {}
question_chest.formspec = dofile(minetest.get_modpath("question_chest") .. "/formspec.lua")
question_chest.session_pos = {}

local function pos_to_key(pos)
	return minetest.pos_to_string(pos)
end

local function key_to_pos(key)
	return minetest.string_to_pos(key)
end

local function sanitize(text)
	return text:lower():gsub("^%s*(.-)%s*$", "%1")
end

local function parse_csv(str)
	local result = {}
	for s in (str or ""):gmatch("[^,]+") do
		local trimmed = sanitize(s)
		if trimmed ~= "" then table.insert(result, trimmed) end
	end
	return result
end

local answered = {}
local reward_cache = {}

local function get_meta(pos)
	return minetest.get_meta(pos)
end

local function get_fields(pos)
	return get_meta(pos):to_table().fields or {}
end

local function set_fields(pos, data)
	local meta = get_meta(pos)
	for k, v in pairs(data) do
		meta:set_string(k, v)
	end
end

local function get_inv(pos)
	return get_meta(pos):get_inventory()
end

local function show_question(player, pos)
	local name = player:get_player_name()
	local key = pos_to_key(pos)
	local fields = get_fields(pos)

	if answered[name] and answered[name][key] then
		minetest.show_formspec(name, "question_chest:answered_" .. key,
			"formspec_version[4]size[8,7]" ..
			"label[0.3,0.3;You may now collect your reward.]" ..
			string.format("list[nodemeta:%d,%d,%d;main;0,0.8;8,1;]", pos.x, pos.y, pos.z) ..
			"list[current_player;main;0,2.5;8,4;]" ..
			string.format("listring[nodemeta:%d,%d,%d;main]", pos.x, pos.y, pos.z) ..
			"listring[current_player;main]" ..
			"bgcolor[#1e1e1eBB;true]" ..
			"listcolors[#00000000;#00000000]"
		)
	else
		if fields.question_type == "mcq" then
			local question = fields.question or ""
			local options = minetest.deserialize(fields.mcq_options or "") or {}
			minetest.show_formspec(name, "question_chest:mcq_" .. key, question_chest.formspec.mcq(question, options))
		else
			local question = fields.question or ""
			minetest.show_formspec(name, "question_chest:open_" .. key, question_chest.formspec.open(question))
		end
	end
end

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
	paramtype2 = "facedir",
	light_source = 4,
	groups = {choppy = 2, oddly_breakable_by_hand = 2, unbreakable = 1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)
		local meta = get_meta(pos)
		meta:get_inventory():set_size("main", 8)
		meta:set_string("infotext", "Question Chest")
		meta:set_string("question_type", "open")
	end,

	on_rightclick = function(pos, node, player)
		local name = player:get_player_name()
		if minetest.check_player_privs(name, {question_chest_admin = true}) then
			question_chest.session_pos[name] = pos
			minetest.show_formspec(name, "question_chest:config_" .. pos_to_key(pos), question_chest.formspec.teacher_config(pos))
		else
			show_question(player, pos)
		end
	end,

	can_dig = function(pos, player)
		return minetest.check_player_privs(player:get_player_name(), {question_chest_admin = true})
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.check_player_privs(player:get_player_name(), {question_chest_admin = true}) then
			return stack:get_count()
		end
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.check_player_privs(name, {question_chest_admin = true}) then
			return stack:get_count()
		end
		if answered[name] and answered[name][pos_to_key(pos)] then
			return stack:get_count()
		end
		return 0
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if fields.quit or fields.cancel then
		question_chest.session_pos[name] = nil
		return true
	end

	local key = formname:match("_(.+)$")
	local pos = key_to_pos(key)

	-- fallback to saved session
	if not pos then
		pos = question_chest.session_pos[name]
	end

	if not pos then return true end

	local meta = get_meta(pos)
	local inv = get_inv(pos)

	-- Student: open question
	if formname:find("^question_chest:open_") and fields.submit_answer then
		local correct = parse_csv(meta:get_string("open_answers"))
		local input = sanitize(fields.answer or "")
		for _, ans in ipairs(correct) do
			if input == ans then
				answered[name] = answered[name] or {}
				answered[name][key] = true
				if reward_cache[key] then
					inv:set_list("main", reward_cache[key])
				end
				minetest.chat_send_player(name, "Correct! You may now open the chest.")
				show_question(player, pos)
				return true
			end
		end
		minetest.chat_send_player(name, "Incorrect answer. Keep trying.")
		return true
	end

	-- Student: mcq
	if formname:find("^question_chest:mcq_") and fields.submit_answer then
		local options = minetest.deserialize(meta:get_string("mcq_options") or "") or {}
		local correct = parse_csv(meta:get_string("mcq_answers"))
		local selected = {}
		for i, opt in ipairs(options) do
			if fields["opt" .. i] == "true" then
				table.insert(selected, sanitize(opt))
			end
		end
		table.sort(selected)
		table.sort(correct)
		local valid = (#selected == #correct)
		for i = 1, #correct do
			if correct[i] ~= selected[i] then
				valid = false
				break
			end
		end
		if valid then
			answered[name] = answered[name] or {}
			answered[name][key] = true
			if reward_cache[key] then
				inv:set_list("main", reward_cache[key])
			end
			minetest.chat_send_player(name, "Correct! You may now open the chest.")
			show_question(player, pos)
		else
			minetest.chat_send_player(name, "Incorrect answer. Keep trying.")
		end
		return true
	end

	-- Teacher form save or update
	if formname:find("^question_chest:config_") then
		if fields.question_type then
			meta:set_string("question_type", fields.question_type)
		end

		if fields.save then
			meta:set_string("question", fields.question or "")
			meta:set_string("open_answers", fields.open_answers or "")
			meta:set_string("mcq_answers", fields.mcq_answers or "")
			meta:set_string("mcq_options", minetest.serialize(parse_csv(fields.mcq_options or "")))
			reward_cache[key] = inv:get_list("main")
			minetest.chat_send_player(name, "Question and reward saved.")
			question_chest.session_pos[name] = nil
			return true
		else
			meta:set_string("question", fields.question or "")
			meta:set_string("open_answers", fields.open_answers or "")
			meta:set_string("mcq_answers", fields.mcq_answers or "")
			meta:set_string("mcq_options", minetest.serialize(parse_csv(fields.mcq_options or "")))
			minetest.show_formspec(name, formname, question_chest.formspec.teacher_config(pos))
			return true
		end
	end
end)

minetest.register_privilege("question_chest_admin", {
	description = "Can configure question chests",
	give_to_singleplayer = true
})