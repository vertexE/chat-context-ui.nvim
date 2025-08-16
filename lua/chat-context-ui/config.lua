-- config.lua

local M = {}

--- @alias ccc.ActionID "generate"|"ask"|"add-selection"|"list-selections"|"clear-selections"|"add-url"|"open-url"|"quit"|"toggle-selection"|"next-selection"|"previous-selection"|"show-previous-answer"|"add-definition"|"toggle-help"|"set-goal"|"toggle-feedback"|"open-feedback-menu"|"expand-item"|"select-item"|"shortcuts"|"clear-chat-history"
--- @alias ccc.ContextID "selections"|"active-selection"|"git-staged"|"buffers"|"file-tree"|"url"|"lsp"

--- show/hide the help screen
--- @type ccc.ActionID
M.toggle_help = "toggle-help"

--- generate inline based off provided context, or replace what you've selected (requires selection context active)
--- @type ccc.ActionID
M.generate = "generate"

--- ask a general question
--- @type ccc.ActionID
M.ask = "ask"

--- ask a general question
--- @type ccc.ActionID
M.clear_chat_history = "clear-chat-history"

--- toggle on/off feedback mode
--- @type ccc.ActionID
M.toggle_feedback = "toggle-feedback"

--- turn on shortcut
--- @type ccc.ActionID
M.shortcuts = "shortcuts"

--- open the feedback menu to select action
--- @type ccc.ActionID
M.open_feedback_menu = "open-feedback-menu"

--- set the active goal feedback mode will use
--- @type ccc.ActionID
M.set_goal = "set-goal"

--- show the previously asked question
--- @type ccc.ActionID
M.show_previous_answer = "show-previous-answer"

--- add the symbol def file to context
--- @type ccc.ActionID
M.add_definition = "add-definition"

--- add the selected code block to the list (MAX 10)
--- @type ccc.ActionID
M.add_selection = "add-selection"

--- list all saved code blocks
--- @type ccc.ActionID
M.list_selections = "list-selections"

--- include/exclude the code block in the list selections menu
--- @type ccc.ActionID
M.toggle_selection = "toggle-selection"

--- include/exclude the code block in the list selections menu
--- @type ccc.ActionID
M.expand_item = "expand-item"

--- include/exclude the code block in the list selections menu
--- @type ccc.ActionID
M.select_item = "select-item"

--- go to next saved code block in the selections menu
--- @type ccc.ActionID
M.next_selection = "next-selection"

--- go to previous selection in the selections menu
--- @type ccc.ActionID
M.previous_selection = "previous-selection"

--- clear all saved code blocks
--- @type ccc.ActionID
M.clear_selections = "clear-selections"

--- add a web url beginning with http(s)://
--- @type ccc.ActionID
M.add_url = "add-url"

--- remove the url
--- @type ccc.ActionID
M.open_url = "open-url"

--- close the menu and delete all keymaps
--- @type ccc.ActionID
M.quit = "quit"

--- all active code blocks saved to the selections list
--- @type ccc.ContextID
M.lsp = "lsp"

--- all active code blocks saved to the selections list
--- @type ccc.ContextID
M.selections = "selections"

--- what's actively highlighted/selected
--- @type ccc.ContextID
M.active_selection = "active-selection"

--- git staged files
--- @type ccc.ContextID
M.git_staged = "git-staged"

--- the current open buffer
--- @type ccc.ContextID
M.buffers = "buffers"

--- the file tree
--- @type ccc.ContextID
M.file_tree = "file-tree"

--- the url
--- @type ccc.ContextID
M.url = "url"

--- @class ccc.AgentOpts
--- @field callback ?fun(prompt:string,resolve:fun(response:string))

--- @alias ccc.layoutOpts "split"|"float"
--- @alias ccc.floatPos "top"|"bottom"

--- @class ccc.UiOpts
--- @field layout ?ccc.layoutOpts
--- @field float_pos ?ccc.floatPos whether the floating menu should be at the top or bottom

--- @type ccc.UiOpts

--- @class ccc.PluginOpts
--- @field copy_on_prompt ?boolean whether to copy the prompt to clipboard after asking
--- @field ui ?ccc.UiOpts
--- @field agent ?ccc.AgentOpts describes what agent to call
--- @field keys ?table<ccc.ActionID|ccc.ContextID, string> override the default keys
--- @field icons ?table<ccc.ActionID|ccc.ContextID, string> override the default keys

