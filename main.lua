local lfs = require("lfs")
inspect = require("libs.inspect")

require("run")
local shortcuts = require("shortcuts")
local commands = require("commands")
local gui = require("gui")
local drawgui = require("drawgui")
local inputcommands = require("inputcommands")
local input = require("input")

function toggleVerbose()
    local verbose = shortcuts.messages and commands.messages
    verbose = not verbose
    shortcuts.messages = verbose
    commands.messages = verbose
end
commands.register("toggleverbose", toggleVerbose)
inputcommands.register("Toggle Verbose Mode", "toggleverbose")

function love.load()
    commands.loadCommands()

    shortcuts.register({"ctrl+p", "up"}, "splitpane", {dir = "up"})
    shortcuts.register({"ctrl+p", "down"}, "splitpane", {dir = "down"})
    shortcuts.register({"ctrl+p", "left"}, "splitpane", {dir = "left"})
    shortcuts.register({"ctrl+p", "right"}, "splitpane", {dir = "right"})
    shortcuts.register({"ctrl+shift+p", "up"}, "splitpane", {dir = "up", carryTab = true})
    shortcuts.register({"ctrl+shift+p", "down"}, "splitpane", {dir = "down", carryTab = true})
    shortcuts.register({"ctrl+shift+p", "left"}, "splitpane", {dir = "left", carryTab = true})
    shortcuts.register({"ctrl+shift+p", "right"}, "splitpane", {dir = "right", carryTab = true})

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

    shortcuts.register("alt+up", "resizepane", {amount = -0.02})
    shortcuts.register("alt+down", "resizepane", {amount = 0.02})
    shortcuts.register("alt+left", "resizepane", {amount = -0.02})
    shortcuts.register("alt+right", "resizepane", {amount = 0.02})

    shortcuts.register("ctrl+t", "newtab")
    shortcuts.register("ctrl+w", "closetab")
    shortcuts.register("ctrl+f2", "renametabprompt")
    shortcuts.register("ctrl+tab", "nexttab")
    shortcuts.register("ctrl+shift+tab", "prevtab")
    shortcuts.register("ctrl+1", "selecttab", {tabIndex = 1})
    shortcuts.register("ctrl+2", "selecttab", {tabIndex = 2})
    shortcuts.register("ctrl+3", "selecttab", {tabIndex = 3})
    shortcuts.register("ctrl+4", "selecttab", {tabIndex = 4})
    shortcuts.register("ctrl+5", "selecttab", {tabIndex = 5})
    shortcuts.register("ctrl+6", "selecttab", {tabIndex = 6})
    shortcuts.register("ctrl+7", "selecttab", {tabIndex = 7})
    shortcuts.register("ctrl+8", "selecttab", {tabIndex = 8})
    shortcuts.register("ctrl+9", "selecttab", {tabIndex = 9})
    shortcuts.register("ctrl+0", "selecttab", {tabIndex = 0})

    shortcuts.register("f5", "reloadtab")
    shortcuts.register("ctrl+f5", "reloadalltabs")
    shortcuts.register("ctrl+n", "createdirectoryprompt")
    shortcuts.register("ctrl+r", "toggleflag", {command = "enumeratepath", flag = "recursive"})
    shortcuts.register("ctrl+g", "enumeratepathprompt")
    shortcuts.register("delete", "deleteselection")
    shortcuts.register("ctrl+delete", "deleteselection", {recursive = true})
    shortcuts.register("f2", "renameselectionprompt")
    shortcuts.register("ctrl+c", "copyselection")
    shortcuts.register("ctrl+x", "cutselection")
    shortcuts.register("ctrl+v", "pasteclipboard")

    -- use h j k l for columns (obviously from left to right)
    shortcuts.register("ctrl+h", "togglemodcol")
    shortcuts.register("ctrl+j", "togglesizecol")

    shortcuts.register("tab", "gotoitemprompt")
    shortcuts.register("ctrl+space", "togglecommandinput")
    shortcuts.register("alt+space", "toggletabinput")

    shortcuts.register("up", "moveitemcursor", {delta = -1})
    shortcuts.register("down", "moveitemcursor", {delta = 1})
    shortcuts.register("pageup", "moveitemcursor", {delta = -8})
    shortcuts.register("pagedown", "moveitemcursor", {delta = 8})
    shortcuts.register("home", "seekitemcursor", {pos = 1})
    shortcuts.register("end", "seekitemcursor", {pos = -1})
    shortcuts.register("shift+up", "moveitemcursor", {delta = -1, selectItems = true})
    shortcuts.register("shift+down", "moveitemcursor", {delta = 1, selectItems = true})
    shortcuts.register("shift+pageup", "moveitemcursor", {delta = -8, selectItems = true})
    shortcuts.register("shift+pagedown", "moveitemcursor", {delta = 8, selectItems = true})
    shortcuts.register("shift+home", "seekitemcursor", {pos = 1, selectItems = true})
    shortcuts.register("shift+end", "seekitemcursor", {pos = -1, selectItems = true})

    shortcuts.register("space", "toggleitemselection")
    shortcuts.register("a", "toggleitemselectall")
    shortcuts.register("return", "execitems")
    shortcuts.register("ctrl+return", "execitems", {newTab = true})
    shortcuts.register("alt+return", "execitems", {newPane = true})

    shortcuts.register({"ctrl+f", "g"}, "filterglobprompt")
    shortcuts.register({"ctrl+f", "s"}, "filterselected")
    shortcuts.register({"ctrl+f", "q"}, "filterqueryprompt")

    shortcuts.register({"ctrl+s", "n"}, "sort", {by = "name"})
    shortcuts.register({"ctrl+s", "m"}, "sort", {by = "mod"})
    shortcuts.register({"ctrl+s", "s"}, "sort", {by = "size"})
    shortcuts.register({"ctrl+s", "t"}, "sort", {by = "type"})
    shortcuts.register({"ctrl+s", "x"}, "sort", {by = "ext"})

    shortcuts.register("ctrl+shift+s", "savesessionprompt")
    shortcuts.register("ctrl+shift+o", "loadsession")

    local home = os.getenv("HOME") or (os.getenv("HOMEDRIVE") .. os.getenv("HOMEPATH")) or lfs.currentdir()
    inputcommands.register("Bookmark: Home", "enumeratepath", {path = home})

    commands.register("quit", love.event.quit)
    inputcommands.register("Quit", "quit")

    inputcommands.finalize()

    love.keyboard.setKeyRepeat(true)
    love.window.maximize()

    gui.init()
end

function love.update()
    if input.isActive() then
        input.update()
    end
end

function love.draw()
    drawgui.draw()
end

function love.keypressed(key, scancode, isRepeat)
    if input.isActive() then
        input.keypressed(key, scancode, isRepeat)
    else
        shortcuts.keypressed(key, scancode, isRepeat)
    end
    triggerRepaint()
end

function love.textinput(text)
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
    if not ctrl and not alt and input.isActive() then
        input.textinput(text)
    end
    triggerRepaint()
end

function love.resize()
    triggerRepaint()
end
