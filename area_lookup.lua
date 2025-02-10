local addon, ns = ...

local previousAreaId;

ns.MAP_UNIVERSAL_ID_OFFSET = 0x4000



--- Return area id (add 0x4000 for classic instance)
--- @return number
function ns:getAreaId()
    local id = C_Map.GetBestMapForUnit("player");
    if id ~= nil then
        return id
    else
        _, _, _, _, _, _, _, id = GetInstanceInfo()
        if id ~= nil then
            return ns.MAP_UNIVERSAL_ID_OFFSET + id --merging old Map system ID with the new one
        else
            error("Couldnt get area id for the current area")
        end
    end
end

--- Return the name of the area from the Globalid
--- @param id number
function ns:areaLocNameFromId(id)
    if id < 0x4000 then
        return C_Map.GetMapInfo(id).name
    else
        return GetRealZoneText(id - ns.MAP_UNIVERSAL_ID_OFFSET)
    end
end

function ns:getAreaDiff(sourceType)
    local areaDiff
    local _, _, difficultyID, _, maxPlayers = GetInstanceInfo()
    if sourceType == ns.SOURCE_TYPE.Item then -- if the source is a bag item we considere being opened everywhere
        areaDiff = "0"
    else
        areaDiff = ns:getAreaId()
    end
    --[[     if harvestType ~= ns.HARVEST_TYPE.Loot or not IsInRaidOrGroup() or GetLootMethod() == "freeforall" then
        area = area .. "#0"
    else
        area = area .. "#" .. GetLootThreshold()
    end ]]
    if difficultyID == 0 then
        areaDiff = areaDiff .. "$0"
    else
        local rsize = (maxPlayers / 5) - 1
        local size = rsize < 0 and 0 or rsize
        local difSize = bit.band(bit.lshift(size, 3), 0xF8) + bit.band(difficultyID, 0x07) -- 0x7 = 0b111
        areaDiff = areaDiff .. "$" .. difSize
    end
    return areaDiff
end

local function saveAreaBountyLocale()
    local areaId = ns:getAreaId()
    local areaName = ns:areaLocNameFromId(areaId)
    ns:SaveLocaleBounty(ns.LOCALE_BOUNTY_TYPE.AREA_NAME, areaId, areaName)
end

ns.AREA_CATEGORY_TYPE = {
    UNKNOWN = 0,
    ZONE = 1,
    DUNGEON = 2,
    RAID = 3,
    MICRODUNGEON = 4,
    CONTINENT = 5
}


local function saveDungeonBountyData(id, name)
    local _, instanceType = GetInstanceInfo()
    local category;
    if instanceType == "party" then
        category = ns.AREA_CATEGORY_TYPE.DUNGEON
    elseif instanceType == "raid" then
        category = ns.AREA_CATEGORY_TYPE.RAID
    else
        category = ns.AREA_CATEGORY_TYPE.UNKNOWN
    end
    ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.AREA, id,
        { name = name, cat = category, mapType = Enum.UIMapType.Dungeon })
end

local function getContinentForMapId(mapId)
    local mapInfo = C_Map.GetMapInfo(mapId)
    if not mapInfo then
        return 0 -- bg map
    end
    if mapInfo.mapType == Enum.UIMapType.Continent then
        return mapId
    else
        return getContinentForMapId(mapInfo.parentMapID)
    end
end

local function saveAreaBountyData()
    local id = ns:getAreaId()
    if id < ns.MAP_UNIVERSAL_ID_OFFSET then
        local MapInfo = C_Map.GetMapInfo(id)
        local name = MapInfo.name
        local mapType = MapInfo.mapType
        if mapType == Enum.UIMapType.Dungeon then
            saveDungeonBountyData(name)
        elseif mapType == Enum.UIMapType.MicroDungeon then
            ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.AREA, id,
                { name = name, cat = ns.AREA_CATEGORY_TYPE.MICRODUNGEON, mapType = mapType })
        elseif mapType == Enum.UIMapType.Zone then
            ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.AREA, id,
                { name = name, cat = getContinentForMapId(id), mapType = mapType })
        elseif mapType == Enum.UIMapType.Continent then
            ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.AREA, id,
                { name = name, cat = ns.AREA_CATEGORY_TYPE.CONTINENT, mapType = mapType })
        else
            ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.AREA, id,
                { name = name, cat = ns.AREA_CATEGORY_TYPE.UNKNOWN, mapType = mapType })
        end
    else -- Classic instance
        local name = GetRealZoneText(id - ns.MAP_UNIVERSAL_ID_OFFSET)
        saveDungeonBountyData(id, name)
    end
end


local function AreaChanged(areaId)
    if ns.scanned and not ns.scanned[ns.SCANNED_TYPE.AREA][areaId] then
        local areaName = ns:areaLocNameFromId(areaId)
        saveAreaBountyLocale()
        saveAreaBountyData()
    end
end



local function CheckAreaChanged()
    local areaId = ns:getAreaId()
    if previousAreaId ~= areaId then
        previousAreaId = areaId
        AreaChanged(areaId)
    end
end
local function ZONE_CHANGED_NEW_AREA()
    CheckAreaChanged()
end

local function PLAYER_ENTERING_WORLD()
    CheckAreaChanged()
end

LootOPedia:RegisterEvent("ZONE_CHANGED_NEW_AREA", ZONE_CHANGED_NEW_AREA)
LootOPedia:RegisterEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
