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
          print("SM d")
        else
          api.start()
          print("SM e")
        end
      end, { desc = "Toggle SM" })
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
          model = "claude-sonnet-4",
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
          file_types = { "avante" },
        },
        ft = { "avante" },
      },
    },
  },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   config = function()
  --     require("copilot").setup({
  --       suggestion = {
  --         enabled = false,
  --         hide_during_completion = true,
  --         auto_trigger = true,
  --         debounce = 75,
  --         keymap = {
  --           accept = false,
  --           accept_line = "<S-tab>",
  --           dismiss = "<C-e>",
  --           next = "<C-j>",
  --           prev = "<C-k>",
  --         },
  --       },
  --       filetypes = {
  --         markdown = true,
  --       },
  --     })
  --
  --     local suggestion = require("copilot.suggestion")
  --
  --     vim.keymap.set("i", "<Tab>", function()
  --       if suggestion.is_visible() then
  --         suggestion.accept()
  --         return ""
  --       else
  --         return "<Tab>"
  --       end
  --     end, { expr = true, noremap = true })
  --   end,
  -- },
}
