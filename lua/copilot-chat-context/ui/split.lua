local M = {}

--- @class ccc.SplitOpts
--- @field bufnr ?integer buffer number
--- @field height ?integer number of rows to set split to or <1 a % of screen
--- @field bo ?table<string, any>
--- @field enter ?boolean whether to enter float, defaults to true
--- @field close_on_q ?boolean

--- @type ccc.SplitOpts
local horizontal_defaults = {
    height = 10,
    bo = {
        filetype = "markdown",
    },
    enter = false,
    close_on_q = true,
}

--- @param content ?string
--- @param opts ?ccc.SplitOpts
--- @return integer bufnr
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
    opts.bufnr = opts.bufnr ~= nil and opts.bufnr or horizontal_defaults.bufnr
    opts.bo = opts.bo ~= nil and opts.bo or horizontal_defaults.bo
    opts.height = opts.height ~= nil and opts.height or horizontal_defaults.height

    vim.cmd("split")
    vim.cmd(string.format("resize %d", 10))
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)

    if content ~= nil and #content > 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))
    end

    for buf_opt, setting in pairs(opts.bo) do
        vim.api.nvim_set_option_value(buf_opt, setting, { buf = bufnr })
    end

    if not opts.enter then
        vim.cmd("wincmd p")
    end

    if opts.close_on_q then
        vim.keymap.set("n", "q", function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end, { buffer = bufnr })
    end

    return bufnr
end

return M
