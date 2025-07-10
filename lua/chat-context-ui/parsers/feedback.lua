local M = {}

--- @alias ccc.FeedbackActionType "INSERT"|"REPLACE"|"DELETE"

--- @type table<ccc.FeedbackActionType>
M.ACTION_TYPES = { "INSERT", "REPLACE", "DELETE" }

--- @class ccc.FeedbackAction
--- @field name string a short descriptor of what the action should do
--- @field filepath string which file the action should take place
--- @field type ccc.FeedbackActionType
--- @field line integer starting line action takes place
--- @field end_line integer end line change, may be the same as line
--- @field expanded boolean whether we should render the content
--- @field content string[] content to insert / replace with, nil if DELETE

---@param action ccc.FeedbackAction
---@return boolean
local validate_action = function(action)
    return action.name ~= nil
        and vim.tbl_contains(M.ACTION_TYPES, action.type)
        and vim.fn.filereadable(vim.fn.fnamemodify(action.filepath, ":p")) == 1
end

---@param s string
---@return ccc.FeedbackAction[]
M.parse = function(s)
    local lines = vim.split(s, "\n")
    local actions = {}
    --- @type ccc.FeedbackAction
    local action = nil
    local new_action_start = false
    local code_block_start = false
    local code_block = {}

    for _, line in ipairs(lines) do
        if string.match(line, "^#") and not code_block_start then
            local segments = vim.split(line, "|")
            -- BUG: if nil vim.trim will throw an error!
            local name = vim.trim(string.sub(segments[1] or "", 2)) -- skip '#'
            local filepath = vim.trim(segments[2] or "")
            local type = vim.trim(segments[3] or "")
            local range = vim.trim(segments[4] or "")
            local line_locations = vim.split(range, ":")
            local sline = tonumber(line_locations[1])
            local eline = tonumber(line_locations[2])

            if sline ~= nil and eline ~= nil then
                action = {
                    name = name,
                    filepath = filepath,
                    type = type,
                    line = sline,
                    expanded = false,
                    end_line = eline,
                    content = {},
                }
                local valid = validate_action(action)
                if valid then
                    new_action_start = true
                    if action.type == "DELETE" then
                        -- DELETE should not have a code block so we don't wait to insert
                        table.insert(actions, action)
                    end
                end
            else
                vim.notify(
                    string.format("chat-context-ui: unable to parse feedback\n%s", line),
                    vim.log.levels.WARN,
                    {}
                )
            end
        end

        if new_action_start and code_block_start and string.match(line, "^```") then
            code_block_start = false
            new_action_start = false
            action.content = code_block
            code_block = {}
            table.insert(actions, action)
        elseif new_action_start and action.type ~= "DELETE" and string.match(line, "^```") then
            code_block_start = true
        elseif new_action_start and code_block_start then
            table.insert(code_block, line)
        end

        -- we skip anything else...
    end

    return actions
end

-- local test_s = [[
-- # Add function documentation | lua/chat-context-ui/parsers/feedback.lua | INSERT | 1:1
-- ```lua
-- --- Sums the numbers in a list and prints the result using vim.print.
-- ```
--
-- # Use local function for sum | lua/chat-context-ui/parsers/feedback.lua | INSERT | 3:3
-- ```lua
-- local function sum_list(list)
--     local sum = 0
--     for _, v in ipairs(list) do
--         sum = sum + v
--     end
--     return sum
-- end
-- ```
--
-- # Use sum_list function | lua/chat-context-ui/parsers/feedback.lua | REPLACE | 4:6
-- ```lua
-- local sum = sum_list(n)
-- ```
--
-- # Add module return for reuse | lua/chat-context-ui/parsers/feedback.lua | INSERT | 9:9
-- ```lua
-- return {
--     sum_list = sum_list,
-- }
-- ```
--
-- # Add file-level module docstring | lua/chat-context-ui/parsers/feedback.lua | INSERT | 1:1
-- ```lua
-- -- extras.lua: Utility functions for UI extras
-- ```
-- ]]
--
-- vim.print(M.parse(test_s))

return M
