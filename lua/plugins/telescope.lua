return {
	"nvim-telescope/telescope.nvim",
	version = false,
	cmd = "Telescope",
	keys = {
		{ "<leader>u", "<cmd>Telescope undo<cr>", desc = "telescope undo" },
		{
			"<leader>?",
			function()
				require("telescope.builtin").oldfiles()
			end,
			desc = "find recently opened files",
		},
		{
			"<leader><space>",
			function()
				require("telescope.builtin").buffers()
			end,
			desc = "find existing buffers",
		},
		{
			"<leader>/",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end,
			desc = "fuzzily search in current buffer",
		},
		{
			"<leader>s/",
			function()
				require("telescope.builtin").live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end,
			desc = "search in open files",
		},
		{
			"<leader>sr",
			function()
				require("telescope.builtin").resume()
			end,
			desc = "search resume",
		},
		{
			"<leader>sh",
			function()
				require("telescope.builtin").help_tags()
			end,
			desc = "search help",
		},
		{
			"<leader>sw",
			function()
				require("telescope.builtin").grep_string()
			end,
			desc = "search current word",
		},
		{
			"<leader>sd",
			function()
				require("telescope.builtin").diagnostics()
			end,
			desc = "search diagnostics",
		},
		{
			"<leader>sq",
			function()
				require("telescope.builtin").quickfix()
			end,
			desc = "search quickfix",
		},
		{
			"<C-f>",
			function()
				require("telescope.builtin").live_grep()
			end,
			desc = "search by grep c-f",
		},
		{
			"<C-p>",
			function()
				require("telescope.builtin").find_files({
					hidden = true,
					find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
				})
			end,
			desc = "search files c-p",
		},
		{
			"<leader>gs",
			function()
				require("telescope.builtin").git_status()
			end,
			desc = "git status",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"debugloop/telescope-undo.nvim",
			config = function()
				require("telescope").load_extension("undo")
			end,
		},
		"nvim-telescope/telescope-ui-select.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				debounce = 100,
				mappings = {
					i = {
						["<C-u>"] = false,
						["<C-d>"] = false,
						["<C-p>"] = require("telescope.actions.layout").toggle_preview,
						["<C-o>"] = require("telescope.actions").send_to_loclist
							+ require("telescope.actions").open_loclist,
					},

					n = {
						["<C-o>"] = require("telescope.actions").send_selected_to_loclist
							+ require("telescope.actions").open_loclist,
					},
				},
				file_ignore_patterns = {
					"node_modules",
					".git/",
				},
				layout_config = {
					horizontal = {
						width = 0.99,
						height = 0.99,
						preview_cutoff = 0,
						preview_width = 0.6,
					},
				},
				preview = {
					treesitter = false,
					hide_on_startup = false,
				},
			},
			pickers = {
				buffers = {
					sort_lastused = true,
					sort_mru = true,
					mappings = {
						i = {
							["<c-d>"] = "delete_buffer",
						},
					},
				},
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
				undo = {},
			},
		})

		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "ui-select")
	end,
}
