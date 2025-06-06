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
        use_cwd_as_project_root = true, -- Use current working directory as project root
      },
      selector = {
        provider = "telescope",
        provider_opts = {},
      },
      cursor_applying_provider = "copilot",
      memory = { enabled = false },
      hints = { enabled = false },
      -- Updated configuration structure - moved from vendors to providers
      providers = {
        copilot = {
          model = "gpt-4.1"
        },
        -- ["copilot-claude-3.5"] = {
        --   __inherited_from = "copilot",
        --   model = "claude-3.5-sonnet",
        --   display_name = "copilot/claude 3.5 sonnet",
        -- },
        -- ["copilot-claude-3.7"] = {
        --   __inherited_from = "copilot",
        --   model = "claude-3.7-sonnet",
        --   display_name = "copilot/claude 3.7 sonnet",
        -- },
        -- ["copilot-claude-3.7-thought"] = {
        --   __inherited_from = "copilot",
        --   model = "claude-3.7-sonnet-thought",
        --   display_name = "copilot/claude 3.7 sonnet (thought)",
        -- },
        -- ["copilot-o4-mini"] = {
        --   __inherited_from = "copilot",
        --   model = "o4-mini",
        --   display_name = "copilot/openai o4-mini",
        -- },
        -- ["copilot-gpt4-1"] = {
        --   __inherited_from = "copilot",
        --   model = "gpt-4.1",
        --   display_name = "copilot/gpt 4.1",
        -- },
        -- ["gemini-2.5-pro"] = {
        --   __inherited_from = "copilot",
        --   model = "gemini-2.5-pro",
        --   display_name = "copilot/gemini-2.5-pro",
        -- },
        -- ["copilot-claude-4-opus"] = {
        --   __inherited_from = "copilot",
        --   model = "claude-opus-4",
        --   display_name = "copilot/claude 4 opus",
        -- },
        -- ["copilot-claude-4-sonnet"] = {
        --   __inherited_from = "copilot",
        --   model = "claude-sonnet-4",
        --   display_name = "copilot/claude 4 sonnet",
        -- },
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
}
