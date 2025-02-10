local addon, ns = ...

local AceConsole = LibStub("AceConsole-3.0")


---@enum SourceTypeID
ns.SOURCE_TYPE = {
    Creature = "1",
    GameObject = "2",
    Item = "3"
}

---@enum HarvestTypeID
ns.HARVEST_TYPE = {
    Loot = "1",
    Skinning = "2",
    Enchanting = "3",
    Mining = "4",
    Herbalism = "5",
    Engineering = "6",
    Fishing = "7",
    Pocket = "8",
    Archaeology = "9",
    Prospecting = "10"
}

local HARVEST_SPELLS = {

    [2575] = ns.HARVEST_TYPE.Mining,
    [2576] = ns.HARVEST_TYPE.Mining,
    [2577] = ns.HARVEST_TYPE.Mining,
    [2578] = ns.HARVEST_TYPE.Mining,
    [2579] = ns.HARVEST_TYPE.Mining,
    [3564] = ns.HARVEST_TYPE.Mining,
    [10248] = ns.HARVEST_TYPE.Mining,
    [13611] = ns.HARVEST_TYPE.Mining,

    [8613] = ns.HARVEST_TYPE.Skinning,
    [8617] = ns.HARVEST_TYPE.Skinning,
    [8618] = ns.HARVEST_TYPE.Skinning,
    [10768] = ns.HARVEST_TYPE.Skinning,
    [32678] = ns.HARVEST_TYPE.Skinning,
    [50305] = ns.HARVEST_TYPE.Skinning,
    [74522] = ns.HARVEST_TYPE.Skinning,

    [2366] = ns.HARVEST_TYPE.Herbalism,
    [2368] = ns.HARVEST_TYPE.Herbalism,
    [3570] = ns.HARVEST_TYPE.Herbalism,

    [921] = ns.HARVEST_TYPE.Pocket,
    [5167] = ns.HARVEST_TYPE.Pocket
    -- Add more IDs if needed
}


local last_harvest = nil     -- return the last "harvest spell" with timestamp
local last_item_locked = nil -- to know wich in-bag item (tiny chest, disenchant) is being opened

local function IsInRaidOrGroup()
    return IsInRaid() or IsInGroup()
end

local function slotItemId(slotIndex)
    local itemLink = GetLootSlotLink(slotIndex)
    if itemLink then
        -- Extract the item ID using string matching
        local itemID = itemLink:match("item:(%d+)")
        return itemID
    end
    return nil;
end

local function getSourceTypedId(guidSource)
    local sourceType, _ = strsplit("-", guidSource) --- ERROR HERE
    if sourceType == "Creature" then
        local _, _, _, _, _, npc_id, _ = strsplit("-", guidSource)
        return ns.SOURCE_TYPE.Creature, npc_id
    elseif sourceType == "GameObject" then
        local _, _, _, _, _, object_id, _ = strsplit("-", guidSource)
        return ns.SOURCE_TYPE.GameObject, object_id
    elseif sourceType == "Item" then
        local _, _, _, _, _, npc_id, _ = strsplit("-", guidSource) -- part 6 creature is npc id
        if last_item_locked then
            return ns.SOURCE_TYPE.Item, last_item_locked.itemID
        else
            return nil
        end
    else
        return nil
    end
end



local function getHarvestType(guidSource, lootTime)
    if last_harvest and lootTime - last_harvest.t < 0.600 then -- succeeded harvest
        local htype = last_harvest.type
        last_harvest = nil
        return htype
    elseif last_harvest and lootTime - last_harvest.t > 0.600 and lootTime - last_harvest.t < 2 then -- Ambiquitous, cant tell if harvested or loot return nil to skip loot
        last_harvest = nil
        return nil
    elseif not ns:DB_LootedGuids()[guidSource] then
        return ns.HARVEST_TYPE.Loot
    else                                     -- npc already harvested, return same harvest mode if it was post kill
        local prev = ns:DB_LootedGuids()[guidSource]
        if prev[ns.HARVEST_TYPE.Pocket] then -- We skip mobs that got pickpocked because PickPocket loot can be mixed with corpse loot once dead
            return nil
        end
        return prev[ns.HARVEST_TYPE.Skinning] and ns.HARVEST_TYPE.Skinning or prev[ns.HARVEST_TYPE.Mining] and
            ns.HARVEST_TYPE.Mining or prev[ns.HARVEST_TYPE.Herbalism] and ns.HARVEST_TYPE.Herbalism or
            prev[ns.HARVEST_TYPE.Engineering] and ns.HARVEST_TYPE.Engineering or ns.HARVEST_TYPE.Loot
    end
end



local function setHarvestDone(guid, harvestType)
    local Db_lg = ns:DB_LootedGuids()
    if not Db_lg[guid] then
        Db_lg[guid] = {}
    end
    Db_lg[guid][harvestType] = true
end

---Try to prefetch loots information ASAP before any other autoloot addon
---@return table
local function prefetchSourcesLoots()
    local numLootItems = GetNumLootItems()
    local r = {}
    for slot = 1, numLootItems, 1 do
        local guidSource, quantity = GetLootSourceInfo(slot)
        if guidSource then
            if not r[guidSource] then
                r[guidSource] = {}
            end
            local itemID = slotItemId(slot)
            local sourceType, sourceId = getSourceTypedId(guidSource)
            local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive =
                GetLootSlotInfo(slot)
            if sourceType and guidSource and lootName then
                r[guidSource][tostring(slot)] = { quantity, itemID, sourceType, sourceId, isQuestItem, lootQuality,
                    lootName }
            end
        else -- if no sourceGUID
            -- Autoloot too fast couldnt retrieve item id
        end
    end
    return r
