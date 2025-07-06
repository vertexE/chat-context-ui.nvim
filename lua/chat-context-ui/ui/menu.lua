local M = {}

local float = require("chat-context-ui.ui.float")
local split = require("chat-context-ui.ui.split")
local config = require("chat-context-ui.config")

--- @param state ccc.State
local draw_help = function(state)
    local ns = vim.api.nvim_create_namespace("chat-context-ui.virtual_text")
    vim.api.nvim_buf_clear_namespace(state.menu.bufnr, ns, 0, -1)

    local keys = config.keys()
    local lines = {}
    for _, pair in ipairs(keys) do
        local id, key = next(pair)

        if id == nil or key == nil then
            table.insert(lines, {})
        else
            table.insert(lines, {
                { key .. " " .. id, "Comment" },
            })
        end
    end

    vim.api.nvim_buf_set_extmark(state.menu.bufnr, ns, 0, 0, {
        virt_text = {
            { "Help", "AIActionsHeader" },
        },
        virt_lines = lines,
        virt_text_pos = "inline",
    })
end

--- @param state ccc.State
local draw_split = function(state)
    local ns = vim.api.nvim_create_namespace("chat-context-ui.virtual_text")
    vim.api.nvim_buf_clear_namespace(state.menu.bufnr, ns, 0, -1)

    local lines = {}
    for _, context in ipairs(state.contexts) do
        local meta = { "", "Comment" }
        if context.meta ~= nil then
            meta = context.meta(state)
        end
        local active_hl = "AIActionsInActiveContext"
        if context.active then
            active_hl = "AIActionsActiveContext"
        end
        table.insert(lines, {
            { config.icon(context.id) .. "  ", active_hl },
            meta,
        })
    end

    -- TODO: extend drawing to include copilot "feedback" mode 

    vim.api.nvim_buf_set_extmark(state.menu.bufnr, ns, 0, 0, {
        virt_text = {
            { "Agent", "AIActionsHeader" },
            { " help " .. config.key(config.toggle_help), "Comment" },
        },
        virt_lines = lines,
        virt_text_pos = "inline",
    })
end

--- @param state ccc.State
M.draw = function(state)
    if not vim.api.nvim_buf_is_valid(state.menu.bufnr) then
        return
    end

    if state.menu.help then
        return draw_help(state)
    end

    if config.ui().layout == "split" then
        return draw_split(state)
    end
    -- else, draw a floating window

    local ns = vim.api.nvim_create_namespace("chat-context-ui.virtual_text")
    vim.api.nvim_buf_clear_namespace(state.menu.bufnr, ns, 0, -1)

    local lines = {}
    for _, action in ipairs(state.actions) do
        if not action.hidden then
            local line =
                { { config.key(action.id) .. " - ", "Comment" }, { config.icon(action.id), "AIActionsAction" } }
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
            { config.icon(context.id) .. "  ", status_hg },
            meta,
        })
    end

    vim.api.nvim_buf_set_extmark(state.menu.bufnr, ns, 0, 0, {
        virt_text = { { "Agent", "AIActionsHeader" } },
        virt_lines = lines,
        virt_text_pos = "inline",
    })
end

--- should open a window on the RHS with the AI options (actions + contexts)
--- @param state ccc.State
M.open = function(state)
    if config.ui().layout == "float" then
        state.menu.bufnr = float.open(nil, {
            title = "",
            rel = "rhs",
            row = 1,
            width = 15,
            height = 20,
            enter = false,
            wo = { number = false, relativenumber = false },
        })
    elseif config.ui().layout == "split" then
        state.menu.bufnr = split.vertical(nil, {
            enter = false,
            wo = { number = false, relativenumber = false, winfixwidth = true },
        })
    else
        vim.notify("invalid layout option", vim.log.levels.ERROR, {})
        return
    end

    M.draw(state)

    state.menu.open = true
end

-- BUG: whenever you go back to the same tab and the win is open it causes issues...
-- may have fixed with winfixwidth? needs more investigation

--- moves the opened menu to the active tab
--- @param state ccc.State
M.reopen = function(state)
    if not vim.api.nvim_buf_is_valid(state.menu.bufnr) then -- cannot draw
        return
    end

    if config.ui().layout == "float" then
        float.open(nil, {
            bufnr = state.menu.bufnr,
            title = "",
            rel = "rhs",
            row = 1,
            width = 15,
            height = 20,
            enter = false,
            wo = { number = false, relativenumber = false },
        })
    elseif config.ui().layout == "split" then -- TODO: can expand ui to include other options (width)
        split.vertical(nil, {
            bufnr = state.menu.bufnr,
            enter = false,
            wo = { number = false, relativenumber = false, winfixwidth = true },
        })
    else
        vim.notify("invalid layout option", vim.log.levels.ERROR, {})
    end
end

return M
