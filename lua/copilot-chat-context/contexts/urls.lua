local M = {}

local store = require("copilot-chat-context.store")
local notify = require("copilot-chat-context.external.notify")

--- @param state ccc.State
--- @return ccc.State
M.setup = function(state)
	store.register_action({
		name = "󰀳",
		msg = "",
		mode = "n",
		key = ",u",
		hidden = false,
		apply = M.replace,
		ui = "menu",
	})
	store.register_action({
		name = "󰜏",
		msg = "",
		mode = "n",
		key = ",U",
		hidden = false,
		apply = M.open,
		ui = "menu",
	})
	store.register_context({
		name = "󰖟",
		key = ",,u",
		active = false,
		getter = M.context,
		ui = "menu",
	})

	return state
end

--- @param state ccc.State
--- @return string
M.context = function(state)
	if #state.url == 0 then
		return ""
	end

	return "\n\n#url " .. state.url .. "\n\n"
end

--- @param state ccc.State
--- @return ccc.State
M.open = function(state)
	if #state.url > 0 then
		notify.add("opening " .. state.url, "INFO", { timeout = 1500, hg = "Comment" })
		local escaped_url = vim.fn.shellescape(state.url, true)
		-- remove the added quotes
		local url = string.sub(escaped_url, 2, #escaped_url - 1)
		vim.system({ "open", url }):wait()
	end
	return state
end

--- @param state ccc.State
--- @return ccc.State
M.replace = function(state)
	if #state.url > 0 then
		notify.add("replacing " .. state.url, "INFO", { timeout = 3500, hg = "Comment" })
	end
	vim.ui.input({ prompt = "url" }, function(input)
		if input == nil or #input == 0 then
			return
		end

		state.url = input
	end)
	return state
end

return M
