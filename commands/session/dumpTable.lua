-- this is really bad and only works for what I am doing with it
local function escapeStr(str)
    return str:gsub("\\", "\\\\")
end

local function dumpTable(obj, indent)
    local oneIndent = "    "
    indent = indent or ""
    if type(obj) == "string" then
        return '"' .. escapeStr(obj) .. '"'
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif obj == nil then
        return "nil"
    elseif type(obj) == "boolean" then
        return obj and "true" or "false"
    elseif type(obj) == "table" then
        local s = "{\n"
        for k, v in pairs(obj) do
            s = s .. indent .. oneIndent .. '[' .. dumpTable(k) .. '] = ' ..
                dumpTable(v, indent .. oneIndent) .. ",\n"
        end
        s = s .. indent .. "}"
        return s
    else
        print("Cannot serialize", type(obj))
    end
end

return dumpTable
