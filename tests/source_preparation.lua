vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local sent = {}
local executed = {}
vim.system = function(cmd, opts, callback)
	table.insert(executed, { cmd = cmd, opts = opts })
	vim.schedule(function()
		callback({ code = 0, signal = 0 })
	end)
	return { kill = function() end }
end
package.loaded["ai.pane"] = {
	ensure_or_open = function()
		return true
	end,
	wait_ready = function(_, callback)
		callback(true)
	end,
	send = function(text)
		table.insert(sent, text)
	end,
	send_block = function(text)
		table.insert(sent, text)
	end,
	toggle = function() end,
}
require("ai.jobs").setup({ tool = "codex", timeout_ms = 1000 })
require("ai.keymaps").setup({ tool = "codex" })
local tmp = assert(vim.env.AI_TEST_TMP)
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
	return vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "formatted" })
		end,
	})
end
local function test(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
		os.exit(1)
	end
	print("PASS " .. name)
end

test("normal reference captures the line after format-on-save", function()
	local path, buf = source("reference.lua")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	format_on_save(buf)
	mapping("n", "<leader>cx")()
	equal(sent[#sent], path .. ":3 ")
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
end)

test("scoped fix retains pre-save snippet while saving formatted content", function()
	local before = #executed
	local jobs_before = #require("ai.jobs").list()
	local path, buf = source("fix.lua")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	format_on_save(buf)
	vim.api.nvim_feedkeys("fix it\r", "t", false)
	mapping("n", "<leader>cf")()
	local job = require("ai.jobs").list()[jobs_before + 1]
	equal(job.location, path .. ":2")
	assert(job.prompt:find("1: alpha\n2: beta\n3: gamma", 1, true))
	assert(job.prompt:find("Request: fix it", 1, true))
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
	equal(#executed, before + 1)
	equal(executed[#executed].opts.cwd, tmp)
	vim.wait(500, function()
		return job.status == "done"
	end)
	equal(job.status, "done")
end)

test("reference retains Neovim write-post capture and modified-state behavior", function()
	local path, buf = source("post-write-reference.lua")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	format_on_save(buf)
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = buf,
		once = true,
		callback = function()
			vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "post-write" })
		end,
	})
	mapping("n", "<leader>cx")()
	equal(sent[#sent], path .. ":4 ")
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
	equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "post-write", "formatted", "alpha", "beta", "gamma" })
end)

test("context prepares a saved line reference", function()
	local path, buf = source("context-reference.lua")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	format_on_save(buf)
	equal(require("ai.context").reference("line"), path .. ":3")
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
end)

test("diagnostic subscription is removed after a failed save", function()
	vim.cmd("messages clear")
	local _, buf = source("diagnostic-failure.lua")
	local before = #vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf })
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			error("synthetic write failure")
		end,
	})
	local count = #sent
	local ok, err = pcall(mapping("n", "<leader>ce"))
	equal(ok, false)
	assert(tostring(err):find("synthetic write failure", 1, true))
	equal(#sent, count)
	assert(not vim.fn.execute("messages"):find("No diagnostics in buffer", 1, true))
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), before)
end)

test("context captures scoped fix without saving", function()
	local path, buf = source("context-fix.lua")
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	format_on_save(buf)
	local captured = require("ai.context").scoped_fix("line")
	equal(captured, { bufnr = buf, location = path .. ":2", snippet = "1: alpha\n2: beta\n3: gamma" })
	equal(vim.fn.filereadable(path), 0)
end)

test("context prepares quickfix text with shared formatting", function()
	local path = source("quickfix.lua")
	vim.fn.setqflist({ { filename = path, lnum = 2, col = 3, text = "first\nsecond" } })
	equal(require("ai.context").quickfix(), "Quickfix list:\n" .. path .. ":2:3: first second")
end)

local function visual()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>2GVj", true, false, true), "nx", false)
	equal(vim.fn.mode(), "V")
end

