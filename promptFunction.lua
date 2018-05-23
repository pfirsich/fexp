local input = require("input")
local commands = require("commands")
local inputcommands = require("inputcommands")

local function promptFunction(title, command, inputArgument, promptCommand, arguments)
    local func = function(args)
        local entry = {
            caption = "> " .. title,
            command = command,
            arguments = arguments or {},
        }
        -- add additional arguments to entry command arguments
        for k, v in pairs(args) do
            entry.arguments[k] = v
        end
        input.toggle({entry}, args.text, inputArgument)
    end
    local promptCommand = promptCommand or command .. "prompt"
    commands.register(promptCommand, func)
    inputcommands.register(title, promptCommand)
    return func
end

return promptFunction
