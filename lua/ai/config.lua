local M = {}

local defaults = {
	tool = "codex",
	timeout_ms = 15 * 60 * 1000,
}

function M.resolve(opts)
	opts = opts or vim.g.ai or {}
	local config = vim.tbl_deep_extend("force", defaults, opts)

	config.tool = opts.tool or vim.g.cf_tool or config.tool
	config.timeout_ms = opts.timeout_ms or vim.g.cf_timeout_ms or config.timeout_ms

	if config.tool ~= "codex" and config.tool ~= "claude" then
	error('vim.g.ai.tool must be "codex" or "claude"')
	end
	if type(config.timeout_ms) ~= "number" then
	error("vim.g.ai.timeout_ms must be a number")
	end

	return config
	end

	return M
