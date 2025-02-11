local addon, ns = ...

local base64 = LibStub('LibBase64-1.0')
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local DataView = ns.DataView


---@alias Loot {itemID:number, dropRate:number, weight:number, minQt:number, maxQt:number}
---@alias HarvestType {harvestTypeID:number, loots:table<number, Loot>}
---@alias Source {sourceID:number, weigth:number, lvlmin:number, lvlmax:number, pwmax:number, hpmax:number, harvestTypes:table<number, HarvestType>}
---@alias SourceType {sourceTypeID:number,sources:table<number, Source>}
---@alias Difficulty {difficultyID:number ,sourceTypes:table<number, SourceType>}
---@alias AreaLootDataCreature {npcClass:number,npcReactionH:number,npcReactionA:number,npcPowerType:number,npcDisplayID:number,npcType:number,npcFaction:number}
---@alias AreaLoots {areaID:number,difficulties:table<number, Difficulty>,dataCreatures:table<number, AreaLootDataCreature>, scannedSources:table<number, boolean>}

---comment
---@param area any
---@return AreaLoots
function ns:ParseAreaLoot(area)
    local bin = base64:decode(area.bin)
    local v = DataView:new(bin)
    --local dataCreatureSize = v.readVarInt()
    ---@type AreaLoots
    local areaLoots = { areaID = area.areaID, difficulties = {}, scannedSources = {} }

    local diffSize = v.readVarInt()
    for i = 1, diffSize, 1 do
        local diffID = v.readInt(1)
        local sourceTypeSize = v.readVarInt()
        local difficulty = { difficultyID = diffID, sourceTypes = {} }
        for j = 1, sourceTypeSize, 1 do
            local sourceTypeIDNum = v.readVarInt()
            local sourceTypeID = tostring(sourceTypeIDNum)
            local sourcesSize = v.readVarInt()
            local sourceType = { sourceTypeID = sourceTypeID, sources = {} }
            for k = 1, sourcesSize, 1 do
                local sourceID = v.readVarInt()
                if sourceTypeID == ns.SOURCE_TYPE.CREATURE then
                    local npcClass = bit.rshift(classFaction, 4)
                    local npcFaction = bit.band(classFaction, 0x0F)
                    local lvlmin = v.readVarInt()
                    --local lvlmax = v.readVarInt()
                    --local pwmax = v.readVarInt()
                    --local hpmax = v.readVarInt()
                end
                local sourceWeight = v.readInt(1)
                ---@type Source
                local source = {
                    sourceID = sourceID,
                    weight = sourceWeight,
                    class = npcClass,
                    faction = npcFaction,
                    lvlmin = lvlmin,
                    harvestTypes = {}
                }
                local harvestTypesSizeIsScanned = v.readInt(1)
                local harvestTypesSize = bit.band(harvestTypesSizeIsScanned, 0x7F)
                local isScanned = bit.band(harvestTypesSizeIsScanned, 0x80) == 0x80
                if isScanned then
                    areaLoots.scannedSources[sourceID] = true
                end
                for l = 1, harvestTypesSize, 1 do
                    local harvestTypeID = v.readVarInt()
                    local harvestType = { harvestTypeID = harvestTypeID, loots = {} }
                    local lootSize = v.readVarInt()
                    for m = 1, lootSize, 1 do
                        local itemID = v.readVarInt()
                        local dropRate = v.readVarInt()
                        local weight = v.readVarInt()
                        local minQt = v.readVarInt()
                        local maxQt = v.readVarInt()
                        harvestType.loots[itemID] = {
                            itemID = itemID,
                            dropRate = dropRate,
                            weight = weight,
                            minQt =
                                minQt,
                            maxQt = maxQt
                        }
                    end
                    source.harvestTypes[harvestTypeID] = harvestType
                end
                sourceType.sources[sourceID] = source
            end
            difficulty.sourceTypes[sourceTypeID] = sourceType
        end
        areaLoots.difficulties[diffID] = difficulty
    end
    local additionalScnSize = v.readVarInt()
    for i = 1, additionalScnSize, 1 do
        local sourceID = v.readVarInt()
        areaLoots.scannedSources[sourceID] = true
    end
    return areaLoots
end

function ns:ParseAreaLocales(area)
    local zipped = base64:decode(area.lstr)
    local bin = LibDeflate:DecompressZlib(zipped)
    local v = DataView:new(bin)
    local locales = {}
    local localeTypesSize = v.readVarInt()
    for i = 1, localeTypesSize, 1 do
        local localeType = v.readVarInt()
        locales[localeType] = {}
        local localeSize = v.readVarInt()
        for j = 1, localeSize, 1 do
            local localeKey = v.readVarInt()
            local localeStr = v.readString()
            locales[localeType][localeKey] = localeStr
        end
    end
    return locales
end

function ns:parseScanned(binstr)
    local bin = base64:decode(binstr)
    local v = DataView:new(bin)
    local scanned = {}
    local scannedTypeSize = v.readVarInt()
    for i = 1, scannedTypeSize, 1 do
        local scannedType = v.readVarInt()
        local scannedSize = v.readVarInt()
        scanned[scannedType] = {}
        for j = 1, scannedSize, 1 do
            local scannedID = v.readVarInt()
            scanned[scannedType][scannedID] = true
        end
    end
    return scanned
end
