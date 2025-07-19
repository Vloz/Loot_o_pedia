local addon, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale("LootOPedia")


---@type AreaLoots?
local areaLoots = nil

---@types AreaCache?
local areaCache = nil


local frame;
local mapFrame;
local leftContainer;
local rightContainer;
local currentAccentColor = nil;
local currentBgColor = nil;

ns.EJBG_TYPE = {
    o = 1, --Official bgFile
    c = 2  --Custom bgFile
}
ns.AreaPresets = {
    [1423] = { --EPLAGUELANDS
        bgC = "#542",
        acC = "#f83",
        bgt = "c",
        bgv = "EPLAGUELANDS"
    },
    [1426] = { --DUNMOROGH
        bgC = "#09f",
        acC = "#fff",
        bgt = "c",
        bgv = "DUNMOROGH"
    },
    [1428] = { --BURNINGSTEPPES
        bgC = "#732",
        acC = "#f43",
        bgt = "c",
        bgv = "BURNINGSTEPPES"
    },
    [1429] = { --ELWYNN
        bgC = "#263",
        acC = "#0ef",
        bgt = "c",
        bgv = "ELWYNN"
    },
    [1436] = { --WESTFALL
        bgC = "#851",
        acC = "#fe0",
        bgt = "c",
        bgv = "WESTFALL"
    },

    [16633] = { --ONY60
        bgC = "#654",
        acC = "#e34",
        bgt = "o",
        bgv = "OnyxiasLair"
    },

    [16693] = { --ZG
        bgC = "#375",
        acC = "#f83",
        bgt = "o",
        bgv = "ZulGurub"
    },

    [16793] = { --MC
        bgC = "#822",
        acC = "#d62",
        bgt = "o",
        bgv = "MoltenCore"
    },
    [16853] = { --BWL
        bgC = "#754",
        acC = "#fc2",
        bgt = "o",
        bgv = "BlackwingLair"
    },
    [16893] = { --AQ20
        bgC = "#a72",
        acC = "#d62",
        bgt = "o",
        bgv = "RuinsofAhnQiraj"
    },
    [16915] = { --AQ40
        bgC = "#85a",
        acC = "#ee9",
        bgt = "o",
        bgv = "TempleofAhnQiraj"
    },
    [16917] = { --NAXX
        bgC = "#063",
        acC = "#f9f",
        bgt = "o",
        bgv = "Naxxramas"
    }
}

---comment
---@return ItemListCategory[]
local function loadItemsData()
    if not areaLoots then
        return nil
    end
    ---@type Difficulty
    local selectedDifficulty = areaLoots.difficulties[next(areaLoots.difficulties)]
    ---@type ItemListCategory[]
    local categories = {}
    if selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature] then
        local sourceType = selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature] --TODO: Select source type here
        for sourceID, source in pairs(sourceType.sources) do
            ---@type ItemListCategory
            local category = {
                id = sourceID,
                name = "[ID " .. sourceID .. "]",
                items = {},
                portrait = nil,
                portraitType = nil,
                weight = 0
            }
            if true then --TODO SET PORTRAIT DEPENDING ON SOURCE_TYPE
                category.portraitType = ns.PORTRAIT_TYPE.NPC_DISPLAYID
                category.portrait = ns:GetNpcDisplayId(sourceID, areaCache)
            end
            for harvestTypeID, harvestType in pairs(source.harvestTypes) do
                for ItemId, loot in pairs(harvestType.loots) do
                    local itemData = { weight = loot.weight, itemId = ItemId }
                    itemData.dropRate = loot.dropRate

                    itemData.minQt = math.min(itemData.minQt or loot.minQt, loot.minQt)
                    itemData.maxQt = math.max(itemData.maxQt or loot.maxQt, loot.maxQt)
                    category.weight = category.weight + itemData.weight
                    category.items[ItemId] = itemData
                end
            end
            table.insert(categories, category)
        end
    end
    return categories
end


--[[ local function loadItemsData(filterSource)
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
end ]]

local function loadPortraitData(sourceTypeId, filterItemID)
    if not areaLoots then
        return nil
    end
    if sourceTypeId == nil then
        sourceTypeId = ns.SOURCE_TYPE.Creature
    end
    ---@type Difficulty
    local selectedDifficulty = areaLoots.difficulties[next(areaLoots.difficulties)]
    local portraitDataArray = {}
    if selectedDifficulty.sourceTypes[sourceTypeId] then
        local sourceType = selectedDifficulty.sourceTypes[ns.SOURCE_TYPE.Creature]
        for sourceID, source in pairs(sourceType.sources) do
            ---@type PortraitData
            local portraitData = {
                type = nil,
                value = nil,
                id = sourceID,
                weight = source.weight,
                loots = {},
                class = source
                    .class,
                faction = source.faction,
                lvlmin = source.lvlmin,
                portraitType = nil,
                portrait = nil
            }
            if sourceTypeId == ns.SOURCE_TYPE.Creature then
                portraitData.type = ns.PORTRAIT_TYPE.NPC_DISPLAYID
                portraitData.value = ns:GetNpcDisplayId(sourceID, areaCache)
            end
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
    --ns:ShowItemList(loadItemsData(portrait.data.id), OnItemEnter, OnItemLeave)
end

function OnPortraitLeave(portrait)
    --ns:ShowItemList(loadItemsData(), OnItemEnter, OnItemLeave)
end

function OnItemEnter(item)
    --ns:ShowPortraitList(loadPortraitData(item.data.itemId), nil, OnPortraitEnter, OnPortraitLeave, currentBgColor)
end

function OnItemLeave(item)
    --ns:ShowPortraitList(loadPortraitData(), 1, OnPortraitEnter, OnPortraitLeave, currentBgColor)
end

function LootOPedia_ShowAreaTabFrame(self, areaId)
    areaLoots = nil
    areaLocales = nil
    if not areaId then
        areaId = ns:getAreaId()
    end
    if ns:IsC_Map(areaId) then -- skip for classic dungeons
        LOP_MapFrame:SetParent(leftContainer)
        LOP_MapFrame:SetPoint("TOP", leftContainer, "TOP", 0, -40)
        LOP_MapFrame:SetFrameLevel(leftContainer:GetFrameLevel())
        LOP_MapFrame:SetMapID(areaId)
        LOP_MapFrame:Show()
    end
    print("AreaId: " .. areaId)
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
        currentBgColor = "#555"
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
        LOP_PortraitList:SetPoint("BOTTOM", leftContainer, "BOTTOM", 0, 10)
        LOP_PortraitList:SetFrameLevel(frame:GetFrameLevel() + 2)
        LOP_PortraitList.BGTx:SetVertexColor(unpack(ns:hexToRGBA(currentBgColor)))
        local rightPanel = frame.RightPanel.Container
        LOP_ItemList:SetParent(rightPanel)
        LOP_ItemList:SetAllPoints(rightPanel)
        local title = ns:DB_Game().build.areas[areaId].name or ns:areaLocNameFromId(areaId) or ("[" .. areaId .. "]")

        areaLoots = ns:ParseAreaLoot(ns:DB_Game().build.areas[areaId])
        areaCache = ns:ParseAreaCache(ns:DB_Game().build.areas[areaId])
        local portraitDataArray = loadPortraitData()

        local itemDataArray = loadItemsData()
        ns:ShowPortraitList(portraitDataArray, 1, OnPortraitEnter, OnPortraitLeave, currentBgColor)
        ns:SetItemListDataSource(itemDataArray, OnItemEnter, OnItemLeave, currentAccentColor, currentBgColor)
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
