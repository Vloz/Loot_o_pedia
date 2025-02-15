local addon, ns = ...

-- dict length
function ns:tgetn(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function ns:hexToRGBA(hex)
    -- Ensure the hex code is in the correct format
    local shortHex = hex:match("#(%x+)")
    if not shortHex or (#shortHex ~= 3 and #shortHex ~= 4) then
        return nil, "Invalid hex format"
    end

    -- Expand short hex format (#RGB or #RGBA to #RRGGBB or #RRGGBBAA)
    if #shortHex == 3 then
        shortHex = shortHex:sub(1, 1) .. shortHex:sub(1, 1) ..
            shortHex:sub(2, 2) .. shortHex:sub(2, 2) ..
            shortHex:sub(3, 3) .. shortHex:sub(3, 3) .. "FF"
    elseif #shortHex == 4 then
        shortHex = shortHex:sub(1, 1) .. shortHex:sub(1, 1) ..
            shortHex:sub(2, 2) .. shortHex:sub(2, 2) ..
            shortHex:sub(3, 3) .. shortHex:sub(3, 3) ..
            shortHex:sub(4, 4) .. shortHex:sub(4, 4)
    else
        return nil, "Invalid short hex format"
    end

    -- Convert to RGBA values (0-255)
    local r = tonumber(shortHex:sub(1, 2), 16) / 255
    local g = tonumber(shortHex:sub(3, 4), 16) / 255
    local b = tonumber(shortHex:sub(5, 6), 16) / 255
    local a = tonumber(shortHex:sub(7, 8), 16) / 255

    return { r, g, b, a } -- Return with alpha
end
