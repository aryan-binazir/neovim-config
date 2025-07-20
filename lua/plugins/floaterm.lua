return {
    'voldikss/vim-floaterm',
    config = function()
        -- Floaterm settings
        vim.g.floaterm_width = 0.8  -- 80% of screen width
        vim.g.floaterm_height = 0.8 -- 80% of screen height
        vim.g.floaterm_position = 'center'
        vim.g.floaterm_title = 'Terminal $1/$2'
        vim.g.floaterm_autoclose = 1 -- Auto close terminal when process exits

        -- Normal mode mappings
        vim.keymap.set('n', '<leader>ft', ':FloatermToggle<CR>', { desc = 'Toggle Floating Terminal' })
        vim.keymap.set('n', '<leader>fk', ':FloatermKill<CR>', { desc = 'Kill Terminal' })

        -- Terminal mode mappings
        vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit Terminal Mode' })
        vim.keymap.set('t', '<C-t>', '<C-\\><C-n>:FloatermToggle<CR>', { desc = 'Toggle Terminal' })
    end,
} 