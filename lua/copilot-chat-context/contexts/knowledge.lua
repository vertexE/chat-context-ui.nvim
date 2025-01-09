local M = {}

local store = require("copilot-chat-context.store")
local config = require("copilot-chat-context.config")
local file = require("copilot-chat-context.external.files")

--- @class ccc.Knowledge
--- @field file string path to the markdown file this knowledge is stored at
--- @field active boolean whether we include this file in the context

--- @param state ccc.State
--- @return table<string,string>
local meta = function(state)
    local active = #vim.tbl_filter(function(value)
        return value.active
    end, state.knowledge.list)

    return { active .. "," .. #state.knowledge.list, "Comment" }
end

--- @return table<string>|nil
local list_files_in_directory = function(directory)
    local handle = vim.uv.fs_scandir(directory)
    if not handle then
        print("Failed to open directory: " .. directory)
        return
    end

    local files = {}
    while true do
        local name, _ = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end
        table.insert(files, name)
    end

    return files
end

local added_files = {}

--- @param state ccc.State
--- @return ccc.State
local load_files = function(state)
    if state.knowledge.dir and #state.knowledge.dir > 0 then
        local dir = vim.fn.expand(state.knowledge.dir)
        local files = list_files_in_directory(dir)
        -- {file, active}
        if files then
            for _, _file in ipairs(files) do
                if not added_files[dir .. "/" .. _file] then
                    table.insert(state.knowledge.list, { file = dir .. "/" .. _file, active = false })
                    added_files[dir .. "/" .. _file] = true
                end
            end
        end
    end
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    state = load_files(state)
    store.register_action({
        id = config.list_knowledge,
        notification = "",
        mode = "n",
        hidden = false,
        apply = M.list,
        ui = "knowledge_open",
    })
    store.register_action({
        id = config.add_knowledge,
        notification = "",
        mode = "n",
        hidden = false,
        apply = M.add,
        ui = "menu",
    })
    store.register_context({
        id = config.knowledge,
        active = false,
        getter = M.context,
        meta = meta,
        ui = "menu",
    })

    return state
end

--- @param state ccc.State
--- @return ccc.State
M.add = function(state)
    local help = ""
    if state.knowledge.dir and #state.knowledge.dir > 0 then
        help = string.format("(%s)", state.knowledge.dir)
    end
    vim.ui.input({ prompt = "knowledge dir " .. help }, function(input)
        if input == nil or #input == 0 then
            return
        end

        state.knowledge.dir = input -- TODO: refresh files list as well
    end)
    return state
end

--- @param state ccc.State
--- @return ccc.State
M.list = function(state)
    state = load_files(state)
    state.knowledge.bufnr = vim.api.nvim_create_buf(true, false)
    store.register_action({
        id = config.preview_knowledge,
        notification = "",
        mode = "n",
        hidden = true,
        ui = "knowledge_redraw",
        apply = function(_state)
            local line_nr = vim.fn.getpos(".")[2]
            if _state.knowledge.preview == line_nr then
                -- turn off all previews
                _state.knowledge.preview = 0
            else
                _state.knowledge.preview = line_nr
            end
            return _state
        end,
    }, { bufnr = state.knowledge.bufnr })
    store.register_action({
        id = config.toggle_knowledge,
        notification = "",
        mode = "n",
        hidden = true,
        ui = "knowledge_redraw",
        apply = function(_state)
            local line_nr = vim.fn.getpos(".")[2]
            local knowledge = _state.knowledge.list[line_nr]
            if knowledge then
                knowledge.active = not knowledge.active
            end
            return _state
        end,
    }, { bufnr = state.knowledge.bufnr })
    vim.api.nvim_buf_attach(state.knowledge.bufnr, false, {
        on_detach = function()
            state.knowledge.open = false
            store.deregister_action(config.toggle_knowledge)
            store.deregister_action(config.preview_knowledge)
        end,
    })
    return state
end

--- @param state ccc.State
--- @return string
M.context = function(state)
    local prompt = "<knowledge>"
    for _, knowledge in ipairs(state.knowledge.list) do
        if knowledge.active then
            local content = file.read(knowledge.file)
            if content then
                prompt = prompt .. "\n" .. content
            end
        end
    end

    return prompt .. "</knowledge>"
end

return M
