return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("avante").setup({})
    end,
} 