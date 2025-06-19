# copilot-chat-context.nvim

Improves UX of the `CopilotChat.nvim` plugin.
- predefined actions
- management of contexts (markdown files, selections, urls, filetree, saved code blocks, etc)

> [!caution]
> plugin still in a "draft" state and not ready for use, expect bugs and no documentation!
> I will continue to flush out the design and usage.

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

## Demo

With the assistant panel, you can do any of the following... 
- **action**: interact with copilot to create a response or manage context state
- **context**: toggle additional info for copilot to use

https://github.com/user-attachments/assets/5722efc4-31b0-4e21-abc7-08810a79d296

## Usage

The default keymaps is as follows

| Action Keymaps | Description |
|--------|-------------|
| `,g`   | generate code   |
| `,a`   | ask a question         |
| `,A`   | show previous answer to question         |
| `,s`   | add selection |
| `,l`   | list selections |
| `,z`   | clear selections |
| `,u`   | add url     |
| `,U`   | open url    |
| `,q`   | quit        |

| Context Keymaps | Description |
|--------|-------------|
| `,,b`  | all active code blocks |
| `,,s`  | active selection |
| `,,g`  | git staged  |
| `,,B`  | current buffer (will likely be phased out...) |
| `,,f`  | file tree   |
| `,,u`  | same as using `#url` from CopilotChat.nvim, uses the url stored from the add-url command |


## Next Steps

- [ ] if the panel is opened in a different tab, it should jump to the active tab if we try to open it again
- [ ] inline prompting using virtual text?
- [ ] possibly add diffs to better compare proposed changes?
- [ ] build repo context map to allow copilot to fetch more info (such as function definitions, class declarations, etc)
