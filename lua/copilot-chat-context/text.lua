local M = {}

--- select code in ``` block
--- @param s string
--- @return string
M.select_content = function(s)
    -- Extract content inside the first triple backtick code block, newline after ``` is optional
    local content = s:match("```[^\n]*\n(.-)\n?```")
    return content or ""
end

-- e.g.
-- local s = [[
-- ```lua
-- test
-- ```
-- ]]
--
-- vim.print(M.select_content(s))

return M
