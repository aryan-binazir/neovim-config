return {
	{
		"coder/claudecode.nvim",
		opts = {
			terminal = {
				provider = "none", -- no UI actions; server + tools remain available
			},
		},
	},
	-- {
	--   "zbirenbaum/copilot.lua",
	--   cmd = "Copilot",
	--   event = "InsertEnter",
	--   config = function()
	--     require("copilot").setup({
	--       suggestion = {
	--         enabled = true,
	--         auto_trigger = true,
	--         keymap = {
	--           accept = "<S-Tab>",
	--           accept_word = "<C-w>",
	--           accept_line = "<C-y>",
	--           dismiss = "<C-e>",
	--           next = "<C-n>",
	--           prev = "<C-p>",
	--         },
	--       },
	--       panel = { enabled = false },
	--     })
	--
	--     vim.g.copilot_enabled = true
	--     vim.keymap.set("n", "<leader>ta", function()
	--       require("copilot.suggestion").toggle_auto_trigger()
	--       vim.g.copilot_enabled = not vim.g.copilot_enabled
	--       print(vim.g.copilot_enabled and "AI on" or "AI off")
	--     end, { desc = "Toggle Copilot" })
	--   end,
	-- },
	-- {
	-- 	"supermaven-inc/supermaven-nvim",
	-- 	config = function()
	-- 		require("supermaven-nvim").setup({
	-- 			keymaps = {
	-- 				accept_suggestion = "<S-Tab>",
	-- 				accept_word = "<C-w>",
	-- 				clear_suggestion = "<C-e>",
	-- 			},
	-- 		})
	--
	-- 		local api = require("supermaven-nvim.api")
	-- 		vim.api.nvim_create_autocmd("VimEnter", {
	-- 			callback = function()
	-- 				vim.defer_fn(function()
	-- 					api.start()
	-- 					print("se")
	-- 				end, 100)
	-- 			end,
	-- 		})
	--
	-- 		vim.keymap.set("n", "<leader>sm", function()
	-- 			if api.is_running() then
	-- 				api.stop()
	-- 				print("sd")
	-- 			else
	-- 				api.start()
	-- 				print("se")
	-- 			end
	-- 		end, { desc = "Toggle SM" })
	-- 	end,
	-- },
}
