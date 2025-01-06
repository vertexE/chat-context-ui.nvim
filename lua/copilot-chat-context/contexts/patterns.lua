local M = {}

local files = require("copilot-chat-context.external.files")
local store = require("copilot-chat-context.store")
local config = require("copilot-chat-context.config")
local git = require("copilot-chat-context.external.git")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_action({
        id = config.open_patterns,
        notification = "",
        mode = "n",
        ui = "doc_patterns",
        hidden = false,
        apply = M.open,
    })
    store.register_context({
        id = config.patterns,
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
    local dir = vim.fn.expand(config.CACHE)
    local content = files.read(dir .. "/" .. git.root():gsub("/", "_") .. state.patterns.file)
    if content ~= nil then
        local prompt = "refer to the following coding patterns as examples you should follow\n"
        return prompt .. "<patterns>" .. content .. "\n</patterns>"
    end
    return ""
end

return M
