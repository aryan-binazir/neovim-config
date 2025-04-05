return {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            "debugloop/telescope-undo.nvim",
            config = function()
                require("telescope").load_extension("undo")
            end,
        },
        'nvim-telescope/telescope-ui-select.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
            cond = function()
                return vim.fn.executable 'make' == 1
            end,
        },
    },
    config = function()
        local telescope = require('telescope')
        telescope.setup {
            defaults = {
                mappings = {
                    i = {
                        ['<C-u>'] = false,
                        ['<C-d>'] = false,
                        ['<C-p>'] = require('telescope.actions.layout').toggle_preview,
                        ["<C-o>"] = require('telescope.actions').send_to_loclist + require('telescope.actions').open_loclist,
                    },

                    n = {
                        ["<C-o>"] = require('telescope.actions').send_selected_to_loclist + require('telescope.actions').open_loclist,
                    },                 
                },
                file_ignore_patterns = {
                    "node_modules",
                    ".git/"
                },
                layout_config = {
                    horizontal = {
                        width = 0.99,
                        height = 0.99,
                        preview_cutoff = 0,
                        preview_width = 0.6,
                    }
                },
                preview = {
                    hide_on_startup = false
                },
                attach_mappings = function(bufnr, map)
                    -- Force our C-p mapping in insert mode
                    vim.keymap.set('i', '<C-p>', require('telescope.actions.layout').toggle_preview, 
                        { buffer = bufnr, noremap = true, silent = true })
                    return true
                end
            },
            pickers = {},
            extensions = {
                ['ui-select'] = {
                    require('telescope.themes').get_dropdown(),
                },
                undo = {},
            },
        }

        pcall(telescope.load_extension, 'fzf')
        pcall(telescope.load_extension, 'ui-select')

        -- Git root functionality (commented out but preserved)
        -- local function find_git_root()
        --   -- Use the current buffer's path as the starting point for the git search
        --   local current_file = vim.api.nvim_buf_get_name(0)
        --   local current_dir
        --   local cwd = vim.fn.getcwd()
        --   -- If the buffer is not associated with a file, return nil
        --   if current_file == '' then
        --     current_dir = cwd
        --   else
        --     -- Extract the directory from the current file's path
        --     current_dir = vim.fn.fnamemodify(current_file, ':h')
        --   end
        --
        --   -- Find the Git root directory from the current file's path
        --   local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
        --   if vim.v.shell_error ~= 0 then
        --     print 'Not a git repository. Searching on current working directory'
        --     return cwd
        --   end
        --   return git_root
        -- end
        --
        -- -- Custom live_grep function to search in git root
        -- local function live_grep_git_root()
        --   local git_root = find_git_root()
        --   if git_root then
        --     require('telescope.builtin').live_grep {
        --       search_dirs = { git_root },
        --     }
        --   end
        -- end
        --
        -- vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

        -- Telescope keymaps
        vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>", { desc = 'Telescope [U]ndo' })
        vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles,
            { desc = '[?] Find recently opened files' })
        vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers,
            { desc = '[ ] Find existing buffers' })
        vim.keymap.set('n', '<leader>/', function()
            require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false,
            })
        end, { desc = '[/] Fuzzily search in current buffer' })
        vim.keymap.set('n', '<leader>s/', function()
            require('telescope.builtin').live_grep {
                grep_open_files = true,
                prompt_title = 'Live Grep in Open Files',
            }
        end, { desc = '[S]earch [/] in Open Files' })
        vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
        vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
        vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
        vim.keymap.set('n', '<C-f>', require('telescope.builtin').live_grep, { desc = 'Search by Grep C-f' })
        vim.keymap.set('n', '<C-p>', function()
            require('telescope.builtin').find_files({
                hidden = true,
                no_ignore = true,
            })
        end, { desc = 'Search Files C-p' })
        -- vim.keymap.set('n', '<leader>sG', ':LiveGrepGitRoot<cr>', { desc = '[S]earch by [G]rep on Git Root' })
        -- vim.keymap.set('n', '<leader>ss', require('telescope.builtin').builtin, { desc = '[S]earch [S]elect Telescope' })
        -- vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
    end,
}
