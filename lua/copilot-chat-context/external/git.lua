local M = {}

--- @return string path to git root
M.root = function()
	local job = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
	return vim.trim(job.stdout)
end

return M
