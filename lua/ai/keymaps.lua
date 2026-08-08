local yank = require("yank")

local function current_file_or_notify()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
		return nil
	end
	return file
end

local function current_line_reference()
	local file = current_file_or_notify()
	if not file then
		return nil
	end
	return file .. ":" .. vim.fn.line(".")
end

local function ai_pane_target()
	if not vim.g.ai_pane_id then
		return nil
	end
	return vim.fn.shellescape(vim.g.ai_pane_id)
end

local function send_to_ai_pane(text, focus)
	local target = ai_pane_target()
	if not target then
		return
	end
	vim.fn.system("tmux send-keys -t " .. target .. " -l " .. vim.fn.shellescape(text))
	if focus then
		vim.fn.system("tmux select-pane -t " .. target)
	end
end

vim.g.ai_pane_id = nil
local ai_pane_marker = "@nvim_ai_pane"
local config

local function tmux_available()
	return vim.fn.executable("tmux") == 1
end

local function ai_pane_alive()
	local target = ai_pane_target()
	if not target then
		return false
	end
	local check = vim.fn.system("tmux display-message -t " .. target .. " -p '#{pane_id}' 2>/dev/null")
	return vim.trim(check) ~= ""
end

local function tmux_set_pane_option(pane_id, option, value)
	vim.fn.system(
		"tmux set-option -p -t "
			.. vim.fn.shellescape(pane_id)
			.. " "
			.. vim.fn.shellescape(option)
			.. " "
			.. vim.fn.shellescape(value)
			.. " 2>/dev/null"
	)
end

local function mark_ai_pane(pane_id)
	if not pane_id or pane_id == "" then
		return
	end
	tmux_set_pane_option(pane_id, ai_pane_marker, "1")
end

local function close_ai_pane()
	local target = ai_pane_target()
	if target then
		vim.fn.system("tmux kill-pane -t " .. target)
	end
	vim.g.ai_pane_id = nil
	print("AI pane closed")
end

-- Find a pane this config marked, so it survives nvim closing and reopening.
local function find_marked_ai_pane()
	local out = vim.fn.system('tmux list-panes -F "#{pane_id}\t#{@nvim_ai_pane}" 2>/dev/null')
	if vim.v.shell_error ~= 0 then
		return nil
	end
	for _, line in ipairs(vim.split(vim.trim(out), "\n", { trimempty = true })) do
		local parts = vim.split(line, "\t", { plain = true })
		if parts[2] == "1" and parts[1] and parts[1] ~= "" then
			return parts[1]
		end
	end
	return nil
end

local function ensure_ai_pane()
	if ai_pane_alive() then
		return true
	end

	local existing = find_marked_ai_pane()
	if existing then
		vim.g.ai_pane_id = existing
		return true
	end

	return false
end

local function open_ai_split(cmd)
	if not tmux_available() then
		print("tmux not available")
		return false
	end
	local pane_id = vim.fn.system({
		"tmux",
		"split-window",
		"-h",
		"-l",
		"35%",
		"-P",
		"-F",
		"#{pane_id}",
		"-c",
		vim.fn.getcwd(),
		"$SHELL -ic " .. vim.fn.shellescape(cmd),
	})
	pane_id = vim.trim(pane_id)
	if pane_id == "" then
		print("Failed to create tmux split")
		return false
	end
	mark_ai_pane(pane_id)
	vim.g.ai_pane_id = pane_id
	return true
end

local function toggle_ai_split(cmd)
	if ensure_ai_pane() then
		close_ai_pane()
		return
	end
	open_ai_split(cmd)
end

local function ensure_or_open_ai_pane(cmd)
	if ensure_ai_pane() then
		return true
	end
	return open_ai_split(cmd)
end

local ai_split_commands = {
	claude = { lhs = "<leader>cc", cmd = "claude --permission-mode auto", desc = "claude code pane" },
	codex = {
		lhs = "<leader>cd",
		cmd = "codex --sandbox workspace-write --ask-for-approval on-request -c approvals_reviewer=auto_review -c sandbox_workspace_write.network_access=true",
		desc = "codex pane",
	},
}

local function default_ai_split_cmd()
	return ai_split_commands[config.tool].cmd
end

vim.keymap.set("n", "<leader>cx", function()
	local result = current_line_reference()
	if not result then
		return
	end
	if ensure_or_open_ai_pane(default_ai_split_cmd()) then
		send_to_ai_pane(result .. " ", true)
	else
		print("AI pane closed.")
	end
end, { desc = "send current line" })

vim.keymap.set("v", "<leader>cx", function()
	local result = yank.yank_selection(false, true)
	if ensure_or_open_ai_pane(default_ai_split_cmd()) then
		send_to_ai_pane(result .. " ", true)
	else
		print("AI pane closed.")
	end
end, { desc = "send selection" })

for _, mapping in pairs(ai_split_commands) do
	local lhs, cmd, desc = mapping.lhs, mapping.cmd, mapping.desc
	vim.keymap.set("n", lhs, function()
		toggle_ai_split(cmd)
	end, { desc = desc })
end

vim.keymap.set("n", "<leader>cp", function()
	if ensure_or_open_ai_pane(default_ai_split_cmd()) then
		send_to_ai_pane(vim.fn.expand("%:p") .. " ", true)
	else
		print("AI pane closed.")
	end
end, { desc = "send file path" })

local llm_jobs = require("ai.jobs")

local function llm_location_label(file, range)
	return (file .. ":" .. range):gsub("%c", " ")
end

local function cf_snippet(bufnr, start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
	local numbered = {}
	for i, line in ipairs(lines) do
		table.insert(numbered, string.format("%d: %s", start_line + i - 1, line))
	end
	return table.concat(numbered, "\n")
end

local function cf_current_line_snippet()
	local line = vim.fn.line(".")
	local start_line = math.max(1, line - 10)
	local end_line = math.min(vim.api.nvim_buf_line_count(0), line + 10)
	local snippet = cf_snippet(0, start_line, end_line)
	return line, snippet
end

vim.keymap.set("n", "<leader>cl", llm_jobs.open_list, { desc = "job list" })

vim.keymap.set("n", "<leader>cf", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local file = current_file_or_notify()
	if not file then
		return
	end
	local line, snippet = cf_current_line_snippet()
	local message = vim.fn.input("LLM Message: ")
	if message == "" then
		return
	end

	llm_jobs.run(llm_location_label(file, tostring(line)), snippet, message, bufnr)
end, { desc = "run scoped fix" })

vim.keymap.set("v", "<leader>cf", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_line, end_line = yank.visual_range()
	local file = current_file_or_notify()
	if not file then
		yank.feed_escape()
		return
	end
	local range = yank.format_range(start_line, end_line)
	yank.feed_escape()

	vim.schedule(function()
		local message = vim.fn.input("LLM Message: ")
		if message == "" then
			return
		end
		local snippet = cf_snippet(bufnr, start_line, end_line)
		llm_jobs.run(llm_location_label(file, range), snippet, message, bufnr)
	end)
end, { desc = "run scoped fix with selection" })

local M = {}

function M.setup(opts)
	config = opts
end

return M
