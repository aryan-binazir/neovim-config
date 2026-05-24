local obsidian_path = vim.fn.expand(vim.g.obsidian_path or "")

return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	enabled = obsidian_path ~= "" and vim.fn.isdirectory(obsidian_path) == 1,
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = obsidian_path,
			},
		},
	},
}
