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
      mode = "agentic",
      auto_suggestions_provider = "copilot",
      windows = {
        position = "smart",
        width = 60,
      },
      behaviour = {
        auto_suggestions = false,
        auto_focus_sidebar = true,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
        minimize_diff = true,
        enable_token_counting = true,
        use_cwd_as_project_root = true,
        auto_check_diagnostics = true,
        auto_approve_tool_permissions = false,
      },
      selector = {
        provider = "telescope",
        provider_opts = {},
      },
      input = {
        provider = "native",
        provider_opts = {},
      },
      memory = { enabled = false },
      hints = { enabled = false },
      repo_map = {
        ignore_patterns = { "%.git", "%.worktree", "__pycache__", "node_modules" },
        negate_patterns = {},
      },
      providers = {
        copilot = {
          model = "gpt-4.1",
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
      },
      -- Tool management
      disabled_tools = {},
      custom_tools = {},
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
}
