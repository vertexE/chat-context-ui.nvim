local M = {}

local menu = require("chat-context-ui.ui.menu")
local blocks = require("chat-context-ui.ui.blocks")

--- @param state ccc.State
--- @param ui ccc.uiContext
M.draw = function(state, ui)
    menu.draw(state)
    if ui == "blocks_open" then
        blocks.open(state)
    elseif ui == "blocks_redraw" then
        blocks.draw(state)
    end
end

return M
