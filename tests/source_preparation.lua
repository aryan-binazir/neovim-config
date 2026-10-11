vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local tmp = assert(vim.uv.fs_realpath(assert(vim.env.AI_TEST_TMP)))
local sent, blocks, pane_opens = {}, {}, 0
local function record(text)
	table.insert(sent, text)
end
package.loaded["ai.pane"] = {
	ensure_or_open = function()
		pane_opens = pane_opens + 1
		return true
	end,
	wait_ready = function(_, done)
		done(true)
	end,
	send = record,
	send_block = record,
	deliver = function(_, text)
		record(text)
	end,
	deliver_block = function(tool, text, focus)
		table.insert(blocks, { tool = tool, text = text, focus = focus })
		record(text)
	end,
	toggle = function()
		pane_opens = pane_opens + 1
	end,
}
vim.system = function()
	error("source preparation must not launch subprocesses")
end
require("ai.keymaps").setup({ tool = "codex" })
local function equal(actual, expected)
	assert(vim.deep_equal(actual, expected), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local function mapping(mode, lhs)
	return assert(vim.fn.maparg(lhs, mode, false, true).callback)
end
local function source(name)
	vim.cmd.enew({ bang = true })
	local path = tmp .. "/" .. name
	vim.api.nvim_buf_set_name(0, path)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha", "beta", "gamma" })
	return path, vim.api.nvim_get_current_buf()
end
local function format_on_save(buf)
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "formatted" })
		end,
	})
end
local function visual()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>2GVj", true, false, true), "nx", false)
	equal(vim.fn.mode(), "V")
end
local function test(name, run)
	local ok, err = xpcall(run, debug.traceback)
	if not ok then
		io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
		os.exit(1)
	end
	print("PASS " .. name)
end

