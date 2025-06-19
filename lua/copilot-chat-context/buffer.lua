local M = {}

--- @return integer,integer
M.active_selection = function()
    local visual_pos = vim.fn.getpos("v")
    local visual_line = visual_pos[2]
    local cursor_pos = vim.fn.getpos(".")
    local cursor_line = cursor_pos[2]
    local start_line = math.min(visual_line, cursor_line)
    local end_line = math.max(visual_line, cursor_line)
    return start_line, end_line
end

--- checks if the buffer is open in the current tab
--- @param bufnr integer
M.is_open_in_current_tab = function(bufnr)
    -- Get all windows in the current tabpage
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
            return true
        end
    end
    return false
end

return M
