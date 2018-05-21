local functional = {}

 function functional.map(func, tbl)
    local ret = {}
    for k, v in pairs(tbl) do
        ret[k] = func(v)
    end
    return ret
end

function functional.filter(func, tbl)
    local ret = {}
    for k ,v in pairs(tbl) do
        if func(v) then
            ret[k] = v
        end
    end
    return ret
end

return functional
