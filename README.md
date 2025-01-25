# copilot-chat-context.nvim

Improves UX of the `CopilotChat.nvim` plugin.
- predefined actions
- management of contexts (markdown files, selections, urls, filetree, saved code blocks, etc)

> [!caution]
> plugin still in a "draft" state, expect some bugs! Please report if you find any.

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


## Usage

<details>
<summary>generate</summary>
<!-- generate:start -->
generate code inline
    
https://github.com/user-attachments/assets/a3bf5181-d21e-4bda-b960-1874a86d71fc
<!-- generate:end -->
</details>

<details>
<summary>explain</summary>
<!-- explain:start -->
explain selected code / context
    
https://github.com/user-attachments/assets/5b0a34a9-820c-4b20-b812-a3cdc4d15836
<!-- explain:end -->
</details>

<details>
<summary>ask</summary>
<!-- ask:start -->
ask a question
    
https://github.com/user-attachments/assets/7759016d-8042-43e1-8341-6b023da7407c
<!-- ask:end -->
</details>


