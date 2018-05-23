local input = require("input")
local commands = require("commands")
local inputcommands = require("inputcommands")

local function promptFunction(title, command, inputArgument, promptCommand, arguments)
    local func = function(text)
        input.toggle({{
            caption = "> " .. title,
            command = command,
            arguments = arguments or {},
        }}, text, inputArgument)
    end
    local promptCommand = promptCommand or command .. "prompt"
    commands.register(promptCommand, commands.wrap(func, {"text"}))
    inputcommands.register(title, promptCommand)
    return func
end

return promptFunction
