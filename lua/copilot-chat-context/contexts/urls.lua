local M = {}

local textarea = require("copilot-chat-context.ui.textarea")
local store = require("copilot-chat-context.store")
local notify = require("copilot-chat-context.external.notify")
local config = require("copilot-chat-context.config")

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
        notify.add("opening " .. state.url, "INFO", { timeout = 1500, hg = "Comment" })
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
        notify.add("replacing " .. state.url, "INFO", { timeout = 3500, hg = "Comment" })
    end
    textarea.open({ prompt = "url", height = 3 }, function(input)
        if input == nil or #input == 0 then
            return
        end

        if #input > 1 then
            notify.add("only using the 1st line", "WARN", { timeout = 2500, hg = "DiagnosticWarn" })
        end

        state.url = input[1]
    end)
    return state
end

return M
