local M = {}

local float = require("chat-context-ui.ui.float")

-- TODO: plan for next steps
-- cleanup UI --> (icon) name (MiniIconsOrange) file (Comment)
-- if anything else is pressed cancel
-- action to activate listen mode
-- can use this menu when I want to inspect further

-- blink completion source...

--- @param state ccc.State
M.draw = function(state)
    if #state.fb_actions == 0 then
        return
    end

    for _, fb_action in ipairs(state.fb_actions) do
        if fb_action.expanded then
            local ext = vim.fn.fnamemodify(fb_action.filepath, ":e")
            local file_name = vim.fn.fnamemodify(fb_action.filepath, ":t")
            local lines = { string.format("```%s", ext), unpack(fb_action.content) }
            table.insert(lines, 1, string.format("# %s - `%s`", fb_action.name, file_name))
            table.insert(lines, "```")
            vim.api.nvim_buf_set_lines(state.feedback_menu_bufnr, 0, -1, false, lines)
            return -- only draw one action
        end
    end

    local ns_id = vim.api.nvim_create_namespace("chat-context-ui.virtual_text.feedback.menu")
    local vlines = {}
    for _, fb_action in ipairs(state.fb_actions) do
        local file_name = vim.fn.fnamemodify(fb_action.filepath, ":t")
        table.insert(vlines, {
            { " ", "MiniIconsOrange" },
            { string.format(" %s ", fb_action.name), "markdownH4" },
            { file_name, "Comment" },
        })
    end
    local header = vlines[1]
    table.remove(vlines, 1)
    vim.api.nvim_buf_set_extmark(state.feedback_menu_bufnr, ns_id, 0, 0, {
        virt_text = header,
        virt_lines = vlines,
        virt_text_pos = "inline",
    })
end

--- @param state ccc.State
M.open = function(state)
    if #state.fb_actions == 0 or state.feedback_menu_open then
        return
    end

    float.open(nil, {
        bufnr = state.feedback_menu_bufnr,
        rel = "cursor",
        width = 0.5,
        height = 0.3,
        enter = false,
        bo = { filetype = "markdown" },
        wo = { number = false, relativenumber = false, conceallevel = 1 },
    })
    state.feedback_menu_open = true

    M.draw(state)
end

return M
