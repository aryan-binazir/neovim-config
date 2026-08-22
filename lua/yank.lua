local M = {}

local function yank_paths(paths, label)
	vim.fn.setreg("+", table.concat(paths, "\n"))
	print("Yanked " .. #paths .. " " .. label)
end

local function optional_require(name, label)
	local ok, module = pcall(require, name)
	if not ok then
		print(label .. " not available")
		return nil
	end
	return module
end

function M.format_range(start_line, end_line)
	return start_line == end_line and tostring(start_line) or (start_line .. "-" .. end_line)
end

function M.visual_range()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	return start_line, end_line
end

function M.feed_escape()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

local yank_ns = vim.api.nvim_create_namespace("yank_selection_highlight")

function M.yank_selection(include_code, skip_register)
	local start_line, end_line = M.visual_range()
	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.fn.expand("%:p")
	local result = path .. ":" .. M.format_range(start_line, end_line)
	if include_code then
		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
		result = result .. "\n" .. table.concat(lines, "\n")
	end
	if not skip_register then
		vim.fn.setreg("+", result)
	end
	M.feed_escape()
	vim.defer_fn(function()
		vim.hl.range(bufnr, yank_ns, "IncSearch", { start_line - 1, 0 }, { end_line - 1, -1 })
		vim.defer_fn(function()
			vim.api.nvim_buf_clear_namespace(bufnr, yank_ns, 0, -1)
		end, 150)
	end, 0)
	if not skip_register then
		print("Yanked " .. (include_code and "selection with code" or "selection reference"))
	end
	return result
end

vim.keymap.set("n", "<leader>yp", function()
	yank_paths({ vim.fn.expand("%:p") }, "path")
end, { desc = "yank absolute file path" })

vim.keymap.set("n", "<leader>yb", function()
	local paths = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" then
				table.insert(paths, name)
			end
		end
	end
	yank_paths(paths, "buffer paths")
end, { desc = "yank all buffer paths" })

vim.keymap.set("n", "<leader>yh", function()
	local harpoon = optional_require("harpoon", "Harpoon")
	if not harpoon then
		return
	end
	local paths = {}
	local cwd = vim.fn.getcwd() .. "/"
	for _, item in ipairs(harpoon:list().items) do
		if item.value and item.value ~= "" then
			local path = item.value:sub(1, 1) == "/" and item.value or (cwd .. item.value)
			table.insert(paths, path)
		end
	end
	yank_paths(paths, "harpoon paths")
end, { desc = "yank all harpoon paths" })

vim.keymap.set("n", "<leader>yo", function()
	local oil = optional_require("oil", "Oil")
	if not oil then
		return
	end
	local dir = oil.get_current_dir()
	if not dir then
		print("Not in Oil buffer")
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local paths = {}
	for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
		local entry = oil.get_entry_on_line(bufnr, lnum)
		if entry and entry.type == "file" then
			table.insert(paths, dir .. entry.name)
		end
	end
	yank_paths(paths, "Oil paths")
end, { desc = "yank all file paths in oil directory" })

vim.keymap.set("n", "<leader>yd", function()
	local lines = require("ai.context").diagnostic_lines(0)
	if #lines == 0 then
		vim.notify("No diagnostics in buffer")
		return
	end
	yank_paths(lines, "diagnostics")
end, { desc = "yank buffer diagnostics" })

vim.keymap.set("n", "<leader>yq", function()
	local lines = require("ai.context").quickfix_lines()
	if #lines == 0 then
		vim.notify("Quickfix list is empty")
		return
	end
	yank_paths(lines, "quickfix entries")
end, { desc = "yank quickfix list" })

vim.keymap.set("v", "<leader>ys", function()
	M.yank_selection(false)
end, { desc = "yank file path and line numbers (full lines)" })

vim.keymap.set("v", "<leader>yc", function()
	M.yank_selection(true)
end, { desc = "yank file path, lines, and code (full lines)" })

return M
