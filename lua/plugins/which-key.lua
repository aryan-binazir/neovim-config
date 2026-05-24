local icons = {
	ai = { icon = "󰚩", color = "cyan" },
	action = { icon = "󰌵", color = "yellow" },
	close = { icon = "󰅖", color = "red" },
	diagnostics = { icon = "󰒡", color = "yellow" },
	file = { icon = "󰈔", color = "azure" },
	fix = { icon = "󰁨", color = "green" },
	git = { icon = "󰊢", color = "orange" },
	jobs = { icon = "󰒋", color = "green" },
	search = { icon = "󰍉", color = "blue" },
	send = { icon = "󰍉", color = "cyan" },
	terminal = { icon = "", color = "blue" },
	toggle = { icon = "󰨙", color = "purple" },
	yank = { icon = "󰅍", color = "green" },
}

local approved_leader_prefixes = {
	c = true,
	d = true,
	h = true,
	q = true,
	s = true,
	t = true,
	y = true,
}

local function approved_leader_mapping(mapping)
	local lhs = mapping.lhs or ""
	local suffix = lhs:match("^<leader>(.+)$") or lhs:match("^<Leader>(.+)$")
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
		triggers = {
			{ "<leader>", mode = { "n", "v" } },
			{ "<leader>c", mode = { "n", "v" } },
			{ "<leader>d", mode = { "n", "v" } },
			{ "<leader>h", mode = { "n", "v" } },
			{ "<leader>s", mode = { "n", "v" } },
			{ "<leader>t", mode = { "n", "v" } },
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
			{ "<leader>h", group = "git hunks", icon = icons.git },
			{ "<leader>q", desc = "diagnostics list", icon = icons.diagnostics },
			{ "<leader>s", group = "search", icon = icons.search },
			{ "<leader>t", group = "toggle", icon = icons.toggle },
			{ "<leader>y", group = "yank", icon = icons.yank },
		},
	},
}
