local M = {}

local menu = require("chat-context-ui.ui.menu")
local blocks = require("chat-context-ui.ui.blocks")
local feedback = require("chat-context-ui.ui.feedback")

--- the draw func is called after an action or context (not on a loop)
--- @param state ccc.State
--- @param ui ccc.uiContext
M.draw = function(state, ui)
    menu.draw(state)
    if ui == "blocks_open" then
        blocks.open(state)
    elseif ui == "blocks_redraw" then
        blocks.draw(state)
    elseif ui == "feedback_menu_open" then
        feedback.open(state)
    elseif ui == "feedback_menu_redraw" then
        feedback.draw(state)
    end
end

return M
