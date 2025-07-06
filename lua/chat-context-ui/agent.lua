local M = {}

local config = require("chat-context-ui.config")

--- @class ccc.ChatRequest
--- @field prompt string
--- @field resolve fun(result:string)

--- chat with the set agent (user defined)
--- @param r ccc.ChatRequest
M.chat = function(r)
    local agent = config.agent()
    if agent ~= nil then
        agent.callback(r.prompt, r.resolve)
    end
end

return M
