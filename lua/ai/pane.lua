-- Tmux pane hosting an interactive AI tool. One pane at a time, tracked by ID
-- and tool name via vim globals and a tmux pane option so it survives restarts.
local M = {}

vim.g.ai_pane_id = nil
vim.g.ai_pane_tool = nil
local ai_pane_marker = "@nvim_ai_pane"

local function pane_target()
	if not vim.g.ai_pane_id then
		return nil
	end
	return vim.fn.shellescape(vim.g.ai_pane_id)
end

local function pane_alive()
	local target = pane_target()
	if not target then
		return false
	end
	local check = vim.fn.system("tmux display-message -t " .. target .. " -p '#{pane_id}' 2>/dev/null")
	return vim.trim(check) ~= ""
end

local function set_pane_option(pane_id, option, value)
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

local function close_pane()
	local target = pane_target()
	if target then
		vim.fn.system("tmux kill-pane -t " .. target)
	end
	vim.g.ai_pane_id = nil
	vim.g.ai_pane_tool = nil
	print("AI pane closed")
end

-- Find a pane this config marked, so it survives nvim closing and reopening.
local function find_marked_pane()
	local out = vim.fn.system('tmux list-panes -F "#{pane_id}\t#{' .. ai_pane_marker .. '}" 2>/dev/null')
	if vim.v.shell_error ~= 0 then
		return nil
	end
	for _, line in ipairs(vim.split(vim.trim(out), "\n", { trimempty = true })) do
		local parts = vim.split(line, "\t", { plain = true })
		if parts[1] and parts[1] ~= "" and parts[2] and parts[2] ~= "" then
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
		vim.g.ai_pane_id = existing
		vim.g.ai_pane_tool = tool
		return true
	end

	return false
end

local function open_split(name, cmd)
	if vim.fn.executable("tmux") ~= 1 then
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
	set_pane_option(pane_id, ai_pane_marker, name)
	vim.fn.system({ "tmux", "select-pane", "-t", pane_id, "-T", name })
	vim.g.ai_pane_id = pane_id
	vim.g.ai_pane_tool = name
	return true
end

function M.toggle(name, cmd)
	if ensure_pane() then
		if vim.g.ai_pane_tool ~= name then
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
		return true
	end
	return open_split(name, cmd)
end

function M.send(text, focus)
	local target = pane_target()
	if not target then
		return
	end
	vim.fn.system("tmux send-keys -t " .. target .. " -l " .. vim.fn.shellescape(text))
	if focus then
		vim.fn.system("tmux select-pane -t " .. target)
	end
end

function M.send_block(text, focus)
	local target = pane_target()
	if not target then
		return
	end
	vim.fn.system({ "tmux", "load-buffer", "-b", "nvim_ai", "-" }, text)
	vim.fn.system("tmux paste-buffer -p -d -b nvim_ai -t " .. target)
	if focus then
		vim.fn.system("tmux select-pane -t " .. target)
	end
end

return M
