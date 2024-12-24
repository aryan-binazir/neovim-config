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
        
        -- Register normal mode keybindings
        wk.register({
            ["<leader>a"] = {
                mode = { "n" },
                name = "Avante",
                a = { "<cmd>AvanteToggle<cr>", "Show Sidebar" },
                r = { "<cmd>AvanteRefresh<cr>", "Refresh Sidebar" },
                f = { "<cmd>AvanteFocus<cr>", "Switch Sidebar Focus" },
                e = { "<cmd>AvanteEdit<cr>", "Edit Selected Blocks" },
            },
            c = {
                mode = { "n" },
                name = "Conflict Resolution",
                o = { "<cmd>ChooseOurs<cr>", "Choose Ours" },
                t = { "<cmd>ChooseTheirs<cr>", "Choose Theirs" },
                a = { "<cmd>ChooseAllTheirs<cr>", "Choose All Theirs" },
                ["0"] = { "<cmd>ChooseNone<cr>", "Choose None" },
                b = { "<cmd>ChooseBoth<cr>", "Choose Both" },
                c = { "<cmd>ChooseCursor<cr>", "Choose Cursor" },
            },
            ["]"] = {
                mode = { "n" },
                x = { "<cmd>NextConflict<cr>", "Next Conflict" },
                ["]"] = { "<cmd>NextCodeblock<cr>", "Next Codeblock" },
            },
            ["["] = {
                mode = { "n" },
                x = { "<cmd>PrevConflict<cr>", "Previous Conflict" },
                ["["] = { "<cmd>PrevCodeblock<cr>", "Previous Codeblock" },
            },
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