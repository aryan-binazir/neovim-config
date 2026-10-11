local M = {}

local claude_argv = { "claude", "--permission-mode", "auto" }
local codex_argv = {
	"codex",
	"--sandbox",
	"workspace-write",
	"--ask-for-approval",
	"on-request",
	"-c",
	"approvals_reviewer=auto_review",
	"-c",
	"sandbox_workspace_write.network_access=true",
}

local opencode_argv = { "opencode" }
local pi_argv = { "pi" }

M.tools = {
	claude = {
		argv = claude_argv,
	},
	codex = {
		argv = codex_argv,
	},
	opencode = {
		argv = opencode_argv,
	},
	pi = {
		argv = pi_argv,
	},
}

for _, tool in pairs(M.tools) do
	tool.cmd = table.concat(vim.tbl_map(vim.fn.shellescape, tool.argv), " ")
end

function M.resolve(opts)
	if opts == nil then
		opts = {}
	elseif type(opts) ~= "table" then
		error("ai.setup opts must be a table")
	end
	local tool = opts.tool
	if tool == nil then
		tool = "pi"
	end
	local config = {
		tool = tool,
	}

	if not M.tools[config.tool] then
		local names = vim.tbl_keys(M.tools)
		table.sort(names)
		error(
			"invalid value for config.tool: "
				.. tostring(config.tool)
				.. ' (expected one of: "'
				.. table.concat(names, '", "')
				.. '")'
		)
	end
	return config
end

return M
