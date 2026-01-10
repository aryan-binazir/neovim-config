return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"folke/neodev.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Global LspAttach autocmd to ensure keymaps are set
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					local bufnr = event.buf

					local nmap = function(keys, func, desc)
						if desc then
							desc = "LSP: " .. desc
						end
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
					end

					-- Set up keybindings
					nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					nmap("K", vim.lsp.buf.hover, "Hover Documentation")
					nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
					nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
					nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
					nmap("<leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, "[W]orkspace [L]ist Folders")

					-- Telescope-based keybindings (wrapped in pcall to avoid errors if telescope not loaded)
					local has_telescope, telescope = pcall(require, "telescope.builtin")
					if has_telescope then
						nmap("gd", telescope.lsp_definitions, "[G]oto [D]efinition")
						nmap("gr", telescope.lsp_references, "[G]oto [R]eferences")
						nmap("gI", telescope.lsp_implementations, "[G]oto [I]mplementation")
						nmap("<leader>D", telescope.lsp_type_definitions, "Type [D]efinition")
						nmap("<leader>ds", telescope.lsp_document_symbols, "[D]ocument [S]ymbols")
						nmap("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
					else
						-- Fallback to built-in LSP functions
						nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
						nmap("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
						nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
						nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
					end

					-- Create Format command for this buffer
					vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
						vim.lsp.buf.format()
					end, { desc = "Format current buffer with LSP" })
				end,
			})

			-- Keep the on_attach for compatibility but it just triggers the autocmd
			local on_attach = function(client, bufnr)
				-- The LspAttach autocmd will handle everything
			end

			require("mason").setup()
			require("mason-lspconfig").setup()

			local servers = {
				lua_ls = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			}

			require("neodev").setup()

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			if has_cmp then
				capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
			else
				vim.notify("cmp_nvim_lsp not found, using basic capabilities", vim.log.levels.WARN)
			end

			local mason_lspconfig = require("mason-lspconfig")
			local ensure_installed_servers = {
				"lua_ls",
				"gopls",
				"pyright",
				"eslint",
				"jsonls",
				"buf_ls",
				"biome",
				"golangci_lint_ls",
				"graphql",
				"ts_ls",
			}

			mason_lspconfig.setup({
				ensure_installed = ensure_installed_servers,
				handlers = {
					function(server_name)
						local server_config = {
							capabilities = capabilities,
							on_attach = on_attach,
							settings = servers[server_name] or {},
						}

						require("lspconfig")[server_name].setup(server_config)
					end,
				},
			})
		end,
	},
}
