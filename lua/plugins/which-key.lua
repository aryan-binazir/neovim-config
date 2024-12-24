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
            health = {
                checker = false,  -- Disable health checks
            },
        })

        -- Register groups
        wk.register({
            ["<leader>c"] = { name = "+[C]opilot" },
            ["<leader>d"] = { name = "+[D]ebug/Diagnostics" },
            ["<leader>f"] = { name = "+[F]ind/Files" },
            ["<leader>h"] = { name = "+Git [H]unk" },
            ["<leader>l"] = { name = "+[L]SP/Lazy" },
            ["<leader>s"] = { name = "+[S]earch" },
            ["<leader>t"] = { name = "+[T]oggle" },
            ["<leader>w"] = { name = "+[W]orkspace" },
        })
    end
} 