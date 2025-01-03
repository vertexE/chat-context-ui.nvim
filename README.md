# copilot-chat-context.nvim

a fine grained approach to managing copilot chat context

> [!caution]
> plugin still in a "draft" state.

> [!caution]
> currently explain and review do not work until this merges https://github.com/CopilotC-Nvim/CopilotChat.nvim/pull/704

## Install

#### [Lazy](https://github.com/folke/lazy.nvim)

```lua
    {
        "josiahdenton/copilot-chat-context.nvim",
        dependencies = {
            "CopilotC-Nvim/CopilotChat.nvim",
            "echasnovski/mini.nvim", -- optional, uses mini.notify and will fallback to vim.notify if not available
        },
        config = function()
            local context = require("copilot-chat-context")
            context.setup()
            vim.keymap.set("n", "<leader>ai", function()
                context.open()
            end, { desc = "open copilot context panel" })
        end,
        -- other configurations
    },
```


