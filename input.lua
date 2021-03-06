local utf8 = require("utf8")

local TextLine = require("libs.textline")

local commands = require("commands")
local sort = require("util.sort")
local functional = require("util.functional")

local input = {}

input.entries = nil

-- these constructor values are all bogus and overwritten in drawgui.lua when drawing
input.textLine = TextLine(love.graphics.getFont(), 0, 0, 200, 20)

function input.isActive()
    return input.entries ~= nil
end

local function isupper(byte)
    return byte >= 0x41 and byte <= 0x5A
end

local function islower(byte)
    return byte >= 0x61 and byte <= 0x7A
end

local function isalpha(byte)
    return isupper(byte) or islower(byte)
end

local function matchScore(string, query)
    local beginningOfWordBonus = 10
    local adjacentBonus = 5
    local leadingUnmatchedPenalty = 0.5

    local score = 0
    local s = 1
    -- {bool, str, str, str, str, ...}
    --- bool indicates if the first string is matching, then it's alternating
    local parts = {}
    local lastMatching = nil
    local lastMatchPosition = nil
    for q = 1, query:len() do
        -- ignore non ascii and control characters
        if query:byte(q) >= 32 and query:byte(q) <= 126 then
            local qChar = query:sub(q, q):lower()

            local match = nil
            while s <= string:len() do
                local sChar = string:sub(s, s):lower()
                match = qChar == sChar

                if s == 1 then
                    table.insert(parts, match)
                end
                if match ~= lastMatching then
                    table.insert(parts, "")
                end
                parts[#parts] = parts[#parts] .. string:sub(s, s)

                if match then
                    score = score + 1
                    -- if it's matching at the beginning of the string or a word (after a separator)
                    if s == 1 or not isalpha(string:byte(s-1)) then
                        score = score + beginningOfWordBonus
                    end
                    -- beginning of word (camel case)
                    if s > 1 and isupper(string:byte(s)) and islower(string:byte(s-1)) then
                        score = score + beginningOfWordBonus
                    end
                    -- last match was the letter before (=> adjacent matches)
                    if lastMatching then
                        score = score + adjacentBonus
                    end

                    if lastMatchPosition == nil then
                        score = score - s * leadingUnmatchedPenalty
                    end
                    lastMatchPosition = s
                end

                lastMatching = match
                s = s + 1

                if match then
                    break
                end
            end
            if not match and s > string:len() then
                return nil, {}
            end
        end
    end

    if query:len() == 0 then
        parts = {false, string}
    else
        table.insert(parts, string:sub(s))
    end

    return score, parts
end

local function entryCmp(a, b)
    if a.matchScore == nil then return false end
    if b.matchScore == nil then return true end
    return a.matchScore > b.matchScore
end

local function entryCmpCaption(a, b)
    return a.caption < b.caption
end

local function makeColoredText(matchParts)
    local ret = {}
    local matching = matchParts[1]
    for i = 2, #matchParts do
        if matching then
            table.insert(ret, {0.7, 0.7, 1.0})
        else
            table.insert(ret, {1.0, 1.0, 1.0})
        end
        table.insert(ret, matchParts[i])
        matching = not matching
    end
    return ret
end

local function updateInputEntryVisibility()
    if not input.entries then return end

    if input.promptArg then
        input.entries[1].visible = true
        input.entries[1].coloredText = makeColoredText({true, input.entries[1].caption})
        input.selectedEntry = 1
    else
        local text = input.textLine:getText()
        if text:len() > 0 then
            for _, entry in ipairs(input.entries) do
                entry.matchScore, entry.matchingIndices = matchScore(entry.caption, text)
                entry.visible = entry.matchScore and entry.matchScore >= 0
                if entry.matchScore then
                    entry.coloredText = makeColoredText(entry.matchingIndices)
                end
            end
            sort(input.entries, entryCmp)
        else
            for _, entry in ipairs(input.entries) do
                entry.visible = true
                entry.coloredText = makeColoredText({false, entry.caption})
            end
            sort(input.entries, entryCmpCaption)
        end
    end

    -- construct visible set
    input.visibleEntries = functional.filterl(function(entry) return entry.visible end, input.entries)
    -- select first visible (best match)
    input.selectedEntry = #input.visibleEntries > 0 and 1 or nil
end

-- if promptArg is given, the input is a prompt i.e.
-- only the first entry is drawn and always visible,
-- the command will receive an additional argument with the input and the name is 'promptArg'
function input.toggle(entries, text, promptArg)
    input.entries = entries
    input.textLine:setText(text or "", true)
    input.selectedEntry = 1
    input.promptArg = promptArg
    if input.promptArg then
        input.entries = {entries[1]}
    end
    updateInputEntryVisibility()

    -- the only reason this exists is so that we can detect if input.toggle has been called
    -- while a entry in the input list is being executed (in which case we do not close it)
    input.toggled = true
end

local function seekEntry(delta)
    local numVis = #input.visibleEntries
    if numVis == 0 then
        input.selectedEntry = nil
    else
        input.selectedEntry = math.max(1, math.min(numVis, input.selectedEntry + delta))
    end
end

function input.keypressed(key)
    if key == "up" then
        seekEntry(-1)
    end
    if key == "down" then
        seekEntry(1)
    end
    if key == "return" then
        if #input.visibleEntries == 0 then
            -- just close the input
            input.entries = nil
            return
        end

        local entry = input.visibleEntries[input.selectedEntry]
        assert(entry)
        if input.promptArg then
            entry.arguments[input.promptArg] = input.textLine:getText()
        end

        input.toggled = false
        commands.exec(entry.command, entry.arguments)
        if not input.toggled then
            input.entries = nil
        end
    end
    if key == "escape" then
        input.entries = nil
    end

    if input.textLine:keyPressed(key) then
        updateInputEntryVisibility()
    end
end

function input.textinput(text)
    input.textLine:textInput(text)
    updateInputEntryVisibility()
end

function input.update()
    if input.textLine:update() then
        triggerRepaint()
    end
end

return input
