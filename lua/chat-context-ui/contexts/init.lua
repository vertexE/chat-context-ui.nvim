local M = {}

--- @param state ccc.State
M.attach = function(state)
    require("chat-context-ui.contexts.blocks").setup(state)
    require("chat-context-ui.contexts.selection").setup(state)
    require("chat-context-ui.contexts.copilot").setup(state)
    -- require("chat-context-ui.contexts.debugger").setup(state) -- TODO: impl
    require("chat-context-ui.contexts.urls").setup(state)
end

return M
