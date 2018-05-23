local gui = require("gui")
local input = require("input")
local functional = require("functional")
local paths = require("paths")
local message = require("message")

local lg = love.graphics
local floor = math.floor

local fonts = {
    regular = love.graphics.newFont("RobotoMono-Regular.ttf", 14),
    bold = love.graphics.newFont("RobotoMono-Bold.ttf", 14),
    italic = love.graphics.newFont("RobotoMono-Italic.ttf", 14),
}

local drawgui = {}

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

function drawTabItems(tab, x, y, w, h)
    local font = lg.getFont()
    local fontHeight = font:getHeight()
    local lineHeight = fontHeight * 1.25
    local modWidth = font:getWidth("00.00.0000 00:00:00")
    local sizeWidth = font:getWidth("000.000 XB")

    tab._scrollOffset = tab._scrollOffset or 0
    local cursorOffset = tab._scrollOffset + lineHeight * (tab.itemCursor - 1)
    if cursorOffset < 0 then
        tab._scrollOffset = math.min(0, tab._scrollOffset - cursorOffset)
    elseif cursorOffset > h - lineHeight then
        tab._scrollOffset = tab._scrollOffset - (cursorOffset - (h - lineHeight))
    end
    local elemY = y + tab._scrollOffset

    lg.setScissor(x, y, w, h)
    lg.setColor(1, 1, 1)
    for i, item in ipairs(tab.items) do
        local tx, ty = floor(x + 5), floor(elemY + lineHeight/2 - fontHeight/2)
        if ty > y - lineHeight and ty < y + h then
            if item.selected then
                lg.setColor(0.2, 0.2, 1.0)
                lg.rectangle("fill", x, elemY, w, lineHeight)
            end
            if tab.itemCursor == i then
                lg.setColor(1, 1, 1, 0.4)
                lg.rectangle("fill", x, elemY, w, lineHeight)
            end
            lg.setColor(0.1, 0.1, 0.1)
            lg.rectangle("line", x, elemY, w, lineHeight)

            lg.setColor(1, 1, 1)
            lg.setFont(fonts.regular)
            if tab.showModCol then
                local modStr = os.date('%d.%m.%Y %H:%M:%S', item.columns.mod)
                lg.print(modStr, tx, ty)
                tx = tx + modWidth + 20
            end
            if tab.showSizeCol then
                local sizeStr = sizeToString(item.columns.size)
                local width = font:getWidth(sizeStr)
                lg.print(sizeStr, tx + sizeWidth - width, ty)
                tx = tx + sizeWidth + 20
            end

            if item.columns.type == "directory" then
                lg.setColor(0.8, 0.8, 1.0)
                lg.setFont(fonts.bold)
            elseif item.columns.type ~= "file" then
                lg.setFont(fonts.italic)
            end
            lg.print(item.caption, tx, ty)
        end
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
        lg.print(text, tx, ty)
    elseif type(text) == "table" then
        lg.printf(text, tx, ty, 10000)
    end
    lg.setScissor()
end

function drawPane(pane, x, y, w, h)
    local font = lg.getFont()

    if pane.tabs then
        local paneSelected = pane == gui.selectedPane
        if paneSelected then
            lg.setColor(1.0, 0, 1.0)
            lg.rectangle("line", x, y, w, h)
        end

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
            local title = tab.title
            if title:len() == 0 then
                title = tab.path and paths.basename(tab.path) or "unnamed tab"
            end
            lg.setFont(fonts.regular)
            textRegion(title, tabX, y, tabWidth, tabHeight)

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

        lg.setFont(fonts.regular)
        if numTabs == 0 then
            lg.setColor(1, 1, 1)
            local text = "No open tabs."
            local tx, ty = x + w/2 - font:getWidth(text)/2, y + h/2 - font:getHeight()/2
            lg.print("No open tabs.", floor(tx), floor(ty))
        end

        if paneSelected and input.isActive() then
            local numEntries = math.min(10, #input.visibleEntries)
            local inputW = 0.8 * w
            local inputY = y + 70
            local lineHeight = 30
            local inputH = (numEntries + 1) * lineHeight
            local inputX = x + w/2 - inputW/2

            lg.setColor(0.3, 0.3, 0.3)
            lg.rectangle("fill", inputX, inputY, inputW, inputH)
            lg.setColor(1, 1, 1)
            textRegion(input.text, inputX, inputY, inputW, lineHeight)

            -- draw entries
            local entryY = inputY + lineHeight
            local entryH = inputH - lineHeight
            lg.line(inputX, entryY, inputX + inputW, entryY)

            -- here the scrollOffset is an index offset (not in pixels!)
            input._scrollOffset = input._scrollOffset or 0
            if input.selectedEntry == nil then
                input._scrollOffset = 0
            else
                local cursor = input.selectedEntry - input._scrollOffset
                if cursor < 1 then
                    input._scrollOffset = math.max(0, input._scrollOffset + cursor - 1)
                elseif cursor > numEntries then
                    input._scrollOffset = input._scrollOffset + (cursor - numEntries)
                end
            end

            for i = input._scrollOffset + 1, input._scrollOffset + numEntries do
                local entry = input.visibleEntries[i]

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
            end
        end
    else
        assert(pane.splitType == "h" or pane.splitType == "v")
        local split = pane.splitRatio
        if pane.splitType == "h" then
            local left, right = unpack(pane.children)
            drawPane(left, x, y, w*split, h)
            drawPane(right, x + w*split, y, w*(1-split), h)
        else
            local up, down = unpack(pane.children)
            drawPane(up, x, y, w, h*split)
            drawPane(down, x, y + h*split, w, h*(1-split))
        end
    end
end

function drawgui.draw()
    local statusH = 25

    local w, h = love.graphics.getDimensions()
    drawPane(gui.rootPane, 0, 0, w, h - statusH)

    lg.setColor(0.2, 0.2, 0.2)
    local statusY = h - statusH
    lg.rectangle("fill", 0, statusY, w, statusH)
    lg.setColor(0, 0, 0)
    lg.rectangle("line", 0, statusY, w, statusH)

    local font = lg.getFont()
    local fontH = font:getHeight()
    local ty = floor(statusY + statusH/2 - fontH/2)

    lg.setColor(1.0, 1.0, 1.0)

    local tab = gui.getSelectedTab()
    if tab then
        local rightText = ("%d items"):format(#tab.items)
        local selection = gui.getSelectedItems()
        if selection and #selection > 0 then
            rightText = rightText .. (", %d selected"):format(#selection)
        end
        lg.print(rightText, w - font:getWidth(rightText) - 5, ty)
    end

    if message.messageError then
        lg.setColor(1.0, 0.2, 0.2)
    end
    lg.print(message.message, 5, ty)
end

return drawgui
