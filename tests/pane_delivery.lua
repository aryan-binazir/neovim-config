local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.runtimepath:prepend(root)

local function equal(actual, expected)
	assert(vim.deep_equal(actual, expected), vim.inspect(actual) .. " ~= " .. vim.inspect(expected))
end

for _, backend in ipairs({ "tmux", "herdr" }) do
	local calls, notices, ready = {}, {}, nil
	local opens = true
	local function record(method, ...)
		table.insert(calls, { method, ... })
	end
	local adapter = {
		ensure_or_open = function(name, command)
			record("open", name, command)
			return opens
		end,
		wait_ready = function(timeout, callback)
			record("wait", timeout)
			ready = callback
		end,
		send = function(text, focus)
			record("send", text, focus)
		end,
		send_block = function(text, focus)
			record("block", text, focus)
		end,
		toggle = function(name, command)
			record("toggle", name, command)
		end,
	}
	vim.env.HERDR_ENV = backend == "herdr" and "1" or nil
	package.loaded["ai.pane"] = nil
	package.loaded["ai.pane_tmux"] = nil
	package.loaded["ai.pane_herdr"] = nil
	package.preload["ai.pane_" .. backend] = function()
		return adapter
	end
	local other = backend == "tmux" and "herdr" or "tmux"
	package.preload["ai.pane_" .. other] = function()
		error("loaded the wrong backend")
	end
	vim.notify = function(message, level)
		table.insert(notices, { message, level })
	end
	local pane = require("ai.pane")

	local reference = "/tmp/literal $file:3 "
	pane.deliver("synthetic", "synthetic-command", reference, true)
	equal(calls, { { "open", "synthetic", "synthetic-command" }, { "wait", 15000 } })
	assert(type(ready) == "function")
	ready(true)
	equal(calls[3], { "send", reference, true })
	equal(notices, {})

	calls, ready = {}, nil
	pane.deliver_block("synthetic", "synthetic-command", "first\nsecond\n", false)
	equal(calls, { { "open", "synthetic", "synthetic-command" }, { "wait", 15000 } })
	ready(true)
	equal(calls[3], { "block", "first\nsecond\n", false })

	calls, ready = {}, nil
	opens = false
	pane.deliver("synthetic", "synthetic-command", "never", true)
	equal(calls, { { "open", "synthetic", "synthetic-command" } })
	equal(ready, nil)
	equal(notices, {})

	calls, ready = {}, nil
	opens = true
	pane.deliver_block("synthetic", "synthetic-command", "never\n", true)
	ready(false)
	equal(calls, { { "open", "synthetic", "synthetic-command" }, { "wait", 15000 } })
	equal(notices, { { "AI pane did not become ready; nothing sent", vim.log.levels.WARN } })

	calls = {}
	pane.toggle("other", "other-command")
	equal(calls, { { "toggle", "other", "other-command" } })
	print("PASS " .. backend .. " delivery, failure, timeout and toggle")
end

print("pane_delivery checks passed")
