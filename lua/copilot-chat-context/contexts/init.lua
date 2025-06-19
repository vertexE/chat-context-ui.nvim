local M = {}

--- @param state ccc.State
M.attach = function(state)
    require("copilot-chat-context.contexts.blocks").setup(state)
    require("copilot-chat-context.contexts.selection").setup(state)
    require("copilot-chat-context.contexts.copilot").setup(state)
    -- require("copilot-chat-context.contexts.debugger").setup(state) -- TODO: impl
    require("copilot-chat-context.contexts.urls").setup(state)
end

return M
