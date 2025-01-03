local M = {}

local notify = require("copilot-chat-context.external.notify")

local _chat

--- setup depends on notify.setup()
M.setup = function()
	local status, chat = pcall(require, "CopilotChat")
	if status then
		_chat = chat
	else
		notify.add("missing CopilotChat plugin", "ERROR", { timeout = 2000, hg = "DiagnosticError" })
	end
end

M.client = function()
	return _chat
end

return M
