local M = {}

local buffer = require("chat-context-ui.buffer")
local store = require("chat-context-ui.store")
local float = require("chat-context-ui.ui.float")
local textarea = require("chat-context-ui.ui.textarea")
local split = require("chat-context-ui.ui.split")
local loader = require("chat-context-ui.ui.loader")
local text = require("chat-context-ui.text")

local chat = require("chat-context-ui.external.chat")
local config = require("chat-context-ui.config")

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
        id = config.ask,
        notification = "",
        mode = { "n", "x" },
        ui = "menu",
        hidden = false,
        apply = M.ask,
    })
    store.register_action({
        id = config.show_previous_answer,
        notification = "",
        mode = { "n", "x" },
        ui = "menu",
        hidden = false,
        apply = M.show_previous_answer,
    })

    return state
end

--- @param state ccc.State
--- @return string
local contexts = function(state)
    local prompt = "<context>"
    for _, context in ipairs(state.contexts) do
        local content = context.getter(state)
        if content ~= nil and #content > 0 and context.active then
            prompt = prompt .. "\n" .. content
        end
    end
    prompt = prompt .. "\n</context>"
    return prompt
end

--- @type string represents the last response+question from M.ask
local qr_history = ""

--- @type string represents the last response from M.ask
local qr_response = ""

--- @type integer|nil previous ask-question response buffer.
local qr_bufnr = nil

---@param state ccc.State
--- @return ccc.State
M.show_previous_answer = function(state)
    if qr_bufnr ~= nil and vim.api.nvim_buf_is_valid(qr_bufnr) then
        return state
    end

    qr_bufnr = float.open(qr_response, {
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
    return state
end

--- respond to a question based off of the available context
--- @param state ccc.State
--- @return ccc.State
M.ask = function(state)
    state.requesting_bufnr = vim.api.nvim_get_current_buf()
    textarea.open({ prompt = "  Ask" }, function(input)
        if input == nil or #input == 0 then
            return
        end
        local knowledge = contexts(state)
        local pre = [[
<rules>
- answer the following question
- keep it short, to the point, and use markdown standards.
- if there is a previous question, then this question builds on that one
</rules>
        ]]
        chat.client()
            .ask(pre .. "<question>" .. vim.fn.join(input, "\n") .. "</question>\n" .. knowledge .. qr_history, {
                headless = true,
                callback = function(response, _)
                    qr_response = response
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

--- @param state ccc.State
--- @return ccc.State
M.generate = function(state)
    local requesting_bufnr = vim.api.nvim_get_current_buf()
    state.requesting_bufnr = requesting_bufnr
    local status = vim.api.nvim_get_mode()
    local should_replace = status.mode == "v" or status.mode == "V" or status.mode == "^V"
    local sel_start, sel_end = buffer.active_selection()
    local knowledge = contexts(state)
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
    prompt_header = prompt_header .. knowledge .. "\n\n" .. "/COPILOT_GENERATE"

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
            callback = function(response, _)
                local lines = vim.split(text.select_content(response), "\n")
                loader.clear(ns_id)
                if should_replace then
                    vim.api.nvim_buf_set_lines(requesting_bufnr, _start - 1, _end, false, lines)
                else
                    vim.api.nvim_buf_set_lines(requesting_bufnr, _start, _start, false, lines)
                end
            end,
        })
    end)

    return state
end

return M
