local M = {}

local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

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
    vim.api.nvim_clear_autocmds({ group = "chat-context-ui.tab.move" })
    state.menu.bufnr = -1
    return state
end

return M
