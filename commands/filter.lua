local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local functional = require("functional")
local globtopattern = require("libs.globtopattern").globtopattern
local input = require("input")
local promptFunction = require("promptFunction")

local filter = {}

function filter.glob(glob)
    local pat = globtopattern(glob)
    local tab = gui.getSelectedTab()
    if tab then
        tab.items = functional.filterl(function(item)
            return item.caption:match(pat)
        end, tab.items)
        tab.itemCursor = 0
    end
end
commands.register("filterglob", commands.wrap(filter.glob, {"glob"}), {"glob"})
filter.globPrompt = promptFunction("Filter Glob", "filterglob", "glob")

function filter.selected()
    local tab = gui.getSelectedTab()
    if tab then
        tab.items = functional.filterl(function(item)
            return item.selected
        end, tab.items)
        tab.itemCursor = 0
    end
end
commands.register("filterselected", filter.selected)
inputcommands.register("Filter Selected", "filterselected")

local factorMap = {
    [""] = 1,
    K = 1024,
    M = 1024*1024,
    G = 1024*1024*1024,
    T = 1024*1024*1024*1024,
}
local function parseSize(str)
    local num, prefix = str:match("(%d+%.?%d*)%s*([KMGT]?)B?")
    num = tonumber(num)
    return math.floor(num * factorMap[prefix])
end

local function parseTime(str)
    error("Not yet implemented!")
end

function filter.query(query)
    local tab = gui.getSelectedTab()
    if tab then
        query = "return " .. query
        local f, msg = loadstring(query)
        if f then
            local items = {}
            for _, item in ipairs(tab.items) do
                setfenv(f, {
                    type = item.columns.type,
                    mod = item.columns.mod,
                    size = item.columns.size,
                    name = item.arguments.name,
                    path = item.arguments.path,
                    selected = item.selected,
                    s = parseSize,
                    t = parseTime,
                })

                local status, ret = pcall(f)
                if status then
                    if ret then
                        table.insert(items, item)
                    end
                else
                    gui.message("Error executing query: " .. tostring(ret), true)
                    return
                end
            end
            tab.items = items
            tab.itemCursor = 0
        else
            gui.mesage("Query could not be compiled: " .. msg, true)
        end
    end
end
commands.register("filterquery", commands.wrap(filter.query, {"query"}), {"query"})
filter.queryPrompt = promptFunction("Filter Query", "filterquery", "query")

return filter
