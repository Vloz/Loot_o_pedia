local addon, ns = ...


local base64 = LibStub('LibBase64-1.0')

local DataView = ns.DataView

function ns:Import(strBin)
    local bin = base64:decode(strBin)
    local v = DataView:new(bin)
    local magic = v.readString()
    local versionMajor = v.readVarInt()
    local versionMinor = v.readVarInt()
    local build = ns:DB_Game().build or { areas = {} }
    --local scannedStr = v.readString()
    --build.scannedBin = scannedStr
    local areaCount = v.readVarInt()
    for i = 1, areaCount, 1 do
        local areaId = v.readVarInt()
        if not build.areas[areaId] then
            build.areas[areaId] = {}
        end
        --local areaName = v.readString()
        local areaTypeIsScanned = v.readInt(1)
        local areaType = bit.band(areaTypeIsScanned, 0x7F)
        local isScanned = bit.band(areaTypeIsScanned, 0x80) == 0x80
        local areaCat = v.readVarInt()
        build.areas[areaId].mapType = areaType
        build.areas[areaId].cat = areaCat
        if areaType ~= Enum.UIMapType.Continent then
            local lvlLen = v.readVarInt()
            local lvl = {}
            for j = 1, lvlLen, 1 do
                local req = v.readVarInt()
                local gear = v.readVarInt()
                table.insert(lvl, { req, gear })
            end
            --local lstr = v.readString()
            build.areas[areaId].lvl = lvl
            build.areas[areaId].scn = isScanned
        end
    end
    local areabinCount = v.readVarInt()

    for i = 1, areabinCount, 1 do
        local areaId = v.readVarInt()
        local areaBin = v.readVarBin()
        local areaBinStr = base64:encode(areaBin)
        build.areas[areaId].bin = areaBinStr
    end
    ns:DB_Game().build = build
end
