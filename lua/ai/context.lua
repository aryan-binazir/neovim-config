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
	return tostring(message):gsub("[\r\n]+", " ")
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
			table.insert(
				lines,
				string.format("%s:%d:%d: %s", absolute_path(path), item.lnum, item.col, single_line(item.text))
			)
		end
	end
	return lines
end

return M
