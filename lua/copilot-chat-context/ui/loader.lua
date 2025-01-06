local M = {}

local next_loader_id = 1

--- @param _start integer line number
--- @param _end integer line number
--- @param apply_ghost boolean
--- @return integer id
M.create = function(_start, _end, apply_ghost)
    local loader_id = next_loader_id
    next_loader_id = next_loader_id + 1
    local ns_id = vim.api.nvim_create_namespace("user_loader_vt_" .. loader_id)
    if not apply_ghost then
        vim.api.nvim_buf_set_extmark(0, ns_id, _start - 1, 0, {
            virt_text = { { string.rep(" ", 4), "Comment" }, { "  Thinking...", "DiagnosticOk" } },
            virt_text_pos = "eol",
        })
        return ns_id
    end

    local lines = vim.api.nvim_buf_get_lines(0, _start - 1, _end, false)
    for i, line in ipairs(lines) do
        vim.api.nvim_buf_set_extmark(0, ns_id, _start - 1 + i - 1, 0, {
            virt_text = (
                i == 1
                and { { line, "Comment" }, { string.rep(" ", 4), "Comment" }, { "  Thinking...", "DiagnosticOk" } }
            ) or { { line, "Comment" } },
            virt_text_pos = "overlay",
        })
    end
    return ns_id
end

--- @param ns_id integer namespace ID to clear for this loader, returned from M.create
M.clear = function(ns_id)
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

return M
