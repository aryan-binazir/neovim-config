local yank = require("yank")
local pane = require("ai.pane")
local llm_jobs = require("ai.jobs")
local ui = require("ai.ui")
local context = require("ai.context")

local M = {}

local function current_file_or_notify()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
		return nil
	end
	return file
end

local tools = require("ai.config").tools

local function write_current_buffer()
	if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" and vim.bo.modified then
		vim.cmd("silent update")
		return true
	end
	return false
end

local function cf_snippet(bufnr, start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
	local numbered = {}
	for i, line in ipairs(lines) do
		table.insert(numbered, string.format("%d: %s", start_line + i - 1, line))
	end
	return table.concat(numbered, "\n")
end

local function cf_current_line_snippet()
	local line = vim.fn.line(".")
	local start_line = math.max(1, line - 10)
	local end_line = math.min(vim.api.nvim_buf_line_count(0), line + 10)
	local snippet = cf_snippet(0, start_line, end_line)
	return line, snippet
end

function M.setup(config)
	local function with_pane(fn)
		local ok = pane.ensure_or_open(config.tool, tools[config.tool].cmd)
		if not ok then
			return
		end
		pane.wait_ready(15000, function(ready)
			if ready then
				fn()
			else
				vim.notify("AI pane did not become ready; nothing sent", vim.log.levels.WARN)
			end
		end)
	end

	local function send_reference(result)
		write_current_buffer()
		with_pane(function()
			pane.send(result .. " ", true)
		end)
	end

	local function send_block(text)
		with_pane(function()
			pane.send_block(text .. "\n", true)
		end)
	end

	vim.keymap.set("n", "<leader>cx", function()
		write_current_buffer()
		local file = current_file_or_notify()
		if not file then
			return
		end
		send_reference(file .. ":" .. vim.fn.line("."))
	end, { desc = "send current line" })

	vim.keymap.set("v", "<leader>cx", function()
		write_current_buffer()
		local selection = yank.selection()
		if selection.path == "" then
			current_file_or_notify()
			return
		end
		send_reference(selection.ref)
	end, { desc = "send selection" })

	vim.keymap.set("n", "<leader>cc", function()
		pane.toggle("claude", tools.claude.cmd)
	end, { desc = "claude code pane" })

	vim.keymap.set("n", "<leader>cd", function()
		pane.toggle("codex", tools.codex.cmd)
	end, { desc = "codex pane" })

	vim.keymap.set("n", "<leader>cp", function()
		local file = current_file_or_notify()
		if not file then
			return
		end
		send_reference(file)
	end, { desc = "send file path" })

	vim.keymap.set("n", "<leader>ce", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local last_event
		local autocmd = vim.api.nvim_create_autocmd("DiagnosticChanged", {
			buffer = bufnr,
			callback = function()
				last_event = vim.uv.now()
			end,
		})
		local wrote = write_current_buffer()
		if wrote then
			vim.wait(1000, function()
				return last_event ~= nil and (vim.uv.now() - last_event) >= 300
			end, 50)
		end
		vim.api.nvim_del_autocmd(autocmd)
		local lines = context.diagnostic_lines(bufnr)
		if #lines == 0 then
			vim.notify("No diagnostics in buffer")
			return
		end
		local file = vim.fn.expand("%:p")
		send_block("Diagnostics for " .. file .. ":\n" .. table.concat(lines, "\n"))
	end, { desc = "send buffer diagnostics" })

	vim.keymap.set("n", "<leader>cq", function()
		local lines = context.quickfix_lines()
		if #lines == 0 then
			vim.notify("Quickfix list is empty")
			return
		end
		send_block("Quickfix list:\n" .. table.concat(lines, "\n"))
	end, { desc = "send quickfix list" })

	vim.keymap.set("n", "<leader>cl", ui.open_list, { desc = "job list" })

	vim.keymap.set("n", "<leader>cf", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local file = current_file_or_notify()
		if not file then
			return
		end
		local line, snippet = cf_current_line_snippet()
		local message = vim.fn.input("LLM Message: ")
		if message == "" then
			return
		end

		llm_jobs.run(((file .. ":" .. line):gsub("%c", " ")), snippet, message, bufnr)
	end, { desc = "run scoped fix" })

	vim.keymap.set("v", "<leader>cf", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local selection = yank.selection()
		if selection.path == "" then
			vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
			return
		end
		local snippet = cf_snippet(bufnr, selection.start_line, selection.end_line)

		vim.schedule(function()
			local message = vim.fn.input("LLM Message: ")
			if message == "" then
				return
			end
			llm_jobs.run((selection.ref:gsub("%c", " ")), snippet, message, bufnr)
		end)
	end, { desc = "run scoped fix with selection" })
end

return M
