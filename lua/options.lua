-- Options
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g["diagnostics_active"] = true

-- General options
vim.o.hlsearch = false
vim.wo.relativenumber = true
vim.wo.number = true
vim.o.mouse = "a"
-- Fall back to OSC52 when no X11/Wayland clipboard is available on Linux.
if vim.fn.has("linux") == 1 and vim.env.WAYLAND_DISPLAY == nil and vim.env.DISPLAY == nil then
	vim.g.clipboard = "osc52"
end
vim.o.clipboard = "unnamedplus"
vim.o.breakindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = "menuone,noselect"
vim.o.termguicolors = true

-- Lazygit options
vim.g.lazygit_floating_window_winblend = 0
vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
vim.g.lazygit_floating_window_use_plenary = 0
vim.g.lazygit_use_neovim_remote = 1
vim.g.lazygit_use_custom_config_file_path = 0
vim.g.lazygit_config_file_path = {}

-- `nvim /some/dir` opens the directory buffer but leaves cwd at the shell's
-- location, so pickers search the wrong tree. Follow the argument instead.
-- Captured here, not in the callback: oil rewrites the arglist entry to an
-- `oil://` URL before VimEnter runs.
local first_arg = vim.fn.argv(0)
if type(first_arg) == "string" and first_arg ~= "" and vim.fn.isdirectory(first_arg) == 1 then
	local target = vim.fn.fnamemodify(first_arg, ":p")
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			vim.cmd.cd(vim.fn.fnameescape(target))
		end,
	})
end

vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	callback = function()
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})

vim.opt.conceallevel = 2

-- Auto-reload files changed outside of Neovim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
})
