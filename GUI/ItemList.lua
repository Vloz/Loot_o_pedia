--[[
Component used to diplay an itemsPool (from area or from mobs)
]]

local addonName, ns = ...

local LIST_FRAME_WIDTH = 300

local ITEM_FRAME_POOL_SIZE = 140
local ITEM_FRAME_WIDTH = 34
local ITEM_FRAME_MARGIN = 2
local ITEM_FRAME_ROW_MAXCOUNT = 8


local HEADER_FRAME_POOL_SIZE = 20
local HEADER_FRAME_HEIGHT = 18
local HEARDER_FRAME_MARGIN = 20

local itemFramePool;
local headerFramePool;

local currentAccentRGBA = ns.DEFAULT_ACC
local currentBgRGBA = ns.DEFAULT_BG

---@alias ItemListCategory { id:number, name : string, items : ItemData[], portrait?: string, portraitType?: PortraitType  , weight:number }
---@alias ItemData { weight : number, minQt : number, maxQt : number, itemId : number, dropRate : number? }

local ListFrame;

---@type ItemListCategory[]
local dataSource;

local onItemEnterCallback;
local onItemLeaveCallback;

function ns:InitItemList(frame)
    ListFrame = frame
    -- init pool of portrait for sources
    itemFramePool = {}
    for i = 1, ITEM_FRAME_POOL_SIZE do
        local itemFrame = CreateFrame("Button", "LOP_ItemFrame_" .. i, ListFrame,
            "LOP_ItemTemplate")
        itemFrame:SetSize(ITEM_FRAME_WIDTH, ITEM_FRAME_WIDTH)
        local col = (i - 1) % ITEM_FRAME_ROW_MAXCOUNT
        local row = math.floor((i - 1) / ITEM_FRAME_ROW_MAXCOUNT)
        itemFrame:SetPoint("TOPLEFT", ListFrame, "TOPLEFT",
            ITEM_FRAME_MARGIN * 2 + (ITEM_FRAME_WIDTH + ITEM_FRAME_MARGIN) * col,
            -(ITEM_FRAME_WIDTH + ITEM_FRAME_MARGIN) * row - ITEM_FRAME_MARGIN * 2)
        itemFrame:Show()
        itemFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.data.itemId)
            GameTooltip:Show()
            if self.enterCallback then
                self.enterCallback(self)
            end
        end)
        itemFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.leaveCallback then
                self.leaveCallback(self)
            end
        end)
        table.insert(itemFramePool, itemFrame)
    end
    headerFramePool = {}
    for i = 1, HEADER_FRAME_POOL_SIZE do
        local headerFrame = CreateFrame("Frame", "LOP_HeaderFrame_" .. i, ListFrame, "LOP_ItemListHeaderTemplate")
        headerFrame.title:SetText("Header " .. i)
        headerFrame:SetSize(LIST_FRAME_WIDTH, 20)
        headerFramePool[i] = headerFrame
    end
    ListFrame:Hide()
end

function ns:SetItemListDataSource(newDataSource, newOnItemEnter, newOnItemLeave, accHex, bgHex)
    dataSource = newDataSource
    onItemEnterCallback = newOnItemEnter
    onItemLeaveCallback = newOnItemLeave
    currentAccentRGBA = ns:hexToRGBA(accHex) or ns.DEFAULT_ACC
    currentBgRGBA = ns:hexToRGBA(bgHex) or ns.DEFAULT_BG
    ns:showItemListView()
end

