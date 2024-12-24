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

        -- Register groups with new spec format
        local wk = require("which-key")
        wk.register({
            { "<leader>c", group = "copilot" },
            { "<leader>l", group = "lsp/lazy" },
            { "<leader>t", group = "toggle" },
            { "<leader>w", group = "workspace" },
            { "<leader>s", group = "search" },
            { "<leader>h", group = "hunks" },
            { "<leader>f", group = "find/files" },
            { "<leader>d", group = "debug/diagnostics" },
        })
    end
} 