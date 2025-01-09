local M = {}

local menu = require("copilot-chat-context.ui.menu")
local blocks = require("copilot-chat-context.ui.blocks")
local doc = require("copilot-chat-context.ui.doc")
local knowledge = require("copilot-chat-context.ui.knowledge")

--- @param state ccc.State
--- @param ui ccc.uiContext
M.draw = function(state, ui)
    menu.draw(state)
    if ui == "blocks_open" then
        blocks.open(state)
    elseif ui == "blocks_redraw" then
        blocks.draw(state)
    elseif ui == "doc_task" or ui == "doc_patterns" then
        doc.open(state, ui)
    elseif ui == "knowledge_open" then
        knowledge.open(state)
    elseif ui == "knowledge_redraw" then
        knowledge.draw(state)
    end
end

return M
