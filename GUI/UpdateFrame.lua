local addon, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale("LootOPedia")

ns.UPDATETAB_ORIGIN = {
    USER_CLICK = 1,
    NO_BUILD = 2,
    AREA_UNKNOWN = 3,
    AREA_NOT_DL = 4,
}

ns.requiredDLArea = nil

local frame;

function ns:UpdateFrame_OnLoad(self)
    frame = self
end

local function show_Conditional(origin)
    local score, ready = ns:GetUpdateScore()
    local Bar = frame.leftPanel.progress.bar
    local Button = frame.leftPanel.updateButton
    local Message = frame.leftPanel.message
    Bar:SetSize(302 * score, 10)
    frame.leftPanel.intro:SetText(L["UPDFINTRO"])
    Button:SetText(L["BUTUPDATE"])
    if not ready or score < ns.MIN_UPDATESCORE then
        frame.leftPanel.title:SetText(L["Can't update yet!"])
        Bar:SetVertexColor(1, 0, 0)
        Button:Disable()
        Message:SetVertexColor(1, 0, 0)
        if score < ns.MIN_UPDATESCORE then
            Message:SetText(L["NENOUGHDATA"])
        elseif not ready then
            Message:SetText(L["TOOEARLY"])
        end
    else
        Message:SetVertexColor(0, 0.7, 0)
        Message:SetText(L["UPDRMESS"])
        frame.leftPanel.title:SetText(L["Update ready!"])
        Bar:SetVertexColor(0, 0.8, 0)
        Button:Enable()
    end
    if origin == ns.UPDATETAB_ORIGIN.AREA_UNKNOWN then
        local areaName = ns:areaLocNameFromId(ns.requiredDLArea)
        frame.leftPanel.title:SetText(string.format(L["UPDUNKNOWN"], areaName))
    end
    if ns.IS_DEBUG then
        Button:Enable()
    end
    frame:Show()
end

local function show_Allowed(origin)
    local score, ready = ns:GetUpdateScore()
    local Bar = frame.leftPanel.progress.bar
    local Button = frame.leftPanel.updateButton
    local Message = frame.leftPanel.message
    Bar:SetSize(302 * score, 10)
    frame.leftPanel.intro:SetText(L["UPDFINTRO"])
    Button:SetText(L["BUTUPDATE"])
    Message:SetVertexColor(0, 0.7, 0)
    Message:SetText(L["UPDRMESS"])
    if origin == ns.UPDATETAB_ORIGIN.NO_BUILD then
        frame.leftPanel.title:SetText(L["UPDINIT"])
    elseif origin == ns.UPDATETAB_ORIGIN.AREA_NOT_DL then
        local areaName = ns:areaLocNameFromId(ns.requiredDLArea)
        frame.leftPanel.title:SetText(string.format(L["UPDNDL"], areaName))
    end
    Bar:SetVertexColor(0, 0.8, 0)
    Button:Enable()

    frame:Show()
end


function LootOPedia_ShowUpdateTabFrame(frame, args)
    if not args then
        args = { ns.UPDATETAB_ORIGIN.USER_CLICK }
    end
    local origin, areaId = unpack(args)

    ns.requiredDLArea = areaId or ns:getAreaId()

    -- full allow area that are known and initial update
    -- conditionnal update for unknown area and general update
    -- Attempt to throttle spam updating on new area launchs
    if origin == ns.UPDATETAB_ORIGIN.USER_CLICK or origin == ns.UPDATETAB_ORIGIN.AREA_UNKNOWN then
        show_Conditional(origin)
    elseif origin == ns.UPDATETAB_ORIGIN.NO_BUILD or origin == ns.UPDATETAB_ORIGIN.AREA_NOT_DL then
        show_Allowed(origin)
    end
end

function ns:UpdateUI_Export()
    return ns:Export(ns.requiredDLArea or 0)
end

ns.FULL_UPDATESCORE_COUNT = 100
ns.MIN_UPDATESCORE = 0.2
ns.UPDATE_INTERVAL = 60 * 60 * 24
-- return 0-1 if the update is required
function ns:GetUpdateScore()
    local count = 0
    local ready = (not ns:DB_Game().lastUpdate or ns:DB_Game().lastUpdate + ns.UPDATE_INTERVAL < GetServerTime())
    local Db_lr = ns:DB_LootRegister()
    for areaId, sources in pairs(Db_lr) do
        for sourceId, source in pairs(sources) do
            count = count + 1
            if count > ns.FULL_UPDATESCORE_COUNT then
                return 1, ready
            end
        end
    end
    local Db_db = ns:DB_DataBounty()
    for dataBountyType, dataBounty in pairs(Db_db) do
        for key, data in pairs(dataBounty) do
            count = count + 1
            if count > ns.FULL_UPDATESCORE_COUNT then
                return 1, ready
            end
        end
    end
    local Db_lb = ns:DB_LocaleBounty()
    for locale, localeBounty in pairs(Db_lb) do
        for localeBountyType, localeBountyData in pairs(localeBounty) do
            count = count + 1
            if count > ns.FULL_UPDATESCORE_COUNT then
                return 1, ready
            end
        end
    end


    return count / ns.FULL_UPDATESCORE_COUNT, ready
end

function ns:UpdateFrame_OnHide(self)
    ns.requiredDLArea = nil
    LOP_UpdateDialog:Hide()
end
