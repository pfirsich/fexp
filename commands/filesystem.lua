local lfs = require("lfs")

local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")
local gui = require("gui")

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

local function sizeToString(bytes)
    if bytes < 1024 then -- < 1KB
        return ("%d B"):format(bytes)
    elseif bytes < 1024*1024 then -- < 1MB
        return ("%.3f KB"):format(bytes/1024)
    elseif bytes < 1024*1024*1024 then -- < 1 GB
        return ("%.3f MB"):format(bytes/1024/1024)
    elseif bytes < 1024*1024*1024*1024 then -- < 1 TB
        return ("%.3f GB"):format(bytes/1024/1024/1024)
    else
        return ("%.3f TB"):format(bytes/1024/1024/1024/1024)
    end
end

function openFile(path)
    love.system.openURL("file://" .. path)
end
commands.register("openfile", commands.wrap(openFile, {"path"}), {"path"})

function enumeratePath(path)
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
                item.columns.size = sizeToString(attr.size)
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
end
commands.register("enumeratepath", commands.wrap(enumeratePath, {"path"}), {"path"})

function toggleViewItemsInput(text)
    local tab = gui.getSelectedTab()
    if tab then
        local entries = {}
        for i, item in ipairs(tab.items) do
            table.insert(entries, {
                caption = item.caption,
                command = "seekitemcursor",
                arguments = {pos = i},
            })
        end
        input.toggle(entries, text)
    end
end
commands.register("toggleviewitemsinput", commands.wrap(toggleViewItemsInput, {"text"}))

return filesystem
