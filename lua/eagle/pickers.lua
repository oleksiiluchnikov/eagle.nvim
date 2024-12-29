local M = {}
local job = require("plenary.job")
-- local telescope = require("telescope")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local actions_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local ItemCommand = require("eagle.item")

local Layout = require("telescope.pickers.layout")

local function get_alacritty_font_size()
	local config_file = vim.fn.expand("~/.config/alacritty/alacritty.yml")
	local stdout = {}
	job:new({
		command = "bat",
		args = { config_file },
		on_stdout = function(_, data)
			for line in data:gmatch("[^\r\n]+") do
				if line:match(".*size: (%d+)") then
					local font_size = line:match(".*size: (%d+)")
					table.insert(stdout, font_size)
					break
				end
			end
		end,
	}):sync()
	return tonumber(stdout[1])
end

local function store_screen_size()
	vim.g.alacritty_font_size = get_alacritty_font_size()
end

-- Define a function to modify Alacritty's configuration file
local function resize_alacritty(font_size)
	local config_file = vim.fn.expand("~/.config/alacritty/alacritty.yml")
	local new_config = {}

	-- Read the configuration file into a table
	local file = io.open(config_file, "r")
	if not file then
		print("Error opening file " .. config_file)
		return
	end
	local config = file:read("*all")
	file:close()

	-- Backup the configuration file
	os.execute("cp " .. config_file .. " " .. config_file .. ".backup")

	-- Modify the configuration
	for line in config:gmatch("[^\r\n]+") do
		if line:match(".*size: (%d+)") then
			line = line:gsub("size: %d+", "size: " .. font_size)
		end
		table.insert(new_config, line)
	end

	-- Write the modified configuration back to the file
	file = io.open(config_file, "w")
	if not file then
		print("Error opening file " .. config_file)
		return
	end
	for _, line in ipairs(new_config) do
		file:write(line .. "\n")
	end
	file:close()
end

local custom_layout = {
	create_layout = function(picker)
		local function create_window(enter, width, height, row, col, title)
			local bufnr = vim.api.nvim_create_buf(false, true)
			local winid = vim.api.nvim_open_win(bufnr, enter, {
				style = "minimal",
				relative = "editor",
				width = width,
				height = height,
				row = row,
				col = col,
				border = "rounded",
				title = title,
			})

			vim.wo[winid].winhighlight = "Normal:Normal"

			return Layout.Window({
				bufnr = bufnr,
				winid = winid,
			})
		end

		local function destory_window(window)
			if window then
				if vim.api.nvim_win_is_valid(window.winid) then
					vim.api.nvim_win_close(window.winid, true)
				end
				if vim.api.nvim_buf_is_valid(window.bufnr) then
					vim.api.nvim_buf_delete(window.bufnr, { force = true })
				end
			end
		end

		local layout = Layout({
			picker = picker,
			mount = function(self)
				resize_alacritty(18)
				local preview_width = math.floor(180)
				self.results = create_window(false, 38, 20, 0, 0, "Results")
				self.preview = create_window(false, preview_width, 60, 0, 42, "Preview")
				self.prompt = create_window(true, 38, 1, 22, 0, "Prompt")
			end,
			unmount = function(self)
				destory_window(self.results)
				destory_window(self.preview)
				destory_window(self.prompt)
				resize_alacritty(32)
			end,
			update = function(self) end,
		})

		return layout
	end,
}

M.item = {}

local previewer = previewers.new_termopen_previewer({
	get_command = function(entry)
		local function is_image(filepath)
			local image_extensions = { "png", "jpg", "jpeg", "gif" } -- Supported image formats
			local split_path = vim.split(filepath:lower(), ".", { plain = true })
			local extension = split_path[#split_path]
			return vim.tbl_contains(image_extensions, extension)
		end
		if is_image(entry.value) then
			return { "viu", entry.value }
		end
	end,
})

function M.item.list()
	local results = ItemCommand:new():list({
		limit = 999999,
	})
	if not results then
		return
	end

	local function entry_maker(line)
		return {
			value = line, -- This is the value that is passed to telescope
			display = line:match("([^/]+)$"), -- This is the value that is displayed
			ordinal = line:match("([^/]+)$"),
		}
	end

	local function close(bufnr)
		actions.close(bufnr)
	end

	local function enter(bufnr)
		local selection = actions_state.get_selected_entry()
		local source = selection.value
		source = "![image](" .. source .. ")"
		actions.close(bufnr)
		-- put under cursor
		vim.api.nvim_put({ source }, "l", true, true)

		vim.cmd("Glow %")
	end

	pickers
		.new({}, {
			prompt_title = "Eagle Assets",
			finder = finders.new_table({
				results = results,
				entry_maker = entry_maker,
			}),
			sorter = sorters.get_generic_fuzzy_sorter(),
			previewer = previewer,
			create_layout = custom_layout.create_layout,
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = actions_state.get_selected_entry()
					print(vim.inspect(selection))
				end)

				map("i", "<esc>", close)
				map("n", "<esc>", close)

				map("i", "<cr>", enter)
				map("n", "<cr>", enter)

				return true
			end,
		})
		:find()
end

function M.test()
	vim.cmd("lua package.loaded['eagle.pickers'] = nil")
	-- store_screen_size()
	-- resize_alacritty(16)
	M.item.list()
	-- resizeAlacritty(vim.g.alacritty_font_size)
end

return M
