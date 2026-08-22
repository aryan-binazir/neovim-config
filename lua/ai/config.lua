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

-- Per tool, `argv` is the interactive command; `cmd` is its shell-escaped pane form,
-- and `exec` builds the argv for a one-shot background job.
M.tools = {
	claude = {
		argv = claude_argv,
		exec = function(_, prompt)
			local argv = vim.deepcopy(claude_argv)
			vim.list_extend(argv, { "-p", prompt })
			return argv
		end,
	},
	codex = {
		argv = codex_argv,
		exec = function(root, prompt)
			local argv = vim.deepcopy(codex_argv)
			vim.list_extend(argv, { "exec", "--cd", root, "--color", "never", "--skip-git-repo-check", prompt })
			return argv
		end,
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
	local config = {
		tool = opts.tool,
		timeout_ms = opts.timeout_ms,
	}

	if not M.tools[config.tool] then
		error("invalid value for config.tool: " .. tostring(config.tool) .. ' (expected "codex" or "claude")')
	end
	if
		type(config.timeout_ms) ~= "number"
		or config.timeout_ms ~= config.timeout_ms
		or config.timeout_ms <= 0
		or config.timeout_ms == math.huge
		or config.timeout_ms ~= math.floor(config.timeout_ms)
	then
		error("invalid value for config.timeout_ms: " .. tostring(config.timeout_ms) .. " (expected positive integer)")
	end

	return config
end

return M
