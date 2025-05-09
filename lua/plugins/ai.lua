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
          debounce = 75,
          keymap = {
            accept = false,
            accept_line = "<S-tab>",
            dismiss = "<C-e>",
            next = "<C-j>",
            prev = "<C-k>",
          },
        },
      })

      local suggestion = require("copilot.suggestion")

      vim.keymap.set("i", "<Tab>", function()
        if suggestion.is_visible() then
          suggestion.accept()
          return ""
        else
          return "<Tab>"
        end
      end, { expr = true, noremap = true })
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
        model = "claude-3.7-sonnet",
      },
      windows = {
        position = "smart",
        width = 60,
      },
      behaviour = {
        auto_suggestions = false, -- Experimental stage
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
        minimize_diff = true,
        enable_token_counting = true,
        enable_cursor_planning_mode = true,
      },
      cursor_applying_provider = "copilot",
      memory = { enabled = false },
      hints = { enabled = false },
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
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    cmd = {
      "CopilotChat",
      "CopilotChatExplain",
      "CopilotChatFix",
      "CopilotChatModels",
    },
    opts = {
      model = "claude-3.7-sonnet",
      -- model = "claude-3.7-sonnet-thought",
      window = {
        layout = "float",
        border = "rounded",
        width = 1,
        height = 0.9,
      },
      context = {
        enable = true,
        -- strategy = "selected",
        additional_context = "Comment with useful details about the code",
      },
      prompts = {
        Explain = "Explain how this code works in detail.",
        Refactor = "Refactor this code to improve clarity and readability.",
        Optimize = "Optimize this code for better performance.",
        Bugs = "What potential bugs or edge cases are in this code?",
        Documentation = "Generate comprehensive documentation for this code.",
        Tests = "Generate unit tests for this code.",
      },
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChat<CR>",              desc = "CopilotChat - Open" },
      { "<leader>ce", "<cmd>CopilotChatExplain<CR>",       desc = "CopilotChat - Explain Code" },
      { "<leader>cm", "<cmd>CopilotChatModels<CR>",        desc = "List Copilot Chat Models" },
      { "<leader>cf", "<cmd>CopilotChatFix<CR>",           desc = "CopilotChat - Fix Code" },
      { "<leader>ct", "<cmd>CopilotChatTests<CR>",         desc = "CopilotChat - Generate Tests" },
      { "<leader>cv", "<cmd>CopilotChatReview<CR>",        desc = "CopilotChat - Generate Tests" },
      { "<leader>cr", "<cmd>CopilotChatRefactor<CR>",      desc = "CopilotChat - Refactor Code" },
      { "<leader>cd", "<cmd>CopilotChatDocumentation<CR>", desc = "CopilotChat - Generate Docs" },
      -- Visual mode actions
      { "<leader>cc", ":CopilotChat<CR>",                  mode = "x",                           desc = "CopilotChat - Explain Selection" },
      { "<leader>cv", "<cmd>CopilotChatReview<CR>",        mode = "x",                           desc = "CopilotChat - Generate Tests" },
      { "<leader>ce", ":CopilotChatExplain<CR>",           mode = "x",                           desc = "CopilotChat - Explain Selection" },
      { "<leader>cf", ":CopilotChatFix<CR>",               mode = "x",                           desc = "CopilotChat - Fix Selection" },
    }
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
