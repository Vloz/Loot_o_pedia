local addon, ns = ...


ns.LOCALE_BOUNTY_TYPE = {
    AREA_NAME = "1",
    CREATURE_NAME = "2"
}

ns.DATA_BOUNTY_TYPE = {
    AREA = "1",
    CREATURE = "2"
}

function ns:SaveLocaleBounty(localeBountType, key, value)
    local locale = GetLocale()
    local Db_lb = self:DB_LocaleBounty()
    if not Db_lb[locale] then
        Db_lb[locale] = {}
    end
    Db_lb[locale][localeBountType .. "-" .. key] = { l = GetServerTime(), value = value }
end

function ns:GetLocalBounty(localeBountType, key)
    local locale = GetLocale()
    local Db_lb = self:DB_LocaleBounty()
    if not Db_lb then
        return nil
    end
    if not Db_lb[locale] then
        return nil
    end
    if not Db_lb[locale][localeBountType .. "-" .. key] then
        return nil
    end
    return Db_lb[locale][localeBountType .. "-" .. key].value
end

function ns:DB_Init()
    self.db.global[self.game] = {}
    self.db.global[self.game].loot_register = {}
    self.db.global[self.game].looted_Guids = {}
    self.db.global[self.game].DataBounty = {}
    self.db.global[self.game].LocaleBounty = {}
end

function ns:DB_Wipe()
    ns.db.global[ns.game] = nil
    ns:DB_Init()
    ns:OUT("Wiped LootOPedia")
end

-- call once the export has been done and import succeeded
function ns:DB_ClearPostExport()
    ns.db.global[ns.game].loot_register = {}
    ns.db.global[ns.game].DataBounty = {}
    ns.db.global[ns.game].LocaleBounty = {}
end

function ns:DB_Game()
    return self.db.global[self.game]
end

function ns:DB_LootRegister()
    return self.db.global[self.game].loot_register
end

function ns:DB_LootedGuids()
    return self.db.global[self.game].looted_Guids
end

function ns:DB_DataBounty()
    return self.db.global[self.game].DataBounty
end

function ns:DB_LocaleBounty()
    return self.db.global[self.game].LocaleBounty
end

function ns:SaveDataBounty(dataBountyType, key, value)
    local Db_db = self:DB_DataBounty()
    if not Db_db[dataBountyType] then
        Db_db[dataBountyType] = {}
    end
    Db_db[dataBountyType][key] = {
        l = GetServerTime(),
        value =
            value
    }
end

function ns:LoadDataBounty(dataBountyType, key)
    local Db_db = self:DB_DataBounty()
    if not Db_db[dataBountyType] then
        return nil
    end
    if not Db_db[dataBountyType][key] then
        return nil
    end
    return Db_db[dataBountyType][key].value
end

local PRUNER_MAX_AGE = 60 * 60 * 24 * 7

local function prunerMaxAge(db_table)
    local now = GetServerTime()
    for k, v in pairs(db_table) do
        if now - v.l > PRUNER_MAX_AGE then
            db_table[k] = nil
        end
    end
end

-- ran every 4hours of disconnection
function ns:DbPruner()
    ns:DB_Game().looted_Guids = {}
    local Db_lb = ns:DB_LocaleBounty()
    for k, v in pairs(Db_lb) do
        prunerMaxAge(v)
    end
    local Db_db = ns:DB_DataBounty()
    for k, v in pairs(Db_db) do
        prunerMaxAge(v)
    end

    -- remove all old sources from register and remove empty areas
    local Db_lr = ns:DB_LootRegister()
    for areaId, sources in pairs(Db_lr) do
        prunerMaxAge(v)
        if ns:tgetn(sources) == 0 then
            Db_lr[areaId] = nil
        end
    end
end
