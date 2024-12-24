return {
    'folke/which-key.nvim',
    config = function()
        require("which-key").setup({
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

        -- Register groups
        local wk = require("which-key")
        wk.register({
            ["<leader>c"] = { name = "+copilot" },
            ["<leader>l"] = { name = "+lsp/lazy" },
            ["<leader>t"] = { name = "+toggle" },
            ["<leader>w"] = { name = "+workspace" },
            ["<leader>s"] = { name = "+search" },
            ["<leader>h"] = { name = "+hunks" },
            ["<leader>f"] = { name = "+find/files" },
            ["<leader>d"] = { name = "+debug/diagnostics" },
        })
    end
} 