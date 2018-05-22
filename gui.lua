local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")

local gui = {}

gui.rootPane = {}
gui.selectedPane = {}

function gui.init()
    gui.rootPane = {
        parent = nil,
        splitType = nil,
        children = nil,
        selectedTabIndex = 0,
        tabs = {},
    }
    gui.selectedPane = gui.rootPane
end

local function moveTab(fromPane, toPane, tabIndex)
    table.insert(toPane.tabs, fromPane.tabs[tabIndex])
    toPane.selectedTabIndex = #toPane.tabs

    table.remove(fromPane.tabs, tabIndex)
    fromPane.selectedTabIndex = math.max(1, math.min(#fromPane.tabs, tabIndex))
end

local function checkDir(dir)
    if dir ~= "left" and dir ~= "right" and dir ~= "up" and dir ~= "down" then
        print(("Unknown direction '%s' for splitPane!"):format(dir))
        return false
    end
    return true
end

function gui.splitPane(dir, carryTab)
    if not checkDir(dir) then
        return
    end

    local copyPane = { -- the old selected pane, copied and made a child of the selected pane
        parent = gui.selectedPane,
        tabs = gui.selectedPane.tabs,
        selectedTabIndex = gui.selectedPane.selectedTabIndex,
    }
    local newPane = { -- a new empty pane
        parent = gui.selectedPane,
        tabs = {},
        selectedTabIndex = 1,
    }

    if carryTab then
        moveTab(copyPane, newPane, copyPane.selectedTabIndex)
    end

    if dir == "left" then
        gui.selectedPane.children = {newPane, copyPane}
        gui.selectedPane.splitType = "h"
    elseif dir == "right" then
        gui.selectedPane.children = {copyPane, newPane}
        gui.selectedPane.splitType = "h"
    elseif dir == "up" then
        gui.selectedPane.children = {newPane, copyPane}
        gui.selectedPane.splitType = "v"
    elseif dir == "down" then
        gui.selectedPane.children = {copyPane, newPane}
        gui.selectedPane.splitType = "v"
    end

    -- the real old pane doesn't have tabs anymore, just children
    gui.selectedPane.tabs = nil
    gui.selectedPane = newPane
end

commands.register("splitpane", commands.wrap(gui.splitPane, {"dir", "carryTab"}),
    {"dir"}, {carryTab = false})

inputcommands.register("Split Pane Up", "splitpane", {dir = "up"})
inputcommands.register("Split Pane Down", "splitpane", {dir = "down"})
inputcommands.register("Split Pane Left", "splitpane", {dir = "left"})
inputcommands.register("Split Pane Right", "splitpane", {dir = "right"})
inputcommands.register("Split Pane Up (Carry Tab)", "splitpane", {dir = "up", carryTab = true})
inputcommands.register("Split Pane Down (Carry Tab)", "splitpane", {dir = "down", carryTab = true})
inputcommands.register("Split Pane Left (Carry Tab)", "splitpane", {dir = "left", carryTab = true})
inputcommands.register("Split Pane Right (Carry Tab)", "splitpane", {dir = "right", carryTab = true})

local function getRelativePane(pane, dir, secondaryCall)
    local parent = pane.parent
    if parent == nil then
        return nil
    end

    if dir == "left" and parent.splitType == "h" and parent.children[2] == pane then
        pane = parent.children[1]
    elseif dir == "right" and parent.splitType == "h" and parent.children[1] == pane then
        pane = parent.children[2]
    elseif dir == "up" and parent.splitType == "v" and parent.children[2] == pane then
        pane = parent.children[1]
    elseif dir == "down" and parent.splitType == "v" and parent.children[1] == pane then
        pane = parent.children[2]
    else
        pane = getRelativePane(parent, dir, true)
    end

    -- only do this for the tail call, just before returning to the "outside" function
    -- that called getRelativePane
    if pane and not secondaryCall then
        if pane.tabs == nil then -- pick an actual pane with tabs (a child)
            -- we pick depending on where we came from
            if pane.splitType == "h" then
                if dir == "left" then -- coming from the right
                    pane = pane.children[2]
                else -- if coming from the left or from top/bottom (no correct choice possible)
                    pane = pane.children[1]
                end
            else
                if dir == "up" then -- coming from the bottom
                    pane = pane.children[2]
                else -- if coming from the top or from left/right (no correct choice possible)
                    pane = pane.children[1]
                end
            end
        end
    end

    return pane
end

function gui.movePane(dir, carryTab)
    if not checkDir(dir) then
        return
    end

    local destPane = getRelativePane(gui.selectedPane, dir)
    if destPane then
        if carryTab then
            moveTab(gui.selectedPane, destPane, gui.selectedPane.selectedTabIndex)
        end

        gui.selectedPane = destPane
    end
end
commands.register("movepane", commands.wrap(gui.movePane, {"dir", "carryTab"}),
    {"dir"}, {carryTab = false})

inputcommands.register("Move Pane Up", "movepane", {dir = "up"})
inputcommands.register("Move Pane Down", "movepane", {dir = "down"})
inputcommands.register("Move Pane Left", "movepane", {dir = "left"})
inputcommands.register("Move Pane Right", "movepane", {dir = "right"})
inputcommands.register("Move Pane Up (Carry Tab)", "movepane", {dir = "up", carryTab = true})
inputcommands.register("Move Pane Down (Carry Tab)", "movepane", {dir = "down", carryTab = true})
inputcommands.register("Move Pane Left (Carry Tab)", "movepane", {dir = "left", carryTab = true})
inputcommands.register("Move Pane Right (Carry Tab)", "movepane", {dir = "right", carryTab = true})

local function removePane(pane)
    local parent = pane.parent
    if parent then
        local sibling = nil
        if parent.children[2] == pane then
            sibling = parent.children[1]
        else
            sibling = parent.children[2]
        end

        parent.tabs = sibling.tabs
        parent.selectedTabIndex = sibling.selectedTabIndex
    else
        print("Cannot remove root pane!")
    end
end

local function mergePaneInto(pane, destPane)
    destPane.selectedTabIndex = pane.selectedTabIndex + #destPane.tabs
    for _, tab in ipairs(pane.tabs) do
        table.insert(destPane.tabs, tab)
    end
    removePane(pane)
end

function gui.mergePane(dir)
    if not checkDir(dir) then
        return
    end

    local destPane = getRelativePane(gui.selectedPane, dir)
    if destPane then
        mergePaneInto(gui.selectedPane, destPane)
        gui.selectedPane = destPane
    end
end
commands.register("mergepane", commands.wrap(gui.mergePane, {"dir"}), {"dir"})

inputcommands.register("Merge Pane Up", "mergepane", {dir = "up"})
inputcommands.register("Merge Pane Down", "mergepane", {dir = "down"})
inputcommands.register("Merge Pane Left", "mergepane", {dir = "left"})
inputcommands.register("Merge Pane Right", "mergepane", {dir = "down"})

function gui.getSelectedTab()
    return gui.selectedPane.tabs[gui.selectedPane.selectedTabIndex]
end

function gui.newTab()
    local pane = pane or gui.selectedPane
    local tab = {
        title = tostring(love.math.random(10000, 100000)),
        path = "...",
        items = {},
    }
    table.insert(pane.tabs, tab)
    pane.selectedTabIndex = #pane.tabs
end
commands.register("newtab", gui.newTab)

inputcommands.register("New Tab", "newtab")

function gui.closeTab(tabIndex)
    local pane = pane or gui.selectedPane
    tabIndex = tabIndex or pane.selectedTabIndex
    if pane.tabs then
        table.remove(pane.tabs, tabIndex)
        if pane.selectedTabIndex > #pane.tabs then
            pane.selectedTabIndex = #pane.tabs
        end
    else
        print("Cannot close tabs for a pane that doesn't have tabs!")
    end
end
commands.register("closetab", commands.wrap(gui.closeTab, {"tabIndex"}))

inputcommands.register("Close Tab", "closetab")

function gui.selectTab(tabIndex, pane)
    pane = pane or gui.selectedPane
    pane.selectedTabIndex = math.max(1, math.min(#pane.tabs, tabIndex))
end
commands.register("selecttab", commands.wrap(gui.selectTab, {"tabIndex", "paneIndex"}), {"tabIndex"})

function gui.nextTab()
    local pane = pane or gui.selectedPane
    pane.selectedTabIndex = pane.selectedTabIndex + 1
    if pane.selectedTabIndex > #pane.tabs then
        pane.selectedTabIndex = #pane.tabs
    end
end
commands.register("nexttab", gui.nextTab)

inputcommands.register("Next Tab", "nexttab")

function gui.prevTab()
    local pane = pane or gui.selectedPane
    pane.selectedTabIndex = pane.selectedTabIndex - 1
    if pane.selectedTabIndex < 1 then
        pane.selectedTabIndex = 1
    end
end
commands.register("prevtab", gui.prevTab)

inputcommands.register("Previous Tab", "prevtab")

function gui.renameTab(newName)
    local pane = gui.selectedPane
    local tab = pane.tabs[pane.selectedTabIndex]
    if tab then
        tab.title = newName
    end
end
commands.register("renametab", commands.wrap(gui.renameTab, {"newName"}), {"newName"})

function gui.renameTabPrompt()
    local pane = gui.selectedPane
    local tab = pane.tabs[pane.selectedTabIndex]
    if tab then
        input.toggle({{
            caption = "Rename Tab",
            command = "renametab",
            arguments = {},
        }}, tab.title, "newName")
    end
end
commands.register("renametabprompt", gui.renameTabPrompt)

inputcommands.register("Rename Tab", "renametabprompt")

return gui
