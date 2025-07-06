local M = {}

local textarea = require("chat-context-ui.ui.textarea")
local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    store.register_action({
        id = config.add_url,
        notification = "",
        mode = "n",
        hidden = false,
        apply = M.replace,
        ui = "menu",
    })
    store.register_action({
        id = config.open_url,
        notification = "",
        mode = "n",
        hidden = false,
        apply = M.open,
        ui = "menu",
    })
    store.register_context({
        id = config.url,
        active = false,
        --- @param _state ccc.State
        --- @return table<string,string>
        meta = function(_state)
            return { #_state.url > 0 and _state.url or "none", "Comment" }
        end,
        getter = M.context,
        ui = "menu",
    })

    return state
end

--- @param state ccc.State
--- @return string
M.context = function(state)
    if #state.url == 0 then
        return ""
    end

    return "\n\n#url " .. state.url .. "\n\n"
end

--- @param state ccc.State
--- @return ccc.State
M.open = function(state)
    if #state.url > 0 then
        vim.notify("opening " .. state.url, vim.log.levels.INFO, {})
        local escaped_url = vim.fn.shellescape(state.url, true)
        -- remove the added quotes
        local url = string.sub(escaped_url, 2, #escaped_url - 1)
        vim.system({ "open", url }):wait()
    end
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.replace = function(state)
    if #state.url > 0 then
        vim.notify("replacing " .. state.url, vim.log.levels.INFO, {})
    end
    textarea.open({ prompt = "url", height = 3 }, function(input)
        if input == nil or #input == 0 then
            return
        end

        if #input > 1 then
            vim.notify("only using the 1st line", vim.log.levels.WARN, {})
        end

        state.url = input[1]
    end)
    return state
end

return M
