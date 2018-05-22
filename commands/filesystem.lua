local lfs = require("lfs")

local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")
local gui = require("gui")
local sort = require("sort")

local filesystem = {}

local function escapeNonAscii(str)
    if type(str) ~= "string" then
        return str
    end
    local ret = ""
    for i = 1, str:len() do
        if str:byte(i) > 127 then
            ret = ret .. "?"
        else
            ret = ret .. str:sub(i, i)
        end
    end
    return ret
end

function filesystem.openFile(path)
    love.system.openURL("file://" .. path)
end
commands.register("openfile", commands.wrap(filesystem.openFile, {"path"}), {"path"})

function filesystem.enumeratePath(path)
    local tab = gui.getSelectedTab()
    if not tab then
        gui.newTab()
        tab = gui.getSelectedTab()
    end
    tab.path = path
    tab.items = {}
    for file in lfs.dir(path) do
        if file ~= "." then
            local filePath = path .. "/" .. file
            local attr = lfs.attributes(filePath)

            local item = {
                caption = escapeNonAscii(file),
                columns = {type = "n/a", mod = "n/a", size = "n/a"},
                arguments = {path = filePath},
            }

            if attr then
                item.columns.type = attr.mode
                item.columns.mod = attr.modification
                item.columns.size = attr.size
            end

            if item.columns.type == "file" then
                item.command = "openfile"
            elseif item.columns.type == "directory" then
                item.command = "enumeratepath"
            else
                item.command = "nop"
            end

            table.insert(tab.items, item)
        end
    end
    tab.itemCursor = 1

    -- because the sort is stable items with the same type will still be sorted by name
    commands.sort.sort("name")
    commands.sort.sort("type")
end
commands.register("enumeratepath", commands.wrap(filesystem.enumeratePath, {"path"}), {"path"})

return filesystem
