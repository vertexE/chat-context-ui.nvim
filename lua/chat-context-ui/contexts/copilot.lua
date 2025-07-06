local M = {}

local store = require("chat-context-ui.store")
local config = require("chat-context-ui.config")

local git_cache = {
    add = 0,
    del = 0,
    valid = false,
}

---@return string
local git_changes = function()
    if git_cache.valid then
        return string.format("+%d, -%d", git_cache.add, git_cache.del)
    end

    --- sample output:  4 files changed, 51 insertions(+), 13 deletions(-)
    vim.system({ "git", "diff", "--shortstat" }, { text = true }, function(out)
        if #out.stdout > 0 then
            local lines = vim.split(out.stdout, "\n", { trimempty = true })
            local changes = lines[#lines]
            if changes and #changes > 0 then
                local changes_by_type = vim.split(changes, ",", { trimempty = true })
                for i, change in ipairs(changes_by_type) do
                    if i == 2 then
                        local amount = string.match(change, "%d+")
                        git_cache.add = amount
                    elseif i == 3 then
                        local amount = string.match(change, "%d+")
                        git_cache.del = amount
                    end
                end
            end
        end
        git_cache.valid = true
    end)

    return git_cache.valid and string.format("+%d, -%d", git_cache.add, git_cache.del) or "??"
end

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
    vim.api.nvim_create_autocmd("User", {
        pattern = "MiniGitCommandDone",
        group = vim.api.nvim_create_augroup("ccc.git.stats.minigit", { clear = true }),
        desc = "refresh git stats",
        callback = vim.schedule_wrap(function()
            git_cache.valid = false
        end),
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("ccc.git.stats.base", { clear = true }),
        desc = "refresh git stats",
        callback = vim.schedule_wrap(function()
            git_cache.valid = false
        end),
    })

    store.register_context({
        id = config.git_staged,
        active = false,
        ui = "menu",
        --- @param _state ccc.State
        --- @return table<string,string>
        meta = function(_state)
            return { git_changes(), "Comment" }
        end,
        getter = function(_)
            return "\n\n#git:staged\n\n"
        end,
    })
    store.register_context({
        id = config.buffers,
        active = false,
        ui = "menu",
        --- @param _state ccc.State
        --- @return table<string,string>
        meta = function(_state)
            local bufs = vim.api.nvim_list_bufs()
            local len = #vim.iter(bufs)
                :filter(function(buf)
                    return vim.api.nvim_buf_is_valid(buf)
                        and vim.api.nvim_buf_is_loaded(buf)
                        and vim.fn.buflisted(buf)
                        and vim.bo[buf].buftype == "" -- normal buffer
                end)
                :totable()

            local fname = vim.api.nvim_buf_get_name(0)
            local tail_fname = vim.fn.fnamemodify(fname, ":t")
            local content = tail_fname .. (len > 1 and string.format("..+%d", len) or "")

            return { content, "Comment" }
        end,
        getter = function(_)
            return "#buffers"
        end,
    })
    store.register_context({
        id = config.file_tree,
        active = false,
        ui = "menu",
        --- @param _state ccc.State
        --- @return table<string,string>
        meta = function(_state)
            return { vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), "Comment" }
        end,
        getter = function(_)
            return "\n\n#files\n\n"
        end,
    })
    return state
end

return M
