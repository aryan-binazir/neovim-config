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
            accept_line = "<C-y>",
            dismiss = "<C-e>",
            next = "<C-j>",
            prev = "<C-k>",
          },
        },
      })
    end,
  },
  -- {
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   lazy = false,
  --   version = false,
  --   opts = {
  --     provider = "copilot",
  --     copilot = {
  --       model = "claude-3.7-sonnet",
  --     },
  --   },
  --   build = "make",
  --   dependencies = {
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "muniftanjim/nui.nvim",
  --     "nvim-telescope/telescope.nvim",
  --     "hrsh7th/nvim-cmp",
  --     "ibhagwan/fzf-lua",
  --     "nvim-tree/nvim-web-devicons",
  --     "zbirenbaum/copilot.lua",
  --     {
  --       "hakonharnes/img-clip.nvim",
  --       event = "VeryLazy",
  --       opts = {
  --         default = {
  --           embed_image_as_base64 = false,
  --           prompt_for_file_name = false,
  --           drag_and_drop = {
  --             insert_mode = true,
  --           },
  --           use_absolute_path = true,
  --         },
  --       },
  --     },
  --     {
  --       'meanderingprogrammer/render-markdown.nvim',
  --       opts = {
  --         file_types = { "markdown", "avante" },
  --       },
  --       ft = { "markdown", "avante" },
  --     },
  --   },
  -- },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      model = "claude-3.7-sonnet",
    },
  },
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   config = function()
  --     require("copilot_cmp").setup()
  --   end
  -- },
  -- {
  --   "exafunction/codeium.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup({
  --       enable_cmp_source = false,
  --       virtual_text = {
  --         enabled = true,
  --         manual = false,
  --         filetypes = {},
  --         default_filetype_enabled = true,
  --         idle_delay = 75,
  --         virtual_text_priority = 65535,
  --         map_keys = true,
  --         accept_fallback = nil,
  --         key_bindings = {
  --           accept = "<Tab>",
  --           accept_word = false,
  --           accept_line = "<S-Tab>",
  --           clear = "<c-e>",
  --           next = "<c-j>",
  --           prev = "<c-k>",
  --         }
  --       }
  --     })
  --   end
  -- }
}
