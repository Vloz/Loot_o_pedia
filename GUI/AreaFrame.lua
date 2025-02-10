local addon, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale("LootOPedia")


---@type AreaLoots?
local areaLoots = nil

local areaLocales = nil


local function loadItemsData(filterSource)
    if not areaLoots then
        return nil
    end
    ---@type Difficulty
    local selectedDifficulty = areaLoots.difficulties[next(areaLoots.difficulties)]
    local itemDataMap = {}
    if selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature] then
        local sourceType = selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature]
        for sourceID, source in pairs(sourceType.sources) do
            if not filterSource or filterSource == sourceID then
                for harvestTypeID, harvestType in pairs(source.harvestTypes) do
                    for ItemId, loot in pairs(harvestType.loots) do
                        local itemData = itemDataMap[ItemId] or { weight = loot.weight }
                        if filterSource then
                            itemData.dropRate = loot.dropRate
                        end

                        itemData.minQt = math.min(itemData.minQt or loot.minQt, loot.minQt)
                        itemData.maxQt = math.max(itemData.maxQt or loot.maxQt, loot.maxQt)
                        itemDataMap[ItemId] = itemData
                    end
                end
            end
        end
    end
    local sortedItemData = {}
    for itemId, itemData in pairs(itemDataMap) do
        table.insert(sortedItemData,
            {
                itemId = itemId,
                sources = itemData.sources,
                minQt = itemData.minQt,
                maxQt = itemData.maxQt,
                weight =
                    itemData.weight,
                dropRate = itemData.dropRate
            })
    end
    table.sort(sortedItemData, function(a, b) return a.weight > b.weight end)
    return sortedItemData
end

local function loadPortraitData(filterItemID)
    if not areaLoots then
        return nil
    end
    ---@type Difficulty

    local selectedDifficulty = areaLoots.difficulties[next(areaLoots.difficulties)]
    local portraitDataArray = {}
    if selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature] then
        local sourceType = selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature]
        for sourceID, source in pairs(sourceType.sources) do
            ---@type PortraitData
            local portraitData = { type = sourceType, id = sourceID, weight = source.weight, loots = {} }
            for harvestTypeID, harvestType in pairs(source.harvestTypes) do
                for ItemId, loot in pairs(harvestType.loots) do
                    if filterItemID ~= nil and filterItemID == ItemId then
                        portraitData.include = true
                        portraitData.dropRate = loot.dropRate
                        portraitData.minQt = loot.minQt
                        portraitData.maxQt = loot.maxQt
                    end
                    portraitData.loots[ItemId] = {
                        harvestType = harvestType,
                        dropRate = loot.dropRate,
                        weight = loot.weight,
                        minQt =
                            loot.minQt,
                        maxQt = loot.maxQt
                    }
                end
            end
            if filterItemID == nil or portraitData.include then
                table.insert(portraitDataArray, portraitData)
            end
        end
    end
    table.sort(portraitDataArray, function(a, b) return a.weight > b.weight end)
    return portraitDataArray
end

function OnPortraitEnter(portrait)
    ns:ShowItemList(loadItemsData(portrait.data.id), OnItemEnter, OnItemLeave)
end

function OnPortraitLeave(portrait)
    ns:ShowItemList(loadItemsData(), OnItemEnter, OnItemLeave)
end

function OnItemEnter(item)
    ns:ShowPortraitList(loadPortraitData(item.data.itemId), 1, OnPortraitEnter, OnPortraitLeave)
end

function OnItemLeave(item)
    ns:ShowPortraitList(loadPortraitData(), 1, OnPortraitEnter, OnPortraitLeave)
end

function LootOPedia_ShowAreaTabFrame(self, areaId)
    areaLoots = nil
    areaLocales = nil
    if not areaId then
        areaId = ns:getAreaId()
    end
    if not ns:DB_Game().build then
        ns:SelectTab("LOP_update_Tab", { ns.UPDATETAB_ORIGIN.NO_BUILD })
    elseif not ns:DB_Game().build.areas[areaId] then
        ns:SelectTab("LOP_update_Tab", { ns.UPDATETAB_ORIGIN.AREA_UNKNOWN, areaId })
    elseif not ns:DB_Game().build.areas[areaId].bin or strlen(ns:DB_Game().build.areas[areaId].bin) < 16 then
        ns:SelectTab("LOP_update_Tab", { ns.UPDATETAB_ORIGIN.AREA_NOT_DL, areaId })
    else
        LOP_PortraitList:SetParent(LOP_AreaTabFrame)
        LOP_PortraitList:SetPoint("TOPLEFT", LOP_AreaTabFrame, "TOPLEFT", 20, -60)
        local rightPanel = LOP_AreaTabFrame.RightPanel.Container
        LOP_ItemList:SetParent(rightPanel)
        LOP_ItemList:SetAllPoints(rightPanel)
        rightPanel:SetSize(LOP_ItemList:GetWidth(), LOP_ItemList:GetHeight())
        local title = ns:DB_Game().build.areas[areaId].name or ns:areaLocNameFromId(areaId) or ("[" .. areaId .. "]")

        areaLoots = ns:ParseAreaLoot(ns:DB_Game().build.areas[areaId])
        --areaLocales = ns:ParseAreaLocales(ns:DB_Game().build.areas[areaId])
        local portraitDataArray = loadPortraitData()

        local itemDataArray = loadItemsData()
        ns:ShowPortraitList(portraitDataArray, 1, OnPortraitEnter, OnPortraitLeave)
        ns:ShowItemList(itemDataArray, OnItemEnter, OnItemLeave)
        rightPanel:SetSize(LOP_ItemList:GetWidth(), LOP_ItemList:GetHeight())
        LOP_AreaTabFrame.LeftPanel.TitleStr:SetText(title)
        LOP_AreaTabFrame:Show()
    end
end
