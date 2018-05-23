local lfs = require("lfs")

local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")
local gui = require("gui")
local sort = require("sort")
local paths = require("paths")
local promptFunction = require("promptFunction")

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
    path = paths.normpath(path)
    local tab = gui.getSelectedTab()
    if not tab then
        gui.newTab()
        tab = gui.getSelectedTab()
    end
    tab.path = path
    tab.items = {}
    for file in lfs.dir(path) do
        if file ~= "." then
            local filePath = paths.join(path, file)
            local attr = lfs.attributes(filePath)

            local item = {
                caption = escapeNonAscii(file),
                columns = {type = "n/a", mod = 0, size = 0},
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
filesystem.enumeratePathPrompt = promptFunction("Enumerate/Goto Path", "enumeratepath", "path")

function filesystem.reloadTab()
    local tab = gui.getSelectedTab()
    if tab then
        filesystem.enumeratePath(tab.path)
    end
end
commands.register("reloadtab", filesystem.reloadTab)
inputcommands.register("Reload Tab", "reloadtab")

function filesystem.createDirectory(name)
    local tab = gui.getSelectedTab()
    if tab and tab.path then
        local path = paths.join(tab.path, name)
        local success, msg, code = lfs.mkdir(path)
        if not success then
            print(("mkdir '%s' failed:"):format(path), msg, code)
        end
        filesystem.reloadTab()
    end
end
commands.register("createdirectory", commands.wrap(filesystem.createDirectory, {"name"}), {"name"})
filesystem.createDirectoryPrompt = promptFunction("Create Directory (mkdir)", "createdirectory", "name")

function filesystem.renameFile(oldPath, newPath)
    local success, msg, code = os.rename(oldPath, newPath)
    if not success then
        print(("Renaming of '%s' to '%s' failed:"):format(oldPath, newPath), msg, code)
    end
end

function filesystem.dirItems(path)
    local items = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            table.insert(items, file)
        end
    end
    return items
end

function filesystem.remove(path, recursive)
    local attr = lfs.attributes(path)
    if attr.mode == "directory" then
        local dirItems = filesystem.dirItems(path)

        if #dirItems > 0 and not recursive then
            print(("'%s' is not empty!"):format(path))
        else
            if recursive then
                for _, item in ipairs(dirItems) do
                    filesystem.remove(paths.join(path, item), true)
                end
            end

            local success, msg, code = lfs.rmdir(path)
            if not success then
                print(("Removal of '%s' failed:"):format(path), msg, code)
            end
        end
    else
        local success, msg, code = os.remove(path)
        if not success then
            print(("Removal of '%s' failed:"):format(path), msg, code)
        end
    end
end

function filesystem.deleteSelection(recursive)
    local selection = gui.getItemSelection()
    if selection then
        for _, item in ipairs(selection) do
            filesystem.remove(item.arguments.path, recursive)
        end
    end
    filesystem.reloadTab()
end
commands.register("deleteselection", commands.wrap(filesystem.deleteSelection, {"recursive"}))
inputcommands.register("Delete Selection", "deleteselection")
inputcommands.register("Delete Selection Recursively", "deleteselection", {recursive = true})

function filesystem._touchFile(path)
    local success, msg, code = lfs.touch(path)
    if not success then
        -- can I check this more accurately?
        if msg == "No such file or directory" then
            local f, msg = io.open(path, "w")
            if f then
                print("Close. done")
                f:close()
            else
                print(("Cannot create file '%s':"):format(path), msg)
            end
        else
            print(("Touch failed for '%s':"):format(path), msg, code)
        end
    end
end

function filesystem.touchFile(name)
    local tab = gui.getSelectedTab()
    if tab and tab.path then
        filesystem._touchFile(paths.join(tab.path, name))
        filesystem.reloadTab()
    end
end
commands.register("touchfile", commands.wrap(filesystem.touchFile, {"name"}), {"name"})
filesystem.touchPrompt = promptFunction("Touch File", "touchfile", "name")

return filesystem
