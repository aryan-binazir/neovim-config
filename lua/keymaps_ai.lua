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

local cf_tool = vim.g.cf_tool or "codex" -- "codex" | "claude"
if cf_tool ~= "codex" and cf_tool ~= "claude" then
	cf_tool = "codex"
end
local cf_timeout_ms = 15 * 60 * 1000
local cf_log_dir = vim.fn.stdpath("cache") .. "/llm-exec"
local cf_jobs_dir = cf_log_dir .. "/jobs"
local cf_jobs = {}
local cf_next_job_id = 1
local cf_max_jobs = 50
local cf_max_log_files = 100
local cf_list_state = nil

local function cf_location_label(file, range)
	return (file .. ":" .. range):gsub("%c", " ")
end

local function cf_prompt(location, snippet, message)
	return table.concat({
		"You are running as a one-shot editor task from Neovim.",
		"",
		"Read the given location first, then make the smallest useful change that satisfies the request.",
		"Prefer editing the given location or its immediate surrounding code when that is enough.",
		"If the request requires edits elsewhere, make the necessary edits.",
		"Before writing, re-read the relevant file area from disk so your edit is based on the latest contents.",
		"",
		"If you edit files outside the given location, add a brief note near the originally given location explaining:",
		"- which other files you touched",
		"- why those edits were necessary",
		"",
		"Avoid unrelated refactors, broad cleanup, or formatting-only churn.",
		"Do not ask follow-up questions.",
		"Stop when the requested change is complete.",
		"",
		"Location: " .. location,
		"",
		"Source snippet:",
		snippet,
		"",
		"Request: " .. message,
	}, "\n")
end

local function cf_repo_root(file)
	local dir = vim.fs.dirname(file)
	return vim.fs.root(dir, ".git") or dir or vim.fn.getcwd()
end

local function cf_command(tool, repo_root, prompt)
	if tool == "codex" then
		return {
			"codex",
			"--ask-for-approval",
			"never",
			"exec",
			"--cd",
			repo_root,
			"--sandbox",
			"workspace-write",
			"--color",
			"never",
			prompt,
		}
	end
	if tool == "claude" then
		return {
			"claude",
			"-p",
			"--permission-mode",
			"bypassPermissions",
			prompt,
		}
	end
	return nil, "Unknown cf_tool: " .. tostring(tool)
end

local function cf_set_progress(job, status, message, percent)
	local opts = {
		kind = "progress",
		source = "nvim",
		status = status,
		title = job.title,
		percent = percent,
	}
	if job.progress_id then
		opts.id = job.progress_id
	end
	job.progress_id = vim.api.nvim_echo({ { message } }, false, opts)
end

local function cf_append_lines(lines, text)
	if not text or text == "" then
		table.insert(lines, "(empty)")
		return
	end
	for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
		table.insert(lines, line)
	end
end

