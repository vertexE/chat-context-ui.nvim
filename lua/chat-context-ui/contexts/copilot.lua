local M = {}

local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

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
        id = config.buffers,
        active = false,
        ui = "menu",
        getter = function(_)
            return "#buffers"
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
