local addon, ns = ...

local L = LibStub("AceLocale-3.0"):GetLocale("LootOPedia")


ns.Tabs = {
    ["LOP_update_Tab"] = {
        tooltip = "Update",
        icon = { 0.891, 1, 0, 0.109 },
        position = { 76, -41 },
        tabframe = "LOP_UpdateTabFrame"
    },
    ["LOP_area_Tab"] = {
        tooltip = "Places",
        icon = { 0.891, 1, 0.109, 0.218 },
        position = { 156, -41 },
        tabframe = "LOP_AreaTabFrame"
    }
}
local dropListTreeUI = nil

local frame;


function ns:ClearTabFrames()
    for name, data in pairs(ns.Tabs) do
        _G[data.tabframe]:Hide()
    end
end

function ns:MainFrame_OnLoad(self)
    frame = self
    frame:SetAttribute("UIPanelLayout-enabled", true)
    frame:SetAttribute("UIPanelLayout-area", "left")
    frame:SetAttribute("UIPanelLayout-pushable", 1)
    frame:SetAttribute("UIPanelLayout-whileDead", true)
    tinsert(UISpecialFrames, frame:GetName()) -- Permet de fermer avec "Échap"
    --table.insert(UIPanelWindows, { [frame:GetName()] = { area = "left", pushable = 1 } })
    UIPanelWindows[frame:GetName()] = { area = "left", pushable = 1, whileDead = 1 }

    for name, data in pairs(ns.Tabs) do
        local tab = CreateFrame("Frame", name, frame, "LOP_TabTemplate")
        tab:SetFrameLevel(99)
        tab:SetAttribute("data", data)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", unpack(data.position))
        _G[name .. "_Icon"]:SetTexCoord(unpack(data.icon))

        tab:SetScript("OnEnter", function(elem)
            _G[elem:GetName() .. "_hl"]:Show()
            GameTooltip:SetOwner(elem, "ANCHOR_RIGHT")
            GameTooltip:SetText(L[elem:GetAttribute("data").tooltip])
            GameTooltip:Show()
        end)
        if name == "LOP_area_Tab" then
            tab:SetScript("OnEnter", function(elem)
                if not ns.AreaDropListNodeTree then
                    ns:BuildAreadropListTreeUI()
                end
                _G[elem:GetName() .. "_hl"]:Show()
                GameTooltip:SetOwner(elem, "ANCHOR_RIGHT")
                GameTooltip:SetText(L[elem:GetAttribute("data").tooltip])
                GameTooltip:Show()
                ns:ShowDropListFrame(1, ns.AreaDropListNodeTree, elem)
            end)
            tab:SetScript("OnLeave", nil)
        end
    end
    ns:InitDropList(frame)
end

ns.AreaDropListNodeTree = nil

function ns:BuildAreadropListTreeUI()
    ---@type DropListNode
    ns.AreaDropListNodeTree = { nodes = {} }
    local build = ns:DB_Game()["build"]
    if build then
        for areaId, area in pairs(build.areas) do
            if area.mapType == Enum.UIMapType.Continent then
                local node = {
                    type = "category",
                    id = areaId,
                    name = area.name or self:areaLocNameFromId(areaId) or "[" .. areaId .. "]",
                    color = { 0.90, 0.8, 0.4 },
                    nodes = {}
                }
                ns:AddNodeFromPath("/" .. areaId, ns.AreaDropListNodeTree, node)
            elseif area.mapType == Enum.UIMapType.Zone then
                local node = {
                    type = "area",
                    id = areaId,
                    name = area.name or self:areaLocNameFromId(areaId) or "[" .. areaId .. "]"
                }
                ns:AddNodeFromPath("/" .. area.cat .. "/" .. areaId, ns.AreaDropListNodeTree, node)
            elseif area.mapType == Enum.UIMapType.Dungeon then
                if area.cat == ns.AREA_CATEGORY_TYPE.DUNGEON then
                    local node = {
                        type = "area",
                        id = areaId,
                        name = area.name or self:areaLocNameFromId(areaId) or "[" .. areaId .. "]"
                    }
                    if not ns.AreaDropListNodeTree.nodes["DUNGEONS"] then
                        local c = ChatTypeInfo["PARTY"]
                        ns:AddNodeFromPath("/DUNGEONS", ns.AreaDropListNodeTree,
                            { type = "category", name = C_LFGList.GetLfgCategoryInfo(2).name, color = { c.r, c.g, c.b }, nodes = {} })
                    end
                    ns:AddNodeFromPath("/DUNGEONS/" .. areaId, ns.AreaDropListNodeTree, node)
                elseif area.cat == ns.AREA_CATEGORY_TYPE.RAID then
                    local c = ChatTypeInfo["RAID"]
                    local node = {
                        type = "area",
                        id = areaId,
                        name = area.name or self:areaLocNameFromId(areaId) or "[" .. areaId .. "]"
                    }
                    if not ns.AreaDropListNodeTree.nodes["RAIDS"] then
                        ns:AddNodeFromPath("/RAIDS", ns.AreaDropListNodeTree,
                            { type = "category", name = C_LFGList.GetLfgCategoryInfo(114).name, color = { c.r, c.g, c.b }, nodes = {} })
                    end
                    ns:AddNodeFromPath("/RAIDS/" .. areaId, ns.AreaDropListNodeTree, node)
                end
            end
        end
    end
end

function ns:SelectTab(tab_name, args)
    ns.selected_tab = tab_name
    for name, data in pairs(ns.Tabs) do
        if name == ns.selected_tab then
            _G[name .. "_select"]:Show()
            local tabFrame = _G[data.tabframe]
            tabFrame.ShowTabFrame(tabFrame, args)
        else
            _G[name .. "_select"]:Hide()
            _G[data.tabframe]:Hide()
        end
    end
end

local function updateUpdateTabIconColor()
    local icon = _G["LOP_update_Tab_Icon"]
    local score, ready = ns:GetUpdateScore()
    local color;
    if score < ns.MIN_UPDATESCORE or not ready then
        color = { 0.4, 0.4, 0.4, 1 }
    elseif score <= 0.8 then
        color = { 1, 0.8, 0, 1 }
    else
        color = { 0.1, 1, 0.1, 1 }
    end

    icon:SetVertexColor(unpack(color))
end

function LootOPedia_MainFrame_OnShow(frame)
    if not ns.selected_tab then
        ns:SelectTab("LOP_area_Tab")
    end
    updateUpdateTabIconColor()
end
