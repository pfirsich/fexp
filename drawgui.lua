local gui = require("gui")
local input = require("input")
local functional = require("util.functional")
local paths = require("util.paths")
local message = require("message")
local clipboard = require("clipboard")
local memoize = require("util.memoize")

local lg = love.graphics
local floor = math.floor

local fonts = {
    regular = love.graphics.newFont("fonts/RobotoMono-Regular.ttf", 14),
    bold = love.graphics.newFont("fonts/RobotoMono-Bold.ttf", 14),
    italic = love.graphics.newFont("fonts/RobotoMono-Italic.ttf", 14),
}

local fontWidth = {}
for name, font in pairs(fonts) do
    fontWidth[name] = memoize(function(text) return fonts[name]:getWidth(text) end)
end

local drawgui = {}

function scrollIndicator(x, y, w, h, scrollBarH, scroll)
    lg.setColor(1.0, 1.0, 1.0, 0.5)
    local indicatorH = h * scrollBarH
    if scrollBarH < 1 then
        local indicatorW = 7
        local indicatorOffset = scroll * (h - indicatorH)
        lg.rectangle("fill", x + w - indicatorW, y + indicatorOffset, indicatorW, indicatorH)
    end
end

local function getColumnProperty(column, item, property)
    local prop = column[property]
    if prop and type(prop) == "function" then
        return prop(item)
    end
    return prop
end

local function getColumnString(column, item)
    local col = item.columns[column.key]
    if col == nil then
        return ""
    end
    if column.tostr then
        return column.tostr(col)
    end
    return tostring(col)
end

local function drawTabItems(tab, x, y, w, h)
    if #tab.items == 0 then return end
    assert(tab.columns)
    local font = lg.getFont()
    local fontHeight = font:getHeight()
    local lineHeight = floor(fontHeight * 1.25)

    tab._scrollOffset = tab._scrollOffset or 0
    local cursorOffset = tab._scrollOffset + lineHeight * (tab.itemCursor - 1)
    if cursorOffset < 0 then
        tab._scrollOffset = math.min(0, tab._scrollOffset - cursorOffset)
    elseif cursorOffset > h - lineHeight then
        tab._scrollOffset = tab._scrollOffset - (cursorOffset - (h - lineHeight))
    end
    local elemY = y + tab._scrollOffset

    lg.setScissor(x, y, w, h)

    local colWidths = {}
    for i = 1, #tab.columns - 1 do
        local column = tab.columns[i]
        if column.enabled then
            if column.width then
                if type(column.width) == "string" then
                    local font = column.font or "regular"
                    assert(type(font) == "string")
                    colWidths[i] = fontWidth[font](column.width)
                elseif type(column.width) == "number" then
                    colWidths[i] = column.width
                else
                    error("Unknown column width type")
                end
            else
                colWidths[i] = 0
                for _, item in ipairs(tab.items) do
                    local font = getColumnProperty(tab, item, "font") or "regular"
                    local text = getColumnString(column, item)
                    colWidths[i] = math.max(colWidths[i], fontWidth[font](text))
                end
            end
        end
    end

    for i, item in ipairs(tab.items) do
        local textY = floor(elemY + lineHeight/2 - fontHeight/2)
        if textY > y - lineHeight and textY < y + h then
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

            local textX = floor(x + 10)
            for colIndex, column in ipairs(tab.columns) do
                if column.enabled then
                    lg.setColor(getColumnProperty(column, item, "color") or {1, 1, 1})
                    local font = getColumnProperty(column, item, "font") or "regular"
                    lg.setFont(fonts[font])

                    local text = getColumnString(column, item)
                    local textWidth = fontWidth[font](text)

                    local justOffset = 0
                    if column.justify == "right" then
                        justOffset = colWidths[colIndex] - textWidth
                    elseif column.justify == "center" then
                        justOffset = (colWidths[colIndex] - textWidth) / 2
                    end
                    lg.print(text, textX + justOffset, textY)
                    if colIndex < #tab.columns then
                        textX = textX + colWidths[colIndex] + 20
                    end
                end
            end
        end
        elemY = elemY + lineHeight
    end

    local maxScroll = #tab.items * lineHeight - h
    scrollIndicator(x, y, w, h, h / (#tab.items * lineHeight), -tab._scrollOffset / maxScroll)

    lg.setScissor()
end

local function textRegion(text, x, y, w, h, padding, offsetX)
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

local function drawPane(pane, x, y, w, h)
    if pane.tabs then
        local paneSelected = pane == gui.selectedPane

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
            local tx, ty = x + w/2 - fontWidth.regular(text)/2, y + h/2 -
                fonts.regular:getHeight()/2
            lg.print("No open tabs.", floor(tx), floor(ty))
        end

        if not paneSelected then
            lg.setColor(0.0, 0.0, 0.0, 0.2)
            lg.rectangle("fill", x, y, w, h)
        else
            lg.setColor(1.0, 1.0, 1.0, 1.0)
            lg.rectangle("line", x + 1, y + 1, w - 2, h - 2)
            if input.isActive() then
                local numEntries = math.min(10, #input.visibleEntries)
                local inputW = 0.8 * w
                local inputY = y + 70
                local lineHeight = 30
                local inputH = (numEntries + 1) * lineHeight
                local inputX = x + w/2 - inputW/2

                lg.setColor(0.3, 0.3, 0.3)
                lg.rectangle("fill", inputX, inputY, inputW, inputH)
                lg.setColor(1, 1, 1)
                input.textLine:setFont(fonts.regular)
                input.textLine:setArea(inputX + 5, inputY + 5, inputW - 10, lineHeight - 10)
                input.textLine:draw({0.5, 0.5, 0.5}, true)

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
                        local annotOffset = inputW - fontWidth.regular(entry.annotation) - 20
                        lg.setColor(0.7, 0.7, 0.7)
                        textRegion(entry.annotation, inputX, entryY, inputW, lineHeight, nil, annotOffset)
                    end

                    lg.setColor(1, 1, 1)
                    textRegion(entry.coloredText, inputX, entryY, inputW, lineHeight)

                    entryY = entryY + lineHeight
                end

                scrollIndicator(inputX, inputY + lineHeight, inputW, entryH,
                    numEntries / #input.visibleEntries,
                    input._scrollOffset / (#input.visibleEntries - numEntries))
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

    local font = "regular"
    local fontH = fonts[font]:getHeight()
    local ty = floor(statusY + statusH/2 - fontH/2)

    lg.setColor(1.0, 1.0, 1.0)

    local tab = gui.getSelectedTab()
    if tab then
        local rightText = ("%d items"):format(#tab.items)
        local selection = gui.getSelectedItems()
        if selection and #selection > 0 then
            rightText = rightText .. (", %d selected"):format(#selection)
        end

        local clipType, clipData = clipboard.get()
        if clipType == "copyfiles" or clipType == "cutfiles" then
            rightText = rightText .. (", %d in clipboard (%s)"):format(
                #clipData, clipType == "copyfiles" and "copy" or "cut")
        end
        lg.print(rightText, w - fontWidth[font](rightText) - 5, ty)
    end

    if message.messageError then
        lg.setColor(1.0, 0.2, 0.2)
    end
    lg.print(message.message, 5, ty)
end

return drawgui
