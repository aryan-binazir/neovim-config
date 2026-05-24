local icons = {
	ai = { icon = "󰚩", color = "cyan" },
	action = { icon = "󰌵", color = "yellow" },
	close = { icon = "󰅖", color = "red" },
	diagnostics = { icon = "󰒡", color = "yellow" },
	file = { icon = "󰈔", color = "azure" },
	fix = { icon = "󰁨", color = "green" },
	git = { icon = "󰊢", color = "orange" },
	harpoon = { icon = "󱡅", color = "cyan" },
	jobs = { icon = "󰒋", color = "green" },
	search = { icon = "󰍉", color = "blue" },
	send = { icon = "󰍉", color = "cyan" },
	terminal = { icon = "", color = "blue" },
	toggle = { icon = "󰍉", color = "purple" },
	yank = { icon = "󰅍", color = "green" },
}

local approved_leader_prefixes = {
	["<space>"] = true,
	["/"] = true,
	["?"] = true,
	["1"] = true,
	["2"] = true,
	["3"] = true,
	["4"] = true,
	["5"] = true,
	["6"] = true,
	["7"] = true,
	["8"] = true,
	["9"] = true,
	c = true,
	d = true,
	e = true,
	h = true,
	m = true,
	q = true,
	s = true,
	t = true,
	u = true,
	y = true,
}

local function approved_leader_mapping(mapping)
	local lhs = mapping.lhs or ""
	local suffix = lhs:match("^<leader>(.+)$") or lhs:match("^<Leader>(.+)$") or lhs:match("^%s(.+)$")
	if not suffix then
		return true
	end

	local first_key = suffix:match("^<([^>]+)>") or suffix:sub(1, 1)
	return approved_leader_prefixes[first_key] == true
end

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		filter = approved_leader_mapping,
		icons = {
			group = "",
		},
		triggers = {
			{ "<leader>", mode = { "n", "v" } },
			{ "<leader>/", mode = { "n", "v" } },
			{ "<leader><space>", mode = { "n", "v" } },
			{ "<leader>?", mode = { "n", "v" } },
			{ "<leader>c", mode = { "n", "v" } },
			{ "<leader>d", mode = { "n", "v" } },
			{ "<leader>e", mode = { "n", "v" } },
			{ "<leader>h", mode = { "n", "v" } },
			{ "<leader>m", mode = { "n", "v" } },
			{ "<leader>s", mode = { "n", "v" } },
			{ "<leader>t", mode = { "n", "v" } },
			{ "<leader>u", mode = { "n", "v" } },
			{ "<leader>y", mode = { "n", "v" } },
		},
		plugins = {
			marks = false,
			registers = false,
			spelling = {
				enabled = false,
			},
			presets = {
				operators = false,
				motions = false,
				text_objects = false,
				windows = false,
				nav = false,
				z = false,
				g = false,
			},
		},
		spec = {
			{ "<leader>/", desc = "search current buffer", icon = icons.search },
			{ "<leader><space>", desc = "find buffers", icon = icons.file },
			{ "<leader>?", desc = "recent files", icon = icons.file },
			{ "<leader>1", desc = "harpoon files 1-9", icon = icons.harpoon },
			{ "<leader>2", hidden = true },
			{ "<leader>3", hidden = true },
			{ "<leader>4", hidden = true },
			{ "<leader>5", hidden = true },
			{ "<leader>6", hidden = true },
			{ "<leader>7", hidden = true },
			{ "<leader>8", hidden = true },
			{ "<leader>9", hidden = true },
			{ "<leader>c", group = "code / ai", icon = icons.ai },
			{ "<leader>ca", desc = "code action", icon = icons.action },
			{ "<leader>cc", desc = "open claude code", icon = icons.ai },
			{ "<leader>cd", desc = "open codex", icon = icons.terminal },
			{ "<leader>cf", desc = "run llm fix", icon = icons.fix, mode = { "n", "v" } },
			{ "<leader>cl", desc = "llm jobs", icon = icons.jobs },
			{ "<leader>cp", desc = "send file path", icon = icons.file },
			{ "<leader>cq", desc = "close ai pane", icon = icons.close },
			{ "<leader>cx", desc = "send line/selection", icon = icons.send, mode = { "n", "v" } },
			{ "<leader>d", group = "diagnostics", icon = icons.diagnostics },
			{ "<leader>e", desc = "diagnostic float", icon = icons.diagnostics },
			{ "<leader>h", group = "git hunks", icon = icons.git },
			{ "<leader>m", desc = "add to harpoon", icon = icons.harpoon },
			{ "<leader>q", desc = "diagnostics list", icon = icons.diagnostics },
			{ "<leader>s", group = "search", icon = icons.search },
			{ "<leader>t", group = "toggle", icon = icons.toggle },
			{ "<leader>u", desc = "undo history", icon = icons.search },
			{ "<leader>y", group = "yank", icon = icons.yank },
		},
	},
}
