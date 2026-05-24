return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		triggers = {
			{ "<leader>", mode = { "n", "v" } },
		},
		spec = {
			{ "<leader>c", group = "AI" },
			{ "<leader>y", group = "Yank" },
			{ "<leader>s", group = "Search" },
			{ "<leader>t", group = "Toggle" },
			{ "<leader>h", group = "Git hunks" },
			{ "<leader>w", group = "Workspace" },
			{ "<leader>d", group = "Diagnostics" },
			{ "<leader>f", group = "Treesitter movement" },
		},
	},
}
