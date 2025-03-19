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
| `,r`   | review the current buffer and add comments     |
| `,a`   | ask a question         |
| `,e`   | explain selected code     |
| `,s`   | add selection |
| `,l`   | list selections |
| `,z`   | clear selections |
| `,k`   | add knowledge |
| `,L`   | list knowledge |
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
| `,,B`  | current buffer (will likely be phased out...) |
| `,,f`  | file tree   |
| `,,u`  | same as using `#url` from CopilotChat.nvim, uses the url stored from the add-url command |

## Usage

<details>
<summary>generate</summary>
<!-- generate:start -->
quickly generate code inline

https://github.com/user-attachments/assets/5722efc4-31b0-4e21-abc7-08810a79d296

<!-- generate:end -->
</details>


## Next Steps

- [ ] if the panel is opened in a different tab, it should jump to the active tab if we try to open it again
- [ ] inline prompting using virtual text?
- [ ] possibly add diffs to better compare proposed changes?
- [ ] build repo context map to allow copilot to fetch more info (such as function definitions, class declarations, etc)

