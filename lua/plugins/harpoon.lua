return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()

        vim.keymap.set("n", "<leader>m", function() harpoon:list():add() end, { desc = 'Add to Harpoon' })
        vim.keymap.set("n", "<C-g>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        -- Change to leader + number keys
        vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
        vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end)
        vim.keymap.set("n", "<leader>6", function() harpoon:list():select(6) end)
        vim.keymap.set("n", "<leader>7", function() harpoon:list():select(7) end)
        vim.keymap.set("n", "<leader>8", function() harpoon:list():select(8) end)
        vim.keymap.set("n", "<leader>9", function() harpoon:list():select(9) end)

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "<C-n>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<C-m>", function() harpoon:list():next() end)
    end,
}
