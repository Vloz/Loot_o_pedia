local addon, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale("LootOPedia")


---@type AreaLoots?
local areaLoots = nil

local areaLocales = nil
local frame;
local leftContainer;
local rightContainer;
local currentAccentColor = nil;
local currentBgColor = nil;

ns.EJBG_TYPE = {
    o = 1, --Official bgFile
    c = 2  --Custom bgFile
}
ns.AreaPresets = {
    [1429] = { --ELWYNN
        bgC = "#263",
        acC = "0ef",
        bgt = "c",
        bgv = "ELWYNN"
    },
    [1436] = { --WESTFALL
        bgC = "#851",
        acC = "#fe0",
        bgt = "c",
        bgv = "WESTFALL"
    }

}


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
            local portraitData = {
                type = sourceType,
                id = sourceID,
                weight = source.weight,
                loots = {},
                class = source
                    .class,
                faction = source.faction,
                lvlmin = source.lvlmin
            }
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
    ns:ShowPortraitList(loadPortraitData(item.data.itemId), nil, OnPortraitEnter, OnPortraitLeave, currentBgColor)
end

function OnItemLeave(item)
    ns:ShowPortraitList(loadPortraitData(), 1, OnPortraitEnter, OnPortraitLeave, currentBgColor)
end

function LootOPedia_ShowAreaTabFrame(self, areaId)
    areaLoots = nil
    areaLocales = nil
    if not areaId then
        areaId = ns:getAreaId()
    end
    if ns.AreaPresets[areaId] then
        local preset = ns.AreaPresets[areaId]
        if preset.bgt == "o" then
            self.LeftPanel.bgtxt:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BACKGROUND-" .. preset.bgv)
        else
            self.LeftPanel.bgtxt:SetTexture("Interface\\AddOns\\Loot_o_pedia\\media\\ej_bg\\EJ_" .. preset.bgv .. ".png")
        end
        self.LeftPanel.bgtxt:SetTexCoord(0, 0.76, 0, 0.83)
        self.LeftPanel.bgtxt:SetSize(303, 337)
        self.LeftPanel.bgtxt:SetPoint("TOPLEFT", self.LeftPanel, "TOPLEFT", 0, 0)
        self.LeftPanel.bgtxt:Show()
        currentAccentColor = preset.acC
        currentBgColor = preset.bgC
    else
        currentAccentColor = "#fff"
        currentBgColor = "#000"
        self.LeftPanel.bgtxt:Hide()
    end
    if not ns:DB_Game().build then
        ns:SelectTab("LOP_update_Tab", { ns.UPDATETAB_ORIGIN.NO_BUILD })
    elseif not ns:DB_Game().build.areas[areaId] then
        ns:SelectTab("LOP_update_Tab", { ns.UPDATETAB_ORIGIN.AREA_UNKNOWN, areaId })
    elseif not ns:DB_Game().build.areas[areaId].bin or strlen(ns:DB_Game().build.areas[areaId].bin) < 16 then
        ns:SelectTab("LOP_update_Tab", { ns.UPDATETAB_ORIGIN.AREA_NOT_DL, areaId })
    else
        LOP_PortraitList:SetParent(leftContainer)
        LOP_PortraitList:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -190)
        LOP_PortraitList:SetFrameLevel(frame:GetFrameLevel() + 2)
        LOP_PortraitList.BGTx:SetVertexColor(unpack(ns:hexToRGBA(currentBgColor)))
        local rightPanel = frame.RightPanel.Container
        LOP_ItemList:SetParent(rightPanel)
        LOP_ItemList:SetAllPoints(rightPanel)
        rightPanel:SetSize(LOP_ItemList:GetWidth(), LOP_ItemList:GetHeight())
        local title = ns:DB_Game().build.areas[areaId].name or ns:areaLocNameFromId(areaId) or ("[" .. areaId .. "]")

        areaLoots = ns:ParseAreaLoot(ns:DB_Game().build.areas[areaId])
        --areaLocales = ns:ParseAreaLocales(ns:DB_Game().build.areas[areaId])
        local portraitDataArray = loadPortraitData()

        local itemDataArray = loadItemsData()
        ns:ShowPortraitList(portraitDataArray, 1, OnPortraitEnter, OnPortraitLeave, currentBgColor)
        ns:ShowItemList(itemDataArray, OnItemEnter, OnItemLeave)
        rightPanel:SetSize(LOP_ItemList:GetWidth(), LOP_ItemList:GetHeight())
        leftContainer.TitleStr:SetText(title)
        frame:Show()
    end
end

function ns:AreaFrameOnLoad(f)
    frame = f
    leftContainer = frame.LeftPanel.Container
    leftContainer:SetSize(303, 337)
    rightContainer = frame.RightPanel.Container

    leftContainer.TitleStr = leftContainer:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    leftContainer.TitleStr:SetPoint("TOPLEFT", leftContainer, "TOPLEFT", 10, -10)
    leftContainer.TitleStr:SetSize(303, 20)
    leftContainer.TitleStr:SetJustifyH("LEFT")
    leftContainer.TitleStr:SetText("Area")
    leftContainer:Show()
end
