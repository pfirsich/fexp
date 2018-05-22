local utf8 = require("utf8")

local commands = require("commands")
local sort = require("sort")

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
    return a.matchScore >= b.matchScore
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
    if input.promptArg then
        input.entries[1].visible = true
        input.entries[1].coloredText = makeColoredText({true, input.entries[1].caption})
        input.selectedEntry = 1
        input.numVisible = 1
        return
    end

    for _, entry in ipairs(input.entries) do
        entry.matchScore, entry.matchingIndices = matchScore(entry.caption, input.text)
        entry.visible = entry.matchScore and entry.matchScore >= 0
        if entry.matchScore then
            entry.coloredText = makeColoredText(entry.matchingIndices)
        end
    end
    sort(input.entries, entryCmp)
--[[    print(">>> sorted")
    for _, entry in ipairs(input.entries) do
        print(entry.caption, entry.matchScore, inspect(entry.matchingIndices))
    end--]]

    -- select first visible (best match)
    input.selectedEntry = nil
    input.numVisible = 0
    for i, entry in ipairs(input.entries) do
        if entry.visible then
            input.selectedEntry = input.selectedEntry or i
            input.numVisible = input.numVisible + 1
        end
    end
end

-- if promptArg is given, the input is a prompt i.e.
-- only the first entry is drawn and always visible,
-- the command will receive an additional argument with the input and the name is 'promptArg'
function input.toggle(entries, text, promptArg)
    input.entries = entries
    input.text = text or ""
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

local function selectPrevEntry()
    local firstVisible
    for i, entry in ipairs(input.entries) do
        if entry.visible then
            firstVisible = i
            break
        end
    end

    if not firstVisible then
        -- no visible entry => don't do anything
        return
    end

    input.selectedEntry = input.selectedEntry - 1
    while input.selectedEntry > 1 and not input.entries[input.selectedEntry].visible do
        input.selectedEntry = input.selectedEntry - 1
    end

    input.selectedEntry = math.max(firstVisible, input.selectedEntry)
end

local function selectNextEntry()
    local lastVisible
    for i, entry in ipairs(input.entries) do
        if entry.visible then
            lastVisible = i
        end
    end

    if not lastVisible then
        -- no visible entry => don't do anything
        return
    end

    input.selectedEntry = input.selectedEntry + 1
    while input.selectedEntry < #input.entries and not input.entries[input.selectedEntry].visible do
        input.selectedEntry = input.selectedEntry + 1
    end

    input.selectedEntry = math.min(lastVisible, input.selectedEntry)
end

function input.keypressed(key)
    if key == "up" then
        selectPrevEntry()
    end
    if key == "down" then
        selectNextEntry()
    end
    if key == "return" then
        local entry = input.entries[input.selectedEntry]
        if input.promptArg then
            entry.arguments[input.promptArg] = input.text
        end

        input.toggled = false
        commands.exec(entry.command, entry.arguments)
        if not input.toggled then
            input.entries = nil
        end
    end
    if key == "backspace" then
        input.text = sub_utf8(input.text, 1, len_utf8(input.text) - 1)
        updateInputEntryVisibility()
    end
    if key == "escape" then
        input.entries = nil
    end
end

function input.textinput(text)
    input.text = input.text .. text
    updateInputEntryVisibility()
end

return input
