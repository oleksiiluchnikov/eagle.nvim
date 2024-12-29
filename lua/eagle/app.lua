local M = {}
local job = require("plenary.job")

---Get the version of the Eagle
function M.version()
  local stdout = {}
  job:new({
    command = "eagle",
    args = { "app", "--version" },
    on_stdout = function(_, data)
      table.insert(stdout, data)
    end,
    on_stderr = function(_, data)
      print("Error: ", data)
    end,
    on_exit = function(_, data)
      if data ~= 0 then
        print("Error: ", data)
      end
    end,
  }):sync()
  return stdout[1]
end

return M
