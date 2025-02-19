local addon, ns = ...



local TIMESTAMP_FILTER = 1735689600

local EXPORT_VERSION = 1




local TARGET_AREALOOTS_EXPORT_SIZE = 10000
local TARGET_BOUNTYDATA_EXPORT_SIZE = 10000
local TARGET_BOUNTYLOCALE_EXPORT_SIZE = 10000

local DataView = ns.DataView

local function parseAreaIdString(areaId)
    local areaRawID, difficultySize = string.match(areaId, "(%d+)%$(%d+)")
    return tonumber(areaRawID), tonumber(difficultySize) or 0
end

local function parseSourceIDString(sourceId)
    local sourceType, sourceRawID, harvestTypeID = string.match(sourceId, "(%d+)%-(%d+)%-(%d+)")
    return tonumber(sourceType), tonumber(sourceRawID), tonumber(harvestTypeID)
end

local function parseGameStr(game)
    local gamev, season, faction = string.match(game, "GAME%-(%d+)%-(%d+)%-(%d+)")
    return tonumber(gamev), tonumber(season), tonumber(faction)
end

local function serializeSection_AreaLoot()
    local v = DataView:new()
    local Db_lr = ns:DB_LootRegister()
    local length = 0
    local size = 0

    -- sort Db_lr with the most recent l child attribute first
    local Db_lr_lastTime = {}
    for areaIdDif, Sources in pairs(Db_lr) do
        local l = 0
        for _, source in pairs(Sources) do
            l = math.max(l, source.l)
        end
        table.insert(Db_lr_lastTime, { areaIdDif, l })
    end
    table.sort(Db_lr_lastTime, function(a, b) return a[2] > b[2] end)

    for _, areaIdDifLastTime in ipairs(Db_lr_lastTime) do
        local areaIdDif = areaIdDifLastTime[1]
        local Sources = Db_lr[areaIdDif]
        local areaRawID, difficulty = parseAreaIdString(areaIdDif)
        v.writeVarInt(areaRawID)  -- area ID
        v.writeInt(difficulty, 1) -- difficulty
        local sv = DataView:new()
        local sLengnth = 0
        for sourceId, source in pairs(Sources) do
            local sourceType, sourceRawID, harvestTypeID = parseSourceIDString(sourceId)
            sv.writeVarInt(sourceType)
            sv.writeVarInt(sourceRawID)
            sv.writeVarInt(harvestTypeID)
            sv.writeVarInt(source.k)
            sv.writeVarInt(source.sk)
            local lv = DataView:new()
            local lLength = 0
            for itemID, loot in pairs(source.loots) do
                lv.writeVarInt(itemID)
                lv.writeVarInt(loot.pc)
                lv.writeVarInt(loot.spc)
                lv.writeVarInt(loot.minQt)
                lv.writeVarInt(loot.maxQt)
                lLength = lLength + 1
            end
            sv.writeVarInt(lLength)
            sv.concat(lv.bin)
            local pLength = 0
            local pv = DataView:new()
            for posId, _ in pairs(source.pos) do
                pv.writeInt(posId, 2)
                pLength = pLength + 1
            end
            sv.writeVarInt(pLength)
            sv.concat(pv.bin)
            sLengnth = sLengnth + 1
        end
        v.writeVarInt(sLengnth)
        v.concat(sv.bin)
        length = length + 1
        size = size + 5 + strlen(sv.bin)
        if size > TARGET_AREALOOTS_EXPORT_SIZE then
            break
        end
    end
    return v.bin, length
end


local function serializeDataBounty_Areas(bounties)
    local v = DataView:new()
    local size = 0
    local length = 0;
    for areaID, bounty in pairs(bounties) do
        v.writeVarInt(areaID)                    -- area ID
        v.writeVarInt(bounty.value.cat)          -- area category
        v.writeVarInt(bounty.value.mapType or 0) -- map type
        length = length + 1
        size = size + 34 + strlen(bounty.value.cat)
        if size > TARGET_BOUNTYDATA_EXPORT_SIZE then
            break
        end
    end
    return v.bin, length
end

