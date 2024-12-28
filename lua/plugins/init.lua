return {
    -- Git related plugins
    { 'tpope/vim-fugitive', },
    { 'tpope/vim-rhubarb', },
    { 'tpope/vim-sleuth', },
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>",            desc = "LazyGit" },
            { "<leader>lc", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit Current File" }
        },
        config = function()
            -- Add keymap to quit Lazygit floating window
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "lazygit",
                callback = function()
                    vim.keymap.set("n", "q", ":q<CR>", { buffer = true, silent = true })
                end,
            })
        end,
    },

    -- Surround plugin
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({})
        end
    },

    -- "gc" to comment visual regions/lines
    { 'numToStr/Comment.nvim', opts = {} },

    -- Theme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                color_overrides = {
                    mocha = {
                        base = "#000000",
                        mantle = "#000000",
                        crust = "#000000",
                    },
                },
            })
            vim.cmd.colorscheme "catppuccin-mocha"
        end,
    },

    -- Harpoon for quick file navigation
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" }
    },

    -- UI enhancements
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
    },
    {
        'nvim-lualine/lualine.nvim',
        opts = {
            options = {
                icons_enabled = true,
                theme = 'onedark',
                component_separators = '|',
                section_separators = '',
            },
        },
    },

    -- Indentation guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
    },
}
