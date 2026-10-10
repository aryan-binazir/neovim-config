vim.opt.runtimepath:prepend(vim.env.PANE_TEST_ROOT)
local backend = vim.env.PANE_BACKEND
local state_path = vim.env.PANE_FIXTURE
local notices = {}
vim.notify = function(message, level)
	table.insert(notices, { message = message, level = level })
end
local function state()
	return vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
end
local function save(value)
	vim.fn.writefile({ vim.json.encode(value) }, state_path)
end
local function reset(extra)
	package.loaded["ai.pane"] = nil
	package.loaded["ai.pane_tmux"] = nil
	package.loaded["ai.pane_herdr"] = nil
	notices = {}
	save(vim.tbl_extend("force", { panes = vim.empty_dict(), next = 0, calls = {}, sent = {} }, extra or {}))
	return require("ai.pane")
end
local function equal(actual, expected)
	assert(vim.deep_equal(actual, expected), vim.inspect(actual) .. " ~= " .. vim.inspect(expected))
end
local function wait_for(predicate, timeout)
	assert(
		vim.wait(timeout or 4000, predicate, 20),
		"condition not reached: " .. vim.inspect(state()) .. vim.inspect(notices)
	)
end
local function sent()
	return #(state().sent or {})
end
local function timer_count()
	local count = 0
	vim.uv.walk(function(handle)
		if handle:get_type() == "timer" and not handle:is_closing() then
			count = count + 1
		end
	end)
	return count
end
local initial_timers = timer_count()
local pane = reset()
pane.deliver("synthetic", "synthetic-command", "/tmp/file $literal:3 ", true)
wait_for(function()
	return sent() == 1
end)
equal(state().sent[1].text, "/tmp/file $literal:3 ")
equal(state().sent[1].kind, backend == "tmux" and "reference" or "text")
equal(state().focus, state().sent[1].target)
print("PASS " .. backend .. " public reference delivery")
local before_block = state()
before_block.focus = nil
save(before_block)
pane.deliver_block("other", "must-not-run", "first\nsecond\n", true)
wait_for(function()
	return sent() == 2
end)
equal(state().sent[2].text, "first\nsecond\n")
equal(state().sent[2].kind, backend == "tmux" and "block" or "text")
equal(state().focus, state().sent[2].target)
equal(state().sent[2].target, state().sent[1].target)
equal(state().next, 1)
print("PASS " .. backend .. " block, reuse across tools, small public interface")

local recovered = backend == "tmux" and "%42" or "recovered"
pane = reset({ panes = { [recovered] = { tool = "old-tool" } } })
pane.deliver("new-tool", "must-not-run", "recovered ", false)
wait_for(function()
	return sent() == 1
end)
equal(state().sent[1].target, recovered)
equal(state().next, 0)
equal(state().focus, nil)
print("PASS " .. backend .. " marked recovery preserves tool and optional focus")

local current = state()
current.panes = vim.empty_dict()
save(current)
pane.deliver("synthetic", "synthetic-command", "after death ", true)
wait_for(function()
	return sent() == 2
end)
assert(state().sent[2].target ~= recovered)
equal(state().next, 1)
print("PASS " .. backend .. " dead pane reopens")

pane = reset({ shell_polls = 1 })
local began = vim.uv.hrtime()
pane.deliver("synthetic", "synthetic-command", "delayed ", true)
wait_for(function()
	return sent() == 1
end)
local elapsed = (vim.uv.hrtime() - began) / 1000000
assert(elapsed >= (backend == "tmux" and 1500 or 200), tostring(elapsed))
local delivery_delay = (state().sent_at - state().ready_at) / 1000000
if backend == "tmux" then
	assert(delivery_delay >= 1500, "tmux lost startup grace")
else
	assert(delivery_delay < 1500, "Herdr gained tmux grace")
end
print("PASS " .. backend .. " distinct readiness/grace")

