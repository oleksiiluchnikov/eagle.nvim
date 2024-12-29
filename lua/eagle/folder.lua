local M = {}
local job = require("plenary.job")

---@class Folder
---@field id FolderID
---@field name string


function M.list()
  local folders = {}

  local cmd = "eagle folder list"
  local result = vim.fn.system(cmd)

  result = vim.split(result, "\n")

  for _, line in ipairs(result) do
    local folder = vim.split(line, "\n")
    if #folder > 1 then
      table.insert(folders, {
        id = folder[1],
        name = folder[2],
      })
    end
  end

  return folders
end

return M
