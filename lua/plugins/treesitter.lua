return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	dependencies = {
		"nvim-treesitter/nvim-treesitter-context",
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
		},
	},
	build = ":TSUpdate",
	config = function()
		local parsers = { "go", "lua", "python", "tsx", "javascript", "typescript", "bash", "pug", "html" }
		local configured_parsers = {}
		for _, parser in ipairs(parsers) do
			configured_parsers[parser] = true
		end

		if vim.fn.executable("tree-sitter") == 1 then
			vim.system({ "tree-sitter", "--version" }, { text = true }, function(result)
				local major, minor, patch = (result.stdout or ""):match("(%d+)%.(%d+)%.(%d+)")
				local version = major and { tonumber(major), tonumber(minor), tonumber(patch) } or nil
				local compatible = version
					and (version[1] > 0 or version[2] > 26 or (version[2] == 26 and version[3] >= 1))

				if result.code == 0 and compatible then
					vim.schedule(function()
						require("nvim-treesitter").install(parsers)
					end)
				end
			end)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(event)
				local parser = vim.treesitter.language.get_lang(event.match) or event.match
				if configured_parsers[parser] then
					pcall(vim.treesitter.start, event.buf, parser)
				end
			end,
		})

		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
			},
		})

		local select = require("nvim-treesitter-textobjects.select")
		vim.keymap.set({ "x", "o" }, "af", function()
			select.select_textobject("@function.outer", "textobjects")
		end, { desc = "select outer function" })
		vim.keymap.set({ "x", "o" }, "if", function()
			select.select_textobject("@function.inner", "textobjects")
		end, { desc = "select inner function" })
		vim.keymap.set({ "x", "o" }, "ac", function()
			select.select_textobject("@class.outer", "textobjects")
		end, { desc = "select outer class" })
		vim.keymap.set({ "x", "o" }, "ic", function()
			select.select_textobject("@class.inner", "textobjects")
		end, { desc = "select inner class" })
		vim.keymap.set({ "x", "o" }, "aa", function()
			select.select_textobject("@parameter.outer", "textobjects")
		end, { desc = "select outer parameter" })
		vim.keymap.set({ "x", "o" }, "ia", function()
			select.select_textobject("@parameter.inner", "textobjects")
		end, { desc = "select inner parameter" })

		local move = require("nvim-treesitter-textobjects.move")
		vim.keymap.set({ "n", "x", "o" }, "<leader>fn", function()
			move.goto_next_start("@function.outer", "textobjects")
		end, { desc = "next function start" })
		vim.keymap.set({ "n", "x", "o" }, "<leader>fe", function()
			move.goto_next_end("@function.outer", "textobjects")
		end, { desc = "next function end" })
		vim.keymap.set({ "n", "x", "o" }, "<leader>fp", function()
			move.goto_previous_start("@function.outer", "textobjects")
		end, { desc = "previous function start" })
		vim.keymap.set({ "n", "x", "o" }, "<leader>fE", function()
			move.goto_previous_end("@function.outer", "textobjects")
		end, { desc = "previous function end" })
		vim.keymap.set({ "n", "x", "o" }, "]]", function()
			move.goto_next_start("@class.outer", "textobjects")
		end, { desc = "next class start" })
		vim.keymap.set({ "n", "x", "o" }, "][", function()
			move.goto_next_end("@class.outer", "textobjects")
		end, { desc = "next class end" })
		vim.keymap.set({ "n", "x", "o" }, "[[", function()
			move.goto_previous_start("@class.outer", "textobjects")
		end, { desc = "previous class start" })
		vim.keymap.set({ "n", "x", "o" }, "[]", function()
			move.goto_previous_end("@class.outer", "textobjects")
		end, { desc = "previous class end" })

		local swap = require("nvim-treesitter-textobjects.swap")
		vim.keymap.set("n", "<leader>a", function()
			swap.swap_next("@parameter.inner", "textobjects")
		end, { desc = "swap next parameter" })
		vim.keymap.set("n", "<leader>A", function()
			swap.swap_previous("@parameter.inner", "textobjects")
		end, { desc = "swap previous parameter" })

		require("treesitter-context").setup({
			enable = true,
			max_lines = 0,
			min_window_height = 0,
			line_numbers = true,
			multiline_threshold = 20,
			trim_scope = "outer",
			mode = "cursor",
			separator = nil,
			zindex = 20,
			on_attach = nil,
		})
	end,
}