pane = reset({ mark_fail = true })
pane.deliver("synthetic", "synthetic-command", "unmarked but delivered ", true)
wait_for(function()
	return sent() == 1
end)
equal(#notices, 1)
assert(notices[1].message:find("could not be marked for recovery", 1, true))
equal(notices[1].level, vim.log.levels.WARN)
print("PASS " .. backend .. " marker failure warns and still delivers")

pane = reset({ split_fail = true })
pane.deliver("synthetic", "synthetic-command", "never ", true)
equal(sent(), 0)
equal(#notices, 1)
assert(notices[1].message:find("Failed to create", 1, true))
print("PASS " .. backend .. " failed split sends nothing")

if backend == "herdr" then
	pane = reset({ run_fail = true })
	pane.deliver_block("synthetic", "synthetic-command", "never\n", true)
	equal(sent(), 0)
	equal(state().panes, vim.empty_dict())
	assert(notices[1].message:find("Failed to start", 1, true))
	print("PASS Herdr failed run closes created pane")
	pane = reset({ panes = { foreign = { tool = "synthetic", tab = "other-tab" } } })
	pane.deliver("synthetic", "synthetic-command", "own tab ", true)
	wait_for(function()
		return sent() == 1
	end)
	assert(state().sent[1].target ~= "foreign")
	print("PASS Herdr tab recovery scope")
end

pane = reset({ send_fail = true })
pane.deliver("synthetic", "synthetic-command", "never ", true)
wait_for(function()
	return #notices == 1
end)
equal(sent(), 0)
equal(state().focus, nil)
assert(notices[1].message:find("Failed to send", 1, true))
print("PASS " .. backend .. " failed send does not focus")

pane = reset({ never_ready = true })
began = vim.uv.hrtime()
pane.deliver_block("synthetic", "synthetic-command", "never\n", true)
wait_for(function()
	return #notices == 1
end, 25000)
elapsed = (vim.uv.hrtime() - began) / 1000000
assert(elapsed >= 15000 and elapsed < 20000, tostring(elapsed))
equal(notices[1], { message = "AI pane did not become ready; nothing sent", level = vim.log.levels.WARN })
equal(sent(), 0)
print("PASS " .. backend .. " full 15s timeout warns and sends nothing")

if backend == "tmux" then
	pane = reset({ shell_polls = 1 })
	pane.deliver("first", "synthetic-command", "mutable target ", true)
	wait_for(function()
		return (state().polls or 0) >= 2
	end)
	pane.toggle("replacement", "synthetic-command")
	wait_for(function()
		return sent() == 1
	end)
	equal(state().sent[1].target, "%2")
	print("PASS tmux replacement during grace preserves mutable send routing")
else
	pane = reset({ never_ready = true })
	pane.deliver("first", "synthetic-command", "never ", true)
	wait_for(function()
		return (state().polls or 0) >= 1
	end)
	pane.toggle("replacement", "synthetic-command")
	wait_for(function()
		return #notices == 2
	end)
	equal(sent(), 0)
	equal(notices[2].message, "AI pane did not become ready; nothing sent")
	print("PASS Herdr replacement cancels pending delivery")
end
equal(timer_count(), initial_timers)
print("PASS " .. backend .. " completed/failure/replacement delivery timers stopped")

pane = reset()
package.loaded["ai.keymaps"] = nil
vim.g.mapleader = " "
require("ai.config").tools.claude.cmd = "synthetic-command"
require("ai.keymaps").setup({ tool = "claude" })
local file = vim.env.PANE_TEST_TMP .. "/literal $file.txt"
vim.fn.writefile({ "before", "second" }, file)
vim.cmd.edit(vim.fn.fnameescape(file))
vim.api.nvim_buf_set_lines(0, 0, 1, false, { "saved before delivery" })
local function mapping(mode, lhs)
	local before_mapping = state()
	before_mapping.focus = nil
	save(before_mapping)
	local entry = vim.fn.maparg(lhs, mode, false, true)
	assert(type(entry.callback) == "function", "mapping callback absent")
	entry.callback()
end
mapping("n", "<leader>cp")
wait_for(function()
	return sent() == 1
end)
equal(state().sent[1].text, file .. " ")
equal(state().sent[1].kind, backend == "tmux" and "reference" or "text")
equal(state().focus, state().sent[1].target)
equal(vim.fn.readfile(file)[1], "saved before delivery")
vim.api.nvim_win_set_cursor(0, { 2, 0 })
mapping("n", "<leader>cx")
wait_for(function()
	return sent() == 2
end)
equal(state().sent[2].text, file .. ":2 ")
equal(state().sent[2].kind, backend == "tmux" and "reference" or "text")
equal(state().focus, state().sent[2].target)
vim.cmd("normal! ggVj")
mapping("v", "<leader>cx")
wait_for(function()
	return sent() == 3
end)
equal(state().sent[3].text, file .. ":1-2 ")
equal(state().sent[3].kind, backend == "tmux" and "reference" or "text")
equal(state().focus, state().sent[3].target)
vim.fn.setqflist({ { filename = file, lnum = 2, col = 3, text = "synthetic issue" } })
mapping("n", "<leader>cq")
wait_for(function()
	return sent() == 4
end)
equal(state().sent[4].text, "Quickfix list:\n" .. file .. ":2:3: synthetic issue\n")
equal(state().sent[4].kind, backend == "tmux" and "block" or "text")
equal(state().focus, state().sent[4].target)
local ns = vim.api.nvim_create_namespace("pane-delivery-test")
vim.diagnostic.set(
	ns,
	0,
	{ { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = "synthetic diagnostic" } }
)
mapping("n", "<leader>ce")
wait_for(function()
	return sent() == 5
end)
equal(state().sent[5].text, "Diagnostics for " .. file .. ":\n" .. file .. ":1:1: [E] synthetic diagnostic\n")
equal(state().sent[5].kind, backend == "tmux" and "block" or "text")
equal(state().focus, state().sent[5].target)
print("PASS " .. backend .. " actual path, line, visual, quickfix and diagnostic mapping dispatch")

for _, invoked_backend in ipairs(state().backends) do
	equal(invoked_backend, backend)
end
local methods = vim.tbl_keys(pane)
table.sort(methods)
equal(methods, { "deliver", "deliver_block", "toggle" })
print("PASS " .. backend .. " backend selection and public interface")

local launched_synthetic = false
for _, call in ipairs(state().calls) do
	if backend == "tmux" and call[1] == "split-window" then
		assert(call[#call]:find("synthetic-command", 1, true))
		launched_synthetic = true
	elseif backend == "herdr" and call[1] == "pane" and call[2] == "run" then
		equal(call[4], "synthetic-command")
		launched_synthetic = true
	end
end
assert(launched_synthetic, "mapping did not launch configured synthetic command")
print("PASS " .. backend .. " configured command reaches external CLI")
