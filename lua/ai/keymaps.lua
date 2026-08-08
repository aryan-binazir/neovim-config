local yank = require("yank")
local pane = require("ai.pane")
local llm_jobs = require("ai.jobs")
local ui = require("ai.ui")

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

local function llm_location_label(file, range)
	return (file .. ":" .. range):gsub("%c", " ")
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
	local function default_split_cmd()
		return tools[config.tool].cmd
	end

	local function send_reference(result)
		if pane.ensure_or_open(default_split_cmd()) then
			pane.send(result .. " ", true)
		else
			print("AI pane closed.")
		end
	end

	vim.keymap.set("n", "<leader>cx", function()
		local file = current_file_or_notify()
		if not file then
			return
		end
		send_reference(file .. ":" .. vim.fn.line("."))
	end, { desc = "send current line" })

	vim.keymap.set("v", "<leader>cx", function()
		send_reference(yank.yank_selection(false, true))
	end, { desc = "send selection" })

	vim.keymap.set("n", "<leader>cc", function()
		pane.toggle(tools.claude.cmd)
	end, { desc = "claude code pane" })

	vim.keymap.set("n", "<leader>cd", function()
		pane.toggle(tools.codex.cmd)
	end, { desc = "codex pane" })

	vim.keymap.set("n", "<leader>cp", function()
		send_reference(vim.fn.expand("%:p"))
	end, { desc = "send file path" })

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

		llm_jobs.run(llm_location_label(file, tostring(line)), snippet, message, bufnr)
	end, { desc = "run scoped fix" })

	vim.keymap.set("v", "<leader>cf", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local start_line, end_line = yank.visual_range()
		local file = current_file_or_notify()
		if not file then
			yank.feed_escape()
			return
		end
		local range = yank.format_range(start_line, end_line)
		yank.feed_escape()

		vim.schedule(function()
			local message = vim.fn.input("LLM Message: ")
			if message == "" then
				return
			end
			local snippet = cf_snippet(bufnr, start_line, end_line)
			llm_jobs.run(llm_location_label(file, range), snippet, message, bufnr)
		end)
	end, { desc = "run scoped fix with selection" })
end

return M
