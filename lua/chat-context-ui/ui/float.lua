local M = {}

--- @class ccc.FloatOpts
--- @field rel ?"cursor" | "center" | "rhs" | "lhs"
--- @field title ?string what to put as float title
--- @field enter ?boolean whether to enter float, defaults to true
--- @field bufnr ?integer buffer number
--- @field cursor ?{row : integer, col: integer}
--- @field height ?integer uses % of screen size
--- @field width ?integer uses % of screen size
--- @field row ?integer
--- @field col ?integer
--- @field bo ?table<string, any>
--- @field wo ?table<string, any>
--- @field close_on_q ?boolean

--- @type ccc.FloatOpts
local default_opts = {
    rel = "cursor",
    title = "",
    enter = true,
    bo = {
        filetype = "markdown",
    },
    wo = {},
    height = 0.30,
    width = 0.60,
    close_on_q = true,
}

local ABOVE_OFFSET = 2

--- @param content ?string
--- @param opts ?ccc.FloatOpts
--- @return integer,integer
M.open = function(content, opts)
    opts = opts or default_opts
    opts.height = opts.height or default_opts.height
    opts.width = opts.width or default_opts.width
    opts.rel = opts.rel or default_opts.rel
    opts.title = opts.title or default_opts.title
    if opts.enter == nil then
        opts.enter = default_opts.enter
    end
    if opts.close_on_q == nil then
        opts.close_on_q = default_opts.close_on_q
    end
    opts.bo = opts.bo or default_opts.bo
    opts.wo = opts.wo or default_opts.wo
    local bufnr = opts.bufnr or vim.api.nvim_create_buf(true, true)
    local editor_width = vim.o.columns
    local editor_height = vim.o.lines

    if opts.width <= 1 then
        opts.width = math.floor(editor_width * opts.width)
    end
    if opts.height <= 1 then
        opts.height = math.floor(editor_height * opts.height)
    end
    local row, col

    if opts.rel == "center" then
        row = (editor_height - opts.height) * 0.5 -- row is height
        col = (editor_width - opts.width) * 0.5 -- col is width
    elseif opts.rel == "cursor" then
        local pos = vim.fn.getpos(".")
        local win_size = vim.fn.winsaveview()
        row = math.max(pos[2] - win_size.topline - opts.height - ABOVE_OFFSET, 1)
        col = pos[3]
    elseif opts.rel == "rhs" then
        row = 0
        col = editor_width
    elseif opts.rel == "lhs" then
        row = 0
        col = 0
    end

    if opts.row ~= nil then
        row = opts.row
    end
    if opts.col ~= nil then
        row = opts.col
    end

    local float_win = vim.api.nvim_open_win(bufnr, opts.enter, {
        title = opts.title,
        border = "rounded",
        relative = "editor",
        row = row,
        col = col,
        height = opts.height,
        width = opts.width,
    })

    if content ~= nil and #content > 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
    end

    for buf_opt, setting in pairs(opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = bufnr })
    end

    for wo_opt, setting in pairs(opts.wo) do
        vim.api.nvim_set_option_value(wo_opt, setting, { win = float_win })
    end

    if opts.close_on_q then
        vim.keymap.set("n", "q", function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end, { buffer = bufnr })
    end

    return bufnr, float_win
end

return M
