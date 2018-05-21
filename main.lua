inspect = require("libs.inspect")
local shortcuts = require("shortcuts")
local gui = require("gui")
local drawgui = require("drawgui")
local inputcommands = require("inputcommands")
local input = require("input")

local lg = love.graphics

function love.load()
    shortcuts.register("ctrl+s", "print", {str = "pressed ctrl+s"})
    shortcuts.register({"ctrl+k", "ctrl+l"}, "print", {str = "pressed ctrl+k, ctrl+l"})
    shortcuts.register("ctrl+d", "hello")
    shortcuts.register("ctrl+e", "print")
    inputcommands.register("Print something in console", "print", {str = "something"})

    shortcuts.register({"ctrl+k", "up"}, "splitpane", {dir = "up"})
    shortcuts.register({"ctrl+k", "down"}, "splitpane", {dir = "down"})
    shortcuts.register({"ctrl+k", "left"}, "splitpane", {dir = "left"})
    shortcuts.register({"ctrl+k", "right"}, "splitpane", {dir = "right"})
    shortcuts.register({"ctrl+shift+k", "up"}, "splitpane", {dir = "up", carryTab = true})
    shortcuts.register({"ctrl+shift+k", "down"}, "splitpane", {dir = "down", carryTab = true})
    shortcuts.register({"ctrl+shift+k", "left"}, "splitpane", {dir = "left", carryTab = true})
    shortcuts.register({"ctrl+shift+k", "right"}, "splitpane", {dir = "right", carryTab = true})

    shortcuts.register("ctrl+up", "movepane", {dir = "up"})
    shortcuts.register("ctrl+down", "movepane", {dir = "down"})
    shortcuts.register("ctrl+left", "movepane", {dir = "left"})
    shortcuts.register("ctrl+right", "movepane", {dir = "right"})
    shortcuts.register("ctrl+shift+up", "movepane", {dir = "up", carryTab = true})
    shortcuts.register("ctrl+shift+down", "movepane", {dir = "down", carryTab = true})
    shortcuts.register("ctrl+shift+left", "movepane", {dir = "left", carryTab = true})
    shortcuts.register("ctrl+shift+right", "movepane", {dir = "right", carryTab = true})

    shortcuts.register({"ctrl+m", "up"}, "mergepane", {dir = "up"})
    shortcuts.register({"ctrl+m", "down"}, "mergepane", {dir = "down"})
    shortcuts.register({"ctrl+m", "left"}, "mergepane", {dir = "left"})
    shortcuts.register({"ctrl+m", "down"}, "mergepane", {dir = "down"})

    shortcuts.register("ctrl+t", "newtab")
    shortcuts.register("ctrl+w", "closetab")
    shortcuts.register("ctrl+tab", "nexttab")
    shortcuts.register("ctrl+shift+tab", "prevtab")

    shortcuts.register("tab", "togglefilesysteminput")
    shortcuts.register("ctrl+space", "togglecommandinput")

    inputcommands.updateShortcutAnnotations()

    gui.init()
end

function love.draw()
    drawgui.draw()
end

function love.keypressed(key)
    if input.isActive() then
        input.keypressed(key)
    else
        shortcuts.keypressed(key)
    end
end

function love.textinput(text)
    if input.isActive() then
        input.textinput(text)
    end
end
