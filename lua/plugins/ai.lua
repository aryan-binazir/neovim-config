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
  },
  -- {
  --   "github/copilot.vim",
  --   event = "InsertEnter",
  --   config = function()
  --     -- Accept full suggestion with Shift-Tab
  --     vim.g.copilot_no_tab_map = true
  --     vim.keymap.set("i", "<S-Tab>", 'copilot#Accept("\\<CR>")', {
  --       expr = true,
  --       replace_keycodes = false,
  --       desc = "Accept Copilot suggestion",
  --     })
  --
  --     -- Accept line with Ctrl-w
  --     vim.keymap.set("i", "<C-w>", "<Plug>(copilot-accept-line)", { desc = "Accept Copilot line" })
  --
  --     -- Dismiss suggestion with Ctrl-e
  --     vim.keymap.set("i", "<C-e>", "<Plug>(copilot-dismiss)", { desc = "Dismiss Copilot suggestion" })
  --
  --     -- Toggle Copilot (buffer-level)
  --     vim.keymap.set("n", "<leader>cp", function()
  --       if vim.b.copilot_enabled == false then
  --         vim.b.copilot_enabled = true
  --         print("ce")
  --       else
  --         vim.b.copilot_enabled = false
  --         print("cd")
  --       end
  --     end, { desc = "Toggle Copilot" })
  --   end,
  -- },
  -- {
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   lazy = false,
  --   version = false,
  --   build = "make",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --     "nvim-tree/nvim-web-devicons",
  --     "github/copilot.vim", -- already configured above
  --   },
  --   keys = {
  --     { "<leader>am", "<cmd>AvanteModel<cr>", desc = "Avante: Switch Model" },
  --   },
  --   opts = {
  --     provider = "copilot",
  --     auto_suggestions_provider = "copilot",
  --     hints = {
  --       enabled = false,
  --     },
  --     selector = {
  --       provider = "native", -- or "telescope" if you have it installed
  --     },
  --     providers = {
  --       copilot = {
  --         -- model = "gpt-4.1",
  --         extra_request_body = {
  --           temperature = 0,
  --         },
  --       },
  --     },
  --   },
  -- },
}
