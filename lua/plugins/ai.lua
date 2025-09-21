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
            api.stop()
            print("sd")
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
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeChat<cr>", desc = "Claude Chat" },
      { "<leader>ar", "<cmd>ClaudeCodeRestart<cr>", desc = "Restart Claude" },
      { "<leader>as", "<cmd>ClaudeCodeStop<cr>", desc = "Stop Claude" },
      { "<leader>al", "<cmd>ClaudeCodeLog<cr>", desc = "Claude Log" },
    },
    opts = {
      terminal_cmd = "/home/ar/.claude/local/claude --dangerously-skip-permissions",
      git_repo_cwd = true,
      terminal = {
        provider = "snacks",
        split_side = "right",
        split_width_percentage = 50,
      },
    },
  },
}
