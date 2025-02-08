return {
  -- {
  --   "Exafunction/codeium.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup({
  --       -- Optionally disable cmp source if using virtual text only
  --       enable_cmp_source = false,
  --       virtual_text = {
  --         enabled = true,

  --         -- These are the defaults

  --         -- Set to true if you never want completions to be shown automatically.
  --         manual = false,
  --         -- A mapping of filetype to true or false, to enable virtual text.
  --         filetypes = {},
  --         -- Whether to enable virtual text of not for filetypes not specifically listed above.
  --         default_filetype_enabled = true,
  --         -- How long to wait (in ms) before requesting completions after typing stops.
  --         idle_delay = 75,
  --         -- Priority of the virtual text. This usually ensures that the completions appear on top of
  --         -- other plugins that also add virtual text, such as LSP inlay hints, but can be modified if
  --         -- desired.
  --         virtual_text_priority = 65535,
  --         -- Set to false to disable all key bindings for managing completions.
  --         map_keys = true,
  --         -- The key to press when hitting the accept keybinding but no completion is showing.
  --         -- Defaults to \t normally or <c-n> when a popup is showing.
  --         accept_fallback = nil,
  --         -- Key bindings for managing completions in virtual text mode.
  --         key_bindings = {
  --           -- Accept the current completion.
  --           accept = "<S-Tab>",
  --           -- Accept the next word.
  --           accept_word = false,
  --           -- Accept the next line.
  --           accept_line = "<C-l>",
  --           -- Clear the virtual text.
  --           clear = "<C-x>",
  --           -- Cycle to the next completion.
  --           next = "<C-j>",
  --           -- Cycle to the previous completion.
  --           prev = "<C-k>",
  --         }
  --       }
  --     })

  --     -- Create a global function to toggle ghost text
  --     vim.g.codeium_ghost_text_enabled = true
  --     _G.toggle_codeium_ghost_text = function()
  --       vim.g.codeium_ghost_text_enabled = not vim.g.codeium_ghost_text_enabled
  --       require("codeium").setup({
  --         enable_cmp_source = false,
  --         virtual_text = {
  --           enabled = vim.g.codeium_ghost_text_enabled,
  --           manual = false,
  --           filetypes = {},
  --           default_filetype_enabled = true,
  --           idle_delay = 75,
  --           virtual_text_priority = 65535,
  --           map_keys = true,
  --           accept_fallback = nil,
  --           key_bindings = {
  --             accept = "<S-Tab>",
  --             accept_word = false,
  --             accept_line = "<C-l>",
  --             clear = "<C-x>",
  --             next = "<C-j>",
  --             prev = "<C-k>",
  --           }
  --         }
  --       })
  --     end
  --   }
  -- },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<S-Tab>",
            dismiss = "<C-e>",
            next = "<C-j>",
            prev = "<C-k>",
          },
        },
      })
    end,
  },
  -- {
  --   "CopilotC-Nvim/CopilotChat.nvim",
  --   dependencies = {
  --     { "github/copilot.vim" },
  --     { "nvim-lua/plenary.nvim", branch = "master" },
  --   },
  --   build = "make tiktoken",
  --   opts = {
  --     debug = false,
  --     model = "claude-3.5-sonnet",
  --     prompts = {
  --       Explain = "Please explain how this code works.",
  --       Review = "Please review the following code and provide suggestions for improvement.",
  --       Tests = "Please generate unit tests for the following code.",
  --       Refactor = "Please suggest ways to refactor this code to improve its clarity and maintainability.",
  --     },
  --   },
  -- },
}
