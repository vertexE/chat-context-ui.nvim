-- config.lua

local M = {}

--- @alias ccc.ActionID "generate"|"ask"|"add-selection"|"list-selections"|"clear-selections"|"add-url"|"open-url"|"quit"|"toggle-selection"|"next-selection"|"previous-selection"|"show-previous-answer"
--- @alias ccc.ContextID "selections"|"active-selection"|"git-staged"|"buffers"|"file-tree"|"url"|"lsp"

--- generate inline based off provided context, or replace what you've selected (requires selection context active)
--- @type ccc.ActionID
M.generate = "generate"

--- ask a general question
--- @type ccc.ActionID
M.ask = "ask"

--- show the previously asked question
--- @type ccc.ActionID
M.show_previous_answer = "show-previous-answer"

--- add the selected code block to the list (MAX 10)
--- @type ccc.ActionID
M.add_selection = "add-selection"

--- list all saved code blocks
--- @type ccc.ActionID
M.list_selections = "list-selections"

--- include/exclude the code block in the list selections menu
--- @type ccc.ActionID
M.toggle_selection = "toggle-selection"

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

--- default keymap
--- @type table<string, ccc.ActionID|ccc.ContextID>
local default_keys = {
    --- Actions
    [",g"] = M.generate,
    [",a"] = M.ask,
    [",A"] = M.show_previous_answer,
    [",s"] = M.add_selection,
    [",l"] = M.list_selections,
    [",z"] = M.clear_selections,
    [",u"] = M.add_url,
    [",U"] = M.open_url,
    [",q"] = M.quit,
    --- Context Toggles
    [",,b"] = M.selections,
    [",,l"] = M.lsp,
    [",,s"] = M.active_selection,
    [",,g"] = M.git_staged,
    [",,B"] = M.buffers,
    [",,f"] = M.file_tree,
    [",,u"] = M.url,
}

--- @type table<ccc.ActionID|ccc.ContextID,string>
local default_icons = {
    --- actions
    [M.generate] = "",
    [M.ask] = "",
    [M.show_previous_answer] = " ",
    [M.add_selection] = "󰩭",
    [M.list_selections] = "",
    [M.clear_selections] = "󱟃",
    [M.add_url] = "",
    [M.open_url] = "󰜏",
    [M.quit] = "",
    --- contexts
    [M.selections] = "",
    [M.active_selection] = "󰒉",
    [M.git_staged] = "",
    [M.buffers] = "",
    [M.file_tree] = "",
    [M.url] = "",
    [M.lsp] = "",
    -- TODO: debugger
}

--- @type table<ccc.ActionID|ccc.ContextID, string>
local key_lookup = {}

local labels = default_icons

--- @class ccc.PluginOpts
--- @field copy_on_prompt ?boolean whether to copy the prompt to clipboard after asking
--- @field keymaps ?table<string, ccc.ActionID|ccc.ContextID> override the default keys
--- @field leader ?string override the leading key, e.g. generate defaults to ",g" overriding this to <space> makes it "<space>g>"
--- @field labels ?table<ccc.ActionID|ccc.ContextID,string> override the default labels for actions and context toggles

-- TODO:
-- - add vert-split as an option for RHS toolbar + float/split sizing
-- - add ability to disable actions / contexts entirely
-- - try adding ability to hide certain options? Such as hiding ask / explain
-- - always on that tries to suggest changes
-- - automate indexing of the codebase?

--- where we store all context between nvim sessions
M.CACHE = "~/.cache/nvim/chat-context-ui"

--- @param opts ccc.PluginOpts
M.setup = function(opts)
    for key, action in pairs(default_keys) do
        if opts.keymaps ~= nil and opts.keymaps[key] ~= nil then
            key_lookup[opts.keymaps[key]] = key
        else
            key_lookup[action] = key
        end
    end

    if opts.labels ~= nil then
        for id, label in pairs(opts.labels) do
            labels[id] = label
        end
    end
end

--- hidden actions are equivalent to sub-menu actions and may have conflicts with each other
--- if they are in different sub-menus
local hidden_actions = {
    [M.toggle_selection] = "<enter>",
    [M.next_selection] = "<tab>",
    [M.previous_selection] = "<s-tab>",
}

local hidden = function(id)
    return hidden_actions[id]
end

-- returns the action key from the config
--- @param id ccc.ActionID|ccc.ContextID
--- @return string
function M.key(id)
    return key_lookup[id] or hidden(id)
end

-- returns the action key from the config
--- @param id ccc.ActionID|ccc.ContextID
--- @return string
function M.label(id)
    return labels[id] or ""
end

return M
