local commands = require("commands")
local inputcommands = require("inputcommands")
local insertionSort = require("util.sort")
local gui = require("gui")
local message = require("message")
local input = require("input")

local sort = {}

function cmpKey(key, cmpFunc)
    if cmpFunc then
        return function(a, b)
            return cmpFunc(a.columns[key], b.columns[key])
        end
    else
        return function(a, b)
            local va, vb = a.columns[key], b.columns[key]
            assert(type(va) == type(vb))
            if type(va) == "number" or type(va) == "boolean" then
                return va < vb
            elseif type(va) == "string" then
                return va:lower() < vb:lower()
            else
                error("Cannot sort " .. type(va))
            end
        end
    end
end

function sort.sort(by)
    local tab = gui.getSelectedTab()
    if tab then
        assert(tab.columns)
        local column = nil
        if type(by) == "integer" then
            column = tab.columns[by]
        elseif type(by) == "string" then
            column = tab:getColumnByKey(by)
            if not column then
                message.show(("Column '%s' is not present in this tab"):format(by))
                return
            end
        else
            message.show(("Unknown type for sort key '%s' (%s)"):format(type(by), tostring(by)), true)
            return
        end
        insertionSort(tab.items, cmpKey(column.key, column.cmp))
    end
end
commands.register("sort", commands.wrap(sort.sort, {"by"}), {"by"})

function sort.sortPrompt()
    local tab = gui.getSelectedTab()
    if tab and tab.columns then
        local entries = {}
        for i, column in ipairs(tab.columns) do
            table.insert(entries, {
                caption = column.key,
                command = "sort",
                arguments = {by = column.key},
            })
        end
        input.toggle(entries, text)
    end
end
commands.register("sortprompt", sort.sortPrompt)
inputcommands.register("Sort", "sortprompt")

return sort
