local M = {}

local float = require("copilot-chat-context.ui.float")

--- @param state ccc.State
M.draw = function(state)
	if vim.g._user_ai_virtual_text_ns == nil then
		vim.g._user_ai_virtual_text_ns = vim.api.nvim_create_namespace("user_ai_virtual_text")
	end

	vim.api.nvim_buf_clear_namespace(state.menu.bufnr, vim.g._user_ai_virtual_text_ns, 0, -1)

	local lines = {}
	for _, action in ipairs(state.actions) do
		if not action.hidden then
			local line = { { action.key .. " - ", "Comment" }, { action.name, "AIActionsAction" } }
			table.insert(lines, line)
		end
	end
	table.insert(lines, {})
	table.insert(lines, { { "Contexts", "AIActionsHeader" } })

	for _, context in ipairs(state.contexts) do
		local meta = { "", "Comment" }
		if context.meta ~= nil then
			meta = context.meta(state)
		end
		local status_hg = "AIActionsInActiveContext"
		if context.active then
			status_hg = "AIActionsActiveContext"
		end
		table.insert(lines, {
			{ context.key .. " - ", status_hg },
			{ context.name .. "  ", status_hg },
			meta,
		})
	end

	vim.api.nvim_buf_set_extmark(state.menu.bufnr, vim.g._user_ai_virtual_text_ns, 0, 0, {
		virt_text = { { "AI Actions", "AIActionsHeader" } },
		virt_lines = lines,
		virt_text_pos = "eol",
	})
end

--- should open a window on the RHS with the AI options (actions + contexts)
--- @param state ccc.State
M.open = function(state)
	state.menu.bufnr = float.open(nil, {
		rel = "rhs",
		row = 3,
		width = 15,
		height = 28,
		enter = false,
		wo = { number = false, relativenumber = false },
	})
	M.draw(state)
	state.menu.open = true
end

return M
