local message = {}

message.message = ""
message.messageError = false

function message.show(str, isError)
    message.message = str
    message.messageError = isError
    if isError then
        print("Error!", str)
    end
end

return message

