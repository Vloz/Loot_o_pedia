local addonName, ns = ...

ns.scanned_npcs = nil

ns.NpcClassifications = {
    ["worldboss"] = 6,
    ["rareelite"] = 5,
    ["elite"] = 4,
    ["rare"] = 3,
    ["normal"] = 2,
    ["trivial"] = 1,
}

function ns:InitScannnedNpcs(areaId)
    local build = ns:DB_Build()
    if build and build.areas[areaId] then
        print("try parse area loot" .. areaId)
        local arealoots = ns:ParseAreaLoot(build.areas[areaId])
        ns.scanned_npcs = arealoots.scannedSources
    end
end

-- Function to extract NPC ID from a GUID
local function GetNpcIDFromGUID(guid)
    if not guid then return nil end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" then
        return tonumber(npcID)
    end
    return nil
end

local function saveNpcBountyLocale(npcID, name, usx)
    local prev = ns:GetLocalBounty(ns.LOCALE_BOUNTY_TYPE.CREATURE_NAME, npcID)
    if prev then
        if usx == 2 then -- Erase the potential previous gendered name to neutral
            ns:SaveLocaleBounty(ns.LOCALE_BOUNTY_TYPE.CREATURE_NAME, npcID, name)
        end
    else
        ns:SaveLocaleBounty(ns.LOCALE_BOUNTY_TYPE.CREATURE_NAME, npcID, name)
    end
end



local modelPlayer; -- used to get the DisplayID

local function saveNpcBountyData(npcID, npcData)
    local prev = ns:LoadDataBounty(ns.DATA_BOUNTY_TYPE.CREATURE, npcID)
    if not prev then
        if not modelPlayer then
            modelPlayer = CreateFrame("PlayerModel", nil, UIParent)
        end
        modelPlayer:SetCreature(npcID)
        local displayId = modelPlayer:GetDisplayInfo()
        modelPlayer:ClearModel()
        local bounty = {
            dI = displayId,
            cl = npcData.class,
            pT = npcData.pwType,
            rx = npcData.reaction,
            tp = npcData
                .type,
            fc = npcData.faction
        }
        local areaDiff = ns:getAreaDiff()
        bounty.a = { [areaDiff] = { hp = npcData.hp, pw = npcData.pw, lMn = npcData.lvlmin, lMx = npcData.lvlmax } }
        ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.CREATURE, npcID, bounty)
    else
        if not prev.dI then -- sometime diplayId extraction failed at first time
            if not modelPlayer then
                modelPlayer = CreateFrame("PlayerModel", nil, UIParent)
            end
            modelPlayer:SetCreature(npcID)
            local displayId = modelPlayer:GetDisplayInfo()
            prev.dI = displayId
            modelPlayer:ClearModel()
        end
        local areaDiff = ns:getAreaDiff()
        if not prev.a[areaDiff] then
            prev.a[areaDiff] = { hp = npcData.hp, pw = npcData.pw, lMn = npcData.lvlmin, lMx = npcData.lvlmax }
        else
            prev.a[areaDiff].hp = npcData.hp
            prev.a[areaDiff].pw = npcData.pw
            prev.a[areaDiff].lMn = math.min(prev.a[areaDiff].lMn, npcData.lvlmin)
            prev.a[areaDiff].lMx = math.max(prev.a[areaDiff].lMx, npcData.lvlmax)
        end

        ns:SaveDataBounty(ns.DATA_BOUNTY_TYPE.CREATURE, npcID, prev)
    end
end


local factionID = {
    ["Horde"] = 0,
    ["Alliance"] = 1,
    ["Neutral"] = 2,
    ["None"] = 3
}

-- Function to handle the event when mouse is over a unit
local function OnTooltipSetUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit and UnitExists(unit) then
        local guid = UnitGUID(unit)
        local npcID = GetNpcIDFromGUID(guid)
        if ns.scanned_npcs and not ns.scanned_npcs[npcID] then
            local npcName = UnitName(unit)
            if npcID and npcName then
                local maxHP = UnitHealthMax(unit)
                local maxPW = UnitPowerMax(unit)
                local level = UnitLevel(unit)
                level = level == -1 and 128 or level
                local pwType, _ = UnitPowerType(unit)
                local unitType = UnitClassification(unit)
                local unitTypeId = ns.NpcClassifications[unitType]
                local reaction = UnitReaction("player", unit)
                local usx = UnitSex(unit)
                local type = ns:GetCreatureTypeID(UnitCreatureType(unit))
                local factionStr, _ = UnitFactionGroup(unit)
                local faction = factionID[factionStr] or 3
                saveNpcBountyData(npcID,
                    {
                        hp = maxHP,
                        pw = maxPW,
                        lvlmin = level,
                        lvlmax = level,
                        pwType = pwType,
                        class = unitTypeId,
                        reaction = reaction,
                        usx = usx,
                        type = type,
                        faction = faction
                    })
                saveNpcBountyLocale(npcID, npcName, usx)
            end
        end
    end
end

-- Hook the GameTooltip to add custom info
GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
