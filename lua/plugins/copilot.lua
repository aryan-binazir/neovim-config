return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                panel = {
                    enabled = true,
                    auto_refresh = true,
                },
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = "<C-s>",
                        next = "<C-h>",
                        prev = "<C-l>",
                        dismiss = "<C-\\>",
                    },
                },
                filetypes = {
                    markdown = true,
                    help = false,
                },
            })
        end,
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
        end,
        opts = {},
    }
}

