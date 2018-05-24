local commands = require("commands")
local functional = require("util.functional")
local message = require("message")

local shortcuts = {}

shortcuts.map = {}

shortcuts.messages = true

function down(...)
    return love.keyboard.isDown(...)
end

function splitShortcut(str)
    local ret = {}
    for key in str:gmatch("[^%+]+") do
       table.insert(ret, key)
    end
    return ret
end

-- shortcut can be a table containing all the keys or a table of tables with a sequence of inputs
function shortcuts.register(shortcut, command, arguments)
    local shortcutRaw = shortcut
    if type(shortcut) == "string" then
        shortcut = {shortcut}
    end
    shortcut = functional.map(splitShortcut, shortcut)
    table.insert(shortcuts.map, {
        shortcutRaw = shortcutRaw,
        shortcut = shortcut,
        command = command,
        arguments = arguments or {},
    })
end

function shortcutMatch(shortcut, key, mods)
    local shortcutMods = {alt = false, ctrl = false, shift = false}
    for _, part in ipairs(shortcut) do
        if mods[part] ~= nil then -- is a modifier key
            shortcutMods[part] = true
        elseif part == key then -- is pressed
            -- pass
        else
            return false
        end
    end
    for mod, state in pairs(mods) do
        if shortcutMods[mod] ~= state then
            return false
        end
    end
    return true
end

local inputHistory = {}

local canRepeat = {
    up = true,
    down = true,
    left = true,
    right = true,
    pageup = true,
    pagedown = true,
}

function shortcuts.keypressed(key, scancode, isRepeat)
    if isRepeat and not canRepeat[key] then
        return
    end

    local mods = { -- modifiers
        alt = down("lalt") or down("ralt"),
        ctrl = down("lctrl") or down("rctrl"),
        shift = down("lshift") or down("rshift"),
    }

    table.insert(inputHistory, {
        key = key,
        mods = mods,
    })
    while #inputHistory > 3 do
        table.remove(inputHistory, 1)
    end

    local matchingShortcuts = {}
    for _, shortcut in ipairs(shortcuts.map) do
        local sequenceLen = #shortcut.shortcut
        if #inputHistory >= sequenceLen then
            local match = true
            for i = 1, sequenceLen do
                local index = #inputHistory - sequenceLen + i
                if not shortcutMatch(shortcut.shortcut[i], inputHistory[index].key, inputHistory[index].mods) then
                    match = false
                    break
                end
            end
            if match then
                table.insert(matchingShortcuts, shortcut)
            end
        end
    end

    local longestMatch = 0
    for _, shortcut in ipairs(matchingShortcuts) do
        longestMatch = math.max(longestMatch, #shortcut.shortcut)
    end

    for _, shortcut in ipairs(matchingShortcuts) do
        if #shortcut.shortcut == longestMatch then
            commands.exec(shortcut.command, shortcut.arguments)
        end
    end

    if shortcuts.messages and #matchingShortcuts > 0 then
        message.show("Execute shortcut: " .. table.concat(functional.map(function(sc)
            return ("%s -> %s%s"):format(inspect(sc.shortcutRaw), sc.command,
                inspect(sc.arguments, {newline="", indent=""}))
        end, matchingShortcuts)))
    end
end

return shortcuts
