local time = {}

function time.now()
    return love.timer.getTime()
end

return time
