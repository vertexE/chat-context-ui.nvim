--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

--- Create a new completion source.
--- @param opts table
--- @return blink.cmp.Source
function source.new(opts)
    local self = setmetatable({}, { __index = source })
    self.opts = opts
    return self
end

--- @param ctx blink.cmp.Context
--- @param callback fun(result: table)
function source:get_completions(ctx, callback)
    local state = require("chat-context-ui.store").state()

    --- @type lsp.CompletionItem[]
    local items = {}

    for _, fb_action in ipairs(state.fb_actions) do
        local ext = vim.fn.fnamemodify(fb_action.filepath, ":e")
        local lines = { string.format("```%s", ext), unpack(fb_action.content) }
        table.insert(lines, "```")

        --- @type lsp.CompletionItem
        local item = {
            label = fb_action.name,
            textEdit = {
                newText = table.concat(fb_action.content, "\n"),
                range = {
                    start = { line = ctx.cursor[1] - 1, character = 0 },
                    ["end"] = { line = ctx.cursor[1] - 1, character = 1000 },
                },
            },
            documentation = {
                kind = "markdown",
                value = table.concat(lines, "\n"),
            },
        }
        table.insert(items, item)
    end
    callback({
        items = items,
        is_incomplete_backward = false,
        is_incomplete_forward = false,
    })
end

return source
