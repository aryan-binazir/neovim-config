require("yank")
local pane = require("ai.pane")
local llm_jobs = require("ai.jobs")
local ui = require("ai.ui")
local context = require("ai.context")

local M = {}

local tools = require("ai.config").tools

function M.setup(config)
	local function send_reference(result)
		pane.deliver(config.tool, tools[config.tool].cmd, result .. " ", true)
	end

	local function send_block(text)
		pane.deliver_block(config.tool, tools[config.tool].cmd, text .. "\n", true)
	end

	vim.keymap.set("n", "<leader>cx", function()
		local reference = context.reference("line")
		if reference then
			send_reference(reference)
		end
	end, { desc = "send current line" })

	vim.keymap.set("v", "<leader>cx", function()
		local reference = context.reference("selection")
		if reference then
			send_reference(reference)
		end
	end, { desc = "send selection" })

	vim.keymap.set("n", "<leader>cc", function()
		pane.toggle("claude", tools.claude.cmd)
	end, { desc = "claude code pane" })

	vim.keymap.set("n", "<leader>cd", function()
		pane.toggle("codex", tools.codex.cmd)
	end, { desc = "codex pane" })

	vim.keymap.set("n", "<leader>co", function()
		pane.toggle("opencode", tools.opencode.cmd)
	end, { desc = "opencode pane" })

	vim.keymap.set("n", "<leader>pi", function()
		pane.toggle("pi", tools.pi.cmd)
	end, { desc = "pi pane" })

	vim.keymap.set("n", "<leader>cp", function()
		local reference = context.reference("file")
		if reference then
			send_reference(reference)
		end
	end, { desc = "send file path" })

	vim.keymap.set("n", "<leader>ce", function()
		local text = context.diagnostics()
		if text then
			send_block(text)
		end
	end, { desc = "send buffer diagnostics" })

	vim.keymap.set("n", "<leader>cq", function()
		local text = context.quickfix()
		if text then
			send_block(text)
		end
	end, { desc = "send quickfix list" })

	vim.keymap.set("n", "<leader>cl", ui.open_list, { desc = "job list" })

	vim.keymap.set("n", "<leader>cf", function()
		local source = context.scoped_fix("line")
		if not source then
			return
		end
		local message = vim.fn.input("LLM Message: ")
		if message == "" then
			return
		end

		llm_jobs.run(source.location, source.snippet, message, source.bufnr)
	end, { desc = "run scoped fix" })

	vim.keymap.set("v", "<leader>cf", function()
		local source = context.scoped_fix("selection")
		if not source then
			return
		end

		vim.schedule(function()
			local message = vim.fn.input("LLM Message: ")
			if message == "" then
				return
			end
			llm_jobs.run(source.location, source.snippet, message, source.bufnr)
		end)
	end, { desc = "run scoped fix with selection" })
end

return M
