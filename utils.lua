local addon, ns = ...

-- dict length
function ns:tgetn(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function ns:IsUnitCreature(unit)
    return UnitCreatureType(unit) ~= nil
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

-- Function to find a group unit by GUID, including "player"
function ns:GetUnitIDFromGUID(guid)
    -- Check if the GUID matches the player's own GUID
    if UnitGUID("player") == guid then
        return "player"
    end

    -- Check raid members (if in a raid, up to 40 members)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitGUID(unit) == guid then
                return unit
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = "party" .. i
            if UnitGUID(unit) == guid then
                return unit
            end
        end
    end

    return nil -- Return nil if no matching unit is found
end

--not available in math.
function ns:round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

ns.DEFAULT_ACC = { 1, 0.82, 0, 1 }   -- yellow wow
ns.DEFAULT_BGC = { 0.5, 0.5, 0.5, 1 }
