vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local tmp, sent, executions = assert(vim.env.AI_TEST_TMP), {}, {}
local function record(text)
	table.insert(sent, text)
end
package.loaded["ai.pane"] = {
	ensure_or_open = function()
		return true
	end,
	wait_ready = function(_, done)
		done(true)
	end,
	send = record,
	send_block = record,
	deliver = function(_, _, text)
		record(text)
	end,
	deliver_block = function(_, _, text)
		record(text)
	end,
	toggle = function() end,
}
vim.system = function(cmd, opts, done)
	table.insert(executions, { cmd = cmd, opts = opts })
	vim.schedule(function()
		done({ code = 0, signal = 0 })
	end)
	return { kill = function() end }
end
local jobs = require("ai.jobs")
jobs.setup({ tool = "codex", timeout_ms = 1000 })
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
		local before, prompted = #executions, false
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
			return #executions == before + 1
		end))
		local job = jobs.list()[#jobs.list()]
		equal(job.location, path .. (mode == "v" and ":2-3" or ":2"))
		assert(job.prompt:find(mode == "v" and "2: beta\n3: gamma" or "1: alpha\n2: beta\n3: gamma", 1, true))
		assert(job.prompt:find("Request: fix it", 1, true))
		equal(vim.fn.readfile(path), { "formatted", "alpha", "changed during input", "gamma" })
		equal(vim.fn.filereadable(other_path), 0)
		equal(vim.api.nvim_get_current_buf(), other)
		equal(executions[#executions].opts.cwd, tmp)
		assert(vim.wait(500, function()
			return job.status == "done"
		end))
	end
end)

test("cancelled fixes do not save or execute", function()
	for _, mode in ipairs({ "n", "v" }) do
		local path = source("cancel-" .. mode .. ".lua")
		if mode == "v" then
			visual()
		end
		local before, prompted = #executions, false
		vim.fn.input = function()
			prompted = true
			return ""
		end
		mapping(mode, "<leader>cf")()
		vim.api.nvim_feedkeys("", "x", false)
		assert(vim.wait(500, function()
			return prompted
		end))
		equal(#executions, before)
		equal(vim.fn.filereadable(path), 0)
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
