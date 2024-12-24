return {
    'folke/which-key.nvim',
    config = function()
        vim.opt.timeoutlen = 2000  -- Wait 2 seconds for key sequences

        require("which-key").setup()
    end
} 