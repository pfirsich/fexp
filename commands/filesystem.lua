local lfs = require("lfs")

local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")
local gui = require("gui")
local sort = require("util.sort")
local paths = require("util.paths")
local promptFunction = require("util.promptFunction")
local message = require("message")
local functional = require("util.functional")

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

local function tableExtend(tbl, with)
    for _, elem in ipairs(with) do
        table.insert(tbl, elem)
    end
end

local function getDirItem(path, file, caption)
    local filePath = paths.join(path, file)
    local attr = lfs.attributes(filePath)

    local item = {
        caption = escapeNonAscii(caption or file),
        columns = {type = "n/a", mod = 0, size = 0},
        arguments = {name = file, path = filePath},
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

    return item
end

local function getDirItems(path, recursive)
    path = paths.normpath(path)
    local items = {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local filePath = paths.join(path, file)
            local item = getDirItem(path, file)
            table.insert(items, item)

            if recursive then
                local subItems = getDirItems(filePath, recursive)
                for _, item in ipairs(subItems) do
                    item.caption = escapeNonAscii(paths.join(file, item.caption))
                end
                tableExtend(items, subItems)
            end
        end
    end
    return items
end

function filesystem.enumeratePath(path, recursive)
    if recursive == nil then
        recursive = commands.getFlag("enumeratepath", "recursive")
    end

    path = paths.normpath(path)
    local tab = gui.getSelectedTab()
    if not tab then
        gui.newTab()
        tab = gui.getSelectedTab()
    end
    tab.path = path
    tab.items = getDirItems(path, recursive)
    local dotdotPath = paths.normpath(paths.join(path, ".."))
    local dotdotCaption = (".. (%s)"):format(dotdotPath)
    table.insert(tab.items, 1, getDirItem(path, "..", dotdotCaption))
    tab.itemCursor = 1

    -- because the sort is stable items with the same type will still be sorted by name
    commands.sort.sort("name")
    if not recursive then
        commands.sort.sort("type")
    end

    if commands.getFlag("enumeratepath", "recursive") then
        commands.setFlag("enumeratepath", "recursive", false)
    end
end
commands.register("enumeratepath", commands.wrap(filesystem.enumeratePath, {"path", "recursive"}), {"path"})
filesystem.enumeratePathPrompt = promptFunction("Enumerate/Goto Path", "enumeratepath", "path")
filesystem.enumeratePathPromptRec = promptFunction("Enumerate/Goto Path Recursively",
    "enumeratepath", "path", "enumeratepathrecprompt", {recursive = true})

function filesystem.reloadTab()
    local tab = gui.getSelectedTab()
    if tab then
        local cursor = tab.itemCursor
        filesystem.enumeratePath(tab.path)
        tab.itemCursor = math.max(1, math.min(#tab.items, cursor))
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
            message.show(("mkdir '%s' failed: %s (%d)"):format(path, msg, code), true)
        end
        filesystem.reloadTab()
    end
end
commands.register("createdirectory", commands.wrap(filesystem.createDirectory, {"name"}), {"name"})
filesystem.createDirectoryPrompt = promptFunction("Create Directory (mkdir)", "createdirectory", "name")

function filesystem._rename(oldPath, newPath)
    local success, msg, code = os.rename(oldPath, newPath)
    if not success then
        message.show(("Renaming of '%s' to '%s' failed: %s (%d)"):format(oldPath, newPath, msg, code), true)
    end
end

function filesystem.renameSelection(name)
    local tab = gui.getSelectedTab()
    if name:len() > 0 and tab and tab.path then
        local selection = gui.getItemSelection()
        if selection then
            if #selection > 1 then
                message.show("Can't rename more than a single item.", true)
            else
                filesystem._rename(
                    paths.join(tab.path, selection[1].arguments.name),
                    paths.join(tab.path, name))
                filesystem.reloadTab()
            end
        end
    end
end
commands.register("renameselection", commands.wrap(filesystem.renameSelection, {"name"}), {"name"})

function filesystem.renameSelectionPrompt(text)
    local selection = gui.getItemSelection()
    if selection and #selection == 1 then
        if text == nil or text:len() == 0 then
            text = selection[1].arguments.name
        end

        input.toggle({{
            caption = "> Rename Selection",
            command = "renameselection",
            arguments = {},
        }}, text, "name")
    else
        message.show("Exactly one item must be selected to rename.", true)
    end
end
commands.register("renameselectionprompt", commands.wrap(filesystem.renameSelectionPrompt, {"text"}))
inputcommands.register("Rename Selection", "renameselectionprompt")

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
            message.show(("'%s' is not empty!"):format(path), true)
        else
            if recursive then
                for _, item in ipairs(dirItems) do
                    filesystem.remove(paths.join(path, item), true)
                end
            end

            local success, msg, code = lfs.rmdir(path)
            if not success then
                message.show(("Removal of '%s' failed: %s (%d)"):format(path, msg, code), true)
            end
        end
    else
        local success, msg, code = os.remove(path)
        if not success then
            message.show(("Removal of '%s' failed: %d (%d)"):format(path, msg, code), true)
        end
    end
end

function filesystem.deleteSelection(recursive)
    local selection = gui.getItemSelection()
    if selection then
        for _, item in ipairs(selection) do
            filesystem.remove(item.arguments.path, recursive)
        end
        filesystem.reloadTab()
    end
end
commands.register("deleteselection", commands.wrap(filesystem.deleteSelection, {"recursive"}))
inputcommands.register("Delete Selection", "deleteselection")
inputcommands.register("Delete Selection Recursively", "deleteselection", {recursive = true})

function filesystem._touchFile(path)
    local success, msg = lfs.touch(path)
    if not success then
        -- can I check this more accurately?
        if msg == "No such file or directory" then
            local f, msg = io.open(path, "w")
            if f then
                f:close()
            else
                message.show(("Cannot create file '%s': %s"):format(path, msg), true)
            end
        else
            message.show(("Touch failed for '%s': %s"):format(path, msg), true)
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