local function cf_slug(text)
	local slug = text:gsub("[^%w._-]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
	if slug == "" then
		return "job"
	end
	return slug:sub(1, 80)
end

local function cf_job_log_path(id, location)
	local stamp = os.date("%Y%m%d-%H%M%S")
	return string.format("%s/%04d-%s-%s.log", cf_jobs_dir, id, stamp, cf_slug(location))
end

local function cf_prune_jobs()
	while #cf_jobs > cf_max_jobs do
		local removed = false
		for i, job in ipairs(cf_jobs) do
			if job.status ~= "running" and job.status ~= "cancelling" then
				table.remove(cf_jobs, i)
				removed = true
				break
			end
		end
		if not removed then
			return
		end
	end
end

local function cf_find_job(id)
	for _, job in ipairs(cf_jobs) do
		if job.id == id then
			return job
		end
	end
	return nil
end

local function cf_latest_job()
	return cf_jobs[#cf_jobs]
end

local function cf_prune_log_files()
	local active_logs = {}
	for _, job in ipairs(cf_jobs) do
		if job.status == "running" or job.status == "cancelling" then
			active_logs[job.log_path] = true
		end
	end
	if cf_list_state and cf_list_state.mode == "log" and cf_list_state.selected_job_id then
		local viewed_job = cf_find_job(cf_list_state.selected_job_id)
		if viewed_job then
			active_logs[viewed_job.log_path] = true
		end
	end

	local files = vim.fn.globpath(cf_jobs_dir, "*.log", false, true)
	table.sort(files, function(a, b)
		return vim.fn.getftime(a) < vim.fn.getftime(b)
	end)

	local i = 1
	while #files > cf_max_log_files and i <= #files do
		local path = files[i]
		if active_logs[path] then
			i = i + 1
		else
			vim.fn.delete(path)
			table.remove(files, i)
		end
	end
end

local function cf_start_log(job)
	vim.fn.mkdir(cf_jobs_dir, "p")

	local command = vim.deepcopy(job.cmd)
	command[#command] = "[prompt]"
	local lines = {
		"Job: " .. job.id,
		"Tool: " .. job.tool,
		"Repo: " .. job.repo_root,
		"Location: " .. job.location,
		"Started: " .. job.started_at,
		"Command: " .. table.concat(command, " "),
		"",
		"Prompt:",
	}
	cf_append_lines(lines, job.prompt)
	table.insert(lines, "")
	table.insert(lines, "Output:")

	vim.fn.writefile(lines, job.log_path)
	cf_prune_log_files()
end

local function cf_append_log(job, stream, data)
	if not data or data == "" then
		return
	end
	vim.schedule(function()
		if vim.fn.filereadable(job.log_path) == 1 then
			vim.fn.writefile({ "", "[" .. stream .. "]", data }, job.log_path, "a")
		end
	end)
end

local function cf_finish_log(job, result)
	local lines = {
		"",
		"Finished: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"Timed out: " .. tostring(result.code == 124),
		"Exit code: " .. tostring(result.code),
		"Signal: " .. tostring(result.signal),
	}
	vim.fn.writefile(lines, job.log_path, "a")
end

local function cf_format_elapsed(job)
	local stop = job.finished_at_ts or os.time()
	local elapsed = math.max(0, stop - job.started_at_ts)
	local minutes = math.floor(elapsed / 60)
	local seconds = elapsed % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function cf_job_label(job)
	return string.format(
		"#%-3d %-10s %-6s %s %s",
		job.id,
		job.status,
		job.tool,
		cf_format_elapsed(job),
		job.location
	)
end

local function cf_close_list()
	if not cf_list_state then
		return
	end
	if cf_list_state.timer then
		cf_list_state.timer:stop()
		cf_list_state.timer:close()
	end
	local win = cf_list_state.win
	cf_list_state = nil
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function cf_list_buf()
	if cf_list_state and vim.api.nvim_buf_is_valid(cf_list_state.buf) then
		return cf_list_state.buf
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "llm-jobs"
	return buf
end

local cf_render_list
local cf_render_log
local cf_open_job_log
local cf_refresh_current

local function cf_cancel_job(job)
	if not job then
		return
	end
	if job.status ~= "running" and job.status ~= "cancelling" then
		vim.notify("LLM job is not running")
		return
	end
	job.cancel_requested = true
	job.status = "cancelling"
	if job.handle then
		job.handle:kill(15)
	end
	cf_set_progress(job, "running", job.tool .. " cancelling: " .. job.location, nil)
	vim.notify(job.tool .. " cancelling job #" .. job.id, vim.log.levels.WARN)
	if cf_render_list then
		cf_render_list()
	end
end

local function cf_selected_job()
	if not cf_list_state or cf_list_state.mode ~= "list" then
		return nil
	end
	local row = vim.api.nvim_win_get_cursor(cf_list_state.win)[1]
	local id = cf_list_state.line_to_job and cf_list_state.line_to_job[row]
	return id and cf_find_job(id) or nil
end

local function cf_set_lines(buf, lines)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

cf_render_list = function()
	if not cf_list_state or not vim.api.nvim_buf_is_valid(cf_list_state.buf) then
		return
	end
	if cf_list_state.mode ~= "list" then
		return
	end

	local selected_id = cf_list_state.selected_job_id
	local current_row = nil
	local row_job_id = nil
	if cf_list_state.win and vim.api.nvim_win_is_valid(cf_list_state.win) then
		current_row = vim.api.nvim_win_get_cursor(cf_list_state.win)[1]
		row_job_id = cf_list_state.line_to_job and cf_list_state.line_to_job[current_row]
		if row_job_id then
			selected_id = row_job_id
			cf_list_state.selected_job_id = row_job_id
		end
	end

	local lines = {
		"LLM jobs",
		"",
		"  <CR> log   d kill   r refresh   q close",
		"",
	}
	local line_to_job = {}
	if #cf_jobs == 0 then
		table.insert(lines, "  No LLM jobs yet")
	else
		for i = #cf_jobs, 1, -1 do
			local job = cf_jobs[i]
			line_to_job[#lines + 1] = job.id
			table.insert(lines, "  " .. cf_job_label(job))
		end
	end

	cf_list_state.line_to_job = line_to_job
	cf_set_lines(cf_list_state.buf, lines)

	local target_row = current_row or 5
	if selected_id and (not current_row or row_job_id or not line_to_job[target_row]) then
		for row, id in pairs(line_to_job) do
			if id == selected_id then
				target_row = row
				break
			end
		end
	elseif not line_to_job[target_row] then
		for row = 1, #lines do
			if line_to_job[row] then
				target_row = row
				break
			end
		end
	end
	if cf_list_state.win and vim.api.nvim_win_is_valid(cf_list_state.win) then
		local max_row = math.max(1, vim.api.nvim_buf_line_count(cf_list_state.buf))
		target_row = math.min(target_row, max_row)
		vim.api.nvim_win_set_cursor(cf_list_state.win, { target_row, 0 })
	end
end

cf_open_job_log = function(job)
	if not job then
		return
	end
	if vim.fn.filereadable(job.log_path) ~= 1 then
		if not job.log_missing_warned then
			job.log_missing_warned = true
			vim.notify("No log found for job #" .. job.id, vim.log.levels.WARN)
		end
		return
	end
	if not cf_list_state then
		return
	end
	cf_list_state.mode = "log"
	cf_list_state.selected_job_id = job.id
	cf_list_state.log_cache = nil
	cf_render_log()
end

local function cf_log_header(job)
	return {
		"LLM job #" .. job.id .. " log",
		"q/<Esc> back to jobs",
		"",
	}
end

local function cf_log_mtime(stat)
	if not stat or not stat.mtime then
		return ""
	end
	return tostring(stat.mtime.sec) .. "." .. tostring(stat.mtime.nsec or 0)
end

local function cf_read_log_delta(path, offset)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	file:seek("set", offset)
	local data = file:read("*a")
	file:close()
	return data
end

local function cf_append_log_lines(buf, text)
	if not text or text == "" then
		return
	end
	local lines = vim.split(text, "\n", { plain = true })
	if lines[#lines] == "" then
		table.remove(lines)
	end
	if #lines == 0 then
		return
	end
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
	vim.bo[buf].modifiable = false
end

cf_render_log = function()
	if not cf_list_state or cf_list_state.mode ~= "log" then
		return
	end
	local job = cf_find_job(cf_list_state.selected_job_id)
	if not job then
		return
	end
	if vim.fn.filereadable(job.log_path) ~= 1 then
		if not job.log_missing_warned then
			job.log_missing_warned = true
			vim.notify("No log found for job #" .. job.id, vim.log.levels.WARN)
		end
		return
	end
	local stat = vim.uv.fs_stat(job.log_path)
	if not stat then
		return
	end
	local cursor_row = 1
	local was_at_bottom = true
	if cf_list_state.win and vim.api.nvim_win_is_valid(cf_list_state.win) then
		cursor_row = vim.api.nvim_win_get_cursor(cf_list_state.win)[1]
		was_at_bottom = cursor_row >= vim.api.nvim_buf_line_count(cf_list_state.buf) - 2
	end
	local mtime = cf_log_mtime(stat)
	local cache = cf_list_state.log_cache
	local can_append = cache
		and cache.job_id == job.id
		and cache.path == job.log_path
		and stat.size >= cache.size
		and vim.api.nvim_buf_is_valid(cf_list_state.buf)

	if can_append and stat.size == cache.size and mtime == cache.mtime then
		return
	end

	if can_append then
		local delta = cf_read_log_delta(job.log_path, cache.size)
		cf_append_log_lines(cf_list_state.buf, delta)
	else
		local lines = cf_log_header(job)
		vim.list_extend(lines, vim.fn.readfile(job.log_path))
		cf_set_lines(cf_list_state.buf, lines)
	end
	cf_list_state.log_cache = {
		job_id = job.id,
		path = job.log_path,
		size = stat.size,
		mtime = mtime,
	}
	if cf_list_state.win and vim.api.nvim_win_is_valid(cf_list_state.win) then
		local max_row = math.max(1, vim.api.nvim_buf_line_count(cf_list_state.buf))
		local target_row = was_at_bottom and max_row or math.min(cursor_row, max_row)
		vim.api.nvim_win_set_cursor(cf_list_state.win, { target_row, 0 })
	end
end

cf_refresh_current = function()
	if cf_list_state and cf_list_state.mode == "log" then
		cf_render_log()
	else
		cf_render_list()
	end
end

local function cf_back_or_close()
	if not cf_list_state then
		return
	end
	if cf_list_state.mode == "log" then
		cf_list_state.mode = "list"
		cf_list_state.log_cache = nil
		cf_render_list()
		return
	end
	cf_close_list()
end

local function cf_open_list()
	local buf = cf_list_buf()
	local width = math.min(120, math.max(72, math.floor(vim.o.columns * 0.8)))
	local height = math.min(24, math.max(12, math.floor(vim.o.lines * 0.55)))
	local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
	local col = math.max(0, math.floor((vim.o.columns - width) / 2))
	local win
	if cf_list_state and cf_list_state.win and vim.api.nvim_win_is_valid(cf_list_state.win) then
		win = cf_list_state.win
		vim.api.nvim_set_current_win(win)
	else
		win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "single",
			title = " LLM jobs ",
			title_pos = "center",
		})
	end
	vim.wo[win].wrap = false
	vim.wo[win].cursorline = true
	cf_list_state = cf_list_state or {}
	cf_list_state.buf = buf
	cf_list_state.win = win
	cf_list_state.mode = "list"
	cf_list_state.selected_job_id = cf_list_state.selected_job_id or (cf_latest_job() and cf_latest_job().id) or nil

	if not vim.b[buf].llm_job_list_mapped then
		vim.b[buf].llm_job_list_mapped = true
		local opts = { buffer = buf, silent = true, nowait = true }
		vim.keymap.set("n", "q", cf_back_or_close, opts)
		vim.keymap.set("n", "<Esc>", cf_back_or_close, opts)
		vim.keymap.set("n", "r", cf_refresh_current, opts)
		vim.keymap.set("n", "<CR>", function()
			cf_open_job_log(cf_selected_job())
		end, opts)
		vim.keymap.set("n", "d", function()
			cf_cancel_job(cf_selected_job())
		end, opts)
		vim.api.nvim_create_autocmd("BufWipeout", {
			buffer = buf,
			once = true,
			callback = function()
				if cf_list_state and cf_list_state.buf == buf then
					cf_close_list()
				end
			end,
		})
	end
	if not cf_list_state.timer then
		cf_list_state.timer = vim.uv.new_timer()
		cf_list_state.timer:start(
			0,
			1000,
			vim.schedule_wrap(function()
				if not cf_list_state or not vim.api.nvim_buf_is_valid(buf) then
					return
				end
				cf_refresh_current()
			end)
		)
	end
	cf_render_list()
end

local function cf_write_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false, "Current buffer is no longer valid"
	end
	local file = vim.api.nvim_buf_get_name(bufnr)
	if file == "" then
		return false, "Current buffer has no file name"
	end
	if vim.bo[bufnr].buftype ~= "" then
		return false, "Current buffer is not a normal file"
	end
	if not vim.bo[bufnr].modified then
		return true, nil
	end
	local ok, err = pcall(function()
		vim.api.nvim_buf_call(bufnr, function()
			vim.cmd("silent write")
		end)
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, nil
end

local function cf_run(location, snippet, message, bufnr)
	local ok, err = cf_write_buffer(bufnr)
	if not ok then
		vim.notify("LLM exec not started: " .. err, vim.log.levels.ERROR)
		return
	end

	local file = vim.api.nvim_buf_get_name(bufnr)
	local repo_root = cf_repo_root(file)
	local prompt = cf_prompt(location, snippet, message)
	local cmd, cmd_err = cf_command(cf_tool, repo_root, prompt)
	if not cmd then
		vim.notify(cmd_err, vim.log.levels.ERROR)
		return
	end

	local job_id = cf_next_job_id
	cf_next_job_id = cf_next_job_id + 1
	local job = {
		id = job_id,
		tool = cf_tool,
		title = "cf " .. cf_tool,
		status = "running",
		location = location,
		location_file = file,
		repo_root = repo_root,
		prompt = prompt,
		cmd = cmd,
		log_path = cf_job_log_path(job_id, location),
		started_at_ts = os.time(),
		started_at = os.date("%Y-%m-%d %H:%M:%S"),
	}
	table.insert(cf_jobs, job)
	cf_prune_jobs()
	cf_start_log(job)
	cf_set_progress(job, "running", job.tool .. " running: " .. location, nil)
	if cf_render_list then
		cf_render_list()
	end

	local ok_system, handle = pcall(vim.system, cmd, {
		cwd = repo_root,
		text = true,
		stdin = false,
		stdout = function(_, data)
			cf_append_log(job, "stdout", data)
		end,
		stderr = function(_, data)
			cf_append_log(job, "stderr", data)
		end,
		timeout = cf_timeout_ms,
	}, function(result)
		vim.schedule(function()
			job.finished_at_ts = os.time()
			job.exit_code = result.code
			job.signal = result.signal
			cf_finish_log(job, result)

			local status
			local progress_status = "failed"
			local notify_level = vim.log.levels.ERROR
			if job.cancel_requested and (result.code ~= 0 or (result.signal and result.signal ~= 0)) then
				status = "cancelled"
				job.status = "cancelled"
				progress_status = "cancel"
				notify_level = vim.log.levels.WARN
				job.cancelled = true
			elseif result.code == 124 then
				status = "timed out"
				job.status = "timed_out"
			elseif result.signal and result.signal ~= 0 then
				status = "killed"
				job.status = "killed"
			elseif result.code == 0 then
				job.status = "done"
				cf_set_progress(job, "success", job.tool .. " done: " .. location, 100)
				vim.notify(job.tool .. " done: " .. location)
				vim.cmd("checktime")
				if cf_render_list then
					cf_render_list()
				end
				return
			else
				status = "failed"
				job.status = "failed"
			end
			cf_set_progress(job, progress_status, job.tool .. " " .. status .. ": " .. location, 100)
			vim.notify(job.tool .. " " .. status .. "; use <leader>cl for jobs", notify_level)
			if cf_render_list then
				cf_render_list()
			end
		end)
	end)

	if not ok_system then
		job.status = "failed"
		job.finished_at_ts = os.time()
		vim.fn.writefile({
			"",
			"Finished: " .. os.date("%Y-%m-%d %H:%M:%S"),
			"Failed to start: " .. tostring(handle),
		}, job.log_path, "a")
		cf_set_progress(job, "failed", job.tool .. " failed to start", 100)
		vim.notify("Failed to start " .. job.tool .. ": " .. tostring(handle), vim.log.levels.ERROR)
		if cf_render_list then
			cf_render_list()
		end
		return
	end
	job.handle = handle
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

vim.keymap.set("n", "<leader>cl", cf_open_list, { desc = "Open LLM job list" })

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

	cf_run(cf_location_label(file, tostring(line)), snippet, message, bufnr)
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
		cf_run(cf_location_label(file, range), snippet, message, bufnr)
	end)
end, { desc = "Run scoped LLM fix with selection" })
