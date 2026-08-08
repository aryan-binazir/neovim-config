return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- Only enable linters that are installed
		if vim.fn.executable("markdownlint") == 1 then
			lint.linters_by_ft = { markdown = { "markdownlint" } }
		end

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				-- Only run the linter in buffers that you can modify
				if vim.opt_local.modifiable:get() then
					lint.try_lint()
				end
			end,
		})

		vim.api.nvim_create_user_command("Lint", function()
			lint.try_lint()
		end, { desc = "trigger linting for current file" })
	end,
}
