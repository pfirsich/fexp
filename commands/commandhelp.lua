local inspect = require("libs.inspect")

local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local promptFunction = require("util.promptFunction")
local message = require("message")

local commandhelp = {}

local commandHelpItemColumns = {
    {
        key = "command",
        font = "bold",
        color = {0.8, 0.8, 1.0},
        enabled = true,
    },
    {
        key = "help",
        font = "italic",
        enabled = true,
    },
    gotoItemColumn = "command",
}

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

        table.insert(tab.items, {
            columns = {
                command = cap,
                help = command.help,
            },
            command = "nop",
            arguments = {},
        })
    end
    tab.columns = commandHelpItemColumns
    tab.title = "Command Help"
    tab.itemCursor = 1

    commands.sort.sort("command")
end
commands.register("commandhelp", commandhelp.show)
inputcommands.register("Show Command Help", "commandhelp")

return commandhelp
