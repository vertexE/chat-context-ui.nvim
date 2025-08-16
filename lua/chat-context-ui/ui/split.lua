local M = {}

--- @class ccc.HSplitOpts
--- @field bufnr ?integer buffer number
--- @field height ?integer number of rows to set split to or <1 a % of screen
--- @field bo ?table<string, any>
--- @field wo ?table<string, any>
--- @field enter ?boolean whether to enter float, defaults to true
--- @field close_on_q ?boolean

--- @type ccc.HSplitOpts
local horizontal_defaults = {
    height = 10,
    bo = {
        filetype = "markdown",
    },
    wo = {},
    enter = false,
    close_on_q = true,
}

-- TODO: update horizontal or rmv

--- @param content ?string
--- @param opts ?ccc.VSplitOpts
--- @return integer,integer
M.horizontal = function(content, opts)
    opts = opts or {}
    if opts.enter ~= nil then
        opts.enter = opts.enter
    else
        opts.enter = horizontal_defaults.enter
    end
    if opts.close_on_q ~= nil then
        opts.close_on_q = opts.close_on_q
    else
        opts.close_on_q = horizontal_defaults.close_on_q
    end
    opts.bufnr = opts.bufnr ~= nil and opts.bufnr or vim.api.nvim_create_buf(true, true)
    opts.bo = opts.bo ~= nil and opts.bo or horizontal_defaults.bo
    opts.wo = opts.wo ~= nil and opts.wo or horizontal_defaults.wo
    opts.width = opts.width ~= nil and opts.width or 10

    local split_win = vim.api.nvim_open_win(opts.bufnr, opts.enter, {
        split = "below",
        height = opts.width,
    })

    if content ~= nil and #content > 0 then
        vim.api.nvim_buf_set_lines(opts.bufnr, 0, -1, false, vim.split(content, "\n"))
    end

    for buf_opt, setting in pairs(opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = opts.bufnr })
    end

    for wo_opt, setting in pairs(opts.wo) do
        vim.api.nvim_set_option_value(wo_opt, setting, { win = split_win })
    end

    if opts.close_on_q then
        vim.keymap.set("n", "q", function()
            vim.api.nvim_buf_delete(opts.bufnr, { force = true })
        end, { buffer = opts.bufnr })
    end

    return opts.bufnr, split_win
end

--- @class ccc.VSplitOpts
--- @field bufnr ?integer buffer number
--- @field width ?integer number of rows to set split to or <1 a % of screen
--- @field bo ?table<string, any>
--- @field wo ?table<string, any>
--- @field enter ?boolean whether to enter float, defaults to true
--- @field close_on_q ?boolean
--- @field split ?"left"|"right"

--- @type ccc.VSplitOpts
local vertical_defaults = {
    width = 10,
    bo = {
        filetype = "markdown",
    },
    wo = {},
    enter = false,
    close_on_q = true,
    split = "right",
}

--- @param content ?string
--- @param opts ?ccc.VSplitOpts
--- @return integer,integer
M.vertical = function(content, opts)
    opts = opts or {}
    -- Set defaults for vertical split
    if opts.enter ~= nil then
        opts.enter = opts.enter
    else
        opts.enter = vertical_defaults.enter
    end
    if opts.close_on_q ~= nil then
        opts.close_on_q = opts.close_on_q
    else
        opts.close_on_q = vertical_defaults.close_on_q
    end
    opts.bufnr = opts.bufnr ~= nil and opts.bufnr or vim.api.nvim_create_buf(true, true)
    opts.bo = opts.bo ~= nil and opts.bo or vertical_defaults.bo
    opts.wo = opts.wo ~= nil and opts.wo or vertical_defaults.wo
    opts.width = opts.width ~= nil and opts.width or 35 -- default width for vertical split

    local split_win = vim.api.nvim_open_win(opts.bufnr, opts.enter, {
        split = opts.split or vertical_defaults.split,
        width = opts.width,
    })

    if content ~= nil and #content > 0 then
        vim.api.nvim_buf_set_lines(opts.bufnr, 0, -1, false, vim.split(content, "\n"))
    end

    for buf_opt, setting in pairs(opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = opts.bufnr })
    end

    for wo_opt, setting in pairs(opts.wo) do
        vim.api.nvim_set_option_value(wo_opt, setting, { win = split_win })
    end

    if opts.close_on_q then
        vim.keymap.set("n", "q", function()
            vim.api.nvim_buf_delete(opts.bufnr, { force = true })
        end, { buffer = opts.bufnr })
    end

    return opts.bufnr, split_win
end

return M
