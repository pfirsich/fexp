local lfs = require("lfs")

local commands = require("commands")
local inputcommands = require("inputcommands")
local input = require("input")
local gui = require("gui")

local filesystem = {}

function enumeratePath(path)
    local tab = gui.getSelectedTab()
    if not tab then
        gui.newTab()
        tab = gui.getSelectedTab()
    end
    tab.path = path
    tab.items = {}
    for file in lfs.dir(path) do
        table.insert(tab.items, {
            caption = file,
            command = "enumeratepath",
            arguments = {path = path .. "/" .. file},
        })
    end
end
commands.register("enumeratepath", commands.wrap(enumeratePath, {"path"}), {"path"})

function toggleViewItemsInput(text)
    local tab = gui.getSelectedTab()
    if tab then
        local entries = {}
        for _, item in ipairs(tab.items) do
            table.insert(entries, item)
        end
        input.toggle(entries, text)
    end
end
commands.register("toggleviewitemsinput", commands.wrap(toggleViewItemsInput, {"text"}))

return filesystem
