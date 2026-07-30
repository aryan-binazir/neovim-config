return {
	"saghen/blink.cmp",
	version = "1.*",
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			build = (function()
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = { "rafamadriz/friendly-snippets" },
			config = function()
				local luasnip = require("luasnip")
				luasnip.config.setup({})
				require("luasnip.loaders.from_vscode").lazy_load()
				require("snippets.javascript")
				require("snippets.go")
				require("snippets.python")
			end,
		},
	},
	opts = {
		snippets = { preset = "luasnip" },
	},
}
