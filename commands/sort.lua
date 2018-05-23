local commands = require("commands")
local inputcommands = require("inputcommands")
local insertionSort = require("util.sort")
local gui = require("gui")
local message = require("message")

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
    ["n/a"] = 9,
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
        message.show(("Unknown sort type '%s'"):format(by), true)
        return
    end

    local tab = gui.getSelectedTab()
    if tab then
        insertionSort(tab.items, cmpFuncs[by])
    end
end
commands.register("sort", commands.wrap(sort.sort, {"by"}), {"by"})
inputcommands.register("Sort by Type", "sort", {by = "type"})
inputcommands.register("Sort by Name", "sort", {by = "name"})
inputcommands.register("Sort by Size", "sort", {by = "size"})
inputcommands.register("Sort by Modification Time", "sort", {by = "mod"})

return sort
