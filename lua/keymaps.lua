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

-- Yank file paths (for AI workflows)
local function yank_paths(paths, label)
    vim.fn.setreg('+', table.concat(paths, '\n'))
    print('Yanked ' .. #paths .. ' ' .. label)
end

vim.keymap.set('n', '<leader>yp', function()
    yank_paths({ vim.fn.expand('%:p') }, 'path')
end, { desc = 'Yank absolute file path' })

vim.keymap.set('n', '<leader>yb', function()
    local paths = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= '' then table.insert(paths, name) end
        end
    end
    yank_paths(paths, 'buffer paths')
end, { desc = 'Yank all buffer paths' })

vim.keymap.set('n', '<leader>yh', function()
    local ok, harpoon = pcall(require, 'harpoon')
    if not ok then print('Harpoon not available') return end
    local paths = {}
    local cwd = vim.fn.getcwd() .. '/'
    for _, item in ipairs(harpoon:list().items) do
        if item.value and item.value ~= '' then
            table.insert(paths, cwd .. item.value)
        end
    end
    yank_paths(paths, 'harpoon paths')
end, { desc = 'Yank all harpoon paths' })

vim.keymap.set('v', '<leader>ys', function()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end
    local path = vim.fn.expand('%:p')
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local range = start_line == end_line and tostring(start_line) or (start_line .. '-' .. end_line)
    local result = path .. ':' .. range .. '\n' .. table.concat(lines, '\n')
    vim.fn.setreg('+', result)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
    print('Yanked selection with context')
end, { desc = 'Yank file path, lines, and code selection' })

vim.keymap.set('n', '<leader>yo', function()
    local ok, oil = pcall(require, 'oil')
    if not ok then print('Oil not available') return end
    local dir = oil.get_current_dir()
    if not dir then print('Not in Oil buffer') return end
    local bufnr = vim.api.nvim_get_current_buf()
    local paths = {}
    for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
        local entry = oil.get_entry_on_line(bufnr, lnum)
        if entry and entry.type == 'file' then
            table.insert(paths, dir .. entry.name)
        end
    end
    yank_paths(paths, 'Oil paths')
end, { desc = 'Yank all file paths in Oil directory' })

-- Other Keymaps
vim.keymap.set('n', '<leader>tr', ':set relativenumber!<CR>',
    { noremap = true, silent = true, desc = "Toggle relative number" })
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
        vim.hl.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})
