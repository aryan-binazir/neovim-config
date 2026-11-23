return {
	{ "folke/lazydev.nvim", ft = "lua", opts = {} },
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "mason-org/mason.nvim", config = true },
			"mason-org/mason-lspconfig.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			-- Must load before any server starts: blink registers its completion
			-- capabilities with vim.lsp.config("*") when it loads.
			"saghen/blink.cmp",
		},
		config = function()
			local idle_timers = {}
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local client_id = event.data.client_id
					local timer = idle_timers[client_id]
					idle_timers[client_id] = nil
					if timer and not timer:is_closing() then
						timer:stop()
						timer:close()
					end
					local bufnr = event.buf

					local nmap = function(keys, func, desc)
						if desc then
							desc = "lsp: " .. desc
						end
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
					end

					nmap("<leader>rn", vim.lsp.buf.rename, "rename symbol")
					nmap("<leader>ca", vim.lsp.buf.code_action, "code action")
					nmap("<C-k>", vim.lsp.buf.signature_help, "signature help")
					nmap("gD", vim.lsp.buf.declaration, "go to declaration")
					nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "add workspace folder")
					nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "remove workspace folder")
					nmap("<leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, "list workspace folders")

					local telescope = require("telescope.builtin")
					nmap("gd", telescope.lsp_definitions, "go to definition")
					-- nowait: without it every `gr` sits out 'timeoutlen' in case one of
					-- Neovim's built-in gra/gri/grn/grr/grt/grx maps is being typed.
					vim.keymap.set(
						"n",
						"gr",
						telescope.lsp_references,
						{ buffer = bufnr, nowait = true, desc = "lsp: go to references" }
					)
					nmap("gI", telescope.lsp_implementations, "go to implementation")
					nmap("<leader>D", telescope.lsp_type_definitions, "type definition")
					nmap("<leader>ds", telescope.lsp_document_symbols, "document symbols")
					nmap("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "workspace symbols")

					vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
						require("conform").format({ bufnr = bufnr })
					end, { desc = "format current buffer" })
				end,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("lsp-idle", { clear = true }),
				callback = function(event)
					local client_id = event.data.client_id
					vim.schedule(function()
						local client = vim.lsp.get_client_by_id(client_id)
						if
							not client
							or client:is_stopped()
							or next(client.attached_buffers)
							or idle_timers[client_id]
						then
							return
						end
						local timer
						timer = vim.defer_fn(function()
							if idle_timers[client_id] ~= timer then
								return
							end
							idle_timers[client_id] = nil
							client = vim.lsp.get_client_by_id(client_id)
							if client and not next(client.attached_buffers) then
								client:stop(1000)
							end
						end, 30000)
						idle_timers[client_id] = timer
					end)
				end,
			})

			-- gofmt leaves imports alone. gopls fixes them from its in-memory index;
			-- goimports would run the `go` command on every save.
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("go-organize-imports", { clear = true }),
				pattern = "*.go",
				callback = function(event)
					local client = vim.lsp.get_clients({ bufnr = event.buf, name = "gopls" })[1]
					if not client then
						return
					end
					local start_of_file = { line = 0, character = 0 }
					local response = client:request_sync("textDocument/codeAction", {
						textDocument = vim.lsp.util.make_text_document_params(event.buf),
						range = { start = start_of_file, ["end"] = start_of_file },
						context = { only = { "source.organizeImports" }, diagnostics = {} },
					}, 500, event.buf)
					if not response then
						-- gopls is still loading the module; the write goes ahead without the fix.
						vim.notify("gopls was too busy to fix imports on this save; save again", vim.log.levels.WARN)
						return
					end
					for _, action in ipairs(response.result or {}) do
						if action.edit then
							vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
						end
					end
				end,
			})

			local gopls_path = vim.g.gopls_path
			if gopls_path ~= nil and gopls_path ~= "" and vim.fn.executable(gopls_path) ~= 1 then
				vim.notify(
					("Configured gopls path %q is not executable; falling back to Mason-managed gopls"):format(
						gopls_path
					),
					vim.log.levels.WARN
				)
				gopls_path = nil
			end

			local servers = {
				"lua_ls",
				"gopls",
				"pyright",
				"ruff",
				"jsonls",
				"buf_ls",
				"biome",
				"golangci_lint_ls",
				"ts_ls",
			}

			vim.lsp.config("golangci_lint_ls", { before_init = function() end })
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			})
			vim.lsp.config("gopls", {
				cmd = gopls_path ~= nil and gopls_path ~= "" and { gopls_path } or nil,
				settings = {
					gopls = {
						directoryFilters = { "-**/node_modules", "-**/_scratch" },
					},
				},
			})
			-- Biome formats Markdown as CommonMark only (it would rewrite GFM tables) and
			-- conform falls back to LSP formatting on save, so keep it to code and JSON.
			vim.lsp.config("biome", {
				filetypes = vim.tbl_filter(function(filetype)
					return filetype ~= "markdown" and filetype ~= "yaml"
				end, vim.lsp.config.biome.filetypes),
			})
			vim.lsp.config("ts_ls", {
				init_options = {
					disableAutomaticTypingAcquisition = true,
					tsserver = { useSyntaxServer = "never" },
				},
			})

			require("mason-lspconfig").setup({
				-- format.lua pins biome, ruff and typescript-language-server; registry installs would race those versions.
				ensure_installed = vim.tbl_filter(function(server)
					return server ~= "biome" and server ~= "ruff" and server ~= "ts_ls"
				end, servers),
				automatic_enable = servers,
			})

			-- rust-analyzer comes from rustup (`rustup component add rust-analyzer`) rather than
			-- Mason so it stays version-matched with the compiler.
			vim.lsp.config("rust_analyzer", {
				settings = {
					["rust-analyzer"] = {
						files = { exclude = { "_scratch" } },
						check = { command = "clippy" },
					},
				},
			})
			vim.lsp.enable("rust_analyzer")
		end,
	},
}
