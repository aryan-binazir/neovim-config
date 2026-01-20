-- AI workflow keymaps

-- Helper for yanking paths
local function yank_paths(paths, label)
	vim.fn.setreg("+", table.concat(paths, "\n"))
	print("Yanked " .. #paths .. " " .. label)
end

-- Yank absolute file path
vim.keymap.set("n", "<leader>yp", function()
	yank_paths({ vim.fn.expand("%:p") }, "path")
end, { desc = "Yank absolute file path" })

-- Yank all buffer paths
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
end, { desc = "Yank all buffer paths" })

-- Yank all harpoon paths
vim.keymap.set("n", "<leader>yh", function()
	local ok, harpoon = pcall(require, "harpoon")
	if not ok then
		print("Harpoon not available")
		return
	end
	local paths = {}
	local cwd = vim.fn.getcwd() .. "/"
	for _, item in ipairs(harpoon:list().items) do
		if item.value and item.value ~= "" then
			table.insert(paths, cwd .. item.value)
		end
	end
	yank_paths(paths, "harpoon paths")
end, { desc = "Yank all harpoon paths" })

-- Helper for visual selection yanking
local yank_ns = vim.api.nvim_create_namespace("yank_selection_highlight")

local function yank_selection(include_code, skip_register)
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.fn.expand("%:p")
	local range = start_line == end_line and tostring(start_line) or (start_line .. "-" .. end_line)
	local result = path .. ":" .. range
	if include_code then
		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
		result = result .. "\n" .. table.concat(lines, "\n")
	end
	if not skip_register then
		vim.fn.setreg("+", result)
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	-- Highlight the yanked range
	vim.defer_fn(function()
		vim.highlight.range(bufnr, yank_ns, "IncSearch", { start_line - 1, 0 }, { end_line - 1, -1 })
		vim.defer_fn(function()
			vim.api.nvim_buf_clear_namespace(bufnr, yank_ns, 0, -1)
		end, 150)
	end, 0)
	if not skip_register then
		print("Yanked " .. (include_code and "selection with code" or "selection reference"))
	end
	return result
end

-- Yank selection reference (path:lines only)
vim.keymap.set("v", "<leader>ys", function()
	yank_selection(false)
end, { desc = "Yank file path and line numbers" })

-- Yank selection with code (path:lines + code content)
vim.keymap.set("v", "<leader>yc", function()
	yank_selection(true)
end, { desc = "Yank file path, lines, and code" })

-- AI tools in tmux splits
vim.g.ai_pane_id = nil

local function ai_pane_alive()
	if not vim.g.ai_pane_id then return false end
	local check = vim.fn.system("tmux display-message -t "
		.. vim.fn.shellescape(vim.g.ai_pane_id) .. " -p '#{pane_id}' 2>/dev/null")
	return vim.trim(check) ~= ""
end

-- Send selection to AI pane
vim.keymap.set("v", "<leader>cx", function()
	local result = yank_selection(false, true)
	-- Send to AI pane and focus it
	if ai_pane_alive() then
		vim.fn.system("tmux send-keys -t " .. vim.fn.shellescape(vim.g.ai_pane_id) .. " " .. vim.fn.shellescape(result .. " "))
		vim.fn.system("tmux select-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
	else
		print("AI pane closed. Use <leader>cc to open.")
	end
end, { desc = "Send selection to AI pane" })

-- Yank all file paths in Oil directory
vim.keymap.set("n", "<leader>yo", function()
	local ok, oil = pcall(require, "oil")
	if not ok then
		print("Oil not available")
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
end, { desc = "Yank all file paths in Oil directory" })

local function open_ai_split(cmd)
	if ai_pane_alive() then
		vim.fn.system("tmux kill-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
	end
	local pane_id = vim.fn.system(
		'tmux split-window -h -p 35 -P -F "#{pane_id}" -c '
			.. vim.fn.shellescape(vim.fn.getcwd())
			.. " '$SHELL -ic " .. cmd .. "'"
	)
	pane_id = vim.trim(pane_id)
	if pane_id == "" then
		print("Failed to create tmux split")
		return
	end
	vim.g.ai_pane_id = pane_id
end

vim.keymap.set("n", "<leader>cc", function()
	open_ai_split("cc")
end, { desc = "Open Claude Code in tmux split" })

vim.keymap.set("n", "<leader>cu", function()
	open_ai_split("cur")
end, { desc = "Open Cursor-agent in tmux split" })

vim.keymap.set("n", "<leader>cg", function()
	open_ai_split("gemini")
end, { desc = "Open Gemini in tmux split" })

vim.keymap.set("n", "<leader>co", function()
	open_ai_split("opencode")
end, { desc = "Open OpenCode in tmux split" })

vim.keymap.set("n", "<leader>cp", function()
	if ai_pane_alive() then
		local path = vim.fn.expand("%:p")
		vim.fn.system("tmux send-keys -t " .. vim.fn.shellescape(vim.g.ai_pane_id) .. " " .. vim.fn.shellescape(path .. " "))
		vim.fn.system("tmux select-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
	else
		print("AI pane closed. Use <leader>cc to open.")
	end
end, { desc = "Send file path to AI pane" })

vim.keymap.set("n", "<leader>cq", function()
	if ai_pane_alive() then
		vim.fn.system("tmux kill-pane -t " .. vim.fn.shellescape(vim.g.ai_pane_id))
		vim.g.ai_pane_id = nil
		print("AI pane closed")
	else
		print("No AI pane open")
	end
end, { desc = "Close AI pane" })
