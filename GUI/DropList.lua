---@diagnostic disable: need-check-nil
local addon, ns = ...



local dropListFrames = {}
local DROPLIST_MAX_ITEMS = 50
local DROPLIST_MAX_DEPTH = 4
local DROPLIST_MIN_WIDTH = 100
local DROPLIST_ITEM_HEIGHT = 25
local DROPLIST_ITEM_MARGIN = 2
local dropListExitBox = nil

---Create an empty droplist frame
local function CreateEmptydropListFrame(parent, id)
    local areaListFrame = CreateFrame("Frame", "LOP_AreaListFrame_" .. id, parent, "BackdropTemplate")
    areaListFrame:SetMouseMotionEnabled(true)
    areaListFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UIFrameTooltipBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    areaListFrame:SetFrameStrata(parent:GetFrameStrata())
    areaListFrame:SetFrameLevel(100)
    areaListFrame:SetPoint("TOPLEFT", id == 1 and parent or "LOP_AreaListFrame_" .. id - 1, "TOPRIGHT", 0, -20)
    areaListFrame:SetSize(100, 200)
    areaListFrame:Hide()
    local selectortxt = areaListFrame:CreateTexture(nil, "BACKGROUND")
    selectortxt:SetTexture("Interface\\QUESTFRAME\\UI-QuestLogTitleHighlight")
    selectortxt:SetBlendMode("ADD")
    selectortxt:SetAlpha(0.2)
    areaListFrame.selectortxt = selectortxt
    areaListFrame.buttons = {}
    for i = 1, 50, 1 do
        local b = CreateFrame("Button", "LOP_AreaListFrame_" .. id .. "_button_" .. i, areaListFrame)
        b.idList = id
        local bgtxt = b:CreateTexture(nil, "BACKGROUND")
        bgtxt:SetAllPoints(b)
        bgtxt:SetColorTexture(0.5, 0.5, 0.5, 0.1) -- Gris
        b.bgtxt = bgtxt
        local tritxt = b:CreateTexture(nil, "ARTWORK")
        tritxt:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
        tritxt:SetTexCoord(0.22, 0.41, 0, 1)
        tritxt:SetPoint("RIGHT", b, "RIGHT", -2, 0)
        tritxt:SetSize(10, 10)
        b.tritxt = tritxt
        b:SetPoint("TOPLEFT", areaListFrame, "TOPLEFT", 5,
            -(DROPLIST_ITEM_HEIGHT + DROPLIST_ITEM_MARGIN) * (i - 1) - DROPLIST_ITEM_HEIGHT / 4)
        b.text = b:CreateFontString("LOP_AreaListFrame_" .. id .. "_button_" .. i .. "_text", "OVERLAY",
            "GameFontNormal")
        b.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
        b.text:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -7)
        b.text:SetText("Button " .. i)
        b.text:Show()
        areaListFrame.buttons[i] = b
    end

    dropListFrames[id] = areaListFrame
end

---Hide the whole droplist (and the exitbox)
local function HidedropList()
    for i = 1, DROPLIST_MAX_DEPTH, 1 do
        dropListFrames[i]:Hide()
    end
    dropListExitBox:Hide()
    for name, data in pairs(ns.Tabs) do
        _G[name .. "_hl"]:Hide()
    end
    GameTooltip:Hide()
end

---Activate the exit box that surround the droplist and have it removed when hovered
---@param point any Last DroplistFrame
local function ShowExitBox(point)
    dropListExitBox:SetPoint("TOPLEFT", dropListFrames[1], "TOPLEFT", -100, 100)
    dropListExitBox:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", 100, -100)
    dropListExitBox:Show()
end