end

-- If harvestType != loot or any loot quality < threshold (and not questItem), or freeforall, considere it owned
local function playerOwnLoot(harvestType, loots)
    if (not IsInRaidOrGroup() or harvestType ~= ns.HARVEST_TYPE.Loot) then
        return true
    end
    local thresholt = GetLootThreshold()
    for slot, v in pairs(loots) do
        local quantity, itemID, sourceType, sourceId, isQuestItem, lootQuality = unpack(v)
        if lootQuality < thresholt and not isQuestItem then
            return true
        end
    end
    return false
end

local function increaseHarvestCount(areaID, type_source_harvest, owntheloot)
    local timestamp = GetServerTime()
    local Db_lr = ns:DB_LootRegister()
    if not Db_lr[areaID] then
        Db_lr[areaID] = {}
    end
    if not Db_lr[areaID][type_source_harvest] or Db_lr[areaID][type_source_harvest].l < timestamp - 604800 then
        Db_lr[areaID][type_source_harvest] = { k = 0, sk = 0, l = timestamp, loots = {} }
    end
    if not IsInRaidOrGroup() or owntheloot then
        ns:DEBUG("|cffff7777 KILL++ " .. type_source_harvest)
        Db_lr[areaID][type_source_harvest].k = Db_lr[areaID][type_source_harvest].k + 1 -- solo kill
    else
        ns:DEBUG("|cffff7777 SKILL++ " .. type_source_harvest)
        Db_lr[areaID][type_source_harvest].sk = Db_lr[areaID][type_source_harvest].sk + 1 -- sharedKill
    end
end

local function increaseItemLootCount(area, type_source_harvest, owntheloot, itemID, quantity, itemName)
    local timestamp = GetServerTime()
    local Db_source_loots = ns:DB_LootRegister()[area][type_source_harvest].loots;
    if not Db_source_loots[itemID] then
        Db_source_loots[itemID] = { minQt = quantity, maxQt = quantity, pc = 0, spc = 0 }
    end
    if quantity < Db_source_loots[itemID].minQt then
        Db_source_loots[itemID].minQt = quantity
    end
    if quantity > Db_source_loots[itemID].maxQt then
        Db_source_loots[itemID].maxQt = quantity
    end
    if owntheloot then
        ns:DEBUG("|cff00ff00 LOOT++ " ..
            string.format("\124cffffffff\124Hitem:%d::::::::::::1\124h[%s]\124h\124r", itemID, itemName))
        Db_source_loots[itemID].pc = Db_source_loots[itemID].pc + 1
    else
        ns:DEBUG("|cff00ff00 SLOOT++ " ..
            string.format("\124cffffffff\124Hitem:%d::::::::::::1\124h[%s]\124h\124r", itemID, itemName))
        Db_source_loots[itemID].spc = Db_source_loots[itemID].spc + 1
    end
end

-- This happend to get called twice sometimes (maybe in lag flagged situation)
local function LOOT_READY(...)
    local t = GetTime()
    local sources_loots = prefetchSourcesLoots() -- Try to load ASAP data before item gets autolooted

    if ns:tgetn(sources_loots) == 0 then         -- for empty container to still count the kill
        local guidSource = UnitGUID("target")
        sources_loots[guidSource] = {}
    end
    for guidSource, loots in pairs(sources_loots) do
        local sourceType, sourceId = getSourceTypedId(guidSource)
        local harvestType = getHarvestType(guidSource, t)
        local area = ns:getAreaDiff(sourceType)
        if not harvestType then -- skip ambiquitous harvest type
            ns:DEBUG("|cffff7777 ambiquitous harvest... SKIPPP.")
            setHarvestDone(guidSource, ns.HARVEST_TYPE.Loot)
        elseif not ns:DB_LootedGuids()[guidSource] or not ns:DB_LootedGuids()[guidSource][harvestType] then
            local type_source_harvest = sourceType .. "-" .. sourceId .. "-" .. harvestType
            setHarvestDone(guidSource, harvestType)
            local owntheloot = playerOwnLoot(loots)
            increaseHarvestCount(area, type_source_harvest, harvestType)
            for slot, v in pairs(loots) do
                local quantity, itemID, sourceType, sourceId, isQuestItem, lootQuality, lootName = unpack(v)
                if itemID and not isQuestItem then
                    increaseItemLootCount(area, type_source_harvest, owntheloot, itemID, quantity, lootName)
                end
            end
        end
    end
end

-- If a harvest spell succeed we store the npc guid so its next loot windows is considered as pure loot
local function UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if unit == "player" and HARVEST_SPELLS[spellID] then
        last_harvest = {
            t = GetTime(),
            type = HARVEST_SPELLS[spellID]
        }
    end
end

local function ITEM_LOCKED(event, bag, slot) -- to know wich in-bag item (tiny chest, disenchant) is being opened
    last_item_locked = C_Container.GetContainerItemInfo(bag, slot) or nil
end

LootOPedia:RegisterEvent("LOOT_READY", LOOT_READY)
LootOPedia:RegisterEvent("ITEM_LOCKED", ITEM_LOCKED)
LootOPedia:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", UNIT_SPELLCAST_SUCCEEDED)
