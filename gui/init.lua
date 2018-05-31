local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")
local message = require("message")

local gui = {}

gui.Pane = require("gui.pane")
gui.Tab = require("gui.tab")

function gui.init()
    gui.rootPane = gui.Pane()
    gui.selectedPane = gui.rootPane
end

local function checkDir(dir)
    if dir ~= "left" and dir ~= "right" and dir ~= "up" and dir ~= "down" then
        message.show(("Unknown direction '%s' for splitPane!"):format(dir), true)
        return false
    end
    return true
end

function gui.splitPane(dir, carryTab)
    if dir and not checkDir(dir) then
        return
    end

    local copyPane, newPane = gui.selectedPane:split(dir, carryTab)
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

function gui.movePane(dir, carryTab)
    if not checkDir(dir) then
        return
    end

    local destPane = gui.selectedPane:getRelativePane(dir)
    if destPane then
        if carryTab then
            gui.selectedPane:getSelectedTab():move(destPane)
            destPane:selectTab(#destPane.tabs)
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

function gui.mergePane(dir)
    if not checkDir(dir) then
        return
    end

    local destPane = gui.selectedPane:getRelativePane(dir)
    if destPane then
        local replaceRoot = gui.selectedPane:mergeInto(destPane)
        if replaceRoot then
            gui.rootPane = destPane
        end
        gui.selectedPane = destPane
    end
end
commands.register("mergepane", commands.wrap(gui.mergePane, {"dir"}), {"dir"})
inputcommands.register("Merge Pane Up", "mergepane", {dir = "up"})
inputcommands.register("Merge Pane Down", "mergepane", {dir = "down"})
inputcommands.register("Merge Pane Left", "mergepane", {dir = "left"})
inputcommands.register("Merge Pane Right", "mergepane", {dir = "down"})

function gui.resizePane(amount)
    local pane = gui.selectedPane.parent
    if pane then
        pane.splitRatio = pane.splitRatio + amount
        pane.splitRatio = math.max(0.1, math.min(0.9, pane.splitRatio))
    end
end
commands.register("resizepane", commands.wrap(gui.resizePane, {"amount"}), {"amount"})

function gui.foreachPane(func, pane)
    pane = pane or gui.rootPane
    func(pane)
    if pane.children then
        func(pane.children[1])
        func(pane.children[2])
    end
end

function gui.newTab(pane)
    pane = pane or gui.selectedPane
    local tab = gui.Tab(pane)
    pane.selectedTabIndex = tab.index
end
commands.register("newtab", commands.wrap(gui.newTab, {}))
inputcommands.register("New Tab", "newtab")

function gui.closeTab(tabIndex, pane)
    pane = pane or gui.selectedPane
    tabIndex = tabIndex or pane.selectedTabIndex
    if pane.tabs then
        table.remove(pane.tabs, tabIndex)
        pane:selectTabDelta(0)
    else
        message.show("Cannot close tabs for a pane that doesn't have tabs!", true)
    end
end
commands.register("closetab", commands.wrap(gui.closeTab, {"tabIndex"}))
inputcommands.register("Close Tab", "closetab")

function gui.getSelectedTab()
    return gui.selectedPane.tabs[gui.selectedPane.selectedTabIndex]
end

function gui.selectedTabHasColumns(columns)
    local tab = gui.getSelectedTab()
    return tab and tab.columns == columns
end

function gui.focusTab(tab)
    gui.selectedPane = tab.pane
    tab.pane.selectedTabIndex = tab.index
end

function gui.withFocusedTab(tab, func)
    -- save
    local focusedTab = gui.getSelectedTab()

    -- context
    gui.focusTab(tab)
    func()

    -- restore
    if focusedTab then
        gui.focusTab(focusedTab)
    end
end

function gui.selectTab(tabIndex, pane)
    pane = pane or gui.selectedPane
    pane:selectTab(tabIndex)
end
commands.register("selecttab", commands.wrap(gui.selectTab, {"tabIndex"}), {"tabIndex"})

function gui.nextTab(pane)
    pane = pane or gui.selectedPane
    pane:selectTabDelta(1)
end
commands.register("nexttab", commands.wrap(gui.nextTab))
inputcommands.register("Next Tab", "nexttab")

function gui.prevTab(pane)
    pane = pane or gui.selectedPane
    pane:selectTabDelta(-1)
end
commands.register("prevtab", commands.wrap(gui.prevTab))
inputcommands.register("Previous Tab", "prevtab")

function gui.toggleTabInput(text)
    local pane = gui.selectedPane
    if pane then
        local entries = {}
        for i, tab in ipairs(pane.tabs) do
            local title = tab.title
            if title:len() == 0 then
                title = tab.path and paths.basename(tab.path) or "unnamed tab"
            end
            title = title .. (" (%d)"):format(i)
            table.insert(entries, {
                caption = title,
                command = "selecttab",
                arguments = {tabIndex = i},
            })
        end
        input.toggle(entries, text)
    end
end
commands.register("toggletabinput", commands.wrap(gui.toggleTabInput, {"text"}))
inputcommands.register("Toggle Tab Input", "toggletabinput")

function gui.renameTab(newName, pane)
    pane = gui.selectedPane
    local tab = pane.tabs[pane.selectedTabIndex]
    if tab then
        tab.title = newName
    end
end
commands.register("renametab", commands.wrap(gui.renameTab, {"newName"}), {"newName"})

function gui.renameTabPrompt()
    local tab = gui.getSelectedTab()
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

function gui.toggleColumn(column)
    local tab = gui.getSelectedTab()
    if tab and tab.columns then
        if type(column) == "string" then
            column = tab:getColumnByKey(column)
        end
        if column and tab.columns[column] then
            tab.columns[column].enabled = not tab.columns[column].enabled
        end
    end
end
commands.register("togglecolumn", commands.wrap(gui.toggleColumn, {"column"}), {"column"})

function gui.toggleColumnPrompt(text)
    local tab = gui.getSelectedTab()
    if tab and tab.columns then
        local entries = {}
        for i, column in ipairs(tab.columns) do
            table.insert(entries, {
                caption = column.key,
                command = "togglecolumn",
                arguments = {column = i},
            })
        end
        input.toggle(entries, text)
    end
end
commands.register("togglecolumnprompt", commands.wrap(gui.toggleColumnPrompt, {"text"}))
inputcommands.register("Toggle Column", "togglecolumnprompt")

function gui.moveItemCursor(delta, selectItems)
    local tab = gui.getSelectedTab()
    if tab then
        local setSelect = true --not tab.items[tab.itemCursor].selected
        if selectItems then
            tab.items[tab.itemCursor].selected = setSelect
        end
        tab:moveItemCursor(delta)
        if selectItems then
            tab.items[tab.itemCursor].selected = setSelect
        end
    end
end
commands.register("moveitemcursor", commands.wrap(gui.moveItemCursor, {"delta", "selectItems"}), {"delta"})

function gui.seekItemCursor(pos, selectItems)
    local tab = gui.getSelectedTab()
    if tab then
        if pos < 0 then
            pos = #tab.items + pos + 1
        end
        local startRange = tab.itemCursor
        tab:setItemCursor(pos)
        if selectItems then
            local endRange = tab.itemCursor
            if endRange < startRange then
                startRange, endRange = endRange, startRange
            end
            for i = startRange, endRange do
                tab.items[i].selected = true
            end
        end
    end
end
commands.register("seekitemcursor", commands.wrap(gui.seekItemCursor, {"pos", "selectItems"}), {"pos"})

function gui.gotoItemPrompt(text)
    local tab = gui.getSelectedTab()
    if tab then
        local entries = {}
        for i, item in ipairs(tab.items) do
            table.insert(entries, {
                caption = item.columns[tab.columns.gotoItemColumn],
                command = "seekitemcursor",
                arguments = {pos = i},
            })
        end
        input.toggle(entries, text)
    end
end
commands.register("gotoitemprompt", commands.wrap(gui.gotoItemPrompt, {"text"}))

function gui.toggleItemSelection()
    local tab = gui.getSelectedTab()
    if tab then
        local item = tab:getCursorItem()
        item.selected = not item.selected
    end
end
commands.register("toggleitemselection", gui.toggleItemSelection)

function gui.toggleItemSelectAll()
    local tab = gui.getSelectedTab()
    if tab then
        local selectAll = false
        for _, item in ipairs(tab.items) do
            if not item.dontSelectAll and not item.selected then
                selectAll = true
                break
            end
        end

        for _, item in ipairs(tab.items) do
            if item.dontSelectAll then
                item.selected = false
            else
                item.selected = selectAll
            end
        end
    end
end
commands.register("toggleitemselectall", gui.toggleItemSelectAll)

function gui.getSelectedItems()
    local tab = gui.getSelectedTab()
    return tab and tab:getSelectedItems()
end

function gui.getSelection()
    local tab = gui.getSelectedTab()
    return tab and tab:getSelection()
end

function gui.execItems(newTab, newPane)
    local selection = gui.getSelection()
    if selection then
        if #selection == 1 then
            if newPane then
                gui.splitPane()
                newTab = true
            end

            if newTab then
                gui.newTab()
            end

            commands.exec(selection[1].command, selection[1].arguments)
        else
            for _, item in ipairs(selection) do
                if item.columns.type ~= "file" then
                    return
                end
            end

            for _, item in ipairs(selection) do
                commands.exec(item.command, item.arguments)
            end
        end
    end
end
commands.register("execitems", commands.wrap(gui.execItems, {"newTab", "newPane"}))
inputcommands.register("Execute Selected Items", "execitem")

return gui
