local clipboard = {}

local clipDataType = nil
local clipData = nil

function clipboard.set(dataType, data)
    assert(dataType == nil or dataType == "string" or
        dataType == "copyfiles" or dataType == "cutfiles")
    if dataType then
        assert(data)
    end
    clipDataType = dataType
    clipData = data
end

function clipboard.get()
    if clipDataType == nil or clipData == nil then
        return nil, nil
    else
        return clipDataType, clipData
    end
end

return clipboard
