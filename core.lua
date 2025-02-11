local addon, ns = ...
LootOPedia = LibStub("AceAddon-3.0"):NewAddon("LootOPedia", "AceConsole-3.0", "AceEvent-3.0")
local LOPMinimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("LopMinimap", {
    type = "data source",
    text = "Loot-o-pedia",
    icon = "Interface\\AddOns\\Loot_o_pedia\\media\\minimap",
    OnClick = function()
        if LOP_MainFrame:IsVisible() then
            HideUIPanel(LOP_MainFrame)
        else
            ShowUIPanel(LOP_MainFrame)
        end
    end
})

--!DO NOT EDIT
--!Will match release tag with github actions
ns.MAJOR = 9999
ns.MINOR = 9999
--!Will automatically switch to false on release
ns.IS_DEBUG = false

function ns:DEBUG(msg)
    if ns.IS_DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cff7777FF[LOP]|r " .. msg)
    end
end

function ns:OUT(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7777FF[LOP]|r " .. msg)
end

SLASH_LOOTOPEDIA1, SLASH_LOOTOPEDIA2 = '/lootopedia', '/lop';
function SlashCmdList.LOOTOPEDIA(msg, editBox)
    if msg == "wipe" then
        ns:DB_Wipe()
    else
        if LOP_MainFrame:IsVisible() then
            HideUIPanel(LOP_MainFrame)
        else
            ShowUIPanel(LOP_MainFrame)
        end
    end
end

---return the faction ID of the player
local function GetCurrentFactionID()
    local factionGroup, _ = UnitFactionGroup("player")

    if factionGroup == "Alliance" then
        return 1 -- Alliance ID
    else
        return 0 -- Horde ID
    end
end

---return the game string that defining wich database will be used
---@return string
local function GetCurrentGame()
    local version, build, date, tocVersion = GetBuildInfo()

    -- Extract the main version and subversion (e.g., 1.13 from 1.13.7)
    local mainVersion, subVersion = version:match("^(%d+)%.(%d+)")
    if C_Seasons.HasActiveSeason() then
        return "GAME-" .. mainVersion .. "-" .. C_Seasons.GetActiveSeason() .. "-" .. GetCurrentFactionID()
    else
        return "GAME-" .. mainVersion .. "-0-" .. GetCurrentFactionID()
    end
end

local icon = LibStub("LibDBIcon-1.0")
function LootOPedia:OnInitialize()
    ns.db = LibStub("AceDB-3.0"):New("LootOPediaDB")
    ns.game = GetCurrentGame()
    if not ns:DB_Game() then
        ns:DB_Init()
    end

    if ns.db.global[ns.game].last_logout then
        if GetServerTime() - ns.db.global[ns.game].last_logout > 60 * 60 * 4 then
            ns:DbPruner()
        end
        ns.db.global[ns.game].last_logout = nil
    end

    if not ns.db.profile.minimap then
        ns.db.profile.minimap = {
            hide = false
        }
    end
    icon:Register("LopMinimap", LOPMinimapLDB, ns.db.profile.minimap)
end

local function PLAYER_LEAVING_WORLD(event)
    ns.db.global[ns.game].last_logout = GetServerTime()
end

LootOPedia:RegisterEvent("PLAYER_LEAVING_WORLD", PLAYER_LEAVING_WORLD)
