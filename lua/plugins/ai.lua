return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          hide_during_completion = true,
          auto_trigger = true,
          keymap = {
            accept = "<S-Tab>",
            -- accept_line = "<S-Tab>",
            dismiss = "<C-e>",
            next = "<C-j>",
            prev = "<C-k>",
          },
        },
      })
    end,
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
      provider = "copilot",
      copilot = {
        model = "claude-3.5-sonnet",
      },
    },
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "muniftanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
      {
        "hakonharnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        'meanderingprogrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "avante" },
        },
        ft = { "markdown", "avante" },
      },
    },
  },
  -- {
  --   "exafunction/codeium.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup({
  --       -- optionally disable cmp source if using virtual text only
  --       enable_cmp_source = false,
  --       virtual_text = {
  --         enabled = true,
  --
  --         -- these are the defaults
  --
  --         -- set to true if you never want completions to be shown automatically.
  --         manual = false,
  --         -- a mapping of filetype to true or false, to enable virtual text.
  --         filetypes = {},
  --         -- whether to enable virtual text of not for filetypes not specifically listed above.
  --         default_filetype_enabled = true,
  --         -- how long to wait (in ms) before requesting completions after typing stops.
  --         idle_delay = 75,
  --         -- priority of the virtual text. this usually ensures that the completions appear on top of
  --         -- other plugins that also add virtual text, such as lsp inlay hints, but can be modified if
  --         -- desired.
  --         virtual_text_priority = 65535,
  --         -- set to false to disable all key bindings for managing completions.
  --         map_keys = true,
  --         -- the key to press when hitting the accept keybinding but no completion is showing.
  --         -- defaults to \t normally or <c-n> when a popup is showing.
  --         accept_fallback = nil,
  --         -- key bindings for managing completions in virtual text mode.
  --         key_bindings = {
  --           -- accept the current completion.
  --           accept = "<s-tab>",
  --           -- accept the next word.
  --           accept_word = false,
  --           -- accept the next line.
  --           accept_line = "<c-l>",
  --           -- clear the virtual text.
  --           clear = "<c-x>",
  --           -- cycle to the next completion.
  --           next = "<c-j>",
  --           -- cycle to the previous completion.
  --           prev = "<c-k>",
  --         }
  --       }
  --     })
  --
  --     -- create a global function to toggle ghost text
  --     vim.g.codeium_ghost_text_enabled = true
  --     _g.toggle_codeium_ghost_text = function()
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
  --             accept = "<s-tab>",
  --             accept_word = false,
  --             accept_line = "<c-l>",
  --             clear = "<c-x>",
  --             next = "<c-j>",
  --             prev = "<c-k>",
  --           }
  --         }
  --       })
  --     end
  --   }
  -- },
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