local function serializeDataBounty_Creatures(bounties)
    local v = DataView:new()
    local size = 0
    local length = 0;
    for creatureID, bounty in pairs(bounties) do
        v.writeVarInt(creatureID)
        v.writeVarInt(bounty.value.cl or 0) --npc Class
        v.writeVarInt(bounty.value.rx or 0) --npc player reaction (friendly, hostile, ...)
        v.writeVarInt(bounty.value.pT or 0) --npc power type (mana, rage, ...)
        v.writeVarInt(bounty.value.fc or 0) --npc faction
        v.writeVarInt(bounty.value.dI or 0) --npc display ID
        v.writeVarInt(bounty.value.tp or 0) --npc type (beast, humanoid, ...)
        local areaLength = 0
        local av = DataView:new()
        if bounty.value.a then
            for areaDiff, diffNpc in pairs(bounty.value.a) do
                local areaIDstr, diffStr = string.match(areaDiff, "(%d+)%$(%d+)")
                av.writeVarInt(tonumber(areaIDstr))
                av.writeInt(tonumber(diffStr), 1)
                av.writeVarInt(diffNpc.hp or 0)
                av.writeVarInt(diffNpc.pw or 0)  -- hp/power
                av.writeVarInt(diffNpc.lMn or 0)
                av.writeVarInt(diffNpc.lMx or 0) -- min/max level
                areaLength = areaLength + 1
                if areaLength > 16 then
                    break
                end
            end
        end
        v.writeVarInt(areaLength)
        v.concat(av.bin)

        length = length + 1
        size = size + 52
        if size > TARGET_BOUNTYDATA_EXPORT_SIZE then
            break
        end
    end
    return v.bin, length
end



local function serializeSection_BountyData()
    local v = DataView:new()
    local Db_db = ns:DB_DataBounty()
    local length = 0
    for dataBountyTypeID, bounties in pairs(Db_db) do
        if dataBountyTypeID == ns.DATA_BOUNTY_TYPE.AREA then
            v.writeVarInt(tonumber(ns.DATA_BOUNTY_TYPE.AREA))
            local bin, length, ssize = serializeDataBounty_Areas(bounties)
            v.writeVarInt(length)
            v.concat(bin)
        elseif dataBountyTypeID == ns.DATA_BOUNTY_TYPE.CREATURE then
            v.writeVarInt(tonumber(ns.DATA_BOUNTY_TYPE.CREATURE))
            local bin, length, ssize = serializeDataBounty_Creatures(bounties)
            v.writeVarInt(length)
            v.concat(bin)
        else
            break
        end
        length = length + 1
    end
    return v.bin, length
end

local function serializeSection_BountyLocale(locale)
    local v = DataView:new()
    local Db_lb = ns:DB_LocaleBounty()
    local length = 0
    local size = 0
    if Db_lb and Db_lb[locale] then
        for type_key, bounty in pairs(Db_lb[locale]) do
            local locale_bounty_type, key = string.match(type_key, "(%d+)%-(%d+)")
            v.writeVarInt(tonumber(locale_bounty_type))
            v.writeVarInt(tonumber(key))
            v.writeString(bounty.value)
            length = length + 1
            size = size + 8 + strlen(bounty.value)
            if size > TARGET_BOUNTYLOCALE_EXPORT_SIZE then
                break
            end
        end
    end
    return v.bin, length
end


function ns:Export(requiredAreaID)
    local gamev, season, faction = parseGameStr(self.game)
    local locale = GetLocale()
    local v = DataView:new()
    v.writeString("LOP")
    v.writeVarInt(EXPORT_VERSION)
    v.writeVarInt(ns.MAJOR)
    v.writeVarInt(ns.MINOR)
    v.writeVarInt(requiredAreaID or 0)
    v.writeVarInt(GetServerTime() - TIMESTAMP_FILTER)
    v.writeInt(bit.lshift(gamev, 1) + faction, 1)
    v.writeVarInt(season)
    v.writeString(locale)
    v.writeVarInt(3) -- section lentgh
    v.writeString("A")
    local bin, arealength = serializeSection_AreaLoot()
    v.writeVarInt(arealength)
    v.concat(bin)
    v.writeString("D")
    local bin, datalength = serializeSection_BountyData()
    v.writeVarInt(datalength)
    v.concat(bin)
    v.writeString("L")
    local bin, localelength = serializeSection_BountyLocale(locale)
    v.writeVarInt(localelength)
    v.concat(bin)
    ns:DEBUG("|cff77ff77 export size:" .. strlen(v.bin))
    v.writeSum8()
    return v.toBase64()
end
