local M = {}

function M.resolve(opts)
	if opts == nil then
		opts = {}
	elseif type(opts) ~= "table" then
		error("ai.setup opts must be a table")
	end
	local config = {
		tool = opts.tool,
		timeout_ms = opts.timeout_ms,
	}

	if config.tool ~= "codex" and config.tool ~= "claude" then
		error("invalid value for config.tool: " .. tostring(config.tool) .. ' (expected "codex" or "claude")')
	end
	if type(config.timeout_ms) ~= "number" then
		error("invalid value for config.timeout_ms: " .. tostring(config.timeout_ms) .. " (expected number)")
	end

	return config
end

return M
