return {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
        {
            'L3MON4D3/LuaSnip',
            build = (function()
                if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
                    return
                end
                return 'make install_jsregexp'
            end)(),
            dependencies = {
                {
                    'rafamadriz/friendly-snippets',
                    config = function()
                        require('luasnip.loaders.from_vscode').lazy_load()
                    end,
                },
            },
        },
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-buffer',
    },
    config = function()
        local cmp = require 'cmp'
        local luasnip = require 'luasnip'
        luasnip.config.setup {}

        -- Function to toggle completion
        local function toggle_completion()
            if cmp.visible() then
                cmp.close()
            end
            local ok, _ = pcall(require, 'cmp')
            if ok then
                cmp.setup.global({ enabled = not cmp.get_config().enabled })
                vim.notify("Completion " .. (cmp.get_config().enabled and "enabled" or "disabled"))
            end
        end

        -- Keymapping for completion toggle
        vim.keymap.set('n', '<Leader>tc', toggle_completion, { desc = 'Toggle completion' })

        cmp.setup {
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            completion = { completeopt = 'menu,menuone,noinsert' },
            mapping = cmp.mapping.preset.insert {
                ['<C-j>'] = cmp.mapping.select_next_item(),
                ['<C-k>'] = cmp.mapping.select_prev_item(),
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete {},
                ['<S-Tab>'] = cmp.mapping.confirm { select = true },
                ['<C-e>'] = cmp.mapping.abort(),
            },
            sources = {
                { name = 'copilot',  priority = 1000 },
                { name = 'nvim_lsp', priority = 1000 },
                { name = 'luasnip',  priority = 750 },
                { name = 'buffer',   priority = 500, keyword_length = 3 },
                { name = 'path',     priority = 250 },
            },
            formatting = {
                format = function(entry, vim_item)
                    vim_item.kind = ({
                        copilot = "[a]",
                        nvim_lsp = "[LSP]",
                        luasnip = "[Snip]",
                        buffer = "[Buf]",
                        path = "[Path]",
                    })[entry.source.name]
                    return vim_item
                end
            },
        }
    end,
}
