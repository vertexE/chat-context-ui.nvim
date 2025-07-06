local M = {}

local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

local MAX_DIAGNOSTICS = 50 -- TODO: may need to adjust

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_context({
        id = config.lsp,
        ui = "menu",
        active = false,
        --- @param _state ccc.State
        --- @return table<string,string>
        meta = function(_state)
            local diagnostics = vim.diagnostic.get(nil)
            return { string.format("%d", #diagnostics > MAX_DIAGNOSTICS and MAX_DIAGNOSTICS or #diagnostics), "Comment" }
        end,
        getter = M.context,
    })
    -- store.register_action({
    --     id = config.add_definition,
    --     notification = "added symbol's file",
    --     mode = "n",
    --     hidden = false,
    --     apply = M.add_def_file,
    --     ui = "menu",
    -- })

    return state
end

--- which files were added using symbol_def
--- @type table<string, boolean>
local files = {}

M.add_def_file = function(state)
    vim.lsp.buf.definition({
        on_list = function(result)
            if #result.items > 0 then
                for _, item in ipairs(result.items) do
                    files[item.filename] = true
                end
            end
        end,
    })

    return state
end

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
