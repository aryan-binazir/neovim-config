-- Function to toggle diagnostics
function Toggle_diagnostics()
    if vim.g.diagnostics_active then
        vim.g.diagnostics_active = false
        vim.diagnostic.enable(false)
    else
        vim.g.diagnostics_active = true
        vim.diagnostic.enable()
    end
end

-- Basic keymaps
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '<A-k>', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', '<A-j>', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Go to diagnostics list' })
vim.keymap.set('n', '<leader>tt', Toggle_diagnostics, { noremap = true, silent = true, desc = "Toggle vim diagnostics" })

-- Other Keymaps
vim.keymap.set('n', '<leader>tr', ':set relativenumber!<CR>',
    { noremap = true, silent = true, desc = "Toggle relative number" })
vim.keymap.set('n', '<leader>l8', ':!pyink --pyink-use-majority-quotes --line-length 79 %<CR>',
    { noremap = true, silent = true, desc = "Pyink PEP8 Formatting" })
vim.keymap.set('n', '<leader>sl', function() vim.cmd("Sleuth") end, { desc = '[SL]euth' })
vim.keymap.set("n", "<leader>rr", "<cmd>e!<CR>", { desc = "Check external changes" })

-- Quick exit keymaps
vim.keymap.set('n', '<leader>qq', ':q!<CR>')
vim.keymap.set('n', '<leader>wq', ':wq!<CR>')

-- Location list specific mappings
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
        vim.keymap.set('n', '<CR>', function()
            -- Get the current line number which represents the location entry
            local line = vim.api.nvim_win_get_cursor(0)[1]
            -- Execute the location list jump
            vim.cmd(line .. 'll')
        end, { buffer = true, noremap = true, desc = 'Jump to location list item' })
    end,
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})
