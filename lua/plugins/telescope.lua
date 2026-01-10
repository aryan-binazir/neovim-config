return {
	"nvim-telescope/telescope.nvim",
	version = false,
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

		-- Telescope keymaps
		vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>", { desc = "Telescope [U]ndo" })
		vim.keymap.set(
			"n",
			"<leader>?",
			require("telescope.builtin").oldfiles,
			{ desc = "[?] Find recently opened files" }
		)
		vim.keymap.set(
			"n",
			"<leader><space>",
			require("telescope.builtin").buffers,
			{ desc = "[ ] Find existing buffers" }
		)
		vim.keymap.set("n", "<leader>/", function()
			require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 10,
				previewer = false,
			}))
		end, { desc = "[/] Fuzzily search in current buffer" })
		vim.keymap.set("n", "<leader>s/", function()
			require("telescope.builtin").live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, { desc = "[S]earch [/] in Open Files" })
		vim.keymap.set("n", "<leader>sr", require("telescope.builtin").resume, { desc = "[S]earch [R]esume" })
		vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
		vim.keymap.set(
			"n",
			"<leader>sw",
			require("telescope.builtin").grep_string,
			{ desc = "[S]earch current [W]ord" }
		)
		vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
		vim.keymap.set("n", "<C-f>", require("telescope.builtin").live_grep, { desc = "Search by Grep C-f" })
		vim.keymap.set("n", "<C-p>", function()
			require("telescope.builtin").find_files({
				hidden = true,
				no_ignore = true,
				find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
			})
		end, { desc = "Search Files C-p" })
	end,
}
