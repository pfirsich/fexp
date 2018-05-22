local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local functional = require("functional")
local globtopattern = require("libs.globtopattern").globtopattern
local input = require("input")

local filter = {}

function filter.glob(glob)
    local pat = globtopattern(glob)
    local tab = gui.getSelectedTab()
    if tab then
        tab.items = functional.filterl(function(item)
            return item.caption:match(pat)
        end, tab.items)
    end
end
commands.register("filterglob", commands.wrap(filter.glob, {"glob"}), {"glob"})

function filter.globPrompt()
    local tab = gui.getSelectedTab()
    if tab then
        input.toggle({{
            caption = "Filter Glob",
            command = "filterglob",
            arguments = {},
        }}, "", "glob")
    end
end
commands.register("filterglobprompt", filter.globPrompt)
inputcommands.register("Filter Glob", "filterglobprompt")

function filter.selected()
    local tab = gui.getSelectedTab()
    if tab then
        print(inspect(tab.items))
        tab.items = functional.filterl(function(item)
            return item.selected
        end, tab.items)
        print(inspect(tab.items))
    end
end
commands.register("filterselected", filter.selected)
inputcommands.register("Filter Selected", "filterselected")

function filter.query(query)

end
commands.register("filterquery", commands.wrap(filter.query, {"query"}), {"query"})

function filter.queryPrompt()
    local tab = gui.getSelectedTab()
    if tab then
        input.toggle({{
            caption = "Filter Query",
            command = "filterquery",
            arguments = {},
        }}, "", "query")
    end
end
commands.register("filterqueryprompt", filter.queryPrompt)
inputcommands.register("Filter Query", "filterqueryprompt")

return filter
