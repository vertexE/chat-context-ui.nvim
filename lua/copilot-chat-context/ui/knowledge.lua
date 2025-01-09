local M = {}

local float = require("copilot-chat-context.ui.float")
local files = require("copilot-chat-context.external.files")

--- @param state ccc.State
M.draw = function(state)
    local home = vim.fn.expand("~")
    --- @type table<string>
    local lines = {}
    for _, knowledge in ipairs(state.knowledge.list) do
        local path = knowledge.file
        if string.find(knowledge.file, home, 0, true) then
            path = "~" .. vim.split(knowledge.file, home, { trimempty = true })[1]
        end

        table.insert(lines, path)
    end

    vim.api.nvim_buf_set_lines(state.knowledge.bufnr, 0, -1, false, lines)
    for i, knowledge in ipairs(state.knowledge.list) do
        local symbol = knowledge.active and "  " or "  "
        local hl = knowledge.active and "DiagnosticOk" or "Comment"
        vim.api.nvim_buf_set_extmark(
            state.knowledge.bufnr,
            vim.api.nvim_create_namespace("ccc.knowledge.list"),
            i - 1,
            0,
            {
                virt_text = { { symbol, hl } },
                virt_text_pos = "inline",
            }
        )
    end

    if state.knowledge.preview > 0 then
        local preview = state.knowledge.list[state.knowledge.preview]
        if preview then
            local content = files.read(preview.file)
            if content then
                -- now we extmark the content right below
                local vt = vim.iter(vim.split(content, "\n"))
                    :map(function(line)
                        return { { line, "Comment" } }
                    end)
                    :totable()
                vim.api.nvim_buf_set_extmark(
                    state.knowledge.bufnr,
                    vim.api.nvim_create_namespace("ccc.knowledge.list"),
                    state.knowledge.preview - 1,
                    0,
                    {
                        virt_lines = vt,
                        virt_text_pos = "inline",
                    }
                )
            end
        end
    end
end

--- @param state ccc.State
M.open = function(state)
    if #state.knowledge.list == 0 or state.knowledge.open then
        return
    end

    float.open(nil, {
        bufnr = state.knowledge.bufnr,
        title = "Select knowledge to include in prompt",
        rel = "center",
        width = 0.8,
        height = 0.5,
        enter = true,
        bo = { filetype = "markdown" },
        wo = { number = false, relativenumber = false, conceallevel = 1 },
    })
    state.knowledge.open = true

    M.draw(state)
end

return M
