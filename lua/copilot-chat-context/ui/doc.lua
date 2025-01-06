local M = {}

local float = require("copilot-chat-context.ui.float")
local config = require("copilot-chat-context.config")
local git = require("copilot-chat-context.external.git")

--- @param state ccc.State
--- @param ui string
M.open = function(state, ui)
    local title = ui == "doc_patterns" and "  Coding Patterns" or "  Task"
    local rel_path = ui == "doc_patterns" and state.patterns.file or state.task.file
    float.open(nil, {
        rel = "center",
        width = 0.8,
        height = 0.3,
        title = title,
        close_on_q = true,
        enter = true,
    })

    local dir = vim.fn.expand(config.CACHE)
    local path = dir .. "/" .. git.root():gsub("/", "_") .. rel_path
    vim.cmd("edit" .. path)
end

return M
