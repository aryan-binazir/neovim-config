-- Tmux pane hosting an interactive AI tool. The marker stores the tool name
-- so the pane can be recovered after nvim restarts.
local M = {}

local ai_pane_marker = "@nvim_ai_pane"
local pane_id = nil
local pane_tool = nil

local function pane_alive()
	if not pane_id then
		return false
	end
	local out = vim.fn.system({ "tmux", "display-message", "-t", pane_id, "-p", "#{pane_id}" })
	return vim.v.shell_error == 0 and vim.trim(out):match("^%%%d+$") ~= nil
end

local function set_pane_option(target, option, value)
	vim.fn.system({ "tmux", "set-option", "-p", "-t", target, option, value })
end

local function close_pane()
	if not pane_id then
		return
	end
	local out = vim.fn.system({ "tmux", "kill-pane", "-t", pane_id })
	local succeeded = vim.v.shell_error == 0
	pane_id = nil
	pane_tool = nil
	if succeeded then
		vim.notify("AI pane closed", vim.log.levels.INFO)
	else
		vim.notify("Failed to close AI pane: " .. vim.trim(out), vim.log.levels.ERROR)
	end
end

-- Find a pane this config marked, so it survives nvim closing and reopening.
local function find_marked_pane()
	local out = vim.fn.system({ "tmux", "list-panes", "-F", "#{pane_id}\t#{" .. ai_pane_marker .. "}" })
	if vim.v.shell_error ~= 0 then
		return nil
	end
	for _, line in ipairs(vim.split(vim.trim(out), "\n", { trimempty = true })) do
		local parts = vim.split(line, "\t", { plain = true })
		if parts[1] and parts[1]:match("^%%%d+$") and parts[2] and parts[2] ~= "" then
			return parts[1], parts[2]
		end
	end
	return nil
end

local function ensure_pane()
	if pane_alive() then
		return true
	end

	local existing, tool = find_marked_pane()
	if existing then
		pane_id = existing
		pane_tool = tool
		return true
	end

	return false
end

local function open_split(name, cmd)
	if vim.fn.executable("tmux") ~= 1 then
		vim.notify("tmux not available", vim.log.levels.ERROR)
		return false
	end
	local out = vim.fn.system({
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
	local created_pane_id = vim.trim(out)
	if vim.v.shell_error ~= 0 or not created_pane_id:match("^%%%d+$") then
		vim.notify("Failed to create tmux split: " .. created_pane_id, vim.log.levels.ERROR)
		return false
	end
	set_pane_option(created_pane_id, ai_pane_marker, name)
	vim.fn.system({ "tmux", "select-pane", "-t", created_pane_id, "-T", name })
	pane_id = created_pane_id
	pane_tool = name
	return true
end

function M.toggle(name, cmd)
	if ensure_pane() then
		if pane_tool ~= name then
			close_pane()
			open_split(name, cmd)
			return
		end
		close_pane()
		return
	end
	open_split(name, cmd)
end

function M.ensure_or_open(name, cmd)
	if ensure_pane() then
		return true, false
	end
	local ok = open_split(name, cmd)
	return ok, ok
end

function M.wait_ready(timeout_ms, callback)
	local target = pane_id
	if not target then
		callback(false)
		return
	end

	local shells = {
		sh = true,
		bash = true,
		zsh = true,
		fish = true,
		dash = true,
		nu = true,
		login = true,
		su = true,
		sudo = true,
		env = true,
		direnv = true,
	}
	local timer = vim.uv.new_timer()
	local started = vim.uv.hrtime()
	local finished = false
	local first_poll = true

	local function finish(ready)
		if finished then
			return
		end
		finished = true
		timer:stop()
		timer:close()
		callback(ready)
	end

	timer:start(
		0,
		250,
		vim.schedule_wrap(function()
			if finished then
				return
			end
			local command = vim.trim(vim.fn.system({
				"tmux",
				"display-message",
				"-p",
				"-t",
				target,
				"#{pane_current_command}",
			}))
			if first_poll then
				first_poll = false
				if command ~= "" and not shells[command] then
					finish(true)
					return
				end
			end
			if command ~= "" and not shells[command] then
				timer:stop()
				timer:start(
					1500,
					0,
					vim.schedule_wrap(function()
						if finished then
							return
						end
						finish(true)
					end)
				)
				return
			end
			if (vim.uv.hrtime() - started) / 1000000 >= timeout_ms then
				finish(false)
			end
		end)
	)
end

function M.send(text, focus)
	if not pane_id then
		return
	end
	vim.fn.system({ "tmux", "send-keys", "-t", pane_id, "-l", text })
	if focus then
		vim.fn.system({ "tmux", "select-pane", "-t", pane_id })
	end
end

function M.send_block(text, focus)
	if not pane_id then
		return
	end
	local buffer_name = "nvim_ai_" .. vim.fn.getpid()
	vim.fn.system({ "tmux", "load-buffer", "-b", buffer_name, "-" }, text)
	vim.fn.system({ "tmux", "paste-buffer", "-r", "-p", "-d", "-b", buffer_name, "-t", pane_id })
	if focus then
		vim.fn.system({ "tmux", "select-pane", "-t", pane_id })
	end
end

return M
