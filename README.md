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

## Panel

When the panel is open, you can do any of the following... 
- **action**: interact with copilot to create a response
- **context**: toggle additional info for copilot to use

<img width="1506" alt="image" src="https://github.com/user-attachments/assets/3415227b-6c79-486c-93e6-a9ca4d2b8668" />

The default keymaps is as follows

| Action Keymaps | Description |
|--------|-------------|
| `,g`   | generate code   |
| `,b`   | build a code block quickly      |
| `,r`   | review the current buffer and add comments     |
| `,a`   | ask a question         |
| `,e`   | explain selected code     |
| `,k`   | add knowledge |
| `,L`   | list knowledge |
| `,s`   | add selection |
| `,l`   | list selections |
| `,z`   | clear selections |
| `,u`   | add url     |
| `,U`   | open url    |
| `,q`   | quit        |

| Context Keymaps | Description |
|--------|-------------|
| `,,A`  | previously asked question and copilot's answer |
| `,,E`  | previous explanation |
| `,,K`  | all active knowledge files |
| `,,b`  | all active code blocks |
| `,,s`  | active selection |
| `,,g`  | git staged  |
| `,,B`  | current buffer  |
| `,,f`  | file tree   |
| `,,u`  | same as using `#url` from CopilotChat.nvim |

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


