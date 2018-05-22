local commands = require("commands")
local inputcommands = require("inputcommands")
local insertionSort = require("sort")
local gui = require("gui")

local sort = {}

local cmpFuncs = {}

local typeMap = {
    ["directory"] = 1,
    ["file"] = 2,
    ["link"] = 3,
    ["socket"] = 4,
    ["named pipe"] = 5,
    ["char device"] = 6,
    ["block device"] = 7,
    ["other"] = 8,
}
function cmpFuncs.type(a, b)
    return typeMap[a.columns.type] < typeMap[b.columns.type]
end

function cmpFuncs.name(a, b)
    return a.caption:lower() < b.caption:lower()
end

function cmpFuncs.size(a, b)
    return a.columns.size < b.columns.size
end

function cmpFuncs.mod(a, b)
    return a.columns.mod < b.columns.mod
end

function sort.sort(by)
    if by ~= "type" and by ~= "name" and by ~= "size" and by ~= "mod" then
        print(("Unknown sort type '%s'"):format(by))
        return
    end

    local tab = gui.getSelectedTab()
    if tab then
        insertionSort(tab.items, cmpFuncs[by])
    end
end
commands.register("sort", commands.wrap(sort.sort, {"by"}), {"by"})

return sort
