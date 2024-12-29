local M = {}
local job = require("plenary.job")

local config = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

function M.setup(opts)
	return vim.tbl_extend("force", config, opts or {})
end

-- M.item = require("eagle.item")
M.app = require("eagle.app")
-- M.library = require("eagle.library")
-- M.folder = require("eagle.folder")

return M
