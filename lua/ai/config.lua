local M = {}

local defaults = {
	tool = "codex",
	timeout_ms = 15 * 60 * 1000,
	cursor_cmd = "cursor-agent --force",
}

local function optional_table(value, name)
	if value == nil then
		return nil
	end
	if type(value) ~= "table" then
		error(name .. " must be a table")
	end
	return value
end

function M.resolve(opts)
	opts = optional_table(opts, "ai.setup opts") or optional_table(vim.g.ai, "vim.g.ai") or {}
	local config = {
		tool = opts.tool or vim.g.cf_tool or defaults.tool,
		timeout_ms = opts.timeout_ms or vim.g.cf_timeout_ms or defaults.timeout_ms,
		cursor_cmd = opts.cursor_cmd or defaults.cursor_cmd,
	}

	if config.tool ~= "codex" and config.tool ~= "claude" then
		error('invalid value for config.tool: ' .. tostring(config.tool) .. ' (expected "codex" or "claude")')
	end
	if type(config.timeout_ms) ~= "number" then
		error("invalid value for config.timeout_ms: " .. tostring(config.timeout_ms) .. " (expected number)")
	end
	if type(config.cursor_cmd) ~= "string" or config.cursor_cmd == "" then
		error("invalid value for config.cursor_cmd: " .. tostring(config.cursor_cmd) .. " (expected non-empty string)")
	end

	return config
end

return M
