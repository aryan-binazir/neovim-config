-- Herdr pane hosting an interactive AI tool. A unique pane label ties the pane
-- to this Neovim pane so it can be recovered after Neovim restarts.
local M = {}

local source_pane_id = vim.env.HERDR_PANE_ID
local source_workspace_id = vim.env.HERDR_WORKSPACE_ID
local source_tab_id = vim.env.HERDR_TAB_ID
local pane_id = nil
local pane_tool = nil

local function marker_prefix()
	if not source_pane_id then
		return nil
	end
	return "nvim-ai-" .. source_pane_id:gsub("[^%w_-]", "-") .. "-"
end

local function marker_label(name)
	return marker_prefix() .. name
end

local function run(args, input)
	local out
	if input == nil then
		out = vim.fn.system(args)
	else
		out = vim.fn.system(args, input)
	end
	return vim.v.shell_error == 0, vim.trim(out)
end

local function run_json(args)
	local ok, out = run(args)
	if not ok then
		return nil, out
	end

	local decoded, payload = pcall(vim.json.decode, out)
	if not decoded or type(payload) ~= "table" then
		return nil, "invalid JSON from Herdr: " .. out
	end
	return payload, nil
end

local function pane_alive()
	if not pane_id then
		return false
	end

	local payload = run_json({ "herdr", "pane", "get", pane_id })
	local alive = payload and payload.result and payload.result.pane and payload.result.pane.pane_id == pane_id
	if not alive then
		pane_id = nil
		pane_tool = nil
	end
	return alive
end

local function close_pane()
	if not pane_id then
		return
	end

	local target = pane_id
	local ok, out = run({ "herdr", "pane", "close", target })
	pane_id = nil
	pane_tool = nil
	if ok then
		vim.notify("AI pane closed", vim.log.levels.INFO)
	else
		vim.notify("Failed to close AI pane: " .. out, vim.log.levels.ERROR)
	end
end

local function find_marked_pane()
	if not source_pane_id or not source_workspace_id or not source_tab_id then
		return nil
	end
	local prefix = marker_prefix()

	local payload = run_json({ "herdr", "pane", "list", "--workspace", source_workspace_id })
	local panes = payload and payload.result and payload.result.panes
	if type(panes) ~= "table" then
		return nil
	end

	for _, candidate in ipairs(panes) do
		local label = candidate.label or ""
		if candidate.tab_id == source_tab_id and label:sub(1, #prefix) == prefix then
			return candidate.pane_id, label:sub(#prefix + 1)
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
	if vim.fn.executable("herdr") ~= 1 then
		vim.notify("Herdr not available", vim.log.levels.ERROR)
		return false
	end
	if not source_pane_id or not source_workspace_id or not source_tab_id then
		vim.notify("Missing Herdr pane context", vim.log.levels.ERROR)
		return false
	end

	local payload, err = run_json({
		"herdr",
		"pane",
		"split",
		"--pane",
		source_pane_id,
		"--direction",
		"right",
		"--ratio",
		"0.35",
		"--cwd",
		vim.fn.getcwd(),
		"--focus",
	})
	local created = payload and payload.result and payload.result.pane and payload.result.pane.pane_id
	if type(created) ~= "string" or created == "" then
		vim.notify("Failed to create Herdr split: " .. (err or "invalid response"), vim.log.levels.ERROR)
		return false
	end

	pane_id = created
	pane_tool = name
	local marked, mark_err = run({ "herdr", "pane", "rename", created, marker_label(name) })
	if not marked then
		vim.notify("AI pane opened but could not be marked for recovery: " .. mark_err, vim.log.levels.WARN)
	end

	local started, start_err = run({ "herdr", "pane", "run", created, cmd })
	if not started then
		run({ "herdr", "pane", "close", created })
		pane_id = nil
		pane_tool = nil
		vim.notify("Failed to start " .. name .. " in Herdr pane: " .. start_err, vim.log.levels.ERROR)
		return false
	end

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

	local timer = vim.uv.new_timer()
	local started = vim.uv.hrtime()
	local finished = false

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
			if pane_id ~= target then
				finish(false)
				return
			end

			local payload = run_json({ "herdr", "agent", "get", target })
			local agent = payload and payload.result and payload.result.agent
			if agent and agent.pane_id == target then
				finish(true)
				return
			end

			if (vim.uv.hrtime() - started) / 1000000 >= timeout_ms then
				finish(false)
			end
		end)
	)
end

local function focus_pane(target)
	run({ "herdr", "agent", "focus", target })
end

function M.send(text, focus)
	if not pane_alive() then
		return
	end

	local target = pane_id
	local ok, out = run({ "herdr", "pane", "send-text", target, text })
	if not ok then
		vim.notify("Failed to send to AI pane: " .. out, vim.log.levels.ERROR)
		return
	end
	if focus then
		focus_pane(target)
	end
end

function M.send_block(text, focus)
	M.send(text, focus)
end

return M
