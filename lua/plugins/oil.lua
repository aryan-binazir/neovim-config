return {
    'stevearc/oil.nvim',
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("oil").setup({
            columns = { "icon", "size", "mtime" },
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
