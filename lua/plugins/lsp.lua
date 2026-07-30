return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			{ "folke/lazydev.nvim", ft = "lua", opts = {} },
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
							desc = "lsp: " .. desc
						end
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
					end

					-- Set up keybindings
					nmap("<leader>rn", vim.lsp.buf.rename, "rename symbol")
					nmap("<leader>ca", vim.lsp.buf.code_action, "code action")
					nmap("K", vim.lsp.buf.hover, "hover documentation")
					nmap("<C-k>", vim.lsp.buf.signature_help, "signature help")
					nmap("gD", vim.lsp.buf.declaration, "go to declaration")
					nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "add workspace folder")
					nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "remove workspace folder")
					nmap("<leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, "list workspace folders")

					-- Telescope-based keybindings (wrapped in pcall to avoid errors if telescope not loaded)
					local has_telescope, telescope = pcall(require, "telescope.builtin")
					if has_telescope then
						nmap("gd", telescope.lsp_definitions, "go to definition")
						nmap("gr", telescope.lsp_references, "go to references")
						nmap("gI", telescope.lsp_implementations, "go to implementation")
						nmap("<leader>D", telescope.lsp_type_definitions, "type definition")
						nmap("<leader>ds", telescope.lsp_document_symbols, "document symbols")
						nmap("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "workspace symbols")
					else
						-- Fallback to built-in LSP functions
						nmap("gd", vim.lsp.buf.definition, "go to definition")
						nmap("gr", vim.lsp.buf.references, "go to references")
						nmap("gI", vim.lsp.buf.implementation, "go to implementation")
						nmap("<leader>D", vim.lsp.buf.type_definition, "type definition")
					end

					-- Create Format command for this buffer
					vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
						vim.lsp.buf.format()
					end, { desc = "format current buffer with lsp" })
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			if has_cmp then
				capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
			else
				vim.notify("cmp_nvim_lsp not found, using basic capabilities", vim.log.levels.WARN)
			end

			local servers = {
				"lua_ls",
				"gopls",
				"pyright",
				"jsonls",
				"buf_ls",
				"biome",
				"golangci_lint_ls",
				"ts_ls",
			}

			vim.lsp.config("*", {
				capabilities = capabilities,
			})
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})

			require("mason-lspconfig").setup({
				ensure_installed = servers,
				automatic_enable = servers,
			})
		end,
	},
}
