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
		local treesitter = require("nvim-treesitter")
		local install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site")
		treesitter.setup({
			install_dir = install_dir,
		})

		local parsers = { "go", "lua", "python", "tsx", "javascript", "typescript", "bash", "pug", "html" }
		local configured_parsers = {}
		for _, parser in ipairs(parsers) do
			configured_parsers[parser] = true
		end
		local function start_treesitter(buffer)
			local filetype = vim.bo[buffer].filetype
			local parser = vim.treesitter.language.get_lang(filetype) or filetype
			if configured_parsers[parser] then
				pcall(vim.treesitter.start, buffer, parser)
			end
		end

		if vim.fn.executable("tree-sitter") == 1 then
			vim.system({ "tree-sitter", "--version" }, { text = true }, function(result)
				local version = vim.version.parse((result.stdout or "") .. (result.stderr or ""))
				local compatible = version and vim.version.cmp(version, { 0, 26, 1 }) >= 0

				if result.code == 0 and compatible then
					vim.schedule(function()
						local task = treesitter.install(parsers)
						task:await(function(error)
							if error then
								return
							end
							vim.schedule(function()
								for _, parser in ipairs(parsers) do
									local path = vim.fs.joinpath(install_dir, "parser", parser .. ".so")
									if vim.uv.fs_stat(path) then
										pcall(vim.treesitter.language.add, parser, { path = path })
									end
								end
								for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
									if vim.api.nvim_buf_is_loaded(buffer) then
										start_treesitter(buffer)
									end
								end
							end)
						end)
					end)
				end
			end)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(event)
				start_treesitter(event.buf)
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
