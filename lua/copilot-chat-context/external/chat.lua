local M = {}

local notify = require("copilot-chat-context.external.notify")

local _chat
local _selection

--- setup depends on notify.setup()
M.setup = function()
    local c_status, chat = pcall(require, "CopilotChat")
    if c_status then
        _chat = chat
    else
        notify.add("missing CopilotChat plugin", "ERROR", { timeout = 2000, hg = "DiagnosticError" })
    end

    local s_status, selection = pcall(require, "CopilotChat.select")
    if s_status then
        _selection = selection
    else
        notify.add("failed to load CopilotChat.select", "ERROR", { timeout = 2000, hg = "DiagnosticError" })
    end
end

M.client = function()
    return _chat
end

M.selection = function()
    return _selection
end

return M
