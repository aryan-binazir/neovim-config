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

-- Helper for printing send status
local function print_send_status(status, message)
	if status == "sent" then
		print("LLM message sent: " .. message)
	elseif status == "started" then
		print("Opened cc and sent: " .. message)
	elseif status == "failed" then
		print("Failed to send message")
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
	toggle_ai_split("acc")
end, { desc = "Open Claude Code in tmux split" })

vim.keymap.set("n", "<leader>cd", function()
	toggle_ai_split("acd")
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

local scoped_prefix =
	"SCOPE: only this location; no other files; no refactors/formatting; minimal diff, then stop; ask if unclear. "

local function scoped_prompt(location, message)
	return scoped_prefix .. "Location: " .. location .. " Message: " .. message
end

local ai_pane_cmds = {
	acc = true,
	acd = true,
	aco = true,
}

local function pane_current_command(pane_id)
	if not pane_id or pane_id == "" then
		return nil
	end
	local cmd = vim.fn.system(
		"tmux display-message -t " .. vim.fn.shellescape(pane_id) .. " -p '#{pane_current_command}' 2>/dev/null"
	)
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return vim.trim(cmd)
end

local function find_ai_pane_in_window()
	local out = vim.fn.system(
		'tmux list-panes -F "#{pane_id}\t#{@nvim_ai_pane}\t#{pane_current_command}" 2>/dev/null'
	)
	if vim.v.shell_error ~= 0 then
		return nil
	end

	local fallback = nil
	for _, line in ipairs(vim.split(vim.trim(out), "\n", { trimempty = true })) do
		local parts = vim.split(line, "\t", { plain = true })
		local pane_id = parts[1]
		local marked = parts[2]
		local cmd = parts[3]
		if marked == "1" and pane_id and pane_id ~= "" then
			return pane_id
		end
		if not fallback and ai_pane_cmds[cmd] and pane_id and pane_id ~= "" then
			fallback = pane_id
		end
	end
	return fallback
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

local function send_scoped_message(location, message)
	local prompt = scoped_prompt(location, message)
	local submit_delay_ms = 75
	local confirm_patterns = { "press enter", "confirm", "are you sure" }

	local function send_submit_key(target_pane, count)
		local repeats = count or 1
		vim.defer_fn(function()
			for _ = 1, repeats do
				vim.fn.system("tmux send-keys -t " .. vim.fn.shellescape(target_pane) .. " C-m")
			end
		end, submit_delay_ms)
	end

	local function pane_needs_confirm(target_pane)
		if pane_current_command(target_pane) ~= "acd" then
			return false
		end
		local output = vim.fn.system(
			"tmux capture-pane -t " .. vim.fn.shellescape(target_pane) .. " -p -S -10 2>/dev/null"
		)
		if vim.v.shell_error ~= 0 then
			return false
		end
		local normalized = string.lower(output)
		for _, pattern in ipairs(confirm_patterns) do
			if string.find(normalized, pattern, 1, true) then
				return true
			end
		end
		return false
	end

	local function make_send_prompt(target_pane)
		return function()
			if not target_pane or target_pane == "" then
				return
			end
			local check = vim.fn.system(
				"tmux display-message -t " .. vim.fn.shellescape(target_pane) .. " -p '#{pane_id}' 2>/dev/null"
			)
			if vim.trim(check) == "" then
				print("AI pane closed before message sent")
				return
			end
			vim.fn.system(
				"tmux send-keys -t " .. vim.fn.shellescape(target_pane) .. " -l " .. vim.fn.shellescape(prompt)
			)
			send_submit_key(target_pane, 1)
			vim.defer_fn(function()
				if pane_needs_confirm(target_pane) then
					send_submit_key(target_pane, 1)
				end
			end, 150)
		end
	end

	if ensure_ai_pane() then
		vim.defer_fn(make_send_prompt(vim.g.ai_pane_id), 300)
		return "sent"
	end

	local pane_id = vim.fn.system(
		'tmux split-window -h -p 35 -d -P -F "#{pane_id}" -c '
			.. vim.fn.shellescape(vim.fn.getcwd())
			.. " '$SHELL -ic acc'"
	)
	pane_id = vim.trim(pane_id)
	if pane_id == "" then
		print("Failed to create tmux split")
		return "failed"
	end
	mark_ai_pane(pane_id, "acc")
	vim.g.ai_pane_id = pane_id
	vim.defer_fn(make_send_prompt(pane_id), 2500)
	return "started"
end

-- Quick scoped message: sends to existing AI pane, or opens cc in background
vim.keymap.set("n", "<leader>cv", function()
	local file = vim.fn.expand("%:p")
	local line = vim.fn.line(".")
	local message = vim.fn.input("LLM Message: ")
	if message == "" then
		return
	end

	print_send_status(send_scoped_message(file .. ":" .. line, message), message)
end, { desc = "LLM scoped message (detached)" })

-- Visual mode: scoped message with line range
vim.keymap.set("v", "<leader>cv", function()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local file = vim.fn.expand("%:p")
	local range = format_range(start_line, end_line)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

	vim.schedule(function()
		local message = vim.fn.input("LLM Message: ")
		if message == "" then
			return
		end
		print_send_status(send_scoped_message(file .. ":" .. range, message), message)
	end)
end, { desc = "LLM scoped message with selection (detached)" })
