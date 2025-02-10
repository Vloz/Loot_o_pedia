local addon, ns = ...

-- dict length
function ns:tgetn(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end
