local M = {}

local ui = require("copilot-chat-context.ui.menu")
local assistant = require("copilot-chat-context.assistant")
local contexts = require("copilot-chat-context.contexts")
local menu = require("copilot-chat-context.menu")
local store = require("copilot-chat-context.store")

local notify = require("copilot-chat-context.external.notify")
local chat = require("copilot-chat-context.external.chat")
local config = require("copilot-chat-context.config")

--- setup should be called before require("copilot-chat-context").open()
--- @param opts ?ccc.PluginOpts
M.setup = function(opts)
    -- load dependencies
    notify.setup()
    chat.setup()
    config.setup(opts or {})
    store.setup()
end

--- opens the main UI context management window as a floating window on the RHS
M.open = function()
    local state = store.state()
    if vim.api.nvim_buf_is_valid(state.menu.bufnr) then
        return -- noop when trying to double open
    end
    -- if store loaded, let's just ui.open again + re-register actions + contexts...
    if state.loaded then
        store.remap()
        ui.open(state)
        return
    end

    assistant.attach(state)
    contexts.attach(state)
    menu.attach(state)
    store.load()
    ui.open(state)
end

return M
