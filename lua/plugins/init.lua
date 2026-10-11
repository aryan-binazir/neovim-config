return {
	-- Git related plugins
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "lazygit" },
			{ "<leader>lc", "<cmd>LazyGitCurrentFile<cr>", desc = "lazygit current file" },
		},
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "lazygit",
				callback = function()
					vim.keymap.set("n", "q", ":q<CR>", { buffer = true, silent = true })
				end,
			})
		end,
	},

	-- Surround plugin
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},

	-- Theme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				color_overrides = {
					mocha = {
						base = "#000000",
						mantle = "#000000",
						crust = "#000000",
					},
				},
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},

	-- UI enhancements
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = {
				icons_enabled = true,
				globalstatus = true,
				theme = "codedark",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				refresh = {
					refresh_time = 100,
					statusline = 10000,
					events = {
						"WinEnter",
						"BufEnter",
						"BufWritePost",
						"SessionLoadPost",
						"FileChangedShellPost",
						"VimResized",
						"Filetype",
						"CursorMoved",
						"CursorMovedI",
						"ModeChanged",
						"DiagnosticChanged",
						"User",
					},
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					"branch",
					{
						"diff",
						source = function()
							local counts = vim.b.gitsigns_status_dict
							if counts then
								return { added = counts.added, modified = counts.changed, removed = counts.removed }
							end
						end,
					},
					"diagnostics",
				},
				lualine_c = { "filename" },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	-- Indentation guides
	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPost", "BufNewFile" },
		main = "ibl",
		opts = {},
	},
}
