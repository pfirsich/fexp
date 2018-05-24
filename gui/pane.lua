local class = require("util.class")

local Pane = class("Pane")

function Pane:initialize(parent)
    self.parent = parent
    self.splitType = nil
    self.children = nil
    self.splitRatio = 0.5
    self.selectedTabIndex = 0
    self.tabs = {}
end

function Pane:str()
    if self.children then
        return ("pane %s '%s': split %s: %s, %s"):format(tostring(self),
            self:getPath(), self.splitType, self.children[1]:getPath(),
            self.children[2]:getPath())
    else
        return ("pane %s '%s': %d tabs, %d selected"):format(tostring(self),
            self:getPath(), #self.tabs, self.selectedTabIndex)
    end
end

function Pane:getPath()
    if self.parent then
        if self.parent.splitType == "h" then
            if self.parent.children[1] == self then
                return self.parent:getPath() .. "l"
            else
                return self.parent:getPath() .. "r"
            end
        else
            if self.parent.children[1] == self then
                return self.parent:getPath() .. "u"
            else
                return self.parent:getPath() .. "d"
            end
        end
    else
        return "/"
    end
end

local function strmul(s, n)
    local ret = ""
    for i = 1, n do
        ret = ret .. s
    end
    return ret
end

function Pane:printGraph(depth)
    depth = depth or 0
    print(strmul("    ", depth) .. self:getPath(), self, self.splitType)
    if self.children then
        printPaneGraph(self.children[1], depth + 1)
        printPaneGraph(self.children[2], depth + 1)
    end
end

function Pane:setTabs(tabs, selectedTabIndex)
    self.tabs = tabs
    self.selectedTabIndex = selectedTabIndex or 1
    self.children = nil
    self.splitType = nil

    for _, tab in ipairs(self.tabs) do
        tab.pane = self
    end
end

function Pane:setChildren(splitType, first, second)
    assert(splitType == "h" or splitType == "v")
    self.splitType = splitType
    self.children = {first, second}
    self.tabs = nil
end

function Pane:getSelectedTab()
    return self.tabs and self.tabs[self.selectedTabIndex]
end

function Pane:split(dir, carryTab)
    if dir then
        assert(dir == "left" or dir == "right" or dir == "up" or dir == "down")
    else
        -- pick dir automatically
        local parent = self.parent
        if parent == nil then
            dir = "right"
        else
            local dirMap = {v = "right", h = "down"}
            dir = dirMap[parent.splitType]
        end
    end

    -- the old selected pane, copied and made a child of the selected pane
    local copyPane = Pane(self)
    copyPane:setTabs(self.tabs, self.selectedTabIndex)
    -- an empty pane
    local newPane = Pane(self)

    if carryTab then
        copyPane:getSelectedTab():move(newPane)
        newPane:selectTab(#newPane.tabs)
    end

    if dir == "left" then
        self:setChildren("h", newPane, copyPane)
    elseif dir == "right" then
        self:setChildren("h", copyPane, newPane)
    elseif dir == "up" then
        self:setChildren("v", newPane, copyPane)
    elseif dir == "down" then
        self:setChildren("v", copyPane, newPane)
    end

    return copyPane, newPane
end

function Pane:getRelativePane(dir, secondaryCall)
    local parent = self.parent
    if parent == nil then
        return nil
    end

    local pane
    if dir == "left" and parent.splitType == "h" and parent.children[2] == self then
        pane = parent.children[1]
    elseif dir == "right" and parent.splitType == "h" and parent.children[1] == self then
        pane = parent.children[2]
    elseif dir == "up" and parent.splitType == "v" and parent.children[2] == self then
        pane = parent.children[1]
    elseif dir == "down" and parent.splitType == "v" and parent.children[1] == self then
        pane = parent.children[2]
    else
        pane = parent:getRelativePane(dir, true)
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

-- this function replaces the pane's parent with it's sibling
-- if the pane's parent is the root pane, the root pane needs to be replaced and true is returned
function Pane:unparent()
    local parent = self.parent
    if parent then
        local sibling = nil
        if parent.children[2] == self then
            sibling = parent.children[1]
        else
            sibling = parent.children[2]
        end

        -- replace parent with sibling
        if parent.parent then
            if parent.parent.children[1] == parent then
                parent.parent.children[1] = sibling
            else
                parent.parent.children[2] = sibling
            end
            sibling.parent = parent.parent
        else
            sibling.parent = nil
            return true
        end
    else
        message.show("Cannot remove root pane!", true)
    end
    return
end

function Pane:mergeInto(destPane)
    destPane.selectedTabIndex = self.selectedTabIndex + #destPane.tabs
    while #self.tabs > 0 do
        self.tabs[1]:move(destPane)
    end
    return self:unparent()
end

function Pane:selectTab(tabIndex)
    self.selectedTabIndex = math.min(#self.tabs, math.max(1, tabIndex))
end

function Pane:selectTabDelta(delta)
    self:selectTab(self.selectedTabIndex + delta)
end

function Pane:getSelectedTab()
    return self.tabs[self.selectedTabIndex]
end

function Pane:getTabIndex(tab)
    for i, _tab in ipairs(self.tabs) do
        if _tab == tab then
            return i
        end
    end
    return nil
end

return Pane
