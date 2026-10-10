local M = {}

local severity_labels = {
	[vim.diagnostic.severity.ERROR] = "E",
	[vim.diagnostic.severity.WARN] = "W",
	[vim.diagnostic.severity.INFO] = "I",
	[vim.diagnostic.severity.HINT] = "H",
}

local function absolute_path(path)
	return vim.fn.fnamemodify(path, ":p")
end

local function single_line(message)
	return (tostring(message):gsub("[\r\n]+", " "))
end

function M.diagnostic_lines(bufnr)
	bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return {}
	end

	local diagnostics = vim.diagnostic.get(bufnr)
	table.sort(diagnostics, function(a, b)
		if a.lnum == b.lnum then
			return a.col < b.col
		end
		return a.lnum < b.lnum
	end)

	local lines = {}
	for _, diagnostic in ipairs(diagnostics) do
		table.insert(
			lines,
			string.format(
				"%s:%d:%d: [%s] %s",
				absolute_path(path),
				diagnostic.lnum + 1,
				diagnostic.col + 1,
				severity_labels[diagnostic.severity] or "?",
				single_line(diagnostic.message)
			)
		)
	end
	return lines
end

function M.quickfix_lines()
	local lines = {}
	for _, item in ipairs(vim.fn.getqflist()) do
		local path = item.bufnr > 0 and vim.api.nvim_buf_get_name(item.bufnr) or ""
		if path == "" then
			path = item.filename or ""
		end
		if path ~= "" then
			local location = absolute_path(path)
			if item.lnum > 0 then
				location = location .. ":" .. item.lnum
				if item.col > 0 then
					location = location .. ":" .. item.col
				end
			end
			table.insert(lines, location .. ": " .. single_line(item.text))
		end
	end
	return lines
end

local function current_file_or_notify()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
		return nil
	end
	return file
end

local function update_current_buffer()
	if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" and vim.bo.modified then
		vim.cmd("silent update")
		return true
	end
	return false
end

function M.reference(scope)
	local result
	if scope == "file" then
		result = current_file_or_notify()
	else
		update_current_buffer()
		if scope == "selection" then
			local selection = require("yank").selection()
			if selection.path == "" then
				current_file_or_notify()
				return nil
			end
			result = selection.ref
		else
			local file = current_file_or_notify()
			if file then
				result = file .. ":" .. vim.fn.line(".")
			end
		end
	end
	if not result then
		return nil
	end
	update_current_buffer()
	return result
end

function M.diagnostics()
	local bufnr = vim.api.nvim_get_current_buf()
	local last_event
	local autocmd = vim.api.nvim_create_autocmd("DiagnosticChanged", {
		buffer = bufnr,
		callback = function()
			last_event = vim.uv.now()
		end,
	})
	local ok, err = pcall(function()
		local wrote = update_current_buffer()
		if wrote then
			vim.wait(1000, function()
				return last_event ~= nil and (vim.uv.now() - last_event) >= 300
			end, 50)
		end
	end)
	if not ok then
		pcall(vim.api.nvim_del_autocmd, autocmd)
		error(err, 0)
	end
	vim.api.nvim_del_autocmd(autocmd)
	local lines = M.diagnostic_lines(bufnr)
	if #lines == 0 then
		vim.notify("No diagnostics in buffer")
		return nil
	end
	local file = vim.fn.expand("%:p")
	return "Diagnostics for " .. file .. ":\n" .. table.concat(lines, "\n")
end

local function numbered_snippet(bufnr, start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
	local numbered = {}
	for i, line in ipairs(lines) do
		table.insert(numbered, string.format("%d: %s", start_line + i - 1, line))
	end
	return table.concat(numbered, "\n")
end

function M.scoped_fix(scope)
	local bufnr = vim.api.nvim_get_current_buf()
	local location, start_line, end_line
	if scope == "selection" then
		local selection = require("yank").selection()
		if selection.path == "" then
			vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
			return nil
		end
		location = selection.ref
		start_line, end_line = selection.start_line, selection.end_line
	else
		local file = current_file_or_notify()
		if not file then
			return nil
		end
		local line = vim.fn.line(".")
		location = file .. ":" .. line
		start_line = math.max(1, line - 10)
		end_line = math.min(vim.api.nvim_buf_line_count(bufnr), line + 10)
	end
	return {
		bufnr = bufnr,
		location = (location:gsub("%c", " ")),
		snippet = numbered_snippet(bufnr, start_line, end_line),
	}
end

function M.quickfix()
	local lines = M.quickfix_lines()
	if #lines == 0 then
		vim.notify("Quickfix list is empty")
		return nil
	end
	return "Quickfix list:\n" .. table.concat(lines, "\n")
end

return M
