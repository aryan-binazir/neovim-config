return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<S-Tab>",
          accept_word = "<C-w>",
          clear_suggestion = "<C-e>",
        },
      })

      local api = require("supermaven-nvim.api")
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.defer_fn(function()
            api.start()
            print("se")
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
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        provider = "none", -- no UI actions; server + tools remain available
      },
    },
  }
}
