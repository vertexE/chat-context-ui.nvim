local M = {}

local buffer = require("copilot-chat-context.buffer")
local store = require("copilot-chat-context.store")
local float = require("copilot-chat-context.ui.float")
local textarea = require("copilot-chat-context.ui.textarea")
local split = require("copilot-chat-context.ui.split")
local loader = require("copilot-chat-context.ui.loader")

local chat = require("copilot-chat-context.external.chat")
local config = require("copilot-chat-context.config")

local CMD_PREFIX = "<command>"
local CMD_POSTFIX = "</command>"

--- @param state ccc.State
--- @return ccc.State
M.attach = function(state)
    store.register_action({
        id = config.generate,
        notification = "",
        mode = { "n", "v" },
        ui = "menu",
        hidden = false,
        apply = M.generate,
    })
    store.register_action({
        id = config.build,
        notification = "",
        mode = { "n" },
        ui = "menu",
        hidden = false,
        apply = M.build,
    })
    store.register_action({
        id = config.review,
        notification = "reviewing buffer",
        mode = "n",
        ui = "menu",
        hidden = false,
        apply = M.review,
    })
    store.register_action({
        id = config.ask,
        notification = "",
        mode = { "n", "x" },
        ui = "menu",
        hidden = false,
        apply = M.ask,
    })
    store.register_action({
        id = config.explain,
        notification = "getting explanation",
        mode = { "x" },
        ui = "menu",
        hidden = false,
        apply = M.explain,
    })
    store.register_context({
        id = config.previous_ask,
        active = false,
        getter = M.qr_history_context,
        ui = "menu",
    })
    store.register_context({
        id = config.previous_explanation,
        active = false,
        getter = M.er_history_context,
        ui = "menu",
    })

    return state
end

--- @param state ccc.State
--- @return string,boolean
local contexts = function(state)
    local prompt = "<context>"
    local include_buffer = false
    for _, context in ipairs(state.contexts) do
        if context.id == config.buffer then
            include_buffer = true
        else
            local content = context.getter(state)
            if content ~= nil and #content > 0 and context.active then
                prompt = prompt .. "\n" .. content
            end
        end
    end
    prompt = prompt .. "\n</context>"
    return prompt, include_buffer
end

--- @type string represents the last response from M.explain
local er_history = ""

--- @param state ccc.State
--- @return ccc.State
M.explain = function(state)
    local sel_start, sel_end = buffer.active_selection()
    local lines = vim.api.nvim_buf_get_lines(0, sel_start - 1, sel_end, false)
    local selected_text = table.concat(lines, "\n")

    local prompt = [[
<rules>
- provide an explanation for the following code.
- use example input as you go through the code
- discuss how the code modifies the input
</rules>
<code>]] .. selected_text .. "</code>"

    chat.client().ask(prompt, {
        headless = true,
        callback = function(response, _)
            er_history = response
            -- Open a split on the bottom of the current buffer
            split.horizontal(response)
        end,
    })
    return state
end

--- @param _ ccc.State
--- @return string
M.er_history_context = function(_)
    if #er_history == 0 then
        return ""
    end
    return "<chat-history>" .. er_history .. "</chat-history>"
end

--- @type string represents the last response from M.ask
local qr_history = ""

--- @type integer|nil previous ask-question response buffer.
local qr_bufnr = nil

--- respond to a question based off of the available context
--- @param state ccc.State
--- @return ccc.State
M.ask = function(state)
    textarea.open({ prompt = "  Ask" }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local knowledge, include_buffer = contexts(state)
        local pre = [[
<rules>
- answer the following question
- keep it short, to the point, and use markdown standards.
- if there is a previous question, then this question builds on that one
</rules>
        ]]
        chat.client().ask(pre .. "<question>" .. vim.fn.join(input, "\n") .. "</question>\n" .. knowledge, {
            headless = true,
            selection = function(source)
                return include_buffer and chat.selection().buffer(source) or nil
            end,
            callback = function(response, _)
                qr_history = "<previous-question>"
                    .. vim.fn.join(input, "\n")
                    .. "</previous-question><previous-answer>"
                    .. response
                    .. "</previous-answer>"
                qr_bufnr = float.open(response, {
                    bufnr = (qr_bufnr and vim.api.nvim_buf_is_valid(qr_bufnr)) and qr_bufnr or nil,
                    enter = false,
                    rel = "lhs",
                    row = 1000, -- ensure it pops up on the bottom
                    height = 10,
                    width = 0.8,
                    bo = { filetype = "markdown" },
                    wo = { wrap = true },
                    close_on_q = true,
                })
            end,
        })
    end)
    return state
