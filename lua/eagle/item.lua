local job = require('plenary.job')

---@class ItemCommandArgs
---@field limit number
---@field offset number
---@field order Order
---@field keyword string
---@field ext string
---@field tags string[]
---@field folders string[]
local ItemCommandArgs = {}

function ItemCommandArgs:new(args)
    args = args or {}
    local o = {
        limit = args.limit or 10,
        offset = args.offset,
        order = args.order,
        keyword = args.keyword,
        ext = args.ext,
        tags = args.tags,
        folders = args.folders,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function ItemCommandArgs:to_args_tbl(args)
    args = args or {}
    if self.limit then
        table.insert(args, '--limit')
        table.insert(args, self.limit)
    end
    if self.offset then
        table.insert(args, '--offset')
        table.insert(args, self.offset)
    end
    if self.order then
        table.insert(args, '--order')
        table.insert(args, self.order)
    end
    if self.keyword then
        table.insert(args, '--keyword')
        table.insert(args, self.keyword)
    end
    if self.ext then
        table.insert(args, '--ext')
        table.insert(args, self.ext)
    end
    if self.tags then
        table.insert(args, '--tags')
        table.insert(args, table.concat(self.tags, ','))
    end
    if self.folders then
        table.insert(args, '--folders')
        table.insert(args, table.concat(self.folders, ','))
    end
    return args
end

---@enum Order

---@class ItemCommand
---@field command string
---@field args ItemCommandArgs
---@field list fun(args: ItemCommandArgs): ItemCommand
---@field exec fun(args: ItemCommandArgs): table
local ItemCommand = {}

---@class ItemCommand
---@param args? ItemCommandArgs
function ItemCommand:new(args)
    args = args or ItemCommandArgs:new()
    local o = {
      command = 'eagle',
      args = {'item'},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end


---@return table
function ItemCommand:exec()
    local stdout = {}
    job:new({
        command = self.command,
        args = self.args,
        on_stdout = function(_, data)
            table.insert(stdout, data)
        end,
        on_exit = function(_, code)
            if code ~= 0 then
                vim.notify(vim.inspect.inspect(stdout), vim.log.levels.ERROR)
            end
        end,
    }):sync()
    return stdout
end

---List items
---@param args? ItemCommandArgs
---@return table
function ItemCommand:list(args)
    args = ItemCommandArgs:new(args)
    self.args[2] = 'list'
    self.args = args:to_args_tbl(self.args)
    return self:exec()
end

function ItemCommand.test()
    vim.cmd('lua package.loaded["eagle.item"] = nil')
    local cmd = ItemCommand:new()
    cmd:list(ItemCommandArgs:new({
      limit = 10,
      keyword = 'test',
      tags = {'LEGO', 'Asset'},
    }))
end

return ItemCommand
