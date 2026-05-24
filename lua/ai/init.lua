local M = {}

function M.setup(opts)
	local config = require("ai.config").resolve(opts)
	require("ai.jobs").setup(config)
	require("ai.keymaps").setup()
	end

function M.statusline_component()
	return require("ai.jobs").statusline_component()
	end

	return M