end

--- @param _ ccc.State
--- @return string
M.qr_history_context = function(_)
    if #qr_history == 0 then
        return ""
    end
    return "<chat-history>" .. qr_history .. "</chat-history>"
end

--- diagnose errors / race conditions in the current buffer
--- @param state ccc.State
--- @return ccc.State
M.review = function(state)
    chat.client().ask("/Review", {
        headless = true,
    })
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.build = function(state)
    local bufnr = vim.api.nvim_get_current_buf()
    local knowledge, include_buffer = contexts(state)
    local filetype = vim.bo[bufnr].filetype
    local _start, _end = buffer.active_selection()
    local prompt_header = string.format(
        [[
<rules>
- you must always respond in code.
- if you want to include an explanation, you MUST use comments.
- use the data in the <context> tags to inform your decisions
- you will build the structure of the code based off of the outline
- keywords in outline is as follows
```outline
{
    "fn": "function block",
    "if": "if block",
    "end": "end of scope"
}
```
- build the code from the outline to match the programming language %s
</rules>
    ]],
        filetype
    )
    prompt_header = prompt_header .. knowledge
    textarea.open({ prompt = "  Build" }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local ns_id = loader.create(_start, _end, false)
        local prompt_cmd = "<outline>" .. vim.fn.join(input, "\n") .. "</outline>"
        chat.client().ask(prompt_header .. prompt_cmd, {
            headless = true,
            selection = function(source)
                return include_buffer and chat.selection().buffer(source) or nil
            end,
            callback = function(response, _)
                local lines = vim.split(response, "\n")
                lines = vim.list_slice(lines, 2, #lines - 1)
                loader.clear(ns_id)
                vim.api.nvim_buf_set_lines(0, _start, _start, false, lines)
            end,
        })
    end)
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.generate = function(state)
    local status = vim.api.nvim_get_mode()
    local should_replace = status.mode == "v" or status.mode == "V" or status.mode == "^V"
    local sel_start, sel_end = buffer.active_selection()
    local knowledge, include_buffer = contexts(state)
    local prompt_header = string.format(
        [[
<rules>
- you must always respond in code.
- if you want to include an explanation, you MUST use comments.
- use the data in the <context> tags to inform your decisions
- for replace mode, only re-create code in the tags <context><active-selection>, the rest of the data in <context> is for reference
- for insert mode, all code in <context> is only for reference, do not include in output
- we're in %s mode, 
</rules>
    ]],
        should_replace and "replace" or "insert"
    )
    prompt_header = prompt_header .. knowledge .. "\n\n" .. "/COPILOT_GENERATE" -- TODO: unsure if I need this...

    local _start, _end
    if should_replace then
        _start, _end = sel_start, sel_end
    else
        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        _start, _end = row, row
    end
    textarea.open({ prompt = "  Generate" }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local ns_id = loader.create(_start, _end, should_replace)
        local prompt_cmd = CMD_PREFIX .. vim.fn.join(input, "\n") .. CMD_POSTFIX
        chat.client().ask(prompt_header .. prompt_cmd, {
            headless = true,
            selection = function(source)
                return include_buffer and chat.selection().buffer(source) or nil
            end,
            callback = function(response, _)
                local lines = vim.split(response, "\n")
                lines = vim.list_slice(lines, 2, #lines - 1)
                loader.clear(ns_id)
                if should_replace then
                    vim.api.nvim_buf_set_lines(0, _start - 1, _end, false, lines)
                else
                    vim.api.nvim_buf_set_lines(0, _start, _start, false, lines)
                end
            end,
        })
    end)

    return state
end

return M
