local save_budget_ms = 500
local formatter_reserve_ms = 200

local function organize_go_imports(bufnr, timeout_ms)
	local gopls = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })[1]
	if not gopls then
		return
	end
	local start_of_file = { line = 0, character = 0 }
	local response = gopls:request_sync("textDocument/codeAction", {
		textDocument = vim.lsp.util.make_text_document_params(bufnr),
		range = { start = start_of_file, ["end"] = start_of_file },
		context = { only = { "source.organizeImports" }, diagnostics = {} },
	}, timeout_ms, bufnr)
	if not response then
		vim.notify("gopls was too busy to fix imports on this save; save again", vim.log.levels.WARN)
		return
	end
	for _, action in ipairs(response.result or {}) do
		if action.edit then
			vim.lsp.util.apply_workspace_edit(action.edit, gopls.offset_encoding)
		end
	end
end

return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				{ "stylua", version = "v2.6.0" },
				{ "biome", version = "2.6.8" },
				{ "ruff", version = "0.17.6" },
				{ "typescript-language-server", version = "6.1.0" },
			},
		},
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_organize_imports", "ruff_format" },
				go = { "gofmt" },
				rust = { "rustfmt" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				css = { "biome" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = function(bufnr)
				local started = vim.uv.hrtime()
				if vim.bo[bufnr].filetype == "go" then
					organize_go_imports(bufnr, save_budget_ms - formatter_reserve_ms)
				end
				local spent_ms = math.ceil((vim.uv.hrtime() - started) / 1e6)
				return { timeout_ms = save_budget_ms - spent_ms }
			end,
		},
	},
}
