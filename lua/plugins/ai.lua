return {
	{
		"coder/claudecode.nvim",
		opts = {
			terminal = {
				provider = "none", -- no UI actions; server + tools remain available
			},
		},
	},
	{
		"supermaven-inc/supermaven-nvim",
		enabled = vim.g.supermaven_enabled == true,
		config = function()
			require("supermaven-nvim").setup({
				keymaps = {
					accept_suggestion = "<S-Tab>",
					accept_word = "<C-w>",
					clear_suggestion = "<C-e>",
				},
			})

			local api = require("supermaven-nvim.api")
			vim.keymap.set("n", "<leader>sm", function()
				if api.is_running() then
					api.stop()
					vim.notify("Supermaven disabled")
				else
					api.start()
					vim.notify("Supermaven enabled")
				end
			end, { desc = "Toggle SM" })
		end,
	},
}
