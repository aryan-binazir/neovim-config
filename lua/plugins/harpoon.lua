local keys = {
	{
		"<leader>m",
		function()
			require("harpoon"):list():add()
		end,
		desc = "add to harpoon",
	},
	{
		"<C-g>",
		function()
			local harpoon = require("harpoon")
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end,
		desc = "harpoon menu",
	},
	{
		"<C-n>",
		function()
			require("harpoon"):list():prev()
		end,
		desc = "previous harpoon",
	},
	{
		"<C-m>",
		function()
			require("harpoon"):list():next()
		end,
		desc = "next harpoon",
	},
}

for i = 1, 9 do
	table.insert(keys, {
		"<leader>" .. i,
		function()
			require("harpoon"):list():select(i)
		end,
		desc = "harpoon to file " .. i,
	})
end

return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = keys,
	config = function()
		require("harpoon"):setup()
	end,
}
