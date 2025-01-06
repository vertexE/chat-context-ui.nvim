local M = {}

local files = require("copilot-chat-context.external.files")
local store = require("copilot-chat-context.store")
local config = require("copilot-chat-context.config")
local git = require("copilot-chat-context.external.git")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_action({
        id = config.open_task,
        notification = "",
        mode = "n",
        ui = "doc_task",
        hidden = false,
        apply = M.open,
    })
    store.register_context({
        id = config.task,
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
    local content = files.read(dir .. "/" .. git.root():gsub("/", "_") .. state.task.file)
    if content ~= nil then
        local prompt = "refer to the following for context on the current task\n"
        return prompt .. "<task>" .. content .. "\n</task>"
    end
    return ""
end

return M
