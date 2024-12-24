return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("avante").setup({})
        
        -- Register commands with which-key
        local wk = require("which-key")
        
        -- Register keybindings using new spec format
        wk.register({
            { "<leader>a", group = "Avante" },
            { "<leader>aa", "<cmd>AvanteToggle<cr>", desc = "Show Sidebar" },
            { "<leader>ae", "<cmd>AvanteEdit<cr>", desc = "Edit Selected Blocks" },
            { "<leader>af", "<cmd>AvanteFocus<cr>", desc = "Switch Sidebar Focus" },
            { "<leader>ar", "<cmd>AvanteRefresh<cr>", desc = "Refresh Sidebar" },
            { "[[", "<cmd>PrevCodeblock<cr>", desc = "Previous Codeblock" },
            { "[x", "<cmd>PrevConflict<cr>", desc = "Previous Conflict" },
            { "]]", "<cmd>NextCodeblock<cr>", desc = "Next Codeblock" },
            { "]x", "<cmd>NextConflict<cr>", desc = "Next Conflict" },
            { "c", group = "Conflict Resolution" },
            { "c0", "<cmd>ChooseNone<cr>", desc = "Choose None" },
            { "ca", "<cmd>ChooseAllTheirs<cr>", desc = "Choose All Theirs" },
            { "cb", "<cmd>ChooseBoth<cr>", desc = "Choose Both" },
            { "cc", "<cmd>ChooseCursor<cr>", desc = "Choose Cursor" },
            { "co", "<cmd>ChooseOurs<cr>", desc = "Choose Ours" },
            { "ct", "<cmd>ChooseTheirs<cr>", desc = "Choose Theirs" },
        })

        -- Register commands
        vim.api.nvim_create_user_command("AvanteAsk", function(opts)
            -- Implementation handled by Avante
        end, {
            nargs = "*",
            desc = "Ask AI about your code",
            complete = function()
                return { "position=right", "position=left", "ask=true", "ask=false" }
            end,
        })

        local commands = {
            "AvanteBuild",
            "AvanteChat",
            "AvanteEdit",
            "AvanteFocus",
            "AvanteRefresh",
            "AvanteSwitchProvider",
            "AvanteShowRepoMap",
            "AvanteToggle",
        }

        for _, cmd in ipairs(commands) do
            vim.api.nvim_create_user_command(cmd, function()
                -- Implementation handled by Avante
            end, { desc = cmd })
        end
    end,
} 