function ns:showItemListView()
    for i, itemFrame in ipairs(itemFramePool) do
        itemFrame:Hide()
    end
    for i, headerFrame in ipairs(headerFramePool) do
        headerFrame:Hide()
    end
    local headerFrI = 1
    local itemFrI = 1
    local heightOffset = 0
    for catI, category in ipairs(dataSource) do
        if headerFrI < #headerFramePool then
            local headerFrame = headerFramePool[headerFrI]
            headerFrame.title:SetText(category.name)
            headerFrame.title:SetTextColor(unpack(currentAccentRGBA))
            headerFrame.line:SetColorTexture(currentAccentRGBA[1], currentAccentRGBA[2], currentAccentRGBA[3], 0.5)
            headerFrame:SetSize(LIST_FRAME_WIDTH, HEADER_FRAME_HEIGHT)
            headerFrame:SetPoint("TOPLEFT", ListFrame, "TOPLEFT", 0,
                -heightOffset - HEARDER_FRAME_MARGIN)
            if category.portrait then
                if category.portraitType == ns.PORTRAIT_TYPE.NPC_DISPLAYID then
                    SetPortraitTextureFromCreatureDisplayID(headerFrame.portrait, category.portrait, true)
                end
                headerFrame.portrait:SetTexCoord(0, 1, 0, 1)
                headerFrame.portrait:Show()
            else
                headerFrame.portrait:Hide()
            end

            headerFrame:Show()
            headerFrI = headerFrI + 1
            local itemDataArray = category.items

            local itemDisplayCount = 0
            for itemID, itemData in pairs(itemDataArray) do
                if itemFrI < #itemFramePool then
                    local itemFrame = itemFramePool[itemFrI]
                    itemFrame.enterCallback = onItemEnterCallback
                    itemFrame.leaveCallback = onItemLeaveCallback
                    itemFrame.icon:SetTexture(GetItemIcon(itemID))
                    if itemData.dropRate then
                        itemFrame.ratetext:SetText(itemData.dropRate .. "%")
                    else
                        itemFrame.ratetext:SetText("")
                    end
                    if itemData.minQt ~= 1 and itemData.maxQt ~= 1 then
                        if itemData.minQt == itemData.maxQt then
                            itemFrame.qttext:SetText(itemData.minQt)
                        else
                            itemFrame.qttext:SetText(itemData.minQt .. "-" .. itemData.maxQt)
                        end
                    else
                        itemFrame.qttext:SetText("")
                    end
                    itemFrame.data = itemData
                    local quality = C_Item.GetItemQualityByID(itemID)
                    if not quality or quality == 0 then
                        itemFrame.IconBorder:Hide()
                    else
                        local r, g, b = GetItemQualityColor(quality)
                        itemFrame.IconBorder:SetVertexColor(r, g, b, 1)
                        itemFrame.IconBorder:Show()
                    end
                    itemDisplayCount = itemDisplayCount + 1

                    local col = (itemDisplayCount - 1) % ITEM_FRAME_ROW_MAXCOUNT
                    local row = math.floor((itemDisplayCount - 1) / ITEM_FRAME_ROW_MAXCOUNT)
                    itemFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT",
                        ITEM_FRAME_MARGIN * 3 + (ITEM_FRAME_WIDTH + ITEM_FRAME_MARGIN) * col,
                        -(ITEM_FRAME_WIDTH + ITEM_FRAME_MARGIN) * row - ITEM_FRAME_MARGIN * 2)
                    itemFrame:Show()
                    itemFrI = itemFrI + 1
                end
            end
            heightOffset = heightOffset + HEADER_FRAME_HEIGHT + math.ceil(itemDisplayCount / ITEM_FRAME_ROW_MAXCOUNT) *
                (ITEM_FRAME_WIDTH + ITEM_FRAME_MARGIN) + HEARDER_FRAME_MARGIN
            --headerFrame:SetSize(LIST_FRAME_WIDTH, heightOffset)
        end
    end

    --[[ for i, headerFrame in ipairs(headerFramePool) do
        if i <= #dataSource then
            local category = dataSource[i]
            headerFrame:Show()
            headerFrame.title:SetText(category.name)
            print("Show header " .. category.name)
            headerFrame:SetSize(LIST_FRAME_WIDTH, HEADER_FRAME_HEIGHT)
            headerFrame:SetPoint("TOPLEFT", ListFrame, "TOPLEFT", 0,
                -HEADER_FRAME_HEIGHT * (i - 1) - ITEM_FRAME_MARGIN)
            local itemDataArray = category.items
            local itemDisplayCount = 0
            for j, itemFrame in ipairs(itemFramePool) do
                if j <= #itemDataArray then
                    itemFrame.enterCallback = onItemEnterCallback
                    itemFrame.leaveCallback = onItemLeaveCallback
                    local itemData = itemDataArray[j]
                    itemFrame.icon:SetTexture(GetItemIcon(itemData.itemId))
                    if itemData.dropRate then
                        itemFrame.ratetext:SetText(itemData.dropRate .. "%")
                    else
                        itemFrame.ratetext:SetText("")
                    end
                    if itemData.minQt ~= 1 and itemData.maxQt ~= 1 then
                        if itemData.minQt == itemData.maxQt then
                            itemFrame.qttext:SetText(itemData.minQt)
                        else
                            itemFrame.qttext:SetText(itemData.minQt .. "-" .. itemData.maxQt)
                        end
                    else
                        itemFrame.qttext:SetText("")
                    end
                    itemFrame.data = itemData
                    local quality = C_Item.GetItemQualityByID(itemData.itemId)
                    if not quality or quality == 0 then
                        itemFrame.IconBorder:Hide()
                    else
                        local r, g, b = GetItemQualityColor(quality)
                        itemFrame.IconBorder:SetVertexColor(r, g, b, 1)
                        itemFrame.IconBorder:Show()
                    end
                    itemDisplayCount = itemDisplayCount + 1
                    itemFrame:Show()
                else
                    itemFrame:Hide()
                end
            end
            headerFrame:SetSize(LIST_FRAME_WIDTH,
                HEADER_FRAME_HEIGHT + ITEM_FRAME_WIDTH * math.ceil(itemDisplayCount / ITEM_FRAME_ROW_MAXCOUNT))
        else
            headerFrame:Hide()
        end
    end ]]
    ListFrame:SetSize(LIST_FRAME_WIDTH,
        HEADER_FRAME_HEIGHT * #dataSource + ITEM_FRAME_WIDTH * math.ceil(#dataSource / ITEM_FRAME_ROW_MAXCOUNT))
    ListFrame:Show()
end

--[[ ---comment
---@param itemDataArray ItemData[]
function ns:ShowItemList(itemDataArray, enterCallback, leaveCallback)
    local itemDisplayCount = 0
    for i, itemFrame in ipairs(itemFramePool) do
        if i <= #itemDataArray then
            itemFrame.enterCallback = enterCallback
            itemFrame.leaveCallback = leaveCallback
            local itemData = itemDataArray[i]
            itemFrame.icon:SetTexture(GetItemIcon(itemData.itemId))
            if itemData.dropRate then
                itemFrame.ratetext:SetText(itemData.dropRate .. "%")
            else
                itemFrame.ratetext:SetText("")
            end
            if itemData.minQt ~= 1 and itemData.maxQt ~= 1 then
                if itemData.minQt == itemData.maxQt then
                    itemFrame.qttext:SetText(itemData.minQt)
                else
                    itemFrame.qttext:SetText(itemData.minQt .. "-" .. itemData.maxQt)
                end
            else
                itemFrame.qttext:SetText("")
            end
            itemFrame.data = itemData
            local quality = C_Item.GetItemQualityByID(itemData.itemId)
            if not quality or quality == 0 then
                itemFrame.IconBorder:Hide()
            else
                local r, g, b = GetItemQualityColor(quality)
                itemFrame.IconBorder:SetVertexColor(r, g, b, 1)
                itemFrame.IconBorder:Show()
            end
            itemDisplayCount = itemDisplayCount + 1
            itemFrame:Show()
        else
            itemFrame:Hide()
        end
    end
    ListFrame:SetSize(ITEM_FRAME_WIDTH * ITEM_FRAME_ROW_MAXCOUNT,
        ITEM_FRAME_WIDTH * math.ceil(itemDisplayCount / ITEM_FRAME_ROW_MAXCOUNT))
    ListFrame:Show()
end ]]
