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
    store.register_action({
        id = config.toggle_help,
        notification = "",
        mode = "n",
        hidden = false,
        ui = "menu",
        apply = M.help,
    })
    return state
end

--- remove all keymaps, delete the menu buf, clear auto commands
--- @param state ccc.State
--- @return ccc.State
M.quit = function(state)
    store.unmap_all()
    vim.api.nvim_buf_delete(state.menu.bufnr, { force = true })
    vim.api.nvim_clear_autocmds({ group = "chat-context-ui.tab.reopen" })
    vim.api.nvim_clear_autocmds({ group = "chat-context-ui.tab.draw" })
    vim.api.nvim_clear_autocmds({ group = "ccc.git.stats.base" })
    vim.api.nvim_clear_autocmds({ group = "ccc.git.stats.minigit" })
    state.menu.bufnr = -1
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.help = function(state)
    state.menu.help = not state.menu.help
    return state
end

return M
