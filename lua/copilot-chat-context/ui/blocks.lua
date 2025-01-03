local M = {}

local float = require("copilot-chat-context.ui.float")

--- expects a valid state.blocks.bufnr
--- @param state ccc.State
M.draw = function(state)
	local block = state.blocks.list[state.blocks.pos]
	local lines = vim.split(block.content, "\n")
	local preview = { "", string.format("```%s", block.extension) }
	for _, line in ipairs(lines) do
		table.insert(preview, line)
	end
	table.insert(preview, "```")
	vim.api.nvim_buf_set_lines(state.blocks.bufnr, 0, -1, false, preview)
	local hg = block.active and "DiagnosticOk" or "Comment"
	local symbol = block.active and "  " or "  "
	local ns = vim.api.nvim_create_namespace("user_ai_blocks_list")
	vim.api.nvim_buf_clear_namespace(state.blocks.bufnr, ns, 0, -1)
	vim.api.nvim_buf_set_extmark(state.blocks.bufnr, ns, 0, 0, {
		virt_text = {
			{
				string.rep(" ", 4) .. symbol .. block.path .. " " .. string.format(
					"(%d/%d)",
					state.blocks.pos,
					#state.blocks.list
				),
				hg,
			},
		},
		virt_text_pos = "overlay",
	})
end

--- @param state ccc.State
M.open = function(state)
	if #state.blocks.list == 0 or state.blocks.open then
		return
	end

	float.open(nil, {
		bufnr = state.blocks.bufnr,
		rel = "center",
		width = 0.8,
		height = 0.5,
		enter = true,
		bo = { filetype = "markdown" },
		wo = { number = false, relativenumber = false, conceallevel = 1 },
	})
	state.blocks.open = true

	M.draw(state)
end

return M
