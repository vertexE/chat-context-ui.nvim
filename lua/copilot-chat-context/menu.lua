local M = {}

local store = require("copilot-chat-context.store")
local config = require("copilot-chat-context.config")

--- @param state ccc.State
--- @return ccc.State
M.attach = function(state)
    store.register_action({
        id = config.quit,
        notification = "",
        mode = "n",
        hidden = false,
        ui = "menu",
        apply = M.quit,
    })
    return state
end

--- close out the menu, removing all keymaps
--- @param state ccc.State
--- @return ccc.State
M.quit = function(state)
    store.unmap_all()
    vim.api.nvim_buf_delete(state.menu.bufnr, { force = true })
    state.menu.bufnr = -1
    return state
end

return M
