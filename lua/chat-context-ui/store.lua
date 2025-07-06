local M = {}

local notify = require("chat-context-ui.external.notify")
local files = require("chat-context-ui.external.files")
local git = require("chat-context-ui.external.git")

local ui = require("chat-context-ui.ui")
local config = require("chat-context-ui.config")

--- @alias ccc.uiContext "menu"|"blocks_open"|"blocks_redraw"

--- @class ccc.State
--- @field requesting_bufnr integer
--- @field menu ccc.Menu
--- @field loaded boolean if PersistedState has been loaded in
--- @field blocks ccc.Blocks
--- @field files string[]
--- @field url string
--- @field actions table<ccc.Action>
--- @field contexts table<ccc.Context>
--- @field afterLoad table<ccc.ContextLoad>
--- @field opts ccc.RunOptions

--- @class ccc.RunOptions
--- @field copy_on_prompt boolean instead of calling copilot-chat, copy prompt to clipboard

--- @class ccc.Menu
--- @field open boolean
--- @field help boolean whether to draw the help screen instead
--- @field bufnr integer

--- @class ccc.Blocks
--- @field pos integer
--- @field list table<ccc.Block>
--- @field open boolean
--- @field bufnr integer

--- @class ccc.Action
--- @field id ccc.ActionID
--- @field notification string
--- @field mode "n"|"v"|"x"|table
--- @field hidden boolean
--- @field apply fun(state: ccc.State): ccc.State
--- @field ui ccc.uiContext

--- @class ccc.Context
--- @field id ccc.ContextID
--- @field active boolean
--- @field getter fun(state: ccc.State): string
--- @field meta ?fun(state: ccc.State): table<string,string>
--- @field ui ccc.uiContext

--- @class ccc.ContextLoad
--- @field id ccc.ContextID
--- @field load fun(state: ccc.State): ccc.State after store load, load additional data for context

-- TODO: mv to config.lua
local PERSIST_FILE_NAME = "_chat-context-ui.json"

--- @return ccc.State
M.default_state = function()
    --- @type ccc.State
    return {
        requesting_bufnr = -1,
        opts = {
            copy_on_prompt = false,
        },
        menu = {
            open = false,
            bufnr = -1,
            help = false,
        },
        url = "",
        loaded = false,
        files = {},
        blocks = {
            pos = 1,
            list = {},
            open = false,
            bufnr = -1,
        },
        actions = {},
        contexts = {},
        afterLoad = {},
    }
end

--- @type ccc.State
local state = M.default_state()

--- @class ccc.RegisterOpts
--- @field bufnr ?integer|nil
--- @field remap_only ?boolean whether this action is new

--- @type ccc.RegisterOpts
local register_defaults = {
    bufnr = nil,
    remap_only = false,
}

--- @return ccc.State
M.state = function()
    return state
end

--- @param context ccc.Context
--- @param opts ?ccc.RegisterOpts
--- @return integer index of the registered context
M.register_context = function(context, opts)
    if opts then
        opts.remap_only = opts.remap_only ~= nil and opts.remap_only or register_defaults.remap_only
    else
        opts = opts or register_defaults
    end
    if not opts.remap_only then
        table.insert(state.contexts, context)
    end
    vim.keymap.set("n", config.key(context.id), function()
        for _, registered in ipairs(state.contexts) do
            if registered.id == context.id then
                registered.active = not registered.active
                ui.draw(state, context.ui)
                vim.defer_fn(M.persist, 0)
            end
        end
    end, { desc = "chat-context-ui: toggle " .. context.id, buffer = opts.bufnr })
    return #state.contexts
end

--- @param action ccc.Action
--- @param opts ?ccc.RegisterOpts
--- @return integer index of the registered action
M.register_action = function(action, opts)
    if opts then
        opts.remap_only = opts.remap_only ~= nil and opts.remap_only or register_defaults.remap_only
    else
        opts = opts or register_defaults
    end
    if not opts.remap_only then
        table.insert(state.actions, action)
    end
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
    end, { desc = "chat-context-ui: " .. action.id, buffer = opts.bufnr })
    return #state.actions
end

--- @param cl ccc.ContextLoad
M.register_after_load = function(cl)
    table.insert(state.afterLoad, cl)
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

--- used when re-opening the menu
M.remap = function()
    for _, action in ipairs(state.actions) do
        M.register_action(action, { remap_only = true })
    end
    for _, context in ipairs(state.contexts) do
        M.register_context(context, { remap_only = true })
    end
end

--- used when closing the menu
M.unmap_all = function()
    for _, keymap in ipairs(state.actions) do
        vim.keymap.del(keymap.mode, config.key(keymap.id))
    end
    for _, keymap in ipairs(state.contexts) do
        vim.keymap.del("n", config.key(keymap.id))
    end
end

--- @return boolean
M.loaded = function()
    return state.loaded
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

--- @param opts ?ccc.PluginOpts
M.setup = function(opts)
    opts = opts or {}
    local dir = vim.fn.expand(config.CACHE)
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end

    if opts.copy_on_prompt ~= nil then
        state.opts.copy_on_prompt = opts.copy_on_prompt
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
        state.loaded = true
    end

    for _, cl in ipairs(state.afterLoad) do
        state = cl.load(state)
    end
end

return M
