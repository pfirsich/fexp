local utf8 = require("utf8")
local commands = require("commands")

local input = {}

input.entries = nil

local function len_utf8(text)
    return utf8.len(text)
end

local function sub_utf8(text, from, to)
    return text:sub(utf8.offset(text, from), to and utf8.offset(text, to+1)-1 or text:len())
end

function input.isActive()
    return input.entries ~= nil
end

local function updateInputEntryVisibility()
    if input.text == "" then
        input.selectedEntry = 1
    end
end

function input.toggle(entries, text)
    if input.entries then
        input.entries = nil
    else
        input.entries = entries
        input.text = text or ""
        updateInputEntryVisibility()
    end
end

function input.keypressed(key)
    if key == "up" then
        input.selectedEntry = math.max(1, input.selectedEntry - 1)
        input.selectionLocked = true
    end
    if key == "down" then
        input.selectedEntry = math.min(#input.entries, input.selectedEntry + 1)
        input.selectionLocked = true
    end
    if key == "return" then
        local entry = input.entries[input.selectedEntry]
        commands.exec(entry.command, entry.arguments)
        input.entries = nil
    end
    if key == "backspace" then
        input.text = sub_utf8(input.text, 1, len_utf8(input.text) - 1)
    end
    if key == "escape" then
        input.entries = nil
    end
    updateInputEntryVisibility()
end

function input.textinput(text)
    input.text = input.text .. text
    updateInputEntryVisibility()
end

return input
