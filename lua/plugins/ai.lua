return {
	{
		"coder/claudecode.nvim",
		enabled = vim.g.claudecode_enabled ~= false,
		event = "VeryLazy",
		opts = {
			terminal = {
				provider = "none", -- no UI actions; server + tools remain available
			},
		},
	},
}
