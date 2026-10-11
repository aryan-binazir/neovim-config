local M = {}

function M.setup(opts)
	local config = require("ai.config").resolve(opts)
	require("ai.keymaps").setup(config)
end

return M
