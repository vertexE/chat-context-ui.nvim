local M = {}

local float = require("copilot-chat-context.ui.float")
local config = require("copilot-chat-context.config")

--- @param state ccc.State
M.draw = function(state)
    if not vim.api.nvim_buf_is_valid(state.menu.bufnr) then
        return
    end

    local ns = vim.api.nvim_create_namespace("user_ai_virtual_text")
    vim.api.nvim_buf_clear_namespace(state.menu.bufnr, ns, 0, -1)

    local lines = {}
    for _, action in ipairs(state.actions) do
        if not action.hidden then
            local line =
                { { config.key(action.id) .. " - ", "Comment" }, { config.label(action.id), "AIActionsAction" } }
            table.insert(lines, line)
        end
    end
    table.insert(lines, {})
    table.insert(lines, { { "Contexts", "AIActionsHeader" } })

    for _, context in ipairs(state.contexts) do
        local meta = { "", "Comment" }
        if context.meta ~= nil then
            meta = context.meta(state)
        end
        local status_hg = "AIActionsInActiveContext"
        if context.active then
            status_hg = "AIActionsActiveContext"
        end
        table.insert(lines, {
            { config.key(context.id) .. " - ", status_hg },
            { config.label(context.id) .. "  ", status_hg },
            meta,
        })
    end

    vim.api.nvim_buf_set_extmark(state.menu.bufnr, ns, 0, 0, {
        virt_text = { { "Actions", "AIActionsHeader" } },
        virt_lines = lines,
        virt_text_pos = "inline",
    })
end

--- should open a window on the RHS with the AI options (actions + contexts)
--- @param state ccc.State
M.open = function(state)
    state.menu.bufnr = float.open(nil, {
        title = "Copilot",
        rel = "rhs",
        row = 1,
        width = 15,
        height = 26,
        enter = false,
        wo = { number = false, relativenumber = false },
    })
    M.draw(state)
    state.menu.open = true
end

return M
