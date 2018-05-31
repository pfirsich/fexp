local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local functional = require("util.functional")
local globtopattern = require("libs.globtopattern").globtopattern
local input = require("input")
local message = require("message")
local promptFunction = require("util.promptFunction")
local memoize = require("util.memoize")

local filter = {}

-- we need this, because otherwise the "glob" function in queries would call the real
-- "globtopattern" way too often
globtopattern = memoize(globtopattern)

function filter.glob(glob)
    local pat = globtopattern(glob)
    local tab = gui.getSelectedTab()
    if tab then
        tab.items = functional.filterl(function(item)
            return item.columns[tab.gotoItemColumn]:match(pat)
        end, tab.items)
        tab.itemCursor = 1
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
        tab.itemCursor = 1
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

local function glob(str, glob)
    return str:match(globtopattern(glob))
end

function filter.query(query)
    local tab = gui.getSelectedTab()
    if tab then
        query = "return " .. query
        local f, msg = loadstring(query)
        if f then
            local items = {}
            for _, item in ipairs(tab.items) do
                local env = {
                    selected = item.selected,
                }
                for col, val in pairs(item.columns) do
                    env[col] = val
                end
                for arg, val in pairs(item.arguments) do
                    env[arg] = val
                end

                -- helper functions
                env.glob = glob
                env.time = parseTime
                for prefix, factor in pairs(factorMap) do
                    local f = function(num) return num * factorMap[prefix] end
                    env[prefix .. "B"] = f
                    env[prefix:lower() .. "b"] = f
                end

                setfenv(f, env)

                local status, ret = pcall(f)
                if status then
                    if ret then
                        table.insert(items, item)
                    end
                else
                    message.show("Error executing query: " .. tostring(ret), true)
                    return
                end
            end
            tab.items = items
            tab.itemCursor = 1
        else
            message.show("Query could not be compiled: " .. msg, true)
        end
    end
end
commands.register("filterquery", commands.wrap(filter.query, {"query"}), {"query"})
filter.queryPrompt = promptFunction("Filter Query", "filterquery", "query")

return filter
