local M = {}

local notify = require("copilot-chat-context.external.notify")
local files = require("copilot-chat-context.external.files")
local git = require("copilot-chat-context.external.git")

local ui = require("copilot-chat-context.ui")
local config = require("copilot-chat-context.config")

--- @class ccc.State
--- @field menu ccc.Menu
--- @field blocks ccc.Blocks
--- @field url string
--- @field patterns ccc.Document
--- @field task ccc.Document
--- @field actions table<ccc.Action>
--- @field contexts table<ccc.Context>

--- @class ccc.Menu
--- @field open boolean
--- @field bufnr integer

--- @class ccc.Blocks
--- @field pos integer
--- @field list table<ccc.Block>
--- @field open boolean
--- @field bufnr integer

--- @class ccc.Document
--- @field bufnr integer
--- @field file string

--- @class ccc.Action
--- @field id ccc.ActionID
--- @field notification string
--- @field mode "n"|"v"|"x"|table
--- @field hidden boolean
--- @field apply fun(state: ccc.State): ccc.State
--- @field ui "menu"|"blocks_open"|"blocks_redraw"|"doc_task"|"doc_patterns"

--- @class ccc.Context
--- @field id ccc.ContextID
--- @field active boolean
--- @field getter fun(state: ccc.State): string
--- @field meta ?fun(state: ccc.State): table<string,string>
--- @field ui "menu"|"blocks_open"|"blocks_redraw"|"doc_task"|"doc_patterns"

-- TODO: mv to config.lua
local TASK_FILE_NAME = "_task_context.md"
local PATTERNS_FILE_NAME = "_patterns_context.md"
local PERSIST_FILE_NAME = "_copilot-chat-context.json"

--- @return ccc.State
M.default_state = function()
    return {
        menu = {
            open = false,
            bufnr = -1,
        },
        url = "",
        blocks = {
            pos = 1,
            list = {},
            open = false,
            bufnr = -1,
        },
        patterns = {
            file = PATTERNS_FILE_NAME,
            bufnr = -1,
        },
        task = {
            file = TASK_FILE_NAME,
            bufnr = -1,
        },
        actions = {},
        contexts = {},
    }
end

--- @type ccc.State
local state = M.default_state()

--- @class ccc.RegisterOpts
--- @field bufnr integer|nil

--- @type ccc.RegisterOpts
local register_defaults = {
    bufnr = nil,
}

--- @return ccc.State
M.state = function()
    return state
end

--- @param context ccc.Context
--- @param opts ?ccc.RegisterOpts
--- @return integer index of the registered context
M.register_context = function(context, opts)
    table.insert(state.contexts, context)
    opts = opts or register_defaults
    vim.keymap.set("n", config.key(context.id), function()
        for _, registered in ipairs(state.contexts) do
            if registered.id == context.id then
                registered.active = not registered.active
                ui.draw(state, context.ui)
                vim.defer_fn(M.persist, 0)
            end
        end
    end, { desc = "ai: toggle " .. context.id, buffer = opts.bufnr })
    return #state.contexts
end

--- @param action ccc.Action
--- @param opts ?ccc.RegisterOpts
--- @return integer index of the registered action
M.register_action = function(action, opts)
    table.insert(state.actions, action)
    opts = opts or register_defaults
    vim.keymap.set(action.mode, config.key(action.id), function()
        if #action.notification > 0 then
            notify.add(action.notification, "INFO", { timeout = 1500, hg = "Comment" })
        end
        state = action.apply(state)
        if state.menu.open then
            ui.draw(state, action.ui)
        end
        if action.id ~= config.quit then
            vim.defer_fn(M.persist, 0)
        end
    end, { desc = "ai: " .. action.id, buffer = opts.bufnr })
    return #state.actions
end

--- @param id string
M.deregister_action = function(id)
    local pos = 0
    for i, action in ipairs(state.actions) do
        if action.id == id then
            pos = i
            break
        end
    end
    table.remove(state.actions, pos)
end

--- @class ccc.PersistedState
--- @field blocks table<ccc.Block>
--- @field block_pos integer
--- @field url string
--- @field contexts table<string, boolean>

--- called whenever a state change occurs, with a 500ms delay
--- to ensure we don't slow down UX and updates to the UI.
M.persist = function()
    local contexts = {}
    for _, context in ipairs(state.contexts) do
        contexts[context.id] = context.active
    end

    --- @type ccc.PersistedState
    local persisted = {
        blocks = state.blocks.list,
        block_pos = state.blocks.pos,
        url = state.url,
        contexts = contexts,
    }

    local raw = vim.fn.json_encode(persisted)

    local dir = vim.fn.expand(config.CACHE)
    local err = files.write(dir .. "/" .. git.root():gsub("/", "_") .. PERSIST_FILE_NAME, raw)
    if err ~= nil then
        notify.add("failed to persist ai state", "ERROR", { timeout = 1500, hg = "DiagnosticError" })
    end
end

M.setup = function()
    local dir = vim.fn.expand(config.CACHE)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

--- load cached state for this directory
M.load = function()
    local dir = vim.fn.expand(config.CACHE)
    local content = files.read(dir .. "/" .. git.root():gsub("/", "_") .. PERSIST_FILE_NAME)
    if content ~= nil then
        --- @type ccc.PersistedState
        local persisted = vim.fn.json_decode(content)
        state.blocks.list = persisted.blocks
        state.blocks.pos = persisted.block_pos
        state.url = persisted.url
        for _, context in ipairs(state.contexts) do
            if persisted.contexts[context.id] ~= nil then
                context.active = persisted.contexts[context.id]
            end
        end
    end
end

return M
