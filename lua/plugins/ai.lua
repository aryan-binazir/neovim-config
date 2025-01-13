return {
    {
        "zbirenbaum/copilot.lua",
        config = function()
            require("copilot").setup({
                panel = {
                    -- enabled = true,
                    -- auto_refresh = true,
                    enabled = false,
                    auto_refresh = false,
                },
                suggestion = {
                    enabled = false,
                    auto_trigger = false,
                    -- enabled = true,
                    -- auto_trigger = true,
                    -- keymap = {
                    --     accept = "<C-y>",
                    --     accept_word = "<C-b>",
                    --     next = "<C-j>",
                    --     prev = "<C-k>",
                    --     dismiss = "<C-\\>",
                    -- },
                },
                -- filetypes = {
                -- markdown = true,
                -- help = false,
                -- },
            })
        end
    },
    {
        "zbirenbaum/copilot-cmp",
        config = function()
            require("copilot_cmp").setup()
        end
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            { "zbirenbaum/copilot.lua" },
            { "nvim-lua/plenary.nvim" },
        },
        build = "make tiktoken",
        config = function()
            require("CopilotChat").setup {
                model = 'claude-3.5-sonnet',
            }
            -- Ensure that Copilot uses the same model
            -- require("copilot").setup({
            --     panel = {
            --         enabled = true,
            --         auto_refresh = true,
            --     },
            --     suggestion = {
            --         enabled = false,
            --         auto_trigger = false,
            --         -- keymap = {
            --         --     accept = "<C-y>",
            --         --     accept_word = "<C-b>",
            --         --     next = "<C-j>",
            --         --     prev = "<C-k>",
            --         --     dismiss = "<C-\\>",
            --         -- },
            --     },
            --     filetypes = {
            --         markdown = true,
            --         help = false,
            --     },
            -- })
        end,
        opts = {},
    },
    --
    -- {
    --     "yetone/avante.nvim",
    --     event = "VeryLazy",
    --     lazy = false,
    --     version = false,
    --     opts = {
    --         provider = "copilot",
    --         copilot = {
    --             model = "claude-3.5-sonnet",
    --             api = "chat",
    --         },
    --         window = {
    --             layout = {
    --                 prompt_height = "10%",
    --                 chat_height = "80%"
    --             }
    --         }
    --     },
    --     -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    --     build = "make",
    --     -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    --     dependencies = {
    --         "stevearc/dressing.nvim",
    --         "nvim-lua/plenary.nvim",
    --         "MunifTanjim/nui.nvim",
    --         --- The below dependencies are optional,
    --         "hrsh7th/nvim-cmp",            -- autocompletion for avante commands and mentions
    --         "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --         "zbirenbaum/copilot.lua",      -- for providers='copilot'
    --         {
    --             -- support for image pasting
    --             "HakonHarnes/img-clip.nvim",
    --             event = "VeryLazy",
    --             opts = {
    --                 -- recommended settings
    --                 default = {
    --                     embed_image_as_base64 = false,
    --                     prompt_for_file_name = false,
    --                     drag_and_drop = {
    --                         insert_mode = true,
    --                     },
    --                     -- required for Windows users
    --                     use_absolute_path = true,
    --                 },
    --             },
    --         },
    --         {
    --             -- Make sure to set this up properly if you have lazy=true
    --             'MeanderingProgrammer/render-markdown.nvim',
    --             opts = {
    --                 file_types = { "markdown", "Avante" },
    --             },
    --             ft = { "markdown", "Avante" },
    --         },
    --     },
    -- },
    -- {
    --     "sourcegraph/sg.nvim",
    --     dependencies = {
    --         "nvim-lua/plenary.nvim",
    --         "nvim-telescope/telescope.nvim",
    --     },
    --     build = ":lua require('sg.build').install()",
    --     config = true,
    -- }
}
