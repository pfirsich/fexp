local gui = require("gui")
local commands = require("commands")
local inputcommands = require("inputcommands")
local functional = require("functional")
local globtopattern = require("libs.globtopattern").globtopattern
local input = require("input")

local filter = {}

function filterGlob(glob)
    local pat = globtopattern(glob)
    local tab = gui.getSelectedTab()
    if tab then
        tab.items = functional.filterl(function(item)
            return item.caption:match(pat)
        end, tab.items)
    end
end
commands.register("filterglob", commands.wrap(filterGlob, {"glob"}), {"glob"})

function filterGlobPrompt()
    local tab = gui.getSelectedTab()
    if tab then
        input.toggle({{
            caption = "Filter Glob",
            command = "filterglob",
            arguments = {},
        }}, "", "glob")
    end
end
commands.register("filterglobprompt", filterGlobPrompt)
inputcommands.register("Filter Glob", "filterglobprompt")

function filterSelected()
    local tab = gui.getSelectedTab()
    if tab then
        print(inspect(tab.items))
        tab.items = functional.filterl(function(item)
            return item.selected
        end, tab.items)
        print(inspect(tab.items))
    end
end
commands.register("filterselected", filterSelected)
inputcommands.register("Filter Selected", "filterselected")

function filterQuery(query)

end
commands.register("filterquery", commands.wrap(filterQuery, {"query"}), {"query"})

function filterQueryPrompt()
    local tab = gui.getSelectedTab()
    if tab then
        input.toggle({{
            caption = "Filter Query",
            command = "filterquery",
            arguments = {},
        }}, "", "query")
    end
end
commands.register("filterqueryprompt", filterQueryPrompt)
inputcommands.register("Filter Query", "filterqueryprompt")

return filter
