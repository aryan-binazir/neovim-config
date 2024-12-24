return {
    {
        "github/copilot.vim"
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            { "github/copilot.vim" },
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

