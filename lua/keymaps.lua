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
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Other keymaps
-- vim.keymap.set('n', '<leader>cc', ':CopilotChatToggle<CR>', { noremap = true, silent = true, desc = 'Open Copilot Chat' })
-- vim.keymap.set('n', '<leader>cr', ':CopilotChatReset<CR>', { noremap = true, silent = true, desc = 'Reset Copilot Chat' })
-- vim.keymap.set('n', '<leader>cm', ':CopilotChatModels<CR>',
-- { noremap = true, silent = true, desc = 'Change Copilot Model' })
vim.keymap.set('n', '<leader>tt', Toggle_diagnostics, { noremap = true, silent = true, desc = "Toggle vim diagnostics" })
vim.keymap.set('n', '<leader>tr', ':set relativenumber!<CR>',
    { noremap = true, silent = true, desc = "Toggle relative number" })
vim.keymap.set('n', '<leader>l8', ':!autopep8 --in-place -a -a -a -a --max-line-length 79 %<CR>',
    { noremap = true, silent = true, desc = "Auto Pep 8 Formatting" })
vim.keymap.set('n', '<leader>sl', function() vim.cmd("Sleuth") end, { desc = '[SL]euth' })

-- Quick exit keymaps
vim.keymap.set('n', '<leader>qq', ':q!<CR>')
vim.keymap.set('n', '<leader>wq', ':wq!<CR>')

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})
vim.g.codeium_enabled = true
