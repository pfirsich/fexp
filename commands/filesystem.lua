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
local clipboard = require("clipboard")

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

local function listDir(path)
    local success, ret, ret2 = pcall(lfs.dir, path)
    if success then
        return nil, ret, ret2
    else
        return ret, nil, nil
    end
end

local function getDirItems(path, recursive)
    path = paths.normpath(path)
    local items = {}
    local err, iter, dirObj = listDir(path)
    if err then
        message.show(("Could not list directory '%s': %s"):format(path, err), true)
        return nil
    end
    for file in iter, dirObj do
        if file ~= "." and file ~= ".." then
            local filePath = paths.join(path, file)
            local item = getDirItem(path, file)
            table.insert(items, item)

            if item.columns.type == "directory" and recursive then
                local subItems = getDirItems(filePath, recursive)
                if subItems then
                    for _, item in ipairs(subItems) do
                        item.caption = escapeNonAscii(paths.join(file, item.caption))
                    end
                    tableExtend(items, subItems)
                end
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
    if tab.items then
        local dotdotPath = paths.normpath(paths.join(path, ".."))
        local dotdotCaption = (".. (%s)"):format(dotdotPath)
        table.insert(tab.items, 1, getDirItem(path, "..", dotdotCaption))
        tab.itemCursor = 1

        -- because the sort is stable items with the same type will still be sorted by name
        commands.sort.sort("name")
        if not recursive then
            commands.sort.sort("type")
        end
    end

    if commands.getFlag("enumeratepath", "recursive") then
        commands.setFlag("enumeratepath", "recursive", false)
    end
end
commands.register("enumeratepath", commands.wrap(filesystem.enumeratePath, {"path", "recursive"}), {"path"})
filesystem.enumeratePathPrompt = promptFunction("Enumerate/Goto Path", "enumeratepath", "path")
filesystem.enumeratePathPromptRec = promptFunction("Enumerate/Goto Path Recursively",
    "enumeratepath", "path", "enumeratepathrecprompt", {recursive = true})

function filesystem.reloadTab(tab)
    if not tab then
        tab = gui.getSelectedTab()
    end
    if tab and tab.path then
        gui.withFocusedTab(tab, function()
            local cursor = tab.itemCursor
            filesystem.enumeratePath(tab.path, false)
            tab.itemCursor = math.max(1, math.min(#tab.items, cursor))
        end)
    end
end
commands.register("reloadtab", commands.wrap(filesystem.reloadTab))
inputcommands.register("Reload Tab", "reloadtab")

local function reloadPane(pane, recursive, allTabs)
    pane = pane or gui.selectedPane
    if pane.tabs then
        if allTabs then
            for _, tab in ipairs(pane.tabs) do
                filesystem.reloadTab(tab)
            end
        else
            filesystem.reloadTab(pane:getSelectedTab())
        end
    elseif recursive then
        reloadPane(pane.children[1], recursive, allTabs)
        reloadPane(pane.children[2], recursive, allTabs)
    end
end

function filesystem.reloadAllTabs()
    reloadPane(gui.rootPane, true, true)
end
commands.register("reloadalltabs", filesystem.reloadAllTabs)
inputcommands.register("Reload All Tabs", "reloadalltabs")

function filesystem.createDirectory(name)
    local tab = gui.getSelectedTab()
    if tab and tab.path then
        local path = paths.join(tab.path, name)
        local success, msg, code = lfs.mkdir(path)
        if not success then
            message.show(("mkdir '%s' failed: %s"):format(path, msg), true)
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
        local selection = gui.getSelection()
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
    local selection = gui.getSelection()
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
    local attr, err, code = lfs.attributes(path)
    if not attr then
        message.show(("Could not get attributes of '%s': %s (%d)"):format(path, err, code))
        return
    end
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
    local selection = gui.getSelection()
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

function filesystem.copySelection()
    local selection = gui.getSelection()
    if selection then
        clipboard.set("copyfiles", functional.map(function(item)
            return item.arguments.path
        end, selection))
    end
end
commands.register("copyselection", filesystem.copySelection)
inputcommands.register("Copy Selection", "copyselection")

function filesystem.cutSelection()
    local selection = gui.getSelection()
    if selection then
        clipboard.set("cutfiles", functional.map(function(item)
            return item.arguments.path
        end, selection))
    end
end
commands.register("cutselection", filesystem.cutSelection)
inputcommands.register("Cut Selection", "cutselection")

-- https://gist.github.com/kaeza/bf76c9742f44905f513db9afb19bdac9
function filesystem.copyFile(fromPath, toPath, blockSize)
    blockSize = blockSize or 64*1024

    local sf, df, err
    local function bail(...)
        if sf then sf:close() end
        if df then df:close() end
        return ...
    end

    sf, err = io.open(fromPath, "rb")
    if not sf then return bail(nil, err) end
    df, err = io.open(toPath, "wb")
    if not df then return bail(nil, err) end

    while true do
        local ok, data
        data = sf:read(blockSize)
        if not data then break end
        ok, err = df:write(data)
        if not ok then return bail(nil, err) end
    end
    return bail(true)
end

function filesystem.copyPath(fromPath, toPath)
    local attr, err, code = lfs.attributes(fromPath)
    if attr then
        if attr.mode == "directory" then
            local err, iter, dirObj = listDir(fromPath)
            if err then
                message.show(("Could not list directory '%s': %s"):format(path, err), true)
            else
                local success, err, code = lfs.mkdir(toPath)
                if not success then
                    message.show(("Could not create directory '%s': %s (%d)"):format(toPath, err, code))
                end
                for file in iter, dirObj do
                    if file ~= "." and file ~= ".." then
                        local filePath = paths.join(fromPath, file)
                        filesystem.copyPath(filePath, paths.join(toPath, file))
                    end
                end
            end
        elseif attr.mode == "file" then
            local success, err = filesystem.copyFile(fromPath, toPath)
            if not success then
                message.show(("Could not copy file '%s' to '%s': %s"):format(fromPath, toPath, err), true)
            end
        else
            message.show(("Don't know how to copy '%s'"):format(attr.mode))
        end
    else
        message.show(("Could not get attributes for file '%s': %s (%d)"):format(fromPath, err, code), true)
    end
end

function filesystem.pasteClipboard()
    local tab = gui.getSelectedTab()
    if tab and tab.path then
        local clipType, clipData = clipboard.get()
        if clipType == "cutfiles" then
            for _, item in ipairs(clipData) do
                local target = paths.join(tab.path, paths.basename(item))
                filesystem._rename(item, target)
            end
            clipboard.set()
            filesystem.reloadAllTabs()
        elseif clipType == "copyfiles" then
            for _, item in ipairs(clipData) do
                local target = paths.join(tab.path, paths.basename(item))
                filesystem.copyPath(item, target)
            end
            clipboard.set()
            filesystem.reloadAllTabs()
        elseif clipType then
            gui.message(("Cannot paste clipboard data of type '%s'"):format(clipType), true)
        end
    end
end
commands.register("pasteclipboard", filesystem.pasteClipboard)
inputcommands.register("Paste Clipboard", "pasteclipboard")

return filesystem
