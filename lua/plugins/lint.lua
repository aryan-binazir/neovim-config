return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		local function command_exists(cmd)
			return vim.fn.executable(cmd) == 1
		end

		-- Only enable linters that are installed
		local linters = {}
		if command_exists("markdownlint") then
			linters.markdown = { "markdownlint" }
		end

		lint.linters_by_ft = linters

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

		vim.api.nvim_create_user_command("LintStatus", function()
			local ft = vim.bo.filetype
			if not linters[ft] then
				print("No linters configured for " .. ft)
			else
				print("Configured linters for " .. ft .. ": " .. table.concat(linters[ft], ", "))
			end
		end, { desc = "show linter status for current filetype" })
	end,
}
