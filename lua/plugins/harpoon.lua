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
        for i = 1, 9 do
            vim.keymap.set("n", "<leader>" .. i, function() harpoon:list():select(i) end,
                { desc = "Harpoon to file " .. i })
        end

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "<C-n>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<C-m>", function() harpoon:list():next() end)
    end,
}
