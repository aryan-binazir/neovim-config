local M = {}

function M.setup(opts)
	local config = require("ai.config").resolve(opts)
	require("ai.jobs").setup(config)
	vim.g.ai_cursor_cmd = config.cursor_cmd
	require("ai.keymaps")
end

function M.statusline_component()
	return require("ai.jobs").statusline_component()
end

return M