--- @type ccc.PluginOpts
local plugin_opts = {
    agent = {},
    keys = {
        --- Actions
        [M.generate] = ",g",
        [M.ask] = ",c", -- chat
        [M.clear_chat_history] = ",C",
        [M.toggle_feedback] = ",f",
        [M.shortcuts] = ",s",
        [M.open_feedback_menu] = ",F",
        [M.set_goal] = ",G",
        [M.show_previous_answer] = ",A",
        [M.add_selection] = ",a",
        [M.list_selections] = ",L",
        [M.clear_selections] = ",z",
        [M.add_url] = ",u",
        [M.open_url] = ",U",
        [M.quit] = ",q",
        [M.toggle_help] = ",?",
        --- Context Toggles
        [M.selections] = ",,b",
        [M.lsp] = ",,l",
        [M.active_selection] = ",,s",
        [M.git_staged] = ",,g",
        [M.buffers] = ",,B",
        [M.file_tree] = ",,f",
        [M.url] = ",,u",
    },
    icons = {
        --- actions
        [M.generate] = "",
        [M.ask] = "",
        [M.clear_chat_history] = "",
        [M.toggle_feedback] = "",
        [M.set_goal] = "", -- TODO: might be better to serve as a context??
        [M.show_previous_answer] = " ",
        [M.add_selection] = "󰩭",
        [M.list_selections] = "",
        [M.clear_selections] = "󱟃",
        [M.add_url] = "",
        [M.open_url] = "󰜏",
        [M.quit] = "",
        [M.toggle_help] = "󰞋",
        --- contexts
        [M.selections] = "",
        [M.active_selection] = "󰒉",
        [M.git_staged] = "",
        [M.buffers] = "",
        [M.file_tree] = "",
        [M.url] = "", -- FIXME: probably remove?
        [M.lsp] = "",
        -- TODO: debugger 
    },
    ui = {
        layout = "float",
        float_pos = "top",
    },
}

-- TODO:
-- - add ability to disable actions / contexts entirely
-- - try adding ability to hide certain options? Such as hiding ask / explain
-- - always on that tries to suggest changes (feedback mode)
-- - automate indexing of the codebase? --> would require external work...

--- where we store all context between nvim sessions
M.CACHE = "~/.cache/nvim/chat-context-ui"

--- @param opts ?ccc.PluginOpts
M.setup = function(opts)
    opts = opts or {}
    if opts.keys ~= nil then
        for action, key in pairs(opts.keys) do
            plugin_opts.keys[action] = key
        end
    end

    if opts.icons ~= nil then
        for id, label in pairs(opts.icons) do
            plugin_opts.icons[id] = label
        end
    end

    if opts.ui ~= nil then
        plugin_opts.ui = vim.tbl_extend("force", plugin_opts.ui, opts.ui)
    end

    if opts.agent ~= nil then
        plugin_opts.agent = vim.tbl_extend("force", plugin_opts.agent, opts.agent)
    else
        vim.notify("chat-context-ui: missing agent config", vim.log.levels.ERROR, {})
    end
end

--- hidden actions are equivalent to sub-menu actions and may have conflicts with each other
--- if they are in different sub-menus
local hidden_actions = {
    [M.toggle_selection] = "<enter>",
    [M.next_selection] = "<tab>",
    [M.expand_item] = "<tab>",
    [M.select_item] = "<enter>",
    [M.previous_selection] = "<s-tab>",
}

local hidden = function(id)
    return hidden_actions[id]
end

-- returns the action key from the config
--- @param id ccc.ActionID|ccc.ContextID
--- @return string
function M.key(id)
    return plugin_opts.keys[id] or hidden(id)
end

--- @return table<table<ccc.ActionID|ccc.ContextID, string>>
function M.keys()
    local help = {
        --- Actions
        { [M.generate] = M.key(M.generate) },
        { [M.ask] = M.key(M.ask) },
        { [M.clear_chat_history] = M.key(M.clear_chat_history) },
        { [M.shortcuts] = M.key(M.shortcuts) },
        { [M.toggle_feedback] = M.key(M.toggle_feedback) },
        { [M.open_feedback_menu] = M.key(M.open_feedback_menu) },
        { [M.set_goal] = M.key(M.set_goal) },
        { [M.show_previous_answer] = M.key(M.show_previous_answer) },
        { [M.add_selection] = M.key(M.add_selection) },
        { [M.list_selections] = M.key(M.list_selections) },
        { [M.clear_selections] = M.key(M.clear_selections) },
        { [M.add_url] = M.key(M.add_url) },
        { [M.open_url] = M.key(M.open_url) },
        {},
        --- Context Toggles
        { [M.selections] = M.key(M.selections) },
        { [M.lsp] = M.key(M.lsp) },
        { [M.active_selection] = M.key(M.active_selection) },
        { [M.git_staged] = M.key(M.git_staged) },
        { [M.buffers] = M.key(M.buffers) },
        { [M.file_tree] = M.key(M.file_tree) },
        { [M.url] = M.key(M.url) },
        {},
        { [M.toggle_help] = M.key(M.toggle_help) },
        { [M.quit] = M.key(M.quit) },
    }

    return help
end

-- returns the action key from the config
--- @param id ccc.ActionID|ccc.ContextID
--- @return string
function M.icon(id)
    return plugin_opts.icons[id] or ""
end

--- @return ccc.UiOpts
function M.ui()
    return plugin_opts.ui
end

--- @return ccc.AgentOpts|nil
function M.agent()
    return plugin_opts.agent
end

return M
