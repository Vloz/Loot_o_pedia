local addon, ns = ...



local localizedCreatureTypes = {
    enUS = {
        ["Aberration"] = 1,
        ["Beast"] = 2,
        ["Critter"] = 3,
        ["Demon"] = 4,
        ["Dragonkin"] = 5,
        ["Elemental"] = 6,
        ["Giant"] = 7,
        ["Humanoid"] = 8,
        ["Mechanical"] = 9,
        ["Not specified"] = 10,
        ["Totem"] = 11,
        ["Undead"] = 12,
        ["Non-combat Pet"] = 13,
        ["Gas Cloud"] = 14,
    },
    frFR = {
        ["Aberration"] = 1,
        ["Bête"] = 2,
        ["Bestiole"] = 3,
        ["Démon"] = 4,
        ["Draconien"] = 5,
        ["Élémentaire"] = 6,
        ["Géant"] = 7,
        ["Humanoïde"] = 8,
        ["Mécanique"] = 9,
        ["Non spécifié"] = 10,
        ["Totem"] = 11,
        ["Mort-vivant"] = 12,
        ["Familier pacifique"] = 13,
        ["Nuage de gaz"] = 14,
    },
    deDE = {
        ["Aberration"] = 1,
        ["Wildtier"] = 2,
        ["Kleintier"] = 3,
        ["Dämon"] = 4,
        ["Drachkin"] = 5,
        ["Elementar"] = 6,
        ["Riese"] = 7,
        ["Humanoid"] = 8,
        ["Mechanisch"] = 9,
        ["Nicht spezifiziert"] = 10,
        ["Totem"] = 11,
        ["Untoter"] = 12,
        ["Haustier"] = 13,
        ["Gaswolke"] = 14,
    },
    esES = {
        ["Aberración"] = 1,
        ["Bestia"] = 2,
        ["Alma"] = 3,
        ["Demonio"] = 4,
        ["Dragón"] = 5,
        ["Elemental"] = 6,
        ["Gigante"] = 7,
        ["Humanoide"] = 8,
        ["Mecánico"] = 9,
        ["No especificado"] = 10,
        ["Tótem"] = 11,
        ["No-muerto"] = 12,
        ["Mascota no combatiente"] = 13,
        ["Nube de gas"] = 14,
    },
    itIT = {
        ["Aberrazione"] = 1,
        ["Bestia"] = 2,
        ["Animale"] = 3,
        ["Demone"] = 4,
        ["Dragoide"] = 5,
        ["Elementale"] = 6,
        ["Gigante"] = 7,
        ["Umanoide"] = 8,
        ["Meccanico"] = 9,
        ["Non specificato"] = 10,
        ["Totem"] = 11,
        ["Non morto"] = 12,
        ["Animale non combattente"] = 13,
        ["Nube di gas"] = 14,
    },
    ptBR = {
        ["Aberração"] = 1,
        ["Fera"] = 2,
        ["Bicho"] = 3,
        ["Demônio"] = 4,
        ["Dracônico"] = 5,
        ["Elemental"] = 6,
        ["Gigante"] = 7,
        ["Humanoide"] = 8,
        ["Mecânico"] = 9,
        ["Não especificado"] = 10,
        ["Totem"] = 11,
        ["Mortos-vivos"] = 12,
        ["Mascote pacífica"] = 13,
        ["Nuvem de gás"] = 14,
    },
    ruRU = {
        ["Абберация"] = 1,
        ["Животное"] = 2,
        ["Существо"] = 3,
        ["Демон"] = 4,
        ["Дракон"] = 5,
        ["Элементаль"] = 6,
        ["Гигант"] = 7,
        ["Гуманоид"] = 8,
        ["Механизм"] = 9,
        ["Не указано"] = 10,
        ["Тотем"] = 11,
        ["Нежить"] = 12,
        ["Спутник"] = 13,
        ["Газовое облако"] = 14,
    },
}

function ns:GetCreatureTypeID(creatureType)
    local locale = GetLocale()
    local types = localizedCreatureTypes[locale]
    if types and types[creatureType] then
        return types[creatureType]
    end
    return 0 -- Unknown
end
