local M = {}

local files = require("copilot-chat-context.external.files")
local store = require("copilot-chat-context.store")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_action({
        name = "",
        msg = "",
        mode = "n",
        key = ",p",
        ui = "doc_patterns",
        hidden = false,
        apply = M.open,
    })
    store.register_context({
        name = "",
        key = ",,p",
        ui = "menu",
        active = false,
        getter = M.context,
    })
    return state
end

--- @param state ccc.State
M.open = function(state)
    return state
end

--- @param state ccc.State
--- @return string
M.context = function(state)
    local content = files.read(state.patterns.file_path)
    if content ~= nil then
        local prompt = "refer to the following coding patterns as examples you should follow\n"
        return prompt .. "<patterns>" .. content .. "\n</patterns>"
    end
    return ""
end

return M
