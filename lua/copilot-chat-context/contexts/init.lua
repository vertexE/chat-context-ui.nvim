local M = {}

--- @param state ccc.State
M.setup = function(state)
	require("copilot-chat-context.contexts.blocks").setup(state)
	require("copilot-chat-context.contexts.selection").setup(state)
	require("copilot-chat-context.contexts.copilot").setup(state)
	-- require("copilot-chat-context.contexts.debugger").setup(state)
	require("copilot-chat-context.contexts.urls").setup(state)
	require("copilot-chat-context.contexts.patterns").setup(state)
	require("copilot-chat-context.contexts.task").setup(state)
end

return M
