local M = {}

local buffer = require("copilot-chat-context.buffer")
local store = require("copilot-chat-context.store")
local notify = require("copilot-chat-context.external.notify")
local config = require("copilot-chat-context.config")

--- @class ccc.Block
--- @field content string
--- @field extension string
--- @field path string
--- @field active boolean

--- @param state ccc.State
--- @return table<string,string>
local meta = function(state)
    local active = #vim.tbl_filter(function(value)
        return value.active
    end, state.blocks.list)

    return { active .. "," .. #state.blocks.list, "Comment" }
end

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_action({
        id = config.add_selection,
        notification = "added selection",
        mode = "v",
        hidden = false,
        apply = M.add,
        ui = "menu",
    })
    store.register_action({
        id = config.list_selections,
        notification = "",
        mode = "n",
        hidden = false,
        apply = M.list,
        ui = "blocks_open",
    })
    store.register_action({
        id = config.clear_selections,
        notification = "cleared selections",
        mode = "n",
        hidden = false,
        apply = M.clear,
        ui = "menu",
    })
    store.register_context({
        id = config.selections,
        active = false,
        getter = M.context,
        meta = meta,
        ui = "menu",
    })

    return state
end

--- @param state ccc.State
--- @return ccc.State
M.list = function(state)
    if #state.blocks.list == 0 then
        notify.add("no saved selections", "WARN", { timeout = 1500, hg = "DiagnosticWarn" })
        return state
    end

    state.blocks.bufnr = vim.api.nvim_create_buf(true, false)
    store.register_action({
        id = config.toggle_selection,
        notification = "",
        mode = "n",
        hidden = true,
        ui = "blocks_redraw",
        apply = function(_state)
            for i, block in ipairs(_state.blocks.list) do
                if i == _state.blocks.pos then
                    block.active = not block.active
                end
            end
            return _state
        end,
    }, { bufnr = state.blocks.bufnr })
    store.register_action({
        id = config.next_selection,
        notification = "",
        mode = "n",
        hidden = true,
        ui = "blocks_redraw",
        apply = function(_state)
            _state.blocks.pos = (_state.blocks.pos % #_state.blocks.list) + 1
            return _state
        end,
    }, { bufnr = state.blocks.bufnr })
    store.register_action({
        id = config.previous_selection,
        notification = "",
        mode = "n",
        hidden = true,
        ui = "blocks_redraw",
        apply = function(_state)
            _state.blocks.pos = _state.blocks.pos - 1
            if _state.blocks.pos < 1 then
                _state.blocks.pos = #_state.blocks.list
            end
            return _state
        end,
    }, { bufnr = state.blocks.bufnr })
    vim.api.nvim_buf_attach(state.blocks.bufnr, false, {
        on_detach = function()
            state.blocks.open = false
            store.deregister_action(config.previous_selection)
            store.deregister_action(config.next_selection)
            store.deregister_action(config.toggle_selection)
        end,
    })
    return state
end

local MAX_BLOCKS = 10

--- @param state ccc.State
--- @return ccc.State
M.add = function(state)
    local start_line, end_line = buffer.active_selection()
    local relative_file_path = vim.fn.expand("%:.")
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local segments = vim.split(relative_file_path, ".", { plain = true, trimempty = true })
    local extension = segments[#segments]

    if #state.blocks.list == MAX_BLOCKS then
        state.blocks.list = vim.list_slice(state.blocks.list, 2)
        notify.add("max chunks, dropping oldest", "WARN", { timeout = 1500, hg = "DiagnosticWarn" })
    end

    table.insert(
        state.blocks.list,
        { content = vim.fn.join(lines, "\n"), extension = extension, path = relative_file_path, active = true }
    )
    vim.api.nvim_command('normal! "+y')

    return state
end

--- @param state ccc.State
M.clear = function(state)
    state.blocks.list = {}
    state.blocks.pos = 1
    return state
end

--- @param block ccc.Block
local format_chunk = function(block)
    return string.format(
        [[```%s
%s
```
    ]],
        block.extension,
        block.content
    )
end

--- @param state ccc.State
--- @return string
M.context = function(state)
    local prompt = "<snippets>utilize these snippets or documentation from the code base for additional clarity"
    for _, block in ipairs(state.blocks.list) do
        if block.active then
            prompt = prompt .. "\n" .. format_chunk(block)
        end
    end

    return prompt .. "</snippets>"
end

return M
