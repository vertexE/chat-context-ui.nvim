local M = {}

local ui = require("copilot-chat-context.ui.menu")
local assistant = require("copilot-chat-context.assistant")
local contexts = require("copilot-chat-context.contexts")
local menu = require("copilot-chat-context.menu")
local store = require("copilot-chat-context.store")

local notify = require("copilot-chat-context.external.notify")
local chat = require("copilot-chat-context.external.chat")

M.setup = function()
	-- TODO: allow user to set keys
	-- TODO: allow user to set symbols / prefer text + manage float win sizes

    -- load dependencies
	notify.setup()
	chat.setup()
end

--- @usage
--- vim.keymap.set("n", "<leader>ai", function()
---     require("copilot-chat-context").open()
--- end, { desc = "open AI action panel" })
M.open = function()
	local state = store.state()
	if vim.api.nvim_buf_is_valid(state.menu.bufnr) then
		return -- noop when trying to double open
	end

	assistant.setup(state)
	contexts.setup(state)
	menu.setup(state)
	store.setup() -- TODO: put all of the files/data we create into another location instead of the git repo
	ui.open(state)
end

return M
