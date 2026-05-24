-- AI workflow keymaps

-- Helper for yanking paths
local function yank_paths(paths, label)
	vim.fn.setreg("+", table.concat(paths, "\n"))
	print("Yanked " .. #paths .. " " .. label)
end

-- Helper for formatting line ranges
local function format_range(start_line, end_line)
	return start_line == end_line and tostring(start_line) or (start_line .. "-" .. end_line)
end

-- Helper for sending to AI pane
local function send_to_ai_pane(text, focus)
	if not vim.g.ai_pane_id then
		return
	end
	vim.fn.system("tmux send-keys -t " .. vim.fn.shellescape(vim.g.ai_pane_id) .. " -l " .. vim.fn.shellescape(text))
	if focus then
		vim.fn.system("tmux select-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
	end
end

-- Yank absolute file path
vim.keymap.set("n", "<leader>yp", function()
	yank_paths({ vim.fn.expand("%:p") }, "path")
end, { desc = "Yank absolute file path" })

-- Yank all buffer paths
vim.keymap.set("n", "<leader>yb", function()
	local paths = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" then
				table.insert(paths, name)
			end
		end
	end
	yank_paths(paths, "buffer paths")
end, { desc = "Yank all buffer paths" })

-- Yank all harpoon paths
vim.keymap.set("n", "<leader>yh", function()
	local ok, harpoon = pcall(require, "harpoon")
	if not ok then
		print("Harpoon not available")
		return
	end
	local paths = {}
	local cwd = vim.fn.getcwd() .. "/"
	for _, item in ipairs(harpoon:list().items) do
		if item.value and item.value ~= "" then
			local path = item.value:sub(1, 1) == "/" and item.value or (cwd .. item.value)
			table.insert(paths, path)
		end
	end
	yank_paths(paths, "harpoon paths")
end, { desc = "Yank all harpoon paths" })

-- Helper for visual selection yanking
local yank_ns = vim.api.nvim_create_namespace("yank_selection_highlight")

local function yank_selection(include_code, skip_register)
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.fn.expand("%:p")
	local result = path .. ":" .. format_range(start_line, end_line)
	if include_code then
		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
		result = result .. "\n" .. table.concat(lines, "\n")
	end
	if not skip_register then
		vim.fn.setreg("+", result)
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	-- Highlight the yanked range
	vim.defer_fn(function()
		vim.highlight.range(bufnr, yank_ns, "IncSearch", { start_line - 1, 0 }, { end_line - 1, -1 })
		vim.defer_fn(function()
			vim.api.nvim_buf_clear_namespace(bufnr, yank_ns, 0, -1)
		end, 150)
	end, 0)
	if not skip_register then
		print("Yanked " .. (include_code and "selection with code" or "selection reference"))
	end
	return result
end

-- Yank selection reference (path:lines only)
vim.keymap.set("v", "<leader>ys", function()
	yank_selection(false)
end, { desc = "Yank file path and line numbers (full lines)" })

-- Yank selection with code (path:lines + code content)
vim.keymap.set("v", "<leader>yc", function()
	yank_selection(true)
end, { desc = "Yank file path, lines, and code (full lines)" })

-- AI tools in tmux splits
vim.g.ai_pane_id = nil
local ai_pane_marker = "@nvim_ai_pane"
local ai_pane_cmd_option = "@nvim_ai_cmd"

local function tmux_available()
	return vim.fn.executable("tmux") == 1
end

local function ai_pane_alive()
	if not vim.g.ai_pane_id then
		return false
	end
	local check = vim.fn.system(
		"tmux display-message -t " .. vim.fn.shellescape(vim.g.ai_pane_id) .. " -p '#{pane_id}' 2>/dev/null"
	)
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

local function mark_ai_pane(pane_id, cmd)
	if not pane_id or pane_id == "" then
		return
	end
	tmux_set_pane_option(pane_id, ai_pane_marker, "1")
	tmux_set_pane_option(pane_id, ai_pane_cmd_option, cmd)
end

local ensure_ai_pane

-- Send selection to AI pane
vim.keymap.set("v", "<leader>cx", function()
	if not tmux_available() then
		print("tmux not available")
		return
	end
	local result = yank_selection(false, true)
	if ensure_ai_pane() then
		send_to_ai_pane(result .. " ", true)
	else
		print("AI pane closed.")
	end
end, { desc = "Send selection to AI pane" })

-- Yank all file paths in Oil directory
vim.keymap.set("n", "<leader>yo", function()
	local ok, oil = pcall(require, "oil")
	if not ok then
		print("Oil not available")
		return
	end
	local dir = oil.get_current_dir()
	if not dir then
		print("Not in Oil buffer")
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local paths = {}
	for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
		local entry = oil.get_entry_on_line(bufnr, lnum)
		if entry and entry.type == "file" then
			table.insert(paths, dir .. entry.name)
		end
	end
	yank_paths(paths, "Oil paths")
end, { desc = "Yank all file paths in Oil directory" })

local function toggle_ai_split(cmd)
	if not tmux_available() then
		print("tmux not available")
		return
	end
	if ensure_ai_pane() then
		vim.fn.system("tmux kill-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
		vim.g.ai_pane_id = nil
		print("AI pane closed")
		return
	end
	local pane_id = vim.fn.system(
		'tmux split-window -h -p 35 -P -F "#{pane_id}" -c '
			.. vim.fn.shellescape(vim.fn.getcwd())
			.. " '$SHELL -ic "
			.. cmd
			.. "'"
	)
	pane_id = vim.trim(pane_id)
	if pane_id == "" then
		print("Failed to create tmux split")
		return
	end
	mark_ai_pane(pane_id, cmd)
	vim.g.ai_pane_id = pane_id
end

vim.keymap.set("n", "<leader>cc", function()
	toggle_ai_split("accd")
end, { desc = "Open Claude Code in tmux split" })

vim.keymap.set("n", "<leader>cd", function()
	toggle_ai_split("acdd")
end, { desc = "Open Codex in tmux split" })

vim.keymap.set("n", "<leader>co", function()
	toggle_ai_split("aco")
end, { desc = "Open OpenCode in tmux split" })

vim.keymap.set("n", "<leader>cp", function()
	if ensure_ai_pane() then
		send_to_ai_pane(vim.fn.expand("%:p") .. " ", true)
	else
		print("AI pane closed. Use <leader>cc to open.")
	end
end, { desc = "Send file path to AI pane" })

vim.keymap.set("n", "<leader>cq", function()
	if ensure_ai_pane() then
		vim.fn.system("tmux kill-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
		vim.g.ai_pane_id = nil
		print("AI pane closed")
	else
		print("No AI pane open")
	end
end, { desc = "Close AI pane" })

-- Find a pane this config marked, so it survives nvim closing and reopening.
local function find_ai_pane_in_window()
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

ensure_ai_pane = function()
	if ai_pane_alive() then
		return true
	end

	local existing = find_ai_pane_in_window()
	if existing then
		vim.g.ai_pane_id = existing
		return true
	end

	return false
end

local llm_jobs = require("llm_jobs")

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

vim.keymap.set("n", "<leader>cl", llm_jobs.open_list, { desc = "Open LLM job list" })

-- Quick scoped message: runs a one-shot editor task through cf_tool.
vim.keymap.set("n", "<leader>cf", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
		return
	end
	local line, snippet = cf_current_line_snippet()
	local message = vim.fn.input("LLM Message: ")
	if message == "" then
		return
	end

	llm_jobs.run(llm_location_label(file, tostring(line)), snippet, message, bufnr)
end, { desc = "Run scoped LLM fix" })

-- Visual mode: scoped message with line range
vim.keymap.set("v", "<leader>cf", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		return
	end
	local range = format_range(start_line, end_line)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

	vim.schedule(function()
		local message = vim.fn.input("LLM Message: ")
		if message == "" then
			return
		end
		local snippet = cf_snippet(bufnr, start_line, end_line)
		llm_jobs.run(llm_location_label(file, range), snippet, message, bufnr)
	end)
end, { desc = "Run scoped LLM fix with selection" })
