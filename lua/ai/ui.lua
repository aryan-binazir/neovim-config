-- Floating job list and log viewer for ai.jobs.
local jobs = require("ai.jobs")

local M = {}
local log_missing_warned = {}

-- state is nil while closed; fields: buf, win, mode ("list"|"log"),
-- viewing_id (job whose log is shown), cursor_job (one-shot row preference),
-- line_to_job (list row -> job id), log_key (skip re-render of unchanged log),
-- timer (1s refresh)
local state = nil

local function find_job(id)
	for _, job in ipairs(jobs.list()) do
		if job.id == id then
			return job
		end
	end
	return nil
end

local function close()
	if not state then
		return
	end
	if state.timer then
		state.timer:stop()
		state.timer:close()
	end
	local win = state.win
	state = nil
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function set_lines(buf, lines)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

local function window_config()
	local max_width = math.max(1, vim.o.columns - 4)
	local max_height = math.max(1, vim.o.lines - 4)
	local width = math.min(120, max_width, math.max(1, math.floor(vim.o.columns * 0.8)))
	local height = math.min(24, max_height, math.max(1, math.floor(vim.o.lines * 0.55)))
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		style = "minimal",
		border = "single",
		title = " LLM jobs ",
		title_pos = "center",
	}
end

local function readable_log(job)
	if vim.fn.filereadable(job.log_path) == 1 then
		return true
	end
	if not log_missing_warned[job.id] then
		log_missing_warned[job.id] = true
		vim.notify("No log found for job #" .. job.id, vim.log.levels.WARN)
	end
	return false
end

local function render_list()
	if not state or state.mode ~= "list" or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end
	local win_valid = state.win and vim.api.nvim_win_is_valid(state.win)

	local cursor_job = state.cursor_job
	state.cursor_job = nil
	if not cursor_job and win_valid then
		local row = vim.api.nvim_win_get_cursor(state.win)[1]
		cursor_job = state.line_to_job and state.line_to_job[row]
	end

	local lines = {
		"LLM jobs",
		"",
		"  <CR> log   d kill   r refresh   q close",
		"",
	}
	local line_to_job = {}
	local all = jobs.list()
	if #all == 0 then
		table.insert(lines, "  No LLM jobs yet")
	else
		for i = #all, 1, -1 do
			line_to_job[#lines + 1] = all[i].id
			table.insert(lines, "  " .. jobs.label(all[i]))
		end
	end
	state.line_to_job = line_to_job
	set_lines(state.buf, lines)

	if win_valid then
		local target = nil
		for row, id in pairs(line_to_job) do
			if id == cursor_job then
				target = row
				break
			end
		end
		target = target or vim.api.nvim_win_get_cursor(state.win)[1]
		target = math.max(1, math.min(target, vim.api.nvim_buf_line_count(state.buf)))
		vim.api.nvim_win_set_cursor(state.win, { target, 0 })
	end
end

local function render_log()
	if not state or state.mode ~= "log" or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end
	local job = find_job(state.viewing_id)
	if not job or not readable_log(job) then
		return
	end
	local stat = vim.uv.fs_stat(job.log_path)
	if not stat then
		return
	end
	local mtime = stat.mtime and (tostring(stat.mtime.sec) .. "." .. tostring(stat.mtime.nsec or 0)) or ""
	local key = job.log_path .. "|" .. stat.size .. "|" .. mtime
	if state.log_key == key then
		return
	end
	state.log_key = key

	local win_valid = state.win and vim.api.nvim_win_is_valid(state.win)
	local cursor_row, was_at_bottom = 1, true
	if win_valid then
		cursor_row = vim.api.nvim_win_get_cursor(state.win)[1]
		was_at_bottom = cursor_row >= vim.api.nvim_buf_line_count(state.buf) - 2
	end

	local lines = {
		"LLM job #" .. job.id .. " log",
		"q close   <Esc> jobs",
		"",
	}
	vim.list_extend(lines, vim.fn.readfile(job.log_path))
	set_lines(state.buf, lines)

	if win_valid then
		local max_row = math.max(1, vim.api.nvim_buf_line_count(state.buf))
		local target_row = was_at_bottom and max_row or math.min(cursor_row, max_row)
		vim.api.nvim_win_set_cursor(state.win, { target_row, 0 })
	end
end

local function refresh()
	if state and state.mode == "log" then
		render_log()
	else
		render_list()
	end
end

local function selected_job()
	if not state or state.mode ~= "list" then
		return nil
	end
	local row = vim.api.nvim_win_get_cursor(state.win)[1]
	local id = state.line_to_job and state.line_to_job[row]
	return id and find_job(id) or nil
end

local function open_log(job)
	if not job or not state or not readable_log(job) then
		return
	end
	state.mode = "log"
	state.viewing_id = job.id
	state.log_key = nil
	render_log()
end

local function back_to_list()
	if not state or state.mode ~= "log" then
		return
	end
	state.mode = "list"
	state.log_key = nil
	state.cursor_job = state.viewing_id
	render_list()
end

function M.open_list()
	if state and state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_set_current_win(state.win)
	else
		close()
		local buf = vim.api.nvim_create_buf(false, true)
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "wipe"
		vim.bo[buf].swapfile = false
		vim.bo[buf].filetype = "llm-jobs"
		local win = vim.api.nvim_open_win(buf, true, window_config())
		vim.wo[win].wrap = false
		vim.wo[win].cursorline = true
		state = { buf = buf, win = win }

		local opts = { buffer = buf, silent = true, nowait = true }
		vim.keymap.set("n", "q", close, opts)
		vim.keymap.set("n", "<Esc>", back_to_list, opts)
		vim.keymap.set("n", "r", refresh, opts)
		vim.keymap.set("n", "<CR>", function()
			open_log(selected_job())
		end, opts)
		vim.keymap.set("n", "d", function()
			jobs.cancel(selected_job())
		end, opts)
		vim.api.nvim_create_autocmd("BufWipeout", {
			buffer = buf,
			once = true,
			callback = function()
				if state and state.buf == buf then
					close()
				end
			end,
		})

		local owner = state
		owner.timer = vim.uv.new_timer()
		owner.timer:start(
			0,
			1000,
			vim.schedule_wrap(function()
				if state ~= owner then
					return
				end
				if not state or not vim.api.nvim_buf_is_valid(buf) then
					close()
					return
				end
				refresh()
			end)
		)
	end

	state.mode = "list"
	state.log_key = nil
	local all = jobs.list()
	state.cursor_job = #all > 0 and all[#all].id or nil
	render_list()
end

jobs.on_change = refresh

return M
