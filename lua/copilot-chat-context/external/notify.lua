local M = {}

--- @type "vim"|"mini"
local use = "vim"

local extern_notifier

M.setup = function()
	local status, mini_notify = pcall(require, "mini.notify")
	if status then
		use = "mini"
		extern_notifier = mini_notify
	else -- fallback to vim
		use = "vim"
	end
end

--- @class ccc.NotifierOpts
--- @field hg ?string for mini
--- @field timeout ?integer for mini

--- @param msg any
---@param level "INFO"|"WARN"|"ERROR"
---@param opts ?ccc.NotifierOpts
M.add = function(msg, level, opts)
	if use == "vim" then
		vim.notify(msg, vim.log.levels[level], {})
	elseif use == "mini" then
		opts = opts or { hg = "Comment", timeout = 1500 }
		local id = extern_notifier.add(msg, level, opts.hg)
		vim.defer_fn(function()
			extern_notifier.remove(id)
		end, opts.timeout)
	end
end

return M