local function last_job()
	local list = require("ai.jobs").list()
	return list[#list]
end

local function run_fix(mode, message)
	vim.api.nvim_feedkeys(message .. "\r", "t", false)
	mapping(mode, "<leader>cf")()
end

test("visual reference saves before capturing its range", function()
	local path, buf = source("visual-reference.lua")
	visual()
	format_on_save(buf)
	mapping("v", "<leader>cx")()
	equal(sent[#sent], path .. ":3-4 ")
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
	vim.api.nvim_feedkeys("", "x", false)
	vim.wait(200, function()
		return false
	end)
	equal(vim.fn.mode(), "n")
end)

test("file reference saves without adding line numbers", function()
	local path, buf = source("file-reference.lua")
	format_on_save(buf)
	mapping("n", "<leader>cp")()
	equal(sent[#sent], path .. " ")
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
end)

test("unnamed references and fixes never dispatch", function()
	vim.cmd.enew({ bang = true })
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha", "beta", "gamma" })
	local count, executions = #sent, #executed
	mapping("n", "<leader>cx")()
	mapping("n", "<leader>cp")()
	mapping("n", "<leader>cf")()
	visual()
	mapping("v", "<leader>cx")()
	vim.api.nvim_feedkeys("", "x", false)
	visual()
	mapping("v", "<leader>cf")()
	vim.api.nvim_feedkeys("", "x", false)
	equal({ #sent, #executed }, { count, executions })
end)

test("cancelled scoped fix does not save or dispatch", function()
	local path, buf = source("cancelled.lua")
	format_on_save(buf)
	local count = #executed
	run_fix("n", "")
	equal(#executed, count)
	equal(vim.fn.filereadable(path), 0)
	equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "alpha", "beta", "gamma" })
end)

test("readonly references and scoped fixes do not dispatch after failed save", function()
	local path, buf = source("readonly.lua")
	vim.bo[buf].readonly = true
	local count, executions = #sent, #executed
	equal(pcall(mapping("n", "<leader>cx")), false)
	run_fix("n", "fix readonly")
	equal({ #sent, #executed }, { count, executions })
	equal(vim.fn.filereadable(path), 0)
	vim.bo[buf].readonly = false
end)

test("visual scoped fix captures before scheduled input and save", function()
	local path, buf = source("visual-fix.lua")
	visual()
	format_on_save(buf)
	local count = #executed
	mapping("v", "<leader>cf")()
	equal(#executed, count)
	vim.api.nvim_feedkeys("", "x", false)
	vim.api.nvim_feedkeys("fix selected\r", "t", false)
	vim.wait(500, function()
		return #executed == count + 1
	end)
	equal(#executed, count + 1)
	local job = last_job()
	equal(job.location, path .. ":2-3")
	assert(job.prompt:find("2: beta\n3: gamma", 1, true))
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
	vim.wait(500, function()
		return job.status == "done"
	end)
	equal(job.status, "done")
end)

test("diagnostics settle after the last real DiagnosticChanged event", function()
	local path, buf = source("diagnostics.lua")
	local namespace = vim.api.nvim_create_namespace("source-preparation-diagnostics")
	local before = #vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf })
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			assert(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }) > before)
			vim.diagnostic.set(
				namespace,
				buf,
				{ { lnum = 0, col = 0, message = "early", severity = vim.diagnostic.severity.ERROR } }
			)
			vim.defer_fn(function()
				vim.diagnostic.set(namespace, buf, {
					{ lnum = 2, col = 1, message = "last\nmessage", severity = vim.diagnostic.severity.WARN },
					{ lnum = 0, col = 0, message = "first", severity = vim.diagnostic.severity.ERROR },
				})
			end, 120)
		end,
	})
	local started = vim.uv.hrtime()
	mapping("n", "<leader>ce")()
	local elapsed = (vim.uv.hrtime() - started) / 1e6
	assert(elapsed >= 400 and elapsed < 1200, "diagnostic debounce took " .. elapsed)
	equal(
		sent[#sent],
		"Diagnostics for " .. path .. ":\n" .. path .. ":1:1: [E] first\n" .. path .. ":3:2: [W] last message\n"
	)
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), before)
	equal(vim.fn.readfile(path), { "alpha", "beta", "gamma" })
end)

test("diagnostic wait is capped even when no event arrives", function()
	local _, buf = source("no-event.lua")
	local before, count = #vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), #sent
	local started = vim.uv.hrtime()
	mapping("n", "<leader>ce")()
	local elapsed = (vim.uv.hrtime() - started) / 1e6
	assert(elapsed >= 900 and elapsed < 1400, "diagnostic cap took " .. elapsed)
	equal(#sent, count)
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), before)
end)

test("unmodified diagnostics do not wait or save", function()
	local path, buf = source("unmodified.lua")
	vim.cmd("silent write")
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			error("unexpected write")
		end,
	})
	local namespace = vim.api.nvim_create_namespace("source-preparation-existing")
	vim.diagnostic.set(
		namespace,
		buf,
		{ { lnum = 1, col = 0, message = "existing", severity = vim.diagnostic.severity.INFO } }
	)
	local started = vim.uv.hrtime()
	mapping("n", "<leader>ce")()
	assert((vim.uv.hrtime() - started) / 1e6 < 200)
	equal(sent[#sent], "Diagnostics for " .. path .. ":\n" .. path .. ":2:1: [I] existing\n")
end)

test("quickfix mapping retains formatting and empty-list cancellation", function()
	local path = source("quickfix-send.lua")
	vim.fn.setqflist({
		{ filename = path, lnum = 0, col = 0, text = "path only" },
		{ filename = path, lnum = 2, col = 0, text = "line\r\nonly" },
	})
	mapping("n", "<leader>cq")()
	equal(sent[#sent], "Quickfix list:\n" .. path .. ": path only\n" .. path .. ":2: line only\n")
	local count = #sent
	vim.fn.setqflist({})
	mapping("n", "<leader>cq")()
	equal(#sent, count)
end)

test("visual scoped fix saves the original buffer after a buffer switch", function()
	local path, buf = source("original.lua")
	format_on_save(buf)
	local other_path, other = source("other.lua")
	vim.api.nvim_set_current_buf(buf)
	visual()
	vim.schedule(function()
		vim.api.nvim_set_current_buf(other)
	end)
	local count = #executed
	mapping("v", "<leader>cf")()
	vim.api.nvim_feedkeys("", "x", false)
	vim.api.nvim_feedkeys("fix original\r", "t", false)
	vim.wait(500, function()
		return #executed == count + 1
	end)
	equal(#executed, count + 1)
	equal(last_job().location, path .. ":2-3")
	assert(last_job().prompt:find("2: beta\n3: gamma", 1, true))
	equal(vim.fn.readfile(path), { "formatted", "alpha", "beta", "gamma" })
	equal(vim.fn.filereadable(other_path), 0)
	equal(vim.api.nvim_get_current_buf(), other)
	vim.wait(500, function()
		return last_job().status == "done"
	end)
	equal(last_job().status, "done")
end)

test("wiped visual source never starts a scoped job", function()
	local path, buf = source("wiped-visual.lua")
	visual()
	vim.schedule(function()
		vim.api.nvim_buf_delete(buf, { force = true })
	end)
	local count = #executed
	mapping("v", "<leader>cf")()
	vim.api.nvim_feedkeys("", "x", false)
	vim.api.nvim_feedkeys("fix wiped\r", "t", false)
	vim.wait(200, function()
		return false
	end)
	equal(#executed, count)
	equal(vim.fn.filereadable(path), 0)
end)

test("cancelled visual input does not save or execute", function()
	local path = source("cancelled-visual.lua")
	visual()
	local count = #executed
	mapping("v", "<leader>cf")()
	vim.api.nvim_feedkeys("", "x", false)
	vim.api.nvim_feedkeys("\r", "t", false)
	vim.wait(200, function()
		return false
	end)
	equal(#executed, count)
	equal(vim.fn.filereadable(path), 0)
end)

test("named nonfile scoped source is rejected after input", function()
	local path, buf = source("scratch.lua")
	vim.bo[buf].buftype = "nofile"
	local count = #executed
	run_fix("n", "fix scratch")
	equal(#executed, count)
	equal(vim.fn.filereadable(path), 0)
end)

test("continuous diagnostics cannot extend the one-second cap", function()
	local path, buf = source("busy-diagnostics.lua")
	local namespace = vim.api.nvim_create_namespace("source-preparation-busy")
	local timer = vim.uv.new_timer()
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			timer:start(
				0,
				80,
				vim.schedule_wrap(function()
					vim.diagnostic.set(
						namespace,
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
	assert(elapsed >= 900 and elapsed < 1400, "continuous diagnostics took " .. elapsed)
	equal(sent[#sent], "Diagnostics for " .. path .. ":\n" .. path .. ":1:1: [H] busy\n")
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 0)
end)

test("readonly diagnostic save failure cleans its subscription", function()
	local _, buf = source("readonly-diagnostics.lua")
	vim.bo[buf].readonly = true
	local count = #sent
	equal(pcall(mapping("n", "<leader>ce")), false)
	equal(#sent, count)
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 0)
	vim.bo[buf].readonly = false
end)

test("clipboard diagnostics and quickfix use the existing text without saving", function()
	local clipboard = {}
	vim.g.clipboard = {
		name = "source-preparation-fixture",
		copy = {
			["+"] = function(lines)
				clipboard = lines
			end,
			["*"] = function() end,
		},
		paste = {
			["+"] = function()
				return { clipboard, "v" }
			end,
			["*"] = function()
				return { {}, "v" }
			end,
		},
		cache_enabled = 0,
	}
	local path, buf = source("clipboard.lua")
	local namespace = vim.api.nvim_create_namespace("source-preparation-clipboard")
	vim.diagnostic.set(
		namespace,
		buf,
		{ { lnum = 0, col = 2, message = "clipboard\nmessage", severity = vim.diagnostic.severity.ERROR } }
	)
	mapping("n", "<leader>yd")()
	equal(clipboard, { path .. ":1:3: [E] clipboard message" })
	vim.fn.setqflist({ { filename = path, lnum = 2, col = 0, text = "quickfix\nmessage" } })
	mapping("n", "<leader>yq")()
	equal(clipboard, { path .. ":2: quickfix message" })
	visual()
	mapping("v", "<leader>yc")()
	equal(clipboard, { path .. ":2-3", "beta", "gamma" })
	vim.api.nvim_feedkeys("", "x", false)
	visual()
	mapping("v", "<leader>ys")()
	equal(clipboard, { path .. ":2-3" })
	equal(vim.fn.filereadable(path), 0)
	vim.api.nvim_feedkeys("", "x", false)
	vim.wait(200, function()
		return false
	end)
	local namespace_id = vim.api.nvim_get_namespaces().selection_highlight
	equal(vim.api.nvim_buf_get_extmarks(buf, namespace_id, 0, -1, {}), {})
end)

test("unmodified readonly files retain reference and scoped-job dispatch", function()
	local path, buf = source("clean-readonly.lua")
	vim.cmd("silent write")
	vim.bo[buf].readonly = true
	local count = #executed
	mapping("n", "<leader>cx")()
	equal(sent[#sent], path .. ":1 ")
	run_fix("n", "fix clean readonly")
	equal(#executed, count + 1)
	vim.wait(500, function()
		return last_job().status == "done"
	end)
	equal(last_job().status, "done")
	equal(vim.fn.readfile(path), { "alpha", "beta", "gamma" })
	vim.bo[buf].readonly = false
end)

test("diagnostic header retains baseline current-file timing after a buffer switch", function()
	local path, buf = source("header-original.lua")
	local other_path, other = source("header-other.lua")
	vim.api.nvim_set_current_buf(buf)
	local namespace = vim.api.nvim_create_namespace("source-preparation-header")
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = buf,
		once = true,
		callback = function()
			vim.diagnostic.set(
				namespace,
				buf,
				{ { lnum = 0, col = 0, message = "original", severity = vim.diagnostic.severity.ERROR } }
			)
			vim.defer_fn(function()
				vim.api.nvim_set_current_buf(other)
			end, 80)
		end,
	})
	mapping("n", "<leader>ce")()
	equal(sent[#sent], "Diagnostics for " .. other_path .. ":\n" .. path .. ":1:1: [E] original\n")
	equal(vim.fn.filereadable(other_path), 0)
	equal(#vim.api.nvim_get_autocmds({ event = "DiagnosticChanged", buffer = buf }), 0)
end)

test("all AI mapping descriptions remain baseline", function()
	local descriptions = {
		{ "n", "<leader>cx", "send current line" },
		{ "v", "<leader>cx", "send selection" },
		{ "n", "<leader>cc", "claude code pane" },
		{ "n", "<leader>cd", "codex pane" },
		{ "n", "<leader>co", "opencode pane" },
		{ "n", "<leader>pi", "pi pane" },
		{ "n", "<leader>cp", "send file path" },
		{ "n", "<leader>ce", "send buffer diagnostics" },
		{ "n", "<leader>cq", "send quickfix list" },
		{ "n", "<leader>cl", "job list" },
		{ "n", "<leader>cf", "run scoped fix" },
		{ "v", "<leader>cf", "run scoped fix with selection" },
	}
	for _, item in ipairs(descriptions) do
		equal(vim.fn.maparg(item[2], item[1], false, true).desc, item[3])
	end
end)

print("source preparation checks passed")
