local addon, ns = ...

local PORTRAIT_POOL_SIZE = 10
local PORTRAIT_COL_WIDTH = 48
local PORTRAIT_COL_HEIGHT = 48
local PORTRAIT_ROW_MAXCOUNT = 5
local PORTRAIT_COL_MAXCOUNT = 2
local LIST_MARGIN = 0

local portraitPool;
local portraitListFrame;

local enterCallback;
local leaveCallback;
---@type PortraitData[]
local portraitsDataArray;
local page = 1
local currentBgColor = "#fff"

ns.CLASS_COLOR = {
    [ns.NpcClassifications.worldboss] = { 0.9, 0.8, 0, 1 },
    [ns.NpcClassifications.rareelite] = { 0.5, 0.4, 0, 1 },
    [ns.NpcClassifications.elite] = { 0.5, 0.4, 0, 1 },
    [ns.NpcClassifications.rare] = { 0.5, 0.5, 0.5, 1 },
    [ns.NpcClassifications.normal] = { 0, 0, 0, 1 },
    [ns.NpcClassifications.trivial] = { 0.5, 0.5, 0.5, 1 },
    [0] = { 0, 0, 0, 1 },
}



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
        if (col == PORTRAIT_ROW_MAXCOUNT - 1 or row == PORTRAIT_COL_MAXCOUNT - 1) then
            portrait.bgTx:SetTexCoord(0, col == PORTRAIT_ROW_MAXCOUNT - 1 and 0.5 or 0.523, 0,
                row == PORTRAIT_COL_MAXCOUNT - 1 and 0.5 or 0.523)
            portrait.bgTx:SetSize(col == PORTRAIT_ROW_MAXCOUNT - 1 and 46 or 48,
                row == PORTRAIT_COL_MAXCOUNT - 1 and 46 or 48)
        end
        portrait:Show()
        table.insert(portraitPool, portrait)
    end
    print(PORTRAIT_COL_WIDTH * PORTRAIT_ROW_MAXCOUNT + LIST_MARGIN * 2 + 10)
    ListFrame:SetSize(PORTRAIT_COL_WIDTH * PORTRAIT_ROW_MAXCOUNT + LIST_MARGIN * 2 + 10,
        PORTRAIT_COL_HEIGHT * math.ceil(PORTRAIT_POOL_SIZE / PORTRAIT_ROW_MAXCOUNT) + LIST_MARGIN * 2)
    ControlsFrame:SetPoint("TOP", ListFrame, "BOTTOM", 0, 0)
    frame:SetSize(ListFrame:GetWidth(), ListFrame:GetHeight() + ControlsFrame:GetHeight() + 5)
    frame:Hide()
end

---@alias PortraitDataLoot { harvestType : HarvestTypeID, dropRate : number, weight : number, minQt : number, maxQt : number }
---@alias PortraitData  { type : SourceTypeID , id :number, weight :number, loots:table<number, PortraitDataLoot> }

---@enum PortraitType
ns.PORTRAIT_TYPE = { --Depending on portrait type may load texture, displayId, or raw 3dModel
    NPC_DISPLAYID = 1,
}





local function buildPage()
    local baseColor = ns:hexToRGBA(currentBgColor)
    for i = 1, PORTRAIT_POOL_SIZE do
        local portrait = portraitPool[i]
        portrait.borderBase:SetVertexColor(unpack(baseColor))
        portrait.bgTx:SetVertexColor(unpack(baseColor))
        if i <= #portraitsDataArray - ((page - 1) * PORTRAIT_POOL_SIZE) then
            portrait.data = portraitsDataArray[((page - 1) * PORTRAIT_POOL_SIZE) + i]
            portrait.enterCallback = enterCallback
            portrait.leaveCallback = leaveCallback
            if portrait.data.type == ns.PORTRAIT_TYPE.NPC_DISPLAYID then
                SetPortraitTextureFromCreatureDisplayID(portrait.txt, portrait.data.value)
            else
                portrait:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            if portrait.data.dropRate then
                portrait.ratetext:SetText(portrait.data.dropRate .. "%")
            else
                portrait.ratetext:SetText("")
            end
            if portrait.data.minQt and portrait.data.maxQt and (portrait.data.minQt ~= 1 or portrait.data.maxQt ~= 1) then
                if portrait.data.minQt == portrait.data.maxQt then
                    portrait.qttext:SetText(portrait.data.minQt)
                else
                    portrait.qttext:SetText(portrait.data.minQt .. "-" .. portrait.data.maxQt)
                end
            else
                portrait.qttext:SetText("")
            end
            if portrait.data.class then
                portrait.borderAdd:SetVertexColor(unpack(ns.CLASS_COLOR[portrait.data.class]))
            else
                portrait.borderAdd:SetVertexColor(0, 0, 0, 1)
            end
            portrait.borderAdd:Show()
            portrait.borderBase:Show()
            portrait.txt:Show()
            portrait:Enable()
        else
            portrait.borderAdd:Hide()
            portrait.borderBase:Hide()
            portrait.txt:Hide()
            portrait:Disable()
        end
    end
    local pageMax = math.ceil(#portraitsDataArray / PORTRAIT_POOL_SIZE)
    portraitListFrame.ControlsFrame.PageText:SetText(page .. "/" .. pageMax)
    portraitListFrame.ControlsFrame.PrevButton:SetEnabled(page > 1)
    portraitListFrame.ControlsFrame.NextButton:SetEnabled(page < pageMax)
end


---Set the source of the portrait list
---@param portraitsDataArr PortraitData[]
function ns:ShowPortraitList(portraitsDataArr, selectedPage, enterCB, leaveCB, bgC)
    portraitsDataArray = portraitsDataArr
    enterCallback = enterCB
    leaveCallback = leaveCB
    if selectedPage or not page then
        page = selectedPage or 1
    end
    if bgC then
        currentBgColor = bgC
    else
        currentBgColor = "#fff"
    end
    buildPage()
    portraitListFrame:Show()
end

function ns:PortraitPageNext()
    page = page + 1
    buildPage()
end

function ns:PortraitPagePrev()
    page = page - 1
    buildPage()
end
