local class = require("util.class")

local Tab = class("Tab")

function Tab:initialize(pane)
    table.insert(pane.tabs, self)
    self.pane = pane
    self.index = #pane.tabs

    self.title = ""
    self.path = nil
    self.items = {}
    self.itemCursor = 0
    self.showModCol = true
    self.showSizeCol = true
end

function Tab:str()
    return ("tab %s '%s': %s, %d @ %s"):format(tostring(self), self.title, self.path,
        self.index, self.pane:str())
end

-- this modifies mostly pane state, so I am not a fan of it being a Tab member function
function Tab:move(destPane)
    table.remove(self.pane.tabs, self.index)
    for i, tab in ipairs(self.pane.tabs) do
        tab.index = i
    end
    self.pane:selectTabDelta(0)

    table.insert(destPane.tabs, self)
    self.pane = destPane
    self.index = #destPane.tabs
end

-- these only modify tab state

function Tab:setItemCursor(cursor)
    self.itemCursor = math.min(#self.items, math.max(1, cursor))
end

function Tab:moveItemCursor(delta)
    self:setItemCursor(self.itemCursor + delta)
end

function Tab:selectAll(selected)
    for _, item in ipairs(self.items) do
        item.selected = selected
    end
end

function Tab:getSelectedItems()
    local ret = {}
    for _, item in ipairs(self.items) do
        if item.selected then
            table.insert(ret, item)
        end
    end
    return ret
end

-- if the item currently at the cursor is not selected, unselect everything, select the item
-- at the cursor and then return all selected items
function Tab:getSelection()
    if #self.items == 0 then
        return {}
    end
    if not self.items[self.itemCursor].selected then
        self:selectAll(false)
        self.items[self.itemCursor].selected = true
    end
    return self:getSelectedItems()
end

function Tab:getCursorItem()
    return self.items[self.itemCursor]
end

return Tab
