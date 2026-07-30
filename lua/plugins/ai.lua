return {
	{
		"coder/claudecode.nvim",
		enabled = vim.g.claudecode_enabled ~= false,
		opts = {
			terminal = {
				provider = "none", -- no UI actions; server + tools remain available
			},
		},
	},
}
