-- config.lua

local M = {}

--- @alias ccc.ActionID "generate"|"review"|"ask"|"explain"|"add-selection"|"list-selections"|"clear-selections"|"add-url"|"open-url"|"open-patterns"|"open-task"|"quit"|"toggle-selection"|"next-selection"|"previous-selection"|"list-knowledge"|"toggle-knowledge"|"add-knowledge"|"preview-knowledge"
--- @alias ccc.ContextID "previous-ask"|"previous-explanation"|"selections"|"active-selection"|"git-staged"|"buffer"|"file-tree"|"url"|"patterns"|"task"|"knowledge"

--- generate inline based off provided context, or replace what you've selected (requires selection context active)
--- @type ccc.ActionID
M.generate = "generate"

--- review the selected code (visual mode only)
--- @type ccc.ActionID
M.review = "review"

--- ask a general question
--- @type ccc.ActionID
M.ask = "ask"

--- explain the highlighted code (visual mode only)
--- @type ccc.ActionID
M.explain = "explain"

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

--- open the coding patterns file
--- @type ccc.ActionID
M.open_patterns = "open-patterns"

--- open the task file
--- @type ccc.ActionID
M.open_task = "open-task"

--- list available knowledge
--- @type ccc.ActionID
M.list_knowledge = "list-knowledge"

--- add knowledge base, dir path to markdown files
--- @type ccc.ActionID
M.add_knowledge = "add-knowledge"

--- toggle knowledge
--- @type ccc.ActionID
M.toggle_knowledge = "toggle-knowledge"

--- toggle knowledge
--- @type ccc.ActionID
M.preview_knowledge = "preview-knowledge"

--- close the menu and delete all keymaps
--- @type ccc.ActionID
M.quit = "quit"

--- previous response to the "ask" action
--- @type ccc.ContextID
M.previous_ask = "previous-ask"

--- previous response to the "explain" action
--- @type ccc.ContextID
M.previous_explanation = "previous-explanation"

--- all active code blocks saved to the selections list
--- @type ccc.ContextID
M.selections = "selections"

--- all active knowledge
--- @type ccc.ContextID
M.knowledge = "knowledge"

--- what's actively highlighted/selected
--- @type ccc.ContextID
M.active_selection = "active-selection"

--- git staged files
--- @type ccc.ContextID
M.git_staged = "git-staged"

--- the current open buffer
--- @type ccc.ContextID
M.buffer = "buffer"

--- the file tree
--- @type ccc.ContextID
M.file_tree = "file-tree"

--- the url
--- @type ccc.ContextID
M.url = "url"

--- the patterns file
--- @type ccc.ContextID
M.patterns = "patterns"

--- the task file
--- @type ccc.ContextID
M.task = "task"

--- @type table<string, ccc.ActionID|ccc.ContextID>
local default_keys = {
    --- Actions
    [",g"] = M.generate,
    [",r"] = M.review,
    [",a"] = M.ask,
    [",e"] = M.explain,
    [",k"] = M.add_knowledge,
    [",L"] = M.list_knowledge,
    [",s"] = M.add_selection,
    [",l"] = M.list_selections,
    [",z"] = M.clear_selections,
    [",u"] = M.add_url,
    [",U"] = M.open_url,
    [",p"] = M.open_patterns,
    [",t"] = M.open_task,
    [",q"] = M.quit,
    --- Context Toggles
    [",,A"] = M.previous_ask,
    [",,E"] = M.previous_explanation,
    [",,K"] = M.knowledge,
    [",,b"] = M.selections,
    [",,s"] = M.active_selection,
    [",,g"] = M.git_staged,
    [",,B"] = M.buffer,
    [",,f"] = M.file_tree,
    [",,u"] = M.url,
    [",,p"] = M.patterns,
    [",,t"] = M.task,
}

--- @type table<ccc.ActionID|ccc.ContextID,string>
local default_icons = {
    --- actions
    [M.generate] = "",
    [M.review] = "",
    [M.ask] = "",
    [M.explain] = "󱈅",
    [M.add_knowledge] = "󰮆",
    [M.list_knowledge] = "󰆼",
    [M.add_selection] = "󰩭",
    [M.list_selections] = "",
    [M.clear_selections] = "󱟃",
    [M.add_url] = "",
    [M.open_url] = "󰜏",
    [M.open_patterns] = "",
    [M.open_task] = "",
    [M.quit] = "",
    --- contexts
    [M.previous_ask] = " ",
    [M.previous_explanation] = " 󱈅",
    [M.selections] = "",
    [M.knowledge] = "󰆼",
    [M.active_selection] = "󰒉",
    [M.git_staged] = "",
    [M.buffer] = "",
    [M.file_tree] = "",
    [M.url] = "",
    [M.patterns] = "",
    [M.task] = "",
}

--- @type table<ccc.ActionID|ccc.ContextID, string>
local key_lookup = {}

local labels = default_icons

--- @class ccc.PluginOpts
--- @field keymaps ?table<string, ccc.ActionID|ccc.ContextID> override the default keys
--- @field leader ?string override the leading key, e.g. generate defaults to ",g" overriding this to <space> makes it "<space>g>"
--- @field labels ?table<ccc.ActionID|ccc.ContextID,string> override the default labels for actions and context toggles

-- TODO:
-- - add vert-split as an option for RHS toolbar + float/split sizing
-- - add ability to disable actions / contexts entirely
-- - try adding ability to hide certain options? Such as hiding ask / explain

--- where we store all context between nvim sessions
M.CACHE = "~/.cache/nvim/copilot-chat-context"

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
    [M.toggle_knowledge] = "<enter>",
    [M.preview_knowledge] = "<tab>",
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
