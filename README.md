# chat-context-ui.nvim

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
        "josiahdenton/chat-context-ui.nvim",
        dependencies = {
            "CopilotC-Nvim/CopilotChat.nvim",
            "echasnovski/mini.nvim", -- optional, uses mini.notify and will fallback to vim.notify if not available
        },
        config = function()
            local context = require("chat-context-ui")
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
| `,,B`  | all buffers |
| `,,f`  | file tree   |
| `,,u`  | same as using `#url` from CopilotChat.nvim, uses the url stored from the add-url command |


## Next Steps

- [ ] inline prompting using virtual text?
    - open hidden buf and hide cursor
    - type out what you want?
- [ ] possibly add diffs to better compare proposed changes? could make this an option you enable...
- [ ] build repo context map to allow copilot to fetch more info (such as function definitions, class declarations, etc)
- [ ] build out feedback loop + quick actions

### IDEA: Feedback loop + Quick actions

- give constant feedback every N seconds
- suggest quick actions (tries to come up with prompt)
- if you select a quick action, it will start working
  --> it will have to select that range and modify that range
