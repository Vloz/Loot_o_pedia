local addon, ns = ...

local PORTRAIT_POOL_SIZE = 25
local PORTRAIT_COL_WIDTH = 44
local PORTRAIT_COL_HEIGHT = 44
local PORTRAIT_ROW_MAXCOUNT = 5
local LIST_MARGIN = 15

local portraitPool;
local portraitListFrame;



function ns:InitPortraitList(frame)
    portraitListFrame = frame
    local ListFrame = frame.ListFrame
    local ControlsFrame = frame.ControlsFrame
    -- init pool of portrait for sources
    --[[     frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileEdge = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    }) ]]
    portraitPool = {}
    for i = 1, PORTRAIT_POOL_SIZE do
        local portrait = CreateFrame("Button", "LOP_Portrait_" .. i, ListFrame,
            "LOP_PortraitTemplate")
        portrait:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.data.id)
            GameTooltip:Show()
            if self.enterCallback then
                self.enterCallback(self)
            end
        end)
        portrait:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.leaveCallback then
                self.leaveCallback(self)
            end
        end)
        local col = (i - 1) % PORTRAIT_ROW_MAXCOUNT
        local row = math.floor((i - 1) / PORTRAIT_ROW_MAXCOUNT)
        portrait:SetPoint("TOPLEFT", ListFrame, "TOPLEFT", PORTRAIT_COL_WIDTH * col + LIST_MARGIN,
            -PORTRAIT_COL_HEIGHT * row - LIST_MARGIN)
        portrait:Show()
        table.insert(portraitPool, portrait)
    end
    ListFrame:SetSize(PORTRAIT_COL_WIDTH * PORTRAIT_ROW_MAXCOUNT + LIST_MARGIN * 2,
        PORTRAIT_COL_HEIGHT * math.ceil(PORTRAIT_POOL_SIZE / PORTRAIT_ROW_MAXCOUNT) + LIST_MARGIN * 2)
    ControlsFrame:SetPoint("TOP", ListFrame, "BOTTOM", 0, 8)
    frame:SetSize(ListFrame:GetWidth(), ListFrame:GetHeight() + ControlsFrame:GetHeight() + 5)
    frame:Hide()
end

---@alias PortraitDataLoot { harvestType : HarvestTypeID, dropRate : number, weight : number, minQt : number, maxQt : number }
---@alias PortraitData  { type : SourceTypeID , id :number, weight :number, loots:table<number, PortraitDataLoot> }




local modelPlayer; -- modelplayer used to generate missing displayID

local function SetPortraitTexture(creatureID, textureElement)
    local displayID;
    if false then --TODO SUPPORT EMBEDED DISPLAYID
    else          -- No displayID found, generate it from modelplayer
        if not modelPlayer then
            modelPlayer = CreateFrame("PlayerModel", nil, UIParent)
        end
        modelPlayer:SetCreature(creatureID)
        displayID = modelPlayer:GetDisplayInfo()
    end
    SetPortraitTextureFromCreatureDisplayID(textureElement, displayID)
end

---Set the source of the portrait list
---@param portraitsDataArray PortraitData[]
function ns:ShowPortraitList(portraitsDataArray, page, enterCallback, leaveCallback)
    local page = page or 1
    for i = 1 + ((page - 1) * PORTRAIT_POOL_SIZE), PORTRAIT_POOL_SIZE do
        local portrait = portraitPool[i]
        if i <= #portraitsDataArray then
            portrait.data = portraitsDataArray[i]
            portrait.enterCallback = enterCallback
            portrait.leaveCallback = leaveCallback
            SetPortraitTexture(portraitsDataArray[i].id, portrait.txt)
            if portraitsDataArray[i].dropRate then
                portrait.ratetext:SetText(portraitsDataArray[i].dropRate .. "%")
            else
                portrait.ratetext:SetText("")
            end
            if portraitsDataArray[i].minQt and portraitsDataArray[i].maxQt and (portraitsDataArray[i].minQt ~= 1 or portraitsDataArray[i].maxQt ~= 1) then
                if portraitsDataArray[i].minQt == portraitsDataArray[i].maxQt then
                    portrait.qttext:SetText(portraitsDataArray[i].minQt)
                else
                    portrait.qttext:SetText(portraitsDataArray[i].minQt .. "-" .. portraitsDataArray[i].maxQt)
                end
            else
                portrait.qttext:SetText("")
            end
            portrait:Show()
        else
            portrait:Hide()
        end
    end
    local pageMax = math.ceil(#portraitsDataArray / PORTRAIT_POOL_SIZE)
    portraitListFrame.ControlsFrame.PageText:SetText(page .. "/" .. pageMax)
    portraitListFrame.ControlsFrame.PrevButton:SetEnabled(page > 1)
    portraitListFrame.ControlsFrame.NextButton:SetEnabled(page < pageMax)
    portraitListFrame:Show()
end
