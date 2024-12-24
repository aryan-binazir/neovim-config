return {
    'stevearc/oil.nvim',
    config = function()
        require("oil").setup({
            columns = { "icons" },
            keymap = {
                ["<C-h>"] = false,
                ["<C-p>"] = false,
                ["<m-h>"] = "actions.select_split",
            },
            view_options = {
                show_hidden = true
            },
            keymaps = {
                ["<C-p>"] = false,
            },
        })
        -- Set the main Oil keymap
        vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open Oil File Browser" })
    end,
}

