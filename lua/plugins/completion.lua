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
				require("luasnip.loaders.from_vscode").lazy_load({ default_priority = 999 })
				local snippet_modules = {
					javascript = "javascript",
					typescript = "javascript",
					javascriptreact = "javascript",
					typescriptreact = "javascript",
					go = "go",
					python = "python",
					rust = "rust",
				}
				local function load_snippets(filetype)
					local module = snippet_modules[filetype]
					if module then
						require("snippets." .. module)
					end
				end
				vim.api.nvim_create_autocmd("FileType", {
					pattern = vim.tbl_keys(snippet_modules),
					callback = function(event)
						load_snippets(vim.bo[event.buf].filetype)
					end,
				})
				load_snippets(vim.bo.filetype)
			end,
		},
	},
	opts = {
		snippets = { preset = "luasnip" },
	},
}
