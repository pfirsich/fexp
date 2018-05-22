inspect = require("libs.inspect")
local shortcuts = require("shortcuts")
local commands = require("commands")
local gui = require("gui")
local drawgui = require("drawgui")
local inputcommands = require("inputcommands")
local input = require("input")

commands.register("quit", love.event.quit)

love.graphics.setFont(love.graphics.newFont("RobotoMono-Regular.ttf", 14))

function love.load()
    commands.loadCommands()

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
    shortcuts.register({"ctrl+m", "right"}, "mergepane", {dir = "right"})

    shortcuts.register("ctrl+t", "newtab")
    shortcuts.register("ctrl+w", "closetab")
    shortcuts.register("ctrl+tab", "nexttab")
    shortcuts.register("ctrl+shift+tab", "prevtab")
    shortcuts.register("f2", "renametabprompt")

    shortcuts.register("tab", "gotoitemprompt")
    shortcuts.register("ctrl+space", "togglecommandinput")

    shortcuts.register("up", "moveitemcursor", {delta = -1})
    shortcuts.register("down", "moveitemcursor", {delta = 1})
    shortcuts.register("pageup", "moveitemcursor", {delta = -8})
    shortcuts.register("pagedown", "moveitemcursor", {delta = 8})
    shortcuts.register("home", "seekitemcursor", {pos = 1})
    shortcuts.register("end", "seekitemcursor", {pos = -1})

    shortcuts.register("space", "toggleitemselection")
    shortcuts.register("a", "toggleitemselectall")
    shortcuts.register("return", "execitems")

    shortcuts.register({"ctrl+f", "g"}, "filterglobprompt")
    shortcuts.register({"ctrl+f", "s"}, "filterselected")
    shortcuts.register({"ctrl+f", "q"}, "filterqueryprompt")

    shortcuts.register({"ctrl+s", "n"}, "sort", {by = "name"})
    shortcuts.register({"ctrl+s", "m"}, "sort", {by = "mod"})
    shortcuts.register({"ctrl+s", "s"}, "sort", {by = "size"})
    shortcuts.register({"ctrl+s", "t"}, "sort", {by = "type"})

    inputcommands.register("Bookmark: Home", "enumeratepath", {path = "C:/Users/Joel"})

    inputcommands.register("Quit", "quit")

    inputcommands.finalize()

    love.keyboard.setKeyRepeat(true)

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
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
    if not ctrl and not alt and input.isActive() then
        input.textinput(text)
    end
end
