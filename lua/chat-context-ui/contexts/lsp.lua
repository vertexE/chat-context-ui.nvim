local M = {}

local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_context({
        id = config.lsp,
        ui = "menu",
        active = false,
        getter = M.context,
    })

    return state
end

local MAX_DIAGNOSTICS = 50 -- TODO: may need to adjust

--- @param _ ccc.State
--- @return string
M.context = function(_)
    local diagnostics = vim.diagnostic.get(nil)
    if #diagnostics > MAX_DIAGNOSTICS then
        diagnostics = vim.list_slice(diagnostics, 1, MAX_DIAGNOSTICS)
    end

    local reduced = vim.iter(diagnostics)
        :map(function(diagnostic)
            local filename = vim.fn.bufname(diagnostic.bufnr)
            local sev = vim.diagnostic.severity[diagnostic.severity]
            return {
                file = filename,
                severity = sev,
                message = diagnostic.message,
            }
        end)
        :totable()
    return vim.fn.json_encode(reduced)
end

return M
