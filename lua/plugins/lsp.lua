return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'williamboman/mason.nvim', config = true },
            'williamboman/mason-lspconfig.nvim',
            { 'j-hui/fidget.nvim',       opts = {} },
            'folke/neodev.nvim',
        },
        config = function()
            -- Format configuration
            local format_is_enabled = true
            vim.api.nvim_create_user_command('KickstartFormatToggle', function()
                format_is_enabled = not format_is_enabled
                print('Setting autoformatting to: ' .. tostring(format_is_enabled))
            end, {})

            local _augroups = {}
            local get_augroup = function(client)
                if not _augroups[client.id] then
                    local group_name = 'kickstart-lsp-format-' .. client.name
                    local id = vim.api.nvim_create_augroup(group_name, { clear = true })
                    _augroups[client.id] = id
                end
                return _augroups[client.id]
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('kickstart-lsp-attach-format', { clear = true }),
                callback = function(args)
                    local client_id = args.data.client_id
                    local client = vim.lsp.get_client_by_id(client_id)
                    local bufnr = args.buf

                    if not client.server_capabilities.documentFormattingProvider then
                        return
                    end

                    if client.name == 'ts_ls' then
                        return
                    end

                    vim.api.nvim_create_autocmd('BufWritePre', {
                        group = get_augroup(client),
                        buffer = bufnr,
                        callback = function()
                            if not format_is_enabled then
                                return
                            end

                            vim.lsp.buf.format {
                                async = false,
                                filter = function(c)
                                    return c.id == client.id
                                end,
                            }
                        end,
                    })
                end,
            })

            local on_attach = function(_, bufnr)
                local nmap = function(keys, func, desc)
                    if desc then
                        desc = 'LSP: ' .. desc
                    end
                    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
                end

                nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
                nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
                nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
                nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
                nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
                nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
                nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
                nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
                nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
                nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
                nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
                nmap('<leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, '[W]orkspace [L]ist Folders')

                vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
                    vim.lsp.buf.format()
                end, { desc = 'Format current buffer with LSP' })
            end

            require('mason').setup()
            require('mason-lspconfig').setup()

            local servers = {
                lua_ls = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            }

            require('neodev').setup()

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            local mason_lspconfig = require('mason-lspconfig')
            local ensure_installed_servers = { "lua_ls", "gopls", "pyright", "eslint", "jsonls" }

            mason_lspconfig.setup {
                ensure_installed = ensure_installed_servers,
            }

            for _, server_name in ipairs(ensure_installed_servers) do
                -- Get the default config from vim.lsp.config
                local default_config = vim.lsp.config[server_name]

                if not default_config then
                    vim.notify("Server config not found for: " .. server_name, vim.log.levels.WARN)
                    goto continue
                end

                -- Build our custom config
                local config = {
                    name = server_name,
                    cmd = default_config.cmd,
                    filetypes = default_config.filetypes,
                    root_dir = function(fname)
                        local util = require('lspconfig.util')
                        if server_name == 'gopls' then
                            return util.root_pattern('go.mod', 'go.work', '.git')(fname)
                        end
                        if default_config.root_markers then
                            return util.root_pattern(unpack(default_config.root_markers))(fname)
                        end
                        return util.find_git_ancestor(fname)
                    end,
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = servers[server_name],
                }

                -- Special handling for gopls
                if server_name == 'gopls' then
                    config.single_file_support = false
                end

                -- Register config and set up autocommands
                vim.lsp.config(server_name, config)

                -- Set up autocmd to start the server
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = default_config.filetypes,
                    callback = function(args)
                        vim.lsp.start(config, {
                            bufnr = args.buf,
                            reuse_client = function(client, conf)
                                return client.name == conf.name
                            end,
                        })
                    end,
                })

                ::continue::
            end
        end,
    }
}