test("line and selection references capture after saving", function()
	for _, mode in ipairs({ "n", "v" }) do
		local path, buf = source("reference-" .. mode .. ".lua")
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
		if mode == "v" then
			visual()
		end
		format_on_save(buf)
		mapping(mode, "<leader>cx")()
		equal(sent[#sent], path .. (mode == "v" and ":3-4 " or ":3 "))
		equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
		vim.api.nvim_feedkeys("", "x", false)
	end
end)

test("file reference captures the path before saving", function()
	local path, buf = source("file.lua")
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			vim.api.nvim_buf_set_name(buf, tmp .. "/renamed.lua")
		end,
	})
	mapping("n", "<leader>cp")()
	equal(sent[#sent], path .. " ")
	equal(vim.bo[buf].modified, false)
end)

test("scoped fixes capture before input and save the original buffer", function()
	for _, mode in ipairs({ "n", "v" }) do
		local path, buf = source("fix-" .. mode .. ".lua")
		format_on_save(buf)
		local other_path, other = source("other-" .. mode .. ".lua")
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
		if mode == "v" then
			visual()
		end
		local before, prompted = #blocks, false
		vim.fn.input = function()
			prompted = true
			equal(vim.fn.filereadable(path), 0)
			vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "changed during input" })
			vim.api.nvim_set_current_buf(other)
			return "fix it"
		end
		mapping(mode, "<leader>cf")()
		if mode == "v" then
			equal(prompted, false)
			vim.api.nvim_feedkeys("", "x", false)
		end
		assert(vim.wait(500, function()
			return #blocks == before + 1
		end))
		local delivery = blocks[#blocks]
		equal(delivery.tool, "codex")
		equal(delivery.focus, true)
		equal(delivery.text, table.concat({
			"Location: " .. path .. (mode == "v" and ":2-3" or ":2"),
			"",
			"```",
			mode == "v" and "2: beta\n3: gamma" or "1: alpha\n2: beta\n3: gamma",
			"```",
			"",
			"fix it\n",
		}, "\n"))
		equal(vim.fn.readfile(path), { "formatted", "alpha", "changed during input", "gamma" })
		equal(vim.fn.filereadable(other_path), 0)
		equal(vim.api.nvim_get_current_buf(), other)
		equal(#blocks, before + 1)
	end
end)

test("cancelled fixes do not save, send, or open a pane", function()
	for _, mode in ipairs({ "n", "v" }) do
		local path = source("cancel-" .. mode .. ".lua")
		if mode == "v" then
			visual()
		end
		local before, prompted = #blocks, false
		local sent_before, opens_before = #sent, pane_opens
		vim.fn.input = function()
			prompted = true
			return ""
		end
		mapping(mode, "<leader>cf")()
		vim.api.nvim_feedkeys("", "x", false)
		assert(vim.wait(500, function()
			return prompted
		end))
		equal(#blocks, before)
		equal(#sent, sent_before)
		equal(pane_opens, opens_before)
		equal(vim.fn.filereadable(path), 0)
	end
end)

test("scoped fixes route through every configured interactive tool without a timeout", function()
	local config = require("ai.config")
	for tool in pairs(config.tools) do
		local resolved = config.resolve({ tool = tool })
		equal(resolved.tool, tool)
		require("ai.keymaps").setup(resolved)
		local path = source("tool-" .. tool .. ".lua")
		vim.fn.input = function()
			return "continue working"
		end
		local before = #blocks
		mapping("n", "<leader>cf")()
		equal(#blocks, before + 1)
		equal(blocks[#blocks].tool, tool)
		equal(blocks[#blocks].focus, true)
		assert(blocks[#blocks].text:find("Location: " .. path .. ":1", 1, true))
		assert(blocks[#blocks].text:find("\n\ncontinue working\n", 1, true))
		equal(config.resolve({ tool = tool, timeout_ms = "obsolete" }), resolved)
	end
	for _, opts in ipairs({ { tool = "unknown" }, { tool = false } }) do
		equal(pcall(config.resolve, opts), false)
	end
	require("ai.keymaps").setup({ tool = "codex" })
end)

test("Pi is the default interactive agent", function()
	local config = require("ai.config")
	equal(config.resolve(), { tool = "pi" })
	equal(config.resolve({}), { tool = "pi" })
	require("ai").setup()
	local path = source("default-pi.lua")
	vim.fn.input = function()
		return "fix with Pi"
	end
	local before = #blocks
	mapping("n", "<leader>cf")()
	equal(#blocks, before + 1)
	equal(blocks[#blocks].tool, "pi")
	assert(blocks[#blocks].text:find("Location: " .. path .. ":1", 1, true))
	require("ai.keymaps").setup({ tool = "codex" })
end)

test("job modules and job list mapping are absent", function()
	equal(vim.fn.maparg("<leader>cl", "n"), "")
	for _, name in ipairs({ "ai.jobs", "ai.ui" }) do
		equal(package.loaded[name], nil)
	end
end)

test("invalid original buffers after input never deliver", function()
	for _, kind in ipairs({ "unnamed", "nonfile", "readonly", "deleted", "save-error" }) do
		local path, buf = source("invalid-" .. kind .. ".lua")
		local other_path, other = source("invalid-other-" .. kind .. ".lua")
		vim.api.nvim_set_current_buf(buf)
		local before, opens_before = #sent, pane_opens
		vim.fn.input = function()
			if kind == "unnamed" then
				vim.api.nvim_buf_set_name(buf, "")
			elseif kind == "nonfile" then
				vim.bo[buf].buftype = "nofile"
			elseif kind == "readonly" then
				vim.bo[buf].readonly = true
			elseif kind == "deleted" then
				vim.api.nvim_buf_delete(buf, { force = true })
			else
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = buf,
					once = true,
					callback = function()
						error("test save failure")
					end,
				})
			end
			vim.api.nvim_set_current_buf(other)
			return "fix it"
		end
		mapping("n", "<leader>cf")()
		equal(#sent, before)
		equal(pane_opens, opens_before)
		equal(vim.fn.filereadable(path), 0)
		equal(vim.fn.filereadable(other_path), 0)
		equal(vim.api.nvim_get_current_buf(), other)
	end
end)

test("scoped_prompt returns nil for invalid sources", function()
	local context = require("ai.context")
	for _, kind in ipairs({ "unnamed", "nonfile", "readonly", "deleted" }) do
		local _, buf = source("prompt-invalid-" .. kind .. ".lua")
		local captured = assert(context.scoped_fix("line"))
		if kind == "unnamed" then
			vim.api.nvim_buf_set_name(buf, "")
		elseif kind == "nonfile" then
			vim.bo[buf].buftype = "nofile"
		elseif kind == "readonly" then
			vim.bo[buf].readonly = true
		else
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		equal(context.scoped_prompt(captured, "fix it"), nil)
	end
end)

test("diagnostics subscribe before saving and wait for 300ms of quiet", function()
	local path, buf = source("diagnostics.lua")
	local ns, last_event = vim.api.nvim_create_namespace("quiet"), nil
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 1)
			vim.diagnostic.set(ns, buf, { { lnum = 0, col = 0, message = "early" } })
			vim.defer_fn(function()
				last_event = vim.uv.hrtime()
				vim.diagnostic.set(ns, buf, {
					{ lnum = 2, col = 1, message = "last\nmessage", severity = vim.diagnostic.severity.WARN },
					{ lnum = 0, col = 0, message = "first", severity = vim.diagnostic.severity.ERROR },
				})
			end, 120)
		end,
	})
	mapping("n", "<leader>ce")()
	local elapsed = (vim.uv.hrtime() - assert(last_event)) / 1e6
	assert(elapsed >= 280 and elapsed < 450, "quiet period took " .. elapsed .. "ms")
	equal(
		sent[#sent],
		"Diagnostics for " .. path .. ":\n" .. path .. ":1:1: [E] first\n" .. path .. ":3:2: [W] last message\n"
	)
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 0)
end)

test("diagnostic wait stops at one second despite ongoing events", function()
	local path, buf = source("busy.lua")
	local ns, timer = vim.api.nvim_create_namespace("busy"), assert(vim.uv.new_timer())
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			timer:start(
				0,
				80,
				vim.schedule_wrap(function()
					vim.diagnostic.set(
						ns,
						buf,
						{ { lnum = 0, col = 0, message = "busy", severity = vim.diagnostic.severity.HINT } }
					)
				end)
			)
		end,
	})
	local started = vim.uv.hrtime()
	mapping("n", "<leader>ce")()
	local elapsed = (vim.uv.hrtime() - started) / 1e6
	timer:stop()
	timer:close()
	assert(elapsed >= 950 and elapsed < 1200, "diagnostic cap took " .. elapsed .. "ms")
	equal(sent[#sent], "Diagnostics for " .. path .. ":\n" .. path .. ":1:1: [H] busy\n")
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 0)
end)

test("failed diagnostic save removes its subscription without sending", function()
	local _, buf = source("readonly.lua")
	vim.bo[buf].readonly = true
	local before = #sent
	local ok, err = pcall(mapping("n", "<leader>ce"))
	assert(not ok and tostring(err):find("E45", 1, true))
	equal(#sent, before)
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 0)
	vim.bo[buf].readonly = false
end)

test("quickfix blocks preserve locations and normalize multiline messages", function()
	local path = source("quickfix.lua")
	vim.fn.setqflist({
		{ filename = path, lnum = 0, col = 0, text = "path only" },
		{ filename = path, lnum = 2, col = 3, text = "first\r\nsecond" },
	})
	mapping("n", "<leader>cq")()
	equal(sent[#sent], "Quickfix list:\n" .. path .. ": path only\n" .. path .. ":2:3: first second\n")
	local before = #sent
	vim.fn.setqflist({})
	mapping("n", "<leader>cq")()
	equal(#sent, before)
end)

print("source_preparation checks passed")
