local Float = require("float")
-- local cfg = require('outline.config')
local utils = require("utils")

local M = {}
M.current_split_type = nil

M.options = {
	split_type = "vsplit",
	split_size_vsplit = nil,
	split_size_split = nil,
	modifiable = true,
	mappings = {
		update = "<C-u>",
		clear = "<C-r>",
	},
}

local buffer_name = "bufmsg_buffer"

local function is_bmessages_buffer_open(options)
	local bufnr = vim.fn.bufnr(buffer_name)
	return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

local function update_messages_buffer(options)
	return function()
		local new_messages = vim.api.nvim_cmd({ cmd = "messages" }, { output = true })
		if new_messages == "" then
			return
		end

		local bufnr = vim.fn.bufnr(buffer_name)
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local lines = vim.split(new_messages, "\n")

		vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

		if not options.modifiable then
			vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
		end

		if vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()) ~= buffer_name then
			local winnr = vim.fn.bufwinnr(bufnr)
			if winnr ~= -1 then
				local winid = vim.fn.win_getid(winnr)
				vim.api.nvim_win_set_cursor(winid, { #lines, 0 })
			end
		end
	end
end

local function merge_options(defaults, new_options)
	if not new_options then
		return defaults
	end
	return vim.tbl_deep_extend("force", defaults, new_options)
end

local function create_raw_buffer(options)
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(bufnr, buffer_name)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
	vim.api.nvim_set_option_value("bl", false, { buf = bufnr })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
	vim.api.nvim_set_option_value("modifiable", options.modifiable, { buf = bufnr })
	return bufnr
end

local function run_vim_cmd(options)
	local cmd = options.split_type

	if cmd == "vsplit" and options.split_size_vsplit ~= nil then
		cmd = cmd .. " | vertical resize " .. options.split_size_vsplit
	elseif cmd == "split" and options.split_size_split ~= nil then
		cmd = cmd .. " | resize " .. options.split_size_split
	end

	vim.cmd(cmd .. " | enew")
end

local function create_messages_buffer(new_options)
	local options = merge_options(M.options, new_options)

	if is_bmessages_buffer_open(options) then
		if M.current_split_type == options.split_type then
			vim.api.nvim_buf_delete(vim.fn.bufnr(buffer_name), { force = true })
			return nil
		else
			vim.api.nvim_buf_delete(vim.fn.bufnr(buffer_name), { force = true })
		end
	end

	M.current_split_type = options.split_type

	run_vim_cmd(options)
	local bufnr = create_raw_buffer(options)

	local update_fn = update_messages_buffer(options)
	update_fn()

	-- update messages
	vim.keymap.set("n", M.options.mappings.update, update_fn, { silent = true, buffer = bufnr })
	-- clear all messages
	vim.keymap.set("n", M.options.mappings.clear, function()
		vim.ui.input({ prompt = "Are you sure you want to clear the message buffer (y/n)" }, function(input)
			if input == "Y" or input == "y" then
				vim.cmd([[messages clear]])
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
				vim.notify("clear all messages", vim.log.levels.INFO)
			end
		end)
	end, { silent = true, buffer = bufnr })
	vim.keymap.set("n", "?", M.show_keymap_help, { silent = true, buffer = bufnr })
end

-- This function is supposed to be called explicitly by users to configure this plugin
function M.setup(options)
	M.options = vim.tbl_deep_extend("force", M.options, options)

	if M.options.disable_create_user_commands then
		return
	end

	vim.api.nvim_create_user_command("Bufmsg", function()
		create_messages_buffer(M.options)
	end, {})

	vim.api.nvim_create_user_command("Bufmsgvs", function()
		create_messages_buffer(vim.tbl_deep_extend("force", M.options, { split_type = "vsplit" }))
	end, {})

	vim.api.nvim_create_user_command("Bufmsgss", function()
		create_messages_buffer(vim.tbl_deep_extend("force", M.options, { split_type = "split" }))
	end, {})

	vim.api.nvim_set_hl(0, "HelpTip", { fg = "gray" })
	vim.api.nvim_set_hl(0, "HelpKey", { fg = "red" })
end

-- this function generated from Outline.nvim
-- https://github.com/hedyhli/outline.nvim/tree/main/lua/outline
function M.show_keymap_help()
	local keyhint = "Press q or <Esc> to close this window."
	local title = "Current keymaps:"
	local lines = { keyhint, "", title, "" }
	---@type HL[]
	local hl = { { line = 0, from = 0, to = #keyhint, name = "HelpTip" } }
	local left = {}
	local right = {}
	local max_left_width = 0
	local indent = "    "
	local key_hl = "HelpKey"

	for keys, action in pairs(M.options.mappings) do
		if type(keys) == "string" then
			table.insert(left, keys)
			table.insert(hl, {
				line = #left + 3,
				from = #indent,
				to = #keys + #indent,
				name = key_hl,
			})
		else
			local i = #indent
			table.insert(left, table.concat(keys, " / "))
			for _, key in ipairs(keys) do
				table.insert(hl, {
					line = #left + 3,
					from = i,
					to = #key + i,
					name = key_hl,
				})
				i = i + #key + 3
			end
		end
		if #left[#left] > max_left_width then
			max_left_width = #left[#left]
		end
		table.insert(right, action)
	end

	for i, l in ipairs(left) do
		local pad = string.rep(" ", max_left_width - #l + 2)
		table.insert(lines, indent .. l .. pad .. right[i])
	end

	local f = Float:new()
	f:open(lines, hl, "Help", 1)

	utils.nmap(f.bufnr, { "q", "<Esc>" }, function()
		f:close()
	end)
end

return M
