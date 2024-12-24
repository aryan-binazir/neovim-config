return {
    'stevearc/oil.nvim',
    opts = {
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
    },
}

