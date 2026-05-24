local config_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local local_config = config_root .. "/local.lua"

if vim.fn.filereadable(local_config) ~= 1 then
	error("Missing local.lua. Copy local.lua.example to local.lua and edit per machine.")
end

dofile(local_config)

local required_local_values = {}

for _, required in ipairs(required_local_values) do
	local value = vim.g[required.name]
	if type(value) ~= required.kind then
		error("local.lua must set vim.g." .. required.name .. " as " .. required.kind)
	end
end

require("options")
require("keymaps_general")
require("ai").setup(vim.g.ai or {})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	change_detection = {
		notify = false,
	},
})
