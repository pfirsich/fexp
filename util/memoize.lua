local function memoize(func)
    local cache = {}
    return function(arg)
        if not cache[arg] then
            cache[arg] = func(arg)
        end
        return cache[arg]
    end
end

return memoize
