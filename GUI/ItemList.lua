--[[
Component used to diplay an itemsPool (from area or from mobs)
]]

addonName, ns = ...

local ITEM_FRAME_POOL_SIZE = 140
local ITEM_FRAME_WIDTH = 40
local ITEM_FRAME_MARGIN = 2
local ITEM_FRAME_ROW_MAXCOUNT = 7

local itemFramePool;

---@alias ItemData { weight : number, minQt : number, maxQt : number, itemId : number, dropRate : number? }

local ListFrame;


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
        --[[         local highlightTexture = itemFrame:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetBlendMode("ADD")
        itemFrame:SetHighlightTexture(highlightTexture) ]]
        table.insert(itemFramePool, itemFrame)
    end
    --[[ ListFrame:SetSize(ITEM_FRAME_WIDTH * ITEM_FRAME_ROW_MAXCOUNT,
        ITEM_FRAME_WIDTH * math.ceil(ITEM_FRAME_POOL_SIZE / ITEM_FRAME_ROW_MAXCOUNT)) ]]
    ListFrame:Hide()
end

---comment
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
end
