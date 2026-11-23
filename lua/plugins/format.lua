return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				{ "stylua", version = "v2.6.0" },
				{ "biome", version = "2.6.8" },
				{ "ruff", version = "0.17.6" },
				{ "goimports", version = "v0.53.0" },
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
				-- goimports formats like gofmt and also fixes imports; gofmt covers machines without it.
				go = { "goimports", "gofmt", stop_after_first = true },
				rust = { "rustfmt" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				css = { "biome" },
			},
			-- Shared by format-on-save and :Format.
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = {
				timeout_ms = 500,
			},
		},
	},
}
