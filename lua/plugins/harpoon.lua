return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()

        -- vim.keymap.set("n", "<C-t>", function() toggle_telescope(harpoon:list()) end,
        --   { desc = "Open harpoon window" })
        vim.keymap.set("n", "<leader>m", function() harpoon:list():append() end, { desc = 'Add to Harpoon' })
        -- vim.keymap.set("n", "<leader>m", function() harpoon:list():add() end)
        vim.keymap.set("n", "<C-g>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        vim.keymap.set("n", "<C-q>", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<C-w>", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<C-a>", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "<C-n>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<C-m>", function() harpoon:list():next() end)
    end,
}

