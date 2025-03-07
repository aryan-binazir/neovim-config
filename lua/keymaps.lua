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
vim.keymap.set('n', '<leader>l8', ':!autopep8 --in-place -a -a -a -a --max-line-length 79 %<CR>',
    { noremap = true, silent = true, desc = "Auto Pep 8 Formatting" })
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

-- AI
function Toggle_ai()
    if vim.g.copilot_enabled == false then
        vim.g.copilot_enabled = true
        vim.notify("E", vim.log.levels.INFO)
        vim.cmd("Copilot enable")
    else
        vim.g.copilot_enabled = false
        vim.notify("D", vim.log.levels.INFO)
        vim.cmd("Copilot disable")
    end
end

vim.keymap.set("n", "<leader>ta", Toggle_ai, { noremap = true, silent = true, desc = "Toggle AI" })
-- vim.keymap.set("n", "<leader>cc", ":Codeium Chat<CR>", { noremap = true, silent = true, desc = "Open Codeium Chat" })
vim.keymap.set("n", "<leader>cc", ":CopilotChat<CR>", { noremap = true, silent = true, desc = "Open Copilot Chat" })
vim.keymap.set("n", "<leader>cm", ":CopilotChatModels<CR>",
    { noremap = true, silent = true, desc = "List Copilot Chat Models" })

-- Window resizing keymaps
vim.keymap.set("n", "<leader>=", ":vertical resize +25<CR>",
    { noremap = true, silent = true, desc = "Increase window width" })
vim.keymap.set("n", "<leader>-", ":vertical resize -25<CR>",
    { noremap = true, silent = true, desc = "Decrease window width" })
