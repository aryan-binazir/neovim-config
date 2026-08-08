local M = {}

local claude_cmd = "claude --permission-mode auto"
local codex_cmd =
	"codex --sandbox workspace-write --ask-for-approval on-request -c approvals_reviewer=auto_review -c sandbox_workspace_write.network_access=true"

-- Per tool: `cmd` is the interactive command the tmux pane runs; `exec`
-- builds the argv for a one-shot background job from the same flags.
M.tools = {
	claude = {
		cmd = claude_cmd,
		exec = function(_, prompt)
			local argv = vim.split(claude_cmd, " ", { plain = true, trimempty = true })
			table.insert(argv, 2, "-p")
			table.insert(argv, prompt)
			return argv
		end,
	},
	codex = {
		cmd = codex_cmd,
		exec = function(root, prompt)
			return {
				"sh",
				"-c",
				"exec " .. codex_cmd .. ' exec --cd "$1" --color never --skip-git-repo-check "$2" </dev/null',
				"codex-cf",
				root,
				prompt,
			}
		end,
	},
}

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
	if type(config.timeout_ms) ~= "number" then
		error("invalid value for config.timeout_ms: " .. tostring(config.timeout_ms) .. " (expected number)")
	end

	return config
end

return M
