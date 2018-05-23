local commands = require("commands")
local functional = require("functional")

local shortcuts = {}

shortcuts.map = {}

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
    if type(shortcut) == "string" then
        shortcut = {shortcut}
    end
    shortcut = functional.map(splitShortcut, shortcut)
    table.insert(shortcuts.map, {
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

    local matchingShortcut = nil
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
                -- match longest match
                if not matchingShortcut or #matchingShortcut.shortcut < sequenceLen then
                    matchingShortcut = shortcut
                end
            end
        end
    end

    if matchingShortcut then
        commands.exec(matchingShortcut.command, matchingShortcut.arguments)
    end
end

return shortcuts
