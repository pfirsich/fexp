local gui = require("gui")
local input = require("input")
local functional = require("functional")

local lg = love.graphics
local floor = math.floor

local drawgui = {}

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

function drawTabItems(tab, x, y, w, h)
    local font = lg.getFont()
    local fontHeight = font:getHeight()
    local lineHeight = fontHeight * 1.25

    tab._scrollOffset = tab._scrollOffset or 0

    local elemY = y + tab._scrollOffset
    if elemY > 0 then
        tab._scrollOffset = 0
        elemY = y + tab._scrollOffset
    end

    local cursorOffset = tab._scrollOffset + lineHeight * (tab.itemCursor - 1)
    if cursorOffset < 0 then
        tab._scrollOffset = tab._scrollOffset - cursorOffset
    elseif cursorOffset > h - lineHeight then
        tab._scrollOffset = tab._scrollOffset - (cursorOffset - (h - lineHeight))
    end
    elemY = y + tab._scrollOffset

    lg.setScissor(x, y, w, h)
    lg.setColor(1, 1, 1)
    for i, item in ipairs(tab.items) do
        if item.selected then
            lg.setColor(0.2, 0.2, 1.0)
            lg.rectangle("fill", x, elemY, w, lineHeight)
        end
        if tab.itemCursor == i then
            lg.setColor(1, 1, 1, 0.4)
            lg.rectangle("fill", x, elemY, w, lineHeight)
        end
        lg.setColor(1, 1, 1)
        lg.print(escapeNonAscii(item.caption), floor(x + 5), floor(elemY + lineHeight/2 - fontHeight/2))
        elemY = elemY + lineHeight
    end
    lg.setScissor()
end

function textRegion(text, x, y, w, h, padding, offsetX)
    padding = padding or 5
    offsetX = offsetX or 0
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    lg.setScissor(x + padding, y + padding, w - padding*2, h - padding*2)
    local tx, ty = x + padding + offsetX, floor(y + h/2 - lg.getFont():getHeight() / 2)
    if type(text) == "string" then
        lg.print(escapeNonAscii(text), tx, ty)
    elseif type(text) == "table" then
        lg.printf(functional.map(escapeNonAscii, text), tx, ty, 10000)
    end
    lg.setScissor()
end

function drawPane(pane, x, y, w, h)
    local font = lg.getFont()

    if pane.tabs then
        local paneSelected = pane == gui.selectedPane
        if paneSelected then
            lg.setColor(0, 0, 1.0)
        else
            lg.setColor(1.0, 1.0, 1.0)
        end
        lg.rectangle("line", x, y, w, h)

        local numTabs = #pane.tabs
        local tabWidth = w / numTabs
        local tabHeight = 25
        for i, tab in ipairs(pane.tabs) do
            local tabSelected = i == pane.selectedTabIndex
            if tabSelected then
                if paneSelected then
                    lg.setColor(0, 0, 0.8)
                else
                    lg.setColor(0, 0, 0.5)
                end
            else
                lg.setColor(0.1, 0.1, 0.1)
            end
            local tabX = x + (i - 1) * tabWidth
            lg.rectangle("fill", tabX, y, tabWidth, tabHeight)
            lg.setColor(0.4, 0.4, 0.4)
            lg.rectangle("line", tabX, y, tabWidth, tabHeight)
            lg.setColor(1, 1, 1)
            textRegion(tab.title, tabX, y, tabWidth, tabHeight)

            if tabSelected then
                lg.setColor(1, 1, 1)
                local pathLineY = y + tabHeight
                local pathLineH = 25
                lg.rectangle("fill", x, pathLineY, w, pathLineH)
                lg.setColor(0.5, 0.5, 0.5)
                lg.rectangle("line", x, pathLineY, w, pathLineH)
                lg.setColor(0, 0, 0)
                textRegion(tab.path, x, pathLineY, w, pathLineH)

                local itemsY = pathLineY + pathLineH
                drawTabItems(tab, x, itemsY, w, h - (itemsY - y))
            end
        end

        if numTabs == 0 then
            lg.setColor(1, 1, 1)
            local text = "No open tabs."
            local tx, ty = x + w/2 - font:getWidth(text)/2, y + h/2 - font:getHeight()/2
            lg.print("No open tabs.", math.floor(tx), math.floor(ty))
        end

        if paneSelected and input.isActive() then
            local numEntries = math.min(10, input.numVisible)
            local inputW = 0.8 * w
            local inputY = y + 70
            local lineHeight = 30
            local inputH = (numEntries + 1) * lineHeight
            local inputX = x + w/2 - inputW/2
            lg.setColor(0.3, 0.3, 0.3)
            lg.rectangle("fill", inputX, inputY, inputW, inputH)
            lg.setColor(1, 1, 1)
            textRegion(input.text, inputX, inputY, inputW, lineHeight)
            local entryY = inputY + lineHeight
            lg.line(inputX, entryY, inputX + inputW, entryY)

            local entriesDrawn = 0
            for i = 1, #input.entries do
                local entry = input.entries[i]

                if entry.visible then
                    if input.selectedEntry == i then
                        lg.setColor(0.4, 0.4, 0.4)
                        lg.rectangle("fill", inputX, entryY, inputW, lineHeight)
                    end

                    if entry.annotation then
                        local annotOffset = inputW - font:getWidth(entry.annotation) - 10
                        lg.setColor(0.7, 0.7, 0.7)
                        textRegion(entry.annotation, inputX, entryY, inputW, lineHeight, nil, annotOffset)
                    end

                    lg.setColor(1, 1, 1)
                    textRegion(entry.coloredText, inputX, entryY, inputW, lineHeight)

                    entryY = entryY + lineHeight

                    entriesDrawn = entriesDrawn + 1
                    if entriesDrawn >= numEntries then
                        break
                    end
                end
            end
        end
    else
        assert(pane.splitType == "h" or pane.splitType == "v")
        if pane.splitType == "h" then
            local left, right = unpack(pane.children)
            drawPane(left, x, y, w/2, h)
            drawPane(right, x+w/2, y, w/2, h)
        else
            local up, down = unpack(pane.children)
            drawPane(up, x, y, w, h/2)
            drawPane(down, x, y+h/2, w, h/2)
        end
    end
end

function drawgui.draw()
    drawPane(gui.rootPane, 0, 0, love.graphics.getDimensions())
end

return drawgui
