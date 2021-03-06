local inspect = require("libs.inspect")

local message = require("message")

local commands = {}

commands.registry = {}

commands.messages = false

function commands.loadCommands()
    for _, file in ipairs(love.filesystem.getDirectoryItems("commands")) do
        local name
        if love.filesystem.getInfo("commands/" .. file, "directory") then
            name = file
        elseif file:sub(-4) == ".lua" and file ~= "init.lua" then
            name = file:sub(1, -5)
        end
        if name then
            local mod = require("commands." .. name)
            assert(commands[name] == nil or commands[name] == mod)
            commands[name] = mod
        end
    end
end

function commands.register(command, func, mandatoryArguments, defaultArguments)
    assert(not commands.registry[command])
    commands.registry[command] = {
        func = func,
        mandatoryArguments = mandatoryArguments or {},
        defaultArguments = defaultArguments or {},
        flags = {},
    }
    return commands.registry[command]
end

function commands.setHelp(command, help)
    commands.registry[command].help = help
end

function commands.exec(command, arguments)
    local cmd = commands.registry[command]
    if cmd then
        for _, arg in ipairs(cmd.mandatoryArguments) do
            if arguments[arg] == nil then
                message.show(("Missing mandatory argument '%s' for '%s'!"):format(command, arg), true)
                return
            end
        end
        for arg, val in ipairs(cmd.defaultArguments) do
            -- maybe rather put this in a copy of the arguments table?
            if arguments[arg] == nil then
                arguments[arg] = val
            end
        end
        cmd.func(arguments)

        if commands.messages then
            message.show(("Executed %s%s"):format(command, inspect(arguments, {newline="", indent=""})))
        end
    else
        message.show(("Unknown command '%s'!"):format(command), true)
    end
end

-- a command has to be a function that takes a single argument "args", which is a table
-- with argument name/value pairs being saved as key/value
-- this function wraps a normal function and calls it with the values from the "args" table
-- unpacked. The arguments to be unpacked are in the second parameter "argList".
function commands.wrap(func, argList)
    return function(args)
        local funcArgs = {}
        for i, arg in ipairs(argList or {}) do
            funcArgs[i] = args[arg]
        end
        return func(unpack(funcArgs))
    end
end

commands.register("print", function(args)
    print(args.str)
end, {"str"})
commands.setHelp("print", "Print to system console.")

commands.register("nop", function() end)
commands.setHelp("nop", "Does nothing.")

commands.register("togglecommandmessages", function()
    commands.messages = not commands.messages
end)
commands.setHelp("togglecommandmessages", "Toggle status line information about executed commands.")

function commands.getFlag(command, flag)
    return commands.registry[command].flags[flag]
end

function commands.setFlag(command, flag, value)
    commands.registry[command].flags[flag] = value
    message.show(("Set flag '%s' for command '%s' to '%s'"):format(flag, command, tostring(value)))
end

function commands.toggleFlag(command, flag)
    commands.setFlag(command, flag, not commands.getFlag(command, flag))
end

commands.register("setflag", function(args)
    commands.setFlag(args.command, args.flag, args.value)
end, {"command", "flag", "value"})

commands.register("toggleflag", function(args)
    commands.toggleFlag(args.command, args.flag)
end, {"command", "flag"})

return commands
