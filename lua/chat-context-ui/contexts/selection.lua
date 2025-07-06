local M = {}

local buffer = require("chat-context-ui.buffer")
local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_context({
        id = config.active_selection,
        ui = "menu",
        active = false,
        --- @param _state ccc.State
        --- @return table<string,string>
        meta = function(_state)
            local sel_start, sel_end = buffer.active_selection()
            return { string.format("%d:%d", sel_start, sel_end), "Comment" }
        end,
        getter = M.context,
    })
    return state
end

--- @param _ ccc.State
--- @return string
M.context = function(_)
    local sel_start, sel_end = buffer.active_selection()
    vim.api.nvim_command('normal! "+y')
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

    local lines = vim.fn.getline(sel_start, sel_end)
    if #lines == 0 then
        return ""
    end
    if type(lines) == "string" then
        return string.format("<active-selection filetype='%s'>", ft) .. lines .. "</active-selection>"
    end

    return string.format("<active-selection filetype='%s'>", ft) .. table.concat(lines, "\n") .. "</active-selection>"
end

return M
