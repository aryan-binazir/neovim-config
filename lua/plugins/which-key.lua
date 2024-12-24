return {
    'folke/which-key.nvim',
    config = function()
        -- Disable which-key by default
        vim.g.which_key_enabled = false
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
            -- Start in disabled mode
            disable = {
                buftypes = {},
                filetypes = {},
            },
        })

        -- Add toggle keymap
        vim.keymap.set('n', '<leader>tw', function()
            vim.g.which_key_enabled = not vim.g.which_key_enabled
            if vim.g.which_key_enabled then
                require("which-key").setup({ disable = { buftypes = {}, filetypes = {} } })
                vim.notify("Which-key enabled")
            else
                require("which-key").setup({ disable = { buftypes = { ".*" }, filetypes = { ".*" } } })
                vim.notify("Which-key disabled")
            end
        end, { desc = "Toggle which-key" })
    end
} 