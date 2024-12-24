return {
    'folke/which-key.nvim',
    config = function()
        -- Disable which-key by default
        vim.g.which_key_enabled = false
        require("which-key").setup({
            disable = { filetypes = {} },  -- Keep track of filetypes but start enabled
        })
        -- Initially disable which-key
        require("which-key").disable()

        -- Add toggle keymap
        vim.keymap.set('n', '<leader>tw', function()
            vim.g.which_key_enabled = not vim.g.which_key_enabled
            if vim.g.which_key_enabled then
                require("which-key").enable()
                vim.notify("Which-key enabled")
            else
                require("which-key").disable()
                vim.notify("Which-key disabled")
            end
        end, { desc = "Toggle which-key" })
    end
} 