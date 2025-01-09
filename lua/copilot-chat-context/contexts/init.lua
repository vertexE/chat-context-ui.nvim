local M = {}

--- @param state ccc.State
M.attach = function(state)
    require("copilot-chat-context.contexts.blocks").setup(state)
    require("copilot-chat-context.contexts.knowledge").setup(state)
    require("copilot-chat-context.contexts.selection").setup(state)
    require("copilot-chat-context.contexts.copilot").setup(state)
    -- require("copilot-chat-context.contexts.debugger").setup(state) -- TODO: impl
    -- require("copilot-chat-context.contexts.git").setup(state) -- TODO: impl
    require("copilot-chat-context.contexts.urls").setup(state)
    require("copilot-chat-context.contexts.patterns").setup(state)
    require("copilot-chat-context.contexts.task").setup(state)
end

return M
