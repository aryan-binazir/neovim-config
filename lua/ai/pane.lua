local adapter = require(vim.env.HERDR_ENV == "1" and "ai.pane_herdr" or "ai.pane_tmux")
local tools = require("ai.config").tools

local M = {}

function M.toggle(name)
	adapter.toggle(name, tools[name].cmd)
end

local function deliver(name, send, text, focus)
	if not adapter.ensure_or_open(name, tools[name].cmd) then
		return
	end
	adapter.wait_ready(15000, function(ready)
		if ready then
			send(text, focus)
		else
			vim.notify("AI pane did not become ready; nothing sent", vim.log.levels.WARN)
		end
	end)
end

function M.deliver(name, text, focus)
	deliver(name, adapter.send, text, focus)
end

function M.deliver_block(name, text, focus)
	deliver(name, adapter.send_block, text, focus)
end

return M
