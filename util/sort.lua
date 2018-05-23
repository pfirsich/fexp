-- I don't use table.sort, because I need a stable sort
function insertionSort(list, cmp)
    for i = 2, #list do
        local v = list[i]
        local j = i
        while j > 1 and cmp(v, list[j-1]) do
            list[j] = list[j-1]
            j = j - 1
        end
        list[j] = v
    end
end

return insertionSort
