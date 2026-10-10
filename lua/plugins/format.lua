return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				{ "stylua", version = "v2.6.0" },
				{ "biome", version = "2.5.15" },
				{ "black", version = "26.10.1" },
				{ "typescript-language-server", version = "6.0.2" },
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
				python = { "black" },
				go = { "gofmt" },
				rust = { "rustfmt" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				css = { "biome" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		},
	},
}
