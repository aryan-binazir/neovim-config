-- Options
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g["diagnostics_active"] = true

-- General options
vim.o.hlsearch = false
vim.wo.relativenumber = true
vim.wo.number = true
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
vim.o.breakindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menuone,noselect'
vim.o.termguicolors = true

-- Lazygit options
vim.g.lazygit_floating_window_winblend = 0
vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_floating_window_border_chars = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }
vim.g.lazygit_floating_window_use_plenary = 0
vim.g.lazygit_use_neovim_remote = 1
vim.g.lazygit_use_custom_config_file_path = 0
vim.g.lazygit_config_file_path = {}

-- Folding settings
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldenable = false    -- Disable folding at startup
vim.opt.foldlevel = 99       -- High fold level means all folds open
vim.opt.foldnestmax = 3      -- Maximum nesting of folds
vim.opt.foldminlines = 1     -- Minimum lines for a fold
vim.opt.foldcolumn = '0'     -- Don't show fold column

-- Set jade files to be viewed as pug files by treesitter
vim.cmd [[ autocmd BufRead,BufNewFile *.jade set filetype=pug ]]


-- For Obsidian plugin
vim.opt.conceallevel = 2
