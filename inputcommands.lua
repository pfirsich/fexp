local shortcuts = require("shortcuts")
local commands = require("commands")
local input = require("input")

local inputcommands = {}

inputcommands.commands = {}

function inputcommands.register(caption, command, arguments)
    table.insert(inputcommands.commands, {
        caption = caption,
        command = command,
        arguments = arguments or {},
    })
end

-- inspired from here:
-- https://stackoverflow.com/questions/20325332/how-to-check-if-two-tablesobjects-have-the-same-value-in-lua
function tableEqual(a, b)
    local equalKeys = {}
    for k, v in pairs(a) do
        if b[k] == nil or v ~= b[k] then
            return false
        end
        equalKeys[k] = true
    end

    for k, v in pairs(b) do
        if not equalKeys[k] then
            return false
        end
    end

    return true
end

function inputcommands.updateShortcutAnnotations()
    for _, command in ipairs(inputcommands.commands) do
        for _, shortcut in ipairs(shortcuts.map) do
            if not command.annotation and command.command == shortcut.command and
                    tableEqual(command.arguments, shortcut.arguments) then
                local temp = {}
                for _, entry in ipairs(shortcut.shortcut) do
                    table.insert(temp, table.concat(entry, "+"))
                end
                command.annotation = table.concat(temp, ", ")
            end
        end
    end
end

function inputcommands.toggleCommandInput(text)
    input.toggle(inputcommands.commands, text)
end
commands.register("togglecommandinput", commands.wrap(inputcommands.toggleCommandInput, {"text"}))

return inputcommands
