local commands = {}

commands.registry = {}

function commands.register(command, func, mandatoryArguments, defaultArguments)
    commands.registry[command] = {
        func = func,
        mandatoryArguments = mandatoryArguments or {},
        defaultArguments = defaultArguments or {},
    }
end

function commands.exec(command, arguments)
    local cmd = commands.registry[command]
    if cmd then
        for _, arg in ipairs(cmd.mandatoryArguments) do
            if arguments[arg] == nil then
                print(("Missing mandatory argument '%s' for '%s'!"):format(command, arg))
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
    else
        print(("Unknown command '%s'!"):format(command))
    end
end

-- a command has to be a function that takes a single argument "args", which is a table
-- with argument name/value pairs being saved as key/value
-- this function wraps a normal function and calls it with the values from the "args" table
-- unpacked. The arguments to be unpacked are in the second parameter "argList".
function commands.wrap(func, argList)
    return function(args)
        local funcArgs = {}
        for _, arg in ipairs(argList) do
            table.insert(funcArgs, args[arg])
        end
        return func(unpack(funcArgs))
    end
end

commands.register("print", function(args)
    print(args.str)
end, {"str"})

return commands
