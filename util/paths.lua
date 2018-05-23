local paths = {}

-- all of this is very heavily inspired by Python's os.path library.

paths.sep = "/"
paths.altsep = "\\"
-- possible values: "OS X", "Windows", "Linux", "Android" or "iOS".
if love.system.getOS() == "Windows" then
    paths.sep = "\\"
    paths.altsep = "/"
end
paths.allsep = "/\\"

local function rfind(str, char)
    local i = str:match(".*" .. char .. "()")
    return i and i - 1 or nil
end

local function rstrip(str, pat)
    local ret = str:gsub("[" .. pat .. "]*$", "")
    return ret
end

local function lstrip(str, pat)
    local ret = str:gsub("^[" .. pat .. "]*", "")
    return ret
end

local function strip(str, pat)
    return lstrip(rstrip(str, pat), pat)
end

function paths.abspath(path)
    -- Python does: normpath(join(os.getcwd(), path))
    error("Unimplemented")
end

function paths.split(path)
    local dir, base = path:match("(.*)[/\\]+([^/\\]*)$")
    if dir and base then
      return dir, base
    else -- pattern only doesn't match if there is no / or \ in it
      return "", path
    end
end

function paths.basename(path)
    local dir, base = paths.split(path)
    return base
end

function paths.dirname(path)
    local dir, base = paths.split(path)
    return dir
end

function paths.commonpath(...)
    -- return the longest common sub-path of each argument
    error("Unimplemented")
end

function paths.join(...)
    local parts = {}
    local n = select("#", ...)
    for i = 1, n do
        local path = select(i, ...)
        path = strip(path, paths.allsep)
        table.insert(parts, path)
    end
    return table.concat(parts, paths.sep)
end

-- https://github.com/python/cpython/blob/master/Lib/ntpath.py#L450
-- https://github.com/python/cpython/blob/master/Lib/posixpath.py#L331
function paths.normpath(path)
    path = path:gsub(paths.altsep, paths.sep)

    local parts = {}
    for part in path:gmatch("[^" .. paths.sep .. "]+") do
        table.insert(parts, part)
    end

    local i = 1
    while i <= #parts do
        if parts[i]:len() == 0 or parts[i] == "." then
            table.remove(parts, i)
        elseif parts[i] == ".." then
            -- this goes wrong if i == 1, but then the input was garbage
            i = i - 1
            table.remove(parts, i)
            table.remove(parts, i)
        else
            i = i + 1
        end
    end

    return table.concat(parts, paths.sep)
end

function paths.relpath(path, start)
    -- return the path to "path" relative to start
    error("Unimplemented")
end

function paths.splitext(path)
    local base = paths.basename(path)
    local lastDot = rfind(base, "%.")
    if not lastDot or lastDot == 1 then
        return path, ""
    else
        local ext = base:sub(lastDot)
        return path:sub(1, -ext:len() - 1), ext
    end
    -- returns a pair (root, ext) such that root + ext == path
    -- ext is empty r begins with a period and contains at most one period
    -- leading periods on the basename are ignored
    -- e.g. splitext('.cshrc') returns ('.cshrc', '').
end

return paths
