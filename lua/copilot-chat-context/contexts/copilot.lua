local M = {}

local store = require("copilot-chat-context.store")
local config = require("copilot-chat-context.config")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_context({
        id = config.git_staged,
        active = false,
        ui = "menu",
        getter = function(_)
            return "\n\n#git:staged\n\n"
        end,
    })
    store.register_context({
        id = config.buffer,
        active = false,
        ui = "menu",
        getter = function(_)
            return "" -- handled by selection
        end,
    })
    store.register_context({
        id = config.file_tree,
        active = false,
        ui = "menu",
        getter = function(_)
            return "\n\n#files\n\n"
        end,
    })
    return state
end

return M
