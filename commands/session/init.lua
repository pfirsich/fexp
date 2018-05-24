local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local promptFunction = require("util.promptFunction")
local message = require("message")
local dumpTable = require("commands.session.dumpTable")
local paths = require("util.paths")

local session = {}

local function getPaneData(pane)
    if pane.tabs then
        local data = {
            tabs = {},
            selectedTabIndex = pane.selectedTabIndex,
        }
        for _, tab in ipairs(pane.tabs) do
            table.insert(data.tabs, {
                title = tab.title,
                path = tab.path,
                showModCol = tab.showModCol,
                showSizeCol = tab.showSizeCol,
            })
        end
        return data
    else
        return {
            splitType = pane.splitType,
            children = {
                getPaneData(pane.children[1]),
                getPaneData(pane.children[2]),
            }
        }
    end
end

function session.saveSession(filename)
    local tab = gui.getSelectedTab()
    if tab and tab.path then
        local data = getPaneData(gui.rootPane)
        local path = paths.join(tab.path, filename)
        local f, err = io.open(path, "w")
        if not f then
            message.show(("Could not open file '%s': %s"):format(path, err), true)
            return
        end
        local ok, err = f:write("return " .. dumpTable(data))
        if not ok then
            message.show(("Error writing data to '%s': %s"):format(path, err), true)
        end
        f:close()
    else
        message.show("Please select a tab with a directory to save to.", true)
    end
end
commands.register("savesession", commands.wrap(session.saveSession, {"filename"}), {"filename"})
session.saveSessionPrompt = promptFunction("Save Session", "savesession", "filename")

local function buildPane(data, parent)
    local pane = gui.Pane(parent)
    if data.children then
        pane:setChildren(data.splitType,
            buildPane(data.children[1], pane),
            buildPane(data.children[2], pane))
    elseif data.tabs then
        for _, dataTab in ipairs(data.tabs) do
            local tab = gui.Tab(pane)
            tab.title = dataTab.title
            tab.path = dataTab.path
            tab.showSizeCol = dataTab.showSizeCol
            tab.showModCol = dataTab.showModCol
        end
        pane:selectTab(data.selectedTabIndex)
    else
        message.show("Malformed session data", true)
        return nil
    end
    return pane
end

function session.loadSession(path)
    if not path then
        local selection = gui.getSelection()
        if selection and #selection == 1 then
            path = selection[1].arguments.path
        else
            message.show("Only one session file can be loaded at a time.", true)
            return
        end
    end

    local f, err = io.open(path, "r")
    if not f then
        message.show(("Could not open file '%s': %s"):format(path, err), true)
        return
    end
    local data, err = f:read("*a")
    f:close()
    if not data then
        message.show(("Error reading data from '%s': %s"):format(path, data))
        return
    end

    if data then
        local f, msg = loadstring(data)
        if f then
            local status, ret = pcall(f)
            if status then
                data = ret
                gui.rootPane = buildPane(data)

                -- select the first pane with tabs we can find
                gui.selectedPane = gui.rootPane
                while not gui.selectedPane.tabs do
                    gui.selectedPane = gui.selectedPane.children[1]
                end

                commands.filesystem.reloadAllTabs()
            else
                message.show("Error reading session data: " .. tostring(ret), true)
            end
        else
            message.show("Error parsing session data: " .. msg, true)
        end
    else
        print("WHAT")
    end
end
commands.register("loadsession", commands.wrap(session.loadSession, {"path"}))
inputcommands.register("Load Session", "loadsession")

return session
