return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<Tab>",
          accept_word = "<S-Tab>",
          clear_suggestion = "<C-e>",
        },
      })

      local api = require("supermaven-nvim.api")
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.defer_fn(function()
            api.stop()
            print("SM d")
          end, 100)
        end,
      })

      vim.keymap.set("n", "<leader>sm", function()
        if api.is_running() then
          api.stop()
          print("sd")
        else
          api.start()
          print("se")
        end
      end, { desc = "Toggle SM" })
    end,
  },
}
