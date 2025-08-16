local M = {}

local buffer = require("chat-context-ui.buffer")
local store = require("chat-context-ui.store")
local float = require("chat-context-ui.ui.float")
local textarea = require("chat-context-ui.ui.textarea")
local loader = require("chat-context-ui.ui.loader")
local text = require("chat-context-ui.text")
local fb_parser = require("chat-context-ui.parsers.feedback")

local agent = require("chat-context-ui.agent")
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
    store.register_action({
        id = config.toggle_feedback,
        notification = "",
        mode = { "n" },
        ui = "menu",
        hidden = false,
        apply = M.feedback_mode,
    })
    store.register_action({
        id = config.set_goal,
        notification = "",
        mode = { "n" },
        ui = "menu",
        hidden = false,
        apply = M.set_goal,
    })
    store.register_action({
        id = config.open_feedback_menu,
        notification = "",
        mode = { "n" },
        ui = "feedback_menu_open",
        hidden = false,
        apply = M.list_feedback_actions,
    })
    store.register_action({
        id = config.clear_chat_history,
        notification = "",
        mode = { "n" },
        ui = "menu",
        hidden = false,
        apply = M.clear_chat_history,
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

--- @param state ccc.State
--- @return ccc.State
M.set_goal = function(state)
    textarea.open({ prompt = "  Goal", content = state.goal }, function(input)
        if input == nil then
            return
        end
        state.goal = table.concat(input, "\n")
    end)
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.list_feedback_actions = function(state)
    local requesting_bufnr = vim.api.nvim_get_current_buf() -- where we will apply the action
    local requesting_winr = vim.api.nvim_get_current_win()
    local row, col = vim.fn.getpos(".")[2], vim.fn.getpos(".")[3]
    state.feedback_menu_bufnr = vim.api.nvim_create_buf(false, false)
    store.register_action({
        id = config.expand_item,
        notification = "",
        mode = { "n" },
        ui = "feedback_menu_redraw",
        hidden = false,
        apply = function(_state)
            -- loop to check if any toggled on, if so, close expanded and return early
            for _, fb_action in ipairs(_state.fb_actions) do
                if fb_action.expanded then
                    fb_action.expanded = false
                    return _state
                end
            end

            local cur_pos = vim.fn.getpos(".")[2]
            --- @type ccc.FeedbackAction
            local action = _state.fb_actions[cur_pos]
            action.expanded = true
            return _state
        end,
    }, { bufnr = state.feedback_menu_bufnr })
    store.register_action({
        id = config.select_item,
        notification = "",
        mode = { "n" },
        ui = "menu", -- we want the menu redrawn after deleting an action
        hidden = false,
        apply = function(_state)
            local cur_pos = vim.fn.getpos(".")[2]
            vim.api.nvim_buf_delete(_state.feedback_menu_bufnr, { force = true })
            _state.feedback_menu_open = false
            vim.api.nvim_win_set_cursor(requesting_winr, { row, col })

            --- @type ccc.FeedbackAction
            local action = _state.fb_actions[cur_pos]
            vim.cmd(string.format("e %s", action.filepath))
            local max_line = vim.api.nvim_buf_line_count(0)
            vim.api.nvim_win_set_cursor(0, { math.min(action.line, max_line), 0 })
            if action ~= nil and action.type == "INSERT" then
                vim.api.nvim_buf_set_lines(requesting_bufnr, action.line, action.line, false, action.content)
            elseif action ~= nil and action.type == "REPLACE" then
                vim.api.nvim_buf_set_lines(requesting_bufnr, action.line - 1, action.end_line, false, action.content)
            elseif action ~= nil and action.type == "DELETE" then
                vim.api.nvim_buf_set_lines(requesting_bufnr, action.line - 1, action.line, false, {})
            else
                vim.notify("chat-context-ui: invalid feedback action", vim.log.levels.WARN, {})
            end

            --- you should not be able to request the same action again
            table.remove(_state.fb_actions, cur_pos)
            return _state
        end,
    }, { bufnr = state.feedback_menu_bufnr })

    vim.api.nvim_buf_attach(state.feedback_menu_bufnr, false, {
        on_detach = function()
            state.feedback_menu_open = false
            store.deregister_action(config.expand_item)
            store.deregister_action(config.select_item)
        end,
    })

    return state
end

--- @param state ccc.State
--- @return ccc.State
M.feedback_mode = function(state)
    state.feedback_on = not state.feedback_on

    if not state.feedback_on then
        vim.api.nvim_clear_autocmds({ group = "ccc.assistant.feedback" })
        return state
    end

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("ccc.assistant.feedback", { clear = true }),
        callback = function(ev)
            if state.feedback_lock then
                return
            end

            state.feedback_lock = true

            -- TODO: could make this debounce by using a timer?
            vim.defer_fn(function()
                local goal = state.goal
                if goal == nil or #goal == 0 then
                    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
                    goal = string.format("propose improvements to the file %s", fname)
                end

                local prompt = string.format(
                    [[
<goal>%s</goal>
<rules>
- you can respond with the top 6 best actions
- each action starts with #
- you must specify a file path starting from the current working directory
- action types are `INSERT | REPLACE | DELETE`
- you must specify line range, such as 36:36 (only line 36) or 36:42 (inclusive)
- your response MUST follow this schema otherwise you will break the parser
- FORGET ALL OTHER WAYS OF RESPONDING IT MUST EXACTLY MATCH THIS SCHEMA!

<schema>
# <ACTION NAME> | <filepath> | <TYPE> | start_line:end_line
```filetype
content to replace / add, ignored for delete types
```
</schema>

<example>
# Add function documentation | lua/chat-context-ui/parsers/feedback.lua | INSERT | 1:1
```lua
--- Sums the numbers in a list and prints the result using vim.print.
```

# Use local function for sum | lua/chat-context-ui/parsers/feedback.lua | INSERT | 3:3
```lua
local function sum_list(list)
    local sum = 0
    for _, v in ipairs(list) do
        sum = sum + v
    end
    return sum
end
```
</example>


</rules>
    ]],
                    goal
                )
                local knowledge = contexts(state)

                agent.chat({
                    prompt = prompt .. knowledge,
                    resolve = function(result)
                        -- BUG: making the special marker # is a bad idea!
                        local actions = fb_parser.parse(result)
                        state.fb_actions = actions
                        state.feedback_lock = false
                        -- loop through all actions and set marks for the current file
                        local filtered = vim.iter(actions)
                            :filter(function(item)
                                return item.filepath == vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":p:.")
                            end)
                            :totable()
                        local marks = { "a", "b", "c", "d", "e", "f", "g" }
                        local max_buf_len = vim.api.nvim_buf_line_count(ev.buf)
                        for _, fb_action in ipairs(filtered) do
                            if #marks == 0 then
                                break
                            end
                            local mark = marks[1]
                            table.remove(marks, 1)
                            vim.api.nvim_buf_set_mark(ev.buf, mark, math.min(fb_action.line, max_buf_len), 0, {})
                        end
                    end,
                })
            end, 1000)
        end,
    })

    return state
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

    -- TODO: if the questin buffer is already open, close it

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
        agent.chat({
            prompt = pre .. "<question>" .. vim.fn.join(input, "\n") .. "</question>\n" .. knowledge .. qr_history,
            resolve = function(response)
                qr_response = response
                qr_history = "<previous-question>"
                    .. vim.fn.join(input, "\n")
                    .. "</previous-question><previous-answer>"
                    .. response
                    .. "</previous-answer>\n"
                    .. qr_history
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

M.clear_chat_history = function()
    qr_history = ""
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
- for replace mode, only re-create code in the tag <active-selection>, the rest of the data in <context> is for reference
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
        agent.chat({
            prompt = prompt_header .. prompt_cmd,
            resolve = function(response)
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
