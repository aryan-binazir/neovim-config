-- Basic keymaps
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>dk", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "go to previous diagnostic message" })
vim.keymap.set("n", "<leader>dj", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "go to diagnostics list" })
vim.keymap.set("n", "<leader>tt", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { silent = true, desc = "toggle vim diagnostics" })

-- Other Keymaps
vim.keymap.set("n", "<leader>tr", ":set relativenumber!<CR>", { silent = true, desc = "toggle relative number" })
vim.keymap.set("n", "<leader>rr", "<cmd>checktime<CR>", { desc = "check external changes" })

-- Harpoon's global <C-m> is the same key as <CR> in most terminals; give quickfix
-- and location list windows their built-in jump back.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "qf",
	callback = function()
		vim.keymap.set("n", "<CR>", "<CR>", { buffer = true, desc = "jump to quickfix item" })
	end,
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})