---Show the droplist frame at depth ID and build its entries based upon cat nodes
---@param id number
---@param cat DropListNode
---@param point any @UI element
function ns:ShowDropListFrame(id, cat, point)
    for i = id + 1, DROPLIST_MAX_DEPTH, 1 do
        dropListFrames[i]:Hide()
    end
    local frame = dropListFrames[id]
    frame.selectortxt:Hide()
    for i, v in ipairs(frame.buttons) do
        frame.buttons[i]:Hide()
        frame.buttons[i].tritxt:Hide()
        frame.buttons[i]:SetScript("OnEnter", nil)
        frame.buttons[i]:SetScript("OnClick", nil)
    end

    local i = 0
    local maxwidth = 0
    for node_key, node in pairs(cat.nodes) do
        if node.type == "category" and not node.nodes then
            --skip empty categories
        else
            i = i + 1
            frame.buttons[i].text:SetText(node.name or node_key)
            if node.color then
                frame.buttons[i].text:SetTextColor(unpack(node.color))
            else
                frame.buttons[i].text:SetTextColor(1, 1, 1, 1)
            end
            frame.buttons[i]:Show()
            if frame.buttons[i].text:GetWidth() > maxwidth then
                maxwidth = frame.buttons[i].text:GetWidth()
            end

            frame.buttons[i]:SetScript("OnEnter", function(elem)
                if node.type ~= "header" then
                    elem:GetParent().selectortxt:SetAllPoints(elem)
                    elem:GetParent().selectortxt:Show()
                end
                if node.type == "category" and node.nodes then
                    ns:ShowDropListFrame(id + 1, node, elem)
                end
            end)

            if node.type == "category" and node.nodes then -- category meant to shown another Droplist
                frame.buttons[i].tritxt:Show()
            elseif node.type == "header" then              -- header meant to do nothing
                frame.buttons[i].text:SetTextColor(0.5, 0.5, 0.5, 0.5)
            else
                frame.buttons[i].tritxt:Hide()
                frame.buttons[i]:SetScript("OnClick", function(elem)
                    PlaySound(906)
                    if node.type == "area" then
                        ns:SelectTab("LOP_area_Tab", node.id)
                    end
                    HidedropList()
                end)
            end
        end
    end
    local width = math.max(maxwidth, DROPLIST_MIN_WIDTH) + 10
    for i, v in ipairs(frame.buttons) do
        frame.buttons[i]:SetSize(width, DROPLIST_ITEM_HEIGHT)
    end
    frame:SetSize(width + 10, i * (DROPLIST_ITEM_HEIGHT + DROPLIST_ITEM_MARGIN) + 8)
    if id == 1 then
        frame:SetPoint("TOPLEFT", point, "CENTER", 0, 0)
    else
        frame:SetPoint("TOPLEFT", point, "TOPRIGHT", 0, 0)
    end

    frame:Show()
    ShowExitBox(frame)
end

---Create the required frames for the droplist
function ns:InitDropList(MainFrame)
    for i = 1, DROPLIST_MAX_DEPTH, 1 do
        CreateEmptydropListFrame(MainFrame, i)
    end

    -- Create the exit background frame for the Droplist
    dropListExitBox = CreateFrame("Frame", "LOP_DropListExitBox", MainFrame)
    dropListExitBox:Hide()

    -- Green background for debug purpose
    --[[ local textExitDropList = dropListExitBox:CreateTexture(nil, "BACKGROUND")
    textExitDropList:SetColorTexture(0, 1, 0, 1)
    textExitDropList:SetAllPoints(dropListExitBox)
    dropListExitBox.text = textExitDropList ]]

    dropListExitBox:SetFrameStrata(MainFrame:GetFrameStrata())
    dropListExitBox:SetFrameLevel(90)
    dropListExitBox:SetScript("OnEnter", function(elem)
        HidedropList()
    end)
end

---@alias DropListNode {type: "area"|"category"|"header", id: number?, fontColor:number[]?, name:string?, nodes: table<string, DropListNode>?}

---Add node using path example /Extensions/Shadowlands/Dungeons/ID = {type = "area", id = 2437  , name = "Ragefire Chasm"}
---@param path string @Path to the node
---@param nodeTree DropListNode @Root node
---@param node DropListNode @Node to add
function ns:AddNodeFromPath(path, nodeTree, node)
    local parts = { strsplit("/", path) }
    local currentTable = nodeTree
    --DevTools_Dump(node)
    for i, part in ipairs(parts) do
        if part ~= "" then      -- skip root "/"
            local prev = currentTable.nodes[part]
            if i == #parts then --if end part adding node
                if not prev then
                    currentTable.nodes[part] = node
                else
                    local prev_nodes = prev.nodes
                    currentTable.nodes[part] = node
                    currentTable.nodes[part].nodes = prev_nodes
                end
            else -- if not end part adding category if not exists
                if not prev then
                    currentTable.nodes[part] = { type = "category", nodes = {} }
                end
                currentTable = currentTable.nodes[part]
            end
        end
    end
end

-- add path to table from "/part1/part2/part3" to table["part1"]["part2"]["part3"]
--[[ function ns:addPathToTable(path, tbl)
    local parts = { strsplit("/", path) }
    local currentTable = tbl
    for _, part in ipairs(parts) do
        if part ~= "" then
            print("part", part)
            if not currentTable[part] then
                currentTable[part] = {}
            end
            currentTable = currentTable[part]
        end
    end
    return currentTable
end ]]
