local M = {}

--- @return string path to git root or empty string if not a git repo
M.root = function()
    local job = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
    return vim.trim(job.stdout)
end

return M
