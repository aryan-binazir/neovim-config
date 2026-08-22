local icons = {
	ai = { icon = "󰚩", color = "cyan" },
	action = { icon = "󰌵", color = "yellow" },
	buffers = { icon = "󰈔", color = "azure" },
	diagnostic_float = { icon = "󰨄", color = "yellow" },
	diagnostic_list = { icon = "󰉹", color = "yellow" },
	diagnostics = { icon = "󰗖", color = "yellow" },
	file = { icon = "󰈔", color = "azure" },
	fix = { icon = "󰁨", color = "green" },
	git = { icon = "󰊢", color = "orange" },
	harpoon_add = { icon = "󰃅", color = "cyan" },
	harpoon_files = { icon = "󰸕", color = "cyan" },
	jobs = { icon = "󰒋", color = "green" },
	recent = { icon = "󰋚", color = "azure" },
	search = { icon = "󰍉", color = "blue" },
	send = { icon = "󰍉", color = "cyan" },
	terminal = { icon = "", color = "blue" },
	toggle = { icon = "", color = "purple" },
	undo = { icon = "󰕌", color = "blue" },
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
	g = true,
	h = true,
	m = true,
	q = true,
	s = true,
	t = true,
	u = true,
	y = true,
}

local approved_non_leader_mappings = {
	["<C-g>"] = true,
	["<C-m>"] = true,
	["<C-n>"] = true,
}

-- One trigger per approved prefix, so the approval tables above stay the
-- single source of truth for what which-key reacts to.
local function trigger_list()
	local triggers = { { "<leader>", mode = { "n", "v" } } }
	local keys = {}
	for lhs in pairs(approved_non_leader_mappings) do
		table.insert(keys, lhs)
	end
	for prefix in pairs(approved_leader_prefixes) do
		table.insert(keys, "<leader>" .. prefix)
	end
	table.sort(keys)
	for _, lhs in ipairs(keys) do
		table.insert(triggers, { lhs, mode = { "n", "v" } })
	end
	return triggers
end

local function approved_leader_mapping(mapping)
	local lhs = mapping.lhs or ""
	if approved_non_leader_mappings[lhs] then
		return true
	end

	local suffix = lhs:match("^<leader>(.+)$") or lhs:match("^<Leader>(.+)$") or lhs:match("^%s(.+)$")
	if not suffix then
		return false
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
		triggers = trigger_list(),
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
			{ "<C-g>", desc = "harpoon menu", icon = icons.harpoon_files },
			{ "<C-m>", desc = "next harpoon", icon = icons.harpoon_files },
			{ "<C-n>", desc = "previous harpoon", icon = icons.harpoon_files },
			{ "<leader>/", desc = "search current buffer", icon = icons.search },
			{ "<leader><space>", desc = "find buffers", icon = icons.buffers },
			{ "<leader>?", desc = "recent files", icon = icons.recent },
			{ "<leader>1", desc = "harpoon files 1-9", icon = icons.harpoon_files },
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
			{ "<leader>ce", desc = "send diagnostics", icon = icons.send },
			{ "<leader>cf", desc = "run llm fix", icon = icons.fix, mode = { "n", "v" } },
			{ "<leader>cl", desc = "llm jobs", icon = icons.jobs },
			{ "<leader>cp", desc = "send file path", icon = icons.file },
			{ "<leader>cq", desc = "send quickfix", icon = icons.send },
			{ "<leader>cx", desc = "send line/selection", icon = icons.send, mode = { "n", "v" } },
			{ "<leader>d", group = "diagnostics", icon = icons.diagnostics },
			{ "<leader>e", desc = "diagnostic float", icon = icons.diagnostic_float },
			{ "<leader>g", group = "git", icon = icons.git },
			{ "<leader>h", group = "git hunks", icon = icons.git },
			{ "<leader>m", desc = "add to harpoon", icon = icons.harpoon_add },
			{ "<leader>q", desc = "diagnostics list", icon = icons.diagnostic_list },
			{ "<leader>s", group = "search", icon = icons.search },
			{ "<leader>t", group = "toggle", icon = icons.toggle },
			{ "<leader>u", desc = "undo history", icon = icons.undo },
			{ "<leader>y", group = "yank", icon = icons.yank },
		},
	},
}
