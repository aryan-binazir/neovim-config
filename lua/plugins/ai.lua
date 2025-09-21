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
      { "<leader>cc", function()
        -- Check if Claude is running by looking for its buffer
        local claude_buf = nil
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local buf_name = vim.api.nvim_buf_get_name(buf)
          if buf_name:match("ClaudeCode") or buf_name:match("term://") and vim.api.nvim_buf_is_valid(buf) then
            local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
            if lines[1] and lines[1]:match("claude") then
              claude_buf = buf
              break
            end
          end
        end

        if not claude_buf then
          -- Start and immediately hide
          vim.cmd("ClaudeCode")
          vim.schedule(function()
            vim.cmd("wincmd p")  -- Go back to previous window
          end)
        else
          print("Claude already running")
        end
      end, desc = "Start Claude (background)" },
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
