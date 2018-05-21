local gui = require("gui")

local lg = love.graphics
local floor = math.floor

local drawgui = {}

function drawElements(elements, x, y, w, h)
    lg.setScissor(x, y, w, h)
    -- draw
    lg.setScissor()
end

function textRegion(text, x, y, w, h, padding)
    padding = padding or 5
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    lg.setScissor(x + padding, y + padding, w - padding*2, h - padding*2)
    lg.print(text, x + padding, floor(y + h/2 - lg.getFont():getHeight() / 2))
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

                local elementsY = pathLineY + pathLineH
                drawElements(tab.elements, x, elementsY, w, h - (elementsY - y))
            end
        end

        if numTabs == 0 then
            lg.setColor(1, 1, 1)
            local text = "No open tabs."
            local tx, ty = x + w/2 - font:getWidth(text)/2, y + h/2 - font:getHeight()/2
            lg.print("No open tabs.", math.floor(tx), math.floor(ty))
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
