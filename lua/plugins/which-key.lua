return {
    'folke/which-key.nvim',
    config = function()
        vim.opt.timeoutlen = 1000  -- Time to wait for a mapped sequence to complete (in milliseconds)

        local wk = require("which-key")
        
        -- Setup which-key
        wk.setup({
            plugins = {
                presets = {
                    operators = false,
                    motions = false,
                    text_objects = false,
                    windows = false,
                    nav = false,
                    z = false,
                    g = false,
                },
            },
        })

        -- Define groups
        local spec = {
            { '<leader>c', group = '[C]opilot', mode = { 'n', 'x' } },
            { '<leader>d', group = '[D]ebug/Diagnostics' },
            { '<leader>f', group = '[F]ind/Files' },
            { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
            { '<leader>l', group = '[L]SP/Lazy' },
            { '<leader>s', group = '[S]earch' },
            { '<leader>t', group = '[T]oggle' },
            { '<leader>w', group = '[W]orkspace' },
        }

        -- Register groups
        wk.register(spec)
    end
} 