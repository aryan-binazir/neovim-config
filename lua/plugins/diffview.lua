return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
	opts = {},
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "diff working tree" },
		{ "<leader>gD", "<cmd>DiffviewOpen --cached<cr>", desc = "diff staged" },
		{
			"<leader>gm",
			function()
				local base = "main"
				for _, candidate in ipairs({ "origin/main", "origin/master" }) do
					vim.fn.system({ "git", "rev-parse", "--verify", "-q", candidate })
					if vim.v.shell_error == 0 then
						base = candidate
						break
					end
				end
				vim.cmd("DiffviewOpen " .. base .. "...HEAD")
			end,
			desc = "diff branch vs base",
		},
		{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "close diffview" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "file history" },
	},
}
