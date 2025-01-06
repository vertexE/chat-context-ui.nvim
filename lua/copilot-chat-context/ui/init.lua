local M = {}

local menu = require("copilot-chat-context.ui.menu")
local blocks = require("copilot-chat-context.ui.blocks")
local doc = require("copilot-chat-context.ui.doc")

--- @param state ccc.State
--- @param ui string
M.draw = function(state, ui)
    menu.draw(state)
    if ui == "blocks_open" then
        blocks.open(state)
    elseif ui == "blocks_redraw" then
        blocks.draw(state)
    elseif ui == "doc_task" or ui == "doc_patterns" then
        doc.open(state, ui)
    end
end

return M
