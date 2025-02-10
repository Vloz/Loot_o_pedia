local addonName, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale("LootOPedia")

local frame;
local urlField;
local dataField;
local copyPopUp;
local baseUrl;

local function onShow()
    frame.errorFS:SetText("")
    PlaySound(88)
    urlField:SetText(baseUrl .. _G["LOP_EXPORT_URL"])
    urlField:SetCursorPosition(0)
    urlField:HighlightText(0, -1)
end

local function copyPopUpBlink()
    if not copyPopUp.fadeAnim then
        local animGroup = copyPopUp:CreateAnimationGroup()

        local fadeAnim = animGroup:CreateAnimation("Alpha")
        fadeAnim:SetDuration(1.5)
        fadeAnim:SetFromAlpha(1)
        fadeAnim:SetToAlpha(0)
        fadeAnim:SetSmoothing("OUT")

        copyPopUp.fadeAnim = animGroup
    end

    copyPopUp.fadeAnim:Play()
end

local function urlField_OnKeyDown(self, key)
    if (key == "C" or key == "X") and IsControlKeyDown() then
        PlaySound(790)
        copyPopUpBlink()
    end
end


local function dataField_OnTextChanged(self)
    if self.supressTextChanged then
        return
    end
    local text = self:GetText()
    if strlen(text) > 5 then
        local success, result = pcall(ns.Import, ns, text)
        if success then
            PlaySound(878)
            frame:Hide()
        else
            frame.errorFS:SetText(result)
            ns:DEBUG("|cffff7777 " .. result)
            PlaySound(882)
        end
    end

    self.supressTextChanged = true
    self:SetText("")
    C_Timer.After(0.1, function()
        self.supressTextChanged = false
    end)
end


function ns:UpdateDialog_OnLoad(self)
    if ns.DEBUG then
        baseUrl = "http://localhost:5173/update/#"
    else
        baseUrl = "https://loot-o-pedia.web.app/update/#"
    end
    frame = self
    frame:SetScript("OnShow", onShow)
    urlField = self.urlField
    copyPopUp = self.copyPopUp
    dataField = self.dataBox.scroll.field
    self.intro:SetText(L["UPDDLIntro"])
    urlField:SetScript("OnKeyDown", urlField_OnKeyDown)
    urlField:SetScript("OnEditFocusGained", function(self) self:HighlightText(0, -1) end)
    urlField:SetPropagateKeyboardInput(true)
    urlField:SetAutoFocus(true)
    urlField:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= baseUrl .. _G["LOP_EXPORT_URL"] then
            self:SetText(baseUrl .. _G["LOP_EXPORT_URL"])
        end
        self:HighlightText(0, -1)
        self:SetCursorPosition(0)
    end)
    copyPopUp.text:SetText(L["Copied!"])
    copyPopUp:SetAlpha(0)
    --dataField:SetScript("OnKeyDown", dataField_OnKeyDown)
    dataField:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    dataField:SetPropagateKeyboardInput(true)
    dataField:SetScript("OnTextChanged", dataField_OnTextChanged)
    dataField:SetMaxLetters(1024 * 80000)
end
