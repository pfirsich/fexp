local inspect = require("libs.inspect")

local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local promptFunction = require("util.promptFunction")
local message = require("message")

local commandhelp = {}

function commandhelp.show()
    gui.newTab()
    local tab = gui.getSelectedTab()

    for name, command in pairs(commands.registry) do
        local args = {}
        for _, arg in ipairs(command.mandatoryArguments) do
            table.insert(args, arg)
        end
        for arg, val in ipairs(command.defaultArguments) do
            table.insert(args, arg .. " = " .. inspect(val, {newline="", indent=""}))
        end
        local cap = ("%s(%s)"):format(name, table.concat(args, ", "))
        if command.help then
            cap = cap .. "   -   " .. command.help
        end

        table.insert(tab.items, {
            caption = cap,
            columns = {type = "directory", mod = 0, size = 0},
            command = "nop",
            arguments = {},
        })
    end
    tab.title = "Command Help"
    tab.itemCursor = 1
    tab.showModCol = false
    tab.showSizeCol = false

    commands.sort.sort("name")
end
commands.register("commandhelp", commandhelp.show)
inputcommands.register("Show Command Help", "commandhelp")

return commandhelp
