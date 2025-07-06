# chat-context-ui.nvim

chat-context-ui is a UX wrapper around your favorite AI agent.
- generate code in line
- ask questions
- fine grained management of context (code blocks, urls, filetree, selection, lsp, etc...)

> [!caution]
> plugin still in a "draft" state and not ready for use, expect bugs and no documentation!
> I will continue to flush out the design and usage.

## Install

If you were to install and wrap `CopilotChat.nvim`, you could do something like the following

#### [Lazy](https://github.com/folke/lazy.nvim)

```lua
    {
        "josiahdenton/chat-context-ui.nvim",
        dependencies = {
            "CopilotC-Nvim/CopilotChat.nvim",
        },
        keys = {
            {
                "<leader>ai",
                function()
                    require("chat-context-ui").open()
                end,
                mode = { "n" },
                desc = "open AI actions panel",
            },
        },
        --- @type ccc.PluginOpts
        opts = {
            ui = {
                layout = "split",
            },
            agent = {
                callback = function(prompt, resolve)
                    require("CopilotChat").ask(prompt, {
                        headless = true,
                        callback = function(response)
                            resolve(response)
                        end,
                    })
                end,
            },
        },
    },
```

## Demo

With the assistant panel, you can do any of the following... 
- **action**: interact with copilot to create a response or manage context state
- **context**: toggle additional info for copilot to use

https://github.com/user-attachments/assets/5dc82c75-6ced-4610-bf65-36afa7f06436

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
