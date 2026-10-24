-- Horse Genetics for Farming Simulator 25

HorseGenetics = HorseGenetics or {}

-- Keep the mod path; FS25 can clear g_currentModDirectory after load.
HorseGenetics.modDirectory = g_currentModDirectory

HorseGenetics.horses = {}

local function hgT(key, ...)
    local text = tostring(key or "")
    if g_i18n ~= nil and g_i18n.getText ~= nil then
        local ok, result = pcall(function()
            return g_i18n:getText(key)
        end)
        if ok and type(result) == "string" and result ~= "" then
            text = result
        end
    end
    if select("#", ...) > 0 then
        local formatted = string.format(text, ...)
        if formatted ~= nil then
            return formatted
        end
    end
    return text
end

local HG_COAT_L10N = {
    Bay = "hg_coat_bay",
    Black = "hg_coat_black",
    Chestnut = "hg_coat_chestnut",
    Grey = "hg_coat_grey",
    Palomino = "hg_coat_palomino",
    Buckskin = "hg_coat_buckskin",
    Pinto = "hg_coat_pinto",
    ["Seal Brown"] = "hg_coat_sealbrown"
}

local function hgCoatText(coatColour)
    local key = HG_COAT_L10N[coatColour]
    if key ~= nil then
        return hgT(key)
    end
    if coatColour == nil or coatColour == "" then
        return hgT("hg_unknown")
    end
    return tostring(coatColour)
end


local function hgGetOwnerFarmId(object)
    if object == nil then
        return nil
    end
    if object.getOwnerFarmId ~= nil then
        local ok, farmId = pcall(function()
            return object:getOwnerFarmId()
        end)
        if ok and type(farmId) == "number" and farmId > 0 then
            return farmId
        end
    end
    if type(object.ownerFarmId) == "number" and object.ownerFarmId > 0 then
        return object.ownerFarmId
    end
    return nil
end

HorseGenetics.STAT_NAMES = {
    "speed",
    "stamina",
    "health"
}

HorseGenetics.COAT_COLOURS = {
    "Bay",
    "Black",
    "Chestnut",
    "Grey",
    "Palomino",
    "Buckskin",
    "Pinto",
    "Seal Brown"
}

HorseGenetics.nextHorseId = 1
HorseGenetics.recordsReady = false

local function hgApplyHorseDataFile()
    local data = HorseGenetics.HORSE_DATA
    if type(data) ~= "table" then
        return
    end
    if type(data.nextHorseId) == "number" and data.nextHorseId > 0 then
        HorseGenetics.nextHorseId = data.nextHorseId
    end
    if type(data.coatColours) == "table" and data.coatColours[1] ~= nil then
        HorseGenetics.COAT_COLOURS = data.coatColours
    end
end
hgApplyHorseDataFile()

HorseGenetics.xmlSchema = XMLSchema.new("horseGenetics")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics#version", "Save format version")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics#nextHorseId", "Next unique horse ID")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.horse(?)#id", "Horse ID")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.horse(?)#name", "Horse name")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.horse(?)#generation", "Generation")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.horse(?)#coatColour", "Coat colour")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.horse(?)#mareId", "Mother ID")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.horse(?)#stallionId", "Father ID")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.horse(?)#speed", "Speed")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.horse(?)#stamina", "Stamina")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.horse(?)#health", "Health")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.horse(?)#farmId", "Farm ID")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.horse(?)#soldPrice", "Sold price")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.horse(?)#lastKnownSellPrice", "Last shop sell price")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.horse(?)#lastAgeMonths", "Last known age in months")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics#gestationMonths", "Gestation months")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics#pubertyMonths", "Puberty months")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics#valueModifierPercent", "Sale modifier strength")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#parent1Id", "History parent 1")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#parent1Name", "History parent 1 name")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#parent2Id", "History parent 2")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#parent2Name", "History parent 2 name")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#foal1Id", "History foal 1")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#foal1Name", "History foal 1 name")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#foal1Coat", "History foal 1 coat")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.history(?)#foal1Speed", "History foal 1 speed")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.history(?)#foal1Stamina", "History foal 1 stamina")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.history(?)#foal1Health", "History foal 1 health")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#foal2Id", "History foal 2")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#foal2Name", "History foal 2 name")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.history(?)#foal2Coat", "History foal 2 coat")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.history(?)#foal2Speed", "History foal 2 speed")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.history(?)#foal2Stamina", "History foal 2 stamina")
HorseGenetics.xmlSchema:register(XMLValueType.FLOAT, "horseGenetics.history(?)#foal2Health", "History foal 2 health")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.pregnancy(?)#husbandryId", "Stable id")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.pregnancy(?)#parent1Id", "Parent 1")
HorseGenetics.xmlSchema:register(XMLValueType.STRING, "horseGenetics.pregnancy(?)#parent2Id", "Parent 2")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.pregnancy(?)#monthsRemaining", "Months left")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.pregnancy(?)#monthsElapsed", "Months elapsed")
HorseGenetics.xmlSchema:register(XMLValueType.INT, "horseGenetics.pregnancy(?)#farmId", "Farm id")

HorseGenetics.breedingHistory = {}
HorseGenetics.pregnancies = {}
HorseGenetics.VANILLA_GESTATION_MONTHS = 11
HorseGenetics.VANILLA_MATURITY_MONTHS = 22
HorseGenetics.GESTATION_OPTIONS = {1, 3, 6, 8, 11, 14, 16, 18, 22}
HorseGenetics.MATURITY_OPTIONS = {1, 3, 6, 8, 11, 14, 16, 18, 22}
HorseGenetics.VALUE_MODIFIER_OPTIONS = {0, 25, 50, 75, 100, 125, 150, 175, 200}
HorseGenetics.settings = {
    gestationMonths = HorseGenetics.VANILLA_GESTATION_MONTHS,
    pubertyMonths = HorseGenetics.VANILLA_MATURITY_MONTHS,
    valueModifierPercent = 100
}

function HorseGenetics.clampChoice(value, options, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback
    end
    for i = 1, #options do
        if options[i] == value then
            return value
        end
    end
    local nearest, best = fallback, math.huge
    for i = 1, #options do
        local d = math.abs(options[i] - value)
        if d < best then
            nearest, best = options[i], d
        end
    end
    return nearest
end

function HorseGenetics.isEnhancedAnimalSystemActive()
    if HorseGenetics._easActive == true then
        return true
    end
    if g_eas_animalSystem ~= nil
        or EAS_AnimalSystem ~= nil
        or EAS_AnimalCluster ~= nil
        or EAS_PlaceableHusbandryAnimals ~= nil then
        HorseGenetics._easActive = true
        return true
    end
    local names = {
        "FS25_EnhancedAnimalSystem",
        "EnhancedAnimalSystem"
    }
    if type(g_modIsLoaded) == "table" then
        for i = 1, #names do
            if g_modIsLoaded[names[i]] then
                HorseGenetics._easActive = true
                return true
            end
        end
    end
    return false
end

function HorseGenetics.getGestationMonths()
    return HorseGenetics.clampChoice(
        HorseGenetics.settings.gestationMonths,
        HorseGenetics.GESTATION_OPTIONS,
        HorseGenetics.VANILLA_GESTATION_MONTHS
    )
end

function HorseGenetics.getPubertyMonths()
    return HorseGenetics.clampChoice(
        HorseGenetics.settings.pubertyMonths,
        HorseGenetics.MATURITY_OPTIONS,
        HorseGenetics.VANILLA_MATURITY_MONTHS
    )
end

function HorseGenetics.getValueModifierPercent()
    return HorseGenetics.clampChoice(HorseGenetics.settings.valueModifierPercent, HorseGenetics.VALUE_MODIFIER_OPTIONS, 100)
end

function HorseGenetics.getValueModifierStrength()
    return HorseGenetics.getValueModifierPercent() / 100
end

function HorseGenetics.gestationLabel(months)
    months = HorseGenetics.clampChoice(months, HorseGenetics.GESTATION_OPTIONS, HorseGenetics.VANILLA_GESTATION_MONTHS)
    if months == HorseGenetics.VANILLA_GESTATION_MONTHS then
        return hgT("hg_months_vanilla")
    end
    if months == 1 then
        return hgT("hg_month_one")
    end
    return hgT("hg_months_n", months)
end

function HorseGenetics.pubertyLabel(months)
    months = HorseGenetics.clampChoice(months, HorseGenetics.MATURITY_OPTIONS, HorseGenetics.VANILLA_MATURITY_MONTHS)
    if months == HorseGenetics.VANILLA_MATURITY_MONTHS then
        return hgT("hg_puberty_vanilla")
    end
    if months == 1 then
        return hgT("hg_month_one")
    end
    return hgT("hg_months_n", months)
end

function HorseGenetics.valueModifierLabel(percent)
    percent = HorseGenetics.clampChoice(percent, HorseGenetics.VALUE_MODIFIER_OPTIONS, 100)
    if percent == 0 then
        return hgT("hg_value_off")
    end
    if percent == 100 then
        return hgT("hg_value_default")
    end
    return tostring(percent) .. "%"
end

function HorseGenetics.applySettings(gestationMonths, valueModifierPercent, pubertyMonths, skipNetwork)
    HorseGenetics.settings.gestationMonths = HorseGenetics.clampChoice(
        gestationMonths, HorseGenetics.GESTATION_OPTIONS, HorseGenetics.VANILLA_GESTATION_MONTHS)
    HorseGenetics.settings.valueModifierPercent = HorseGenetics.clampChoice(
        valueModifierPercent, HorseGenetics.VALUE_MODIFIER_OPTIONS, 100)
    HorseGenetics.settings.pubertyMonths = HorseGenetics.clampChoice(
        pubertyMonths, HorseGenetics.MATURITY_OPTIONS, HorseGenetics.VANILLA_MATURITY_MONTHS)
    for _, entry in ipairs(HorseGenetics.pregnancies or {}) do
        HorseGenetics.normalizePregnancy(entry)
    end
    if HorseGenetics.applyPubertyToHorseSubtypes ~= nil then
        HorseGenetics.applyPubertyToHorseSubtypes()
    end
    if HorseGenetics.notifyUiDirty ~= nil then
        HorseGenetics.notifyUiDirty()
    end
    if HorseGenetics.syncAllReproductionVisuals ~= nil then
        HorseGenetics.syncAllReproductionVisuals()
    end
    if skipNetwork ~= true and HorseGenetics.isAuthoritative() then
        HorseGenetics:saveToSavegame()
        if HorseGenetics.isMultiplayer() and HorseGeneticsSettingsEvent ~= nil and g_server ~= nil then
            g_server:broadcastEvent(HorseGeneticsSettingsEvent.newFromCurrent(), false)
        end
    end
end

function HorseGenetics.requestSetSettings(gestationMonths, valueModifierPercent, pubertyMonths)
    if HorseGenetics.isAuthoritative() then
        HorseGenetics.applySettings(gestationMonths, valueModifierPercent, pubertyMonths)
        return
    end
    if g_client == nil or HorseGeneticsSettingsEvent == nil then
        return
    end
    local connection = g_client.getServerConnection ~= nil and g_client:getServerConnection() or nil
    if connection ~= nil then
        connection:sendEvent(HorseGeneticsSettingsEvent.new(gestationMonths, valueModifierPercent, pubertyMonths))
    end
end

function HorseGenetics.cycleSetting(options, current, direction)
    local index = 1
    for i = 1, #options do
        if options[i] == current then
            index = i
            break
        end
    end
    index = index + (direction or 1)
    if index < 1 then
        index = #options
    elseif index > #options then
        index = 1
    end
    return options[index]
end

function HorseGenetics.generateHorseId()
    local id = HorseGenetics.nextHorseId

    HorseGenetics.nextHorseId = HorseGenetics.nextHorseId + 1

    return "HG-" .. string.format("%06d", id)
end

function HorseGenetics.createHorse(name, stats, coatColour, generation, mareId, stallionId, farmId)
    if type(name) ~= "string" or name == "" then
        return nil, "Horse must have a name."
    end

    if type(stats) ~= "table" then
        return nil, "Horse must have genetic stats."
    end

    for _, statName in ipairs(HorseGenetics.STAT_NAMES) do
        if type(stats[statName]) ~= "number" then
            return nil, "Missing genetic stat: " .. statName
        end

        if stats[statName] < 0 or stats[statName] > 100 then
            return nil, "Genetic stat out of range: " .. statName
        end
    end

    local validColour = false

    for _, colour in ipairs(HorseGenetics.COAT_COLOURS) do
        if colour == coatColour then
            validColour = true
            break
        end
    end

    if not validColour then
        return nil, "Invalid coat colour: " .. tostring(coatColour)
    end

    if HorseGenetics.suppressNetworkUpdates ~= true
        and HorseGenetics.isAuthoritative ~= nil
        and not HorseGenetics.isAuthoritative() then
        return nil, "Genetics records are created on the server."
    end

    local horse = {
        id = HorseGenetics.generateHorseId(),
        name = name,
        generation = generation or 1,
        stats = {
            speed = stats.speed,
            stamina = stats.stamina,
            health = stats.health
        },
        coatColour = coatColour,
        mareId = mareId,
        stallionId = stallionId,
        farmId = farmId
    }

    HorseGenetics.horses[horse.id] = horse
    if HorseGenetics.suppressNetworkUpdates ~= true and HorseGenetics.broadcastHorseRecord ~= nil then
        HorseGenetics.broadcastHorseRecord(horse)
    end

    return horse
end


-- 45% parent A, 45% parent B, 10% another listed coat.
function HorseGenetics.inheritCoatColour(mareColour, stallionColour)
    local roll = math.random(1, 100)

    if roll <= 45 then
        return mareColour
    end

    if roll <= 90 then
        return stallionColour
    end

    local availableColours = {}

    for _, colour in ipairs(HorseGenetics.COAT_COLOURS) do
        if colour ~= mareColour and colour ~= stallionColour then
            table.insert(availableColours, colour)
        end
    end

    if #availableColours == 0 then
        return mareColour
    end

    return availableColours[math.random(1, #availableColours)]
end

function HorseGenetics.clampStat(value)
    return math.max(0, math.min(100, math.floor(value + 0.5)))
end

function HorseGenetics.generateInitialStats()
    local stats = {}

    for _, statName in ipairs(HorseGenetics.STAT_NAMES) do
        stats[statName] = math.random(35, 75)
    end

    return stats
end

function HorseGenetics.calculateAverage(stats)
    local total = 0
    local count = 0

    for _, statName in ipairs(HorseGenetics.STAT_NAMES) do
        local value = stats[statName]

        if type(value) == "number" then
            total = total + value
            count = count + 1
        end
    end

    if count == 0 then
        return 0
    end

    return total / count
end

function HorseGenetics.calculatePairingScore(mareStats, stallionStats)
    local mareAverage = HorseGenetics.calculateAverage(mareStats)
    local stallionAverage = HorseGenetics.calculateAverage(stallionStats)

    local combinedAverage = (mareAverage + stallionAverage) / 2

    return HorseGenetics.clampStat(combinedAverage)
end

-- Foal stats: parental average, then -8 to +8. Pairing 70+ can add +1 to +3 (20% per stat).
function HorseGenetics.breed(mareStats, stallionStats, mareColour, stallionColour)
    local foalStats = {}
    local pairingScore = HorseGenetics.calculatePairingScore(mareStats, stallionStats)

    for _, statName in ipairs(HorseGenetics.STAT_NAMES) do
        local mareValue = mareStats[statName]
        local stallionValue = stallionStats[statName]

        if type(mareValue) ~= "number" or type(stallionValue) ~= "number" then
            return nil, "Missing parental stat: " .. statName
        end

        local parentalAverage = (mareValue + stallionValue) / 2
        local variation = math.random(-8, 8)
        local improvement = 0
        if pairingScore >= 70 and math.random(1, 100) <= 20 then
            improvement = math.random(1, 3)
        end

        foalStats[statName] = HorseGenetics.clampStat(parentalAverage + variation + improvement)
    end

    return {
        stats = foalStats,
        coatColour = HorseGenetics.inheritCoatColour(mareColour, stallionColour)
    }
end

function HorseGenetics:saveToXMLFile(xmlFile, key)
    xmlFile:setInt(key .. "#version", 1)
    xmlFile:setInt(key .. "#nextHorseId", self.nextHorseId)
    xmlFile:setInt(key .. "#gestationMonths", HorseGenetics.getGestationMonths())
    xmlFile:setInt(key .. "#pubertyMonths", HorseGenetics.getPubertyMonths())
    xmlFile:setInt(key .. "#valueModifierPercent", HorseGenetics.getValueModifierPercent())

    local index = 0

    for _, horse in pairs(self.horses) do
        local horseKey = string.format("%s.horse(%d)", key, index)

        xmlFile:setValue(horseKey .. "#id", horse.id)
        xmlFile:setValue(horseKey .. "#name", horse.name)
        xmlFile:setInt(horseKey .. "#generation", horse.generation)
        xmlFile:setValue(horseKey .. "#coatColour", horse.coatColour)

        xmlFile:setValue(horseKey .. "#mareId", horse.mareId or "")
        xmlFile:setValue(horseKey .. "#stallionId", horse.stallionId or "")

        xmlFile:setFloat(horseKey .. "#speed", horse.stats.speed)
        xmlFile:setFloat(horseKey .. "#stamina", horse.stats.stamina)
        xmlFile:setFloat(horseKey .. "#health", horse.stats.health)
        xmlFile:setInt(horseKey .. "#farmId", horse.farmId or 0)
        xmlFile:setInt(horseKey .. "#soldPrice", horse.soldPrice or 0)
        xmlFile:setInt(horseKey .. "#lastKnownSellPrice", horse.lastKnownSellPrice or 0)
        xmlFile:setInt(horseKey .. "#lastAgeMonths", horse.lastAgeMonths or -1)

        index = index + 1
    end

    local history = self.breedingHistory or {}
    for i, entry in ipairs(history) do
        local historyKey = string.format("%s.history(%d)", key, i - 1)
        xmlFile:setValue(historyKey .. "#parent1Id", entry.parent1Id or "")
        xmlFile:setValue(historyKey .. "#parent1Name", entry.parent1Name or "")
        xmlFile:setValue(historyKey .. "#parent2Id", entry.parent2Id or "")
        xmlFile:setValue(historyKey .. "#parent2Name", entry.parent2Name or "")
        xmlFile:setValue(historyKey .. "#foal1Id", entry.foal1Id or "")
        xmlFile:setValue(historyKey .. "#foal1Name", entry.foal1Name or "")
        xmlFile:setValue(historyKey .. "#foal1Coat", entry.foal1Coat or "")
        xmlFile:setFloat(historyKey .. "#foal1Speed", entry.foal1Speed or 0)
        xmlFile:setFloat(historyKey .. "#foal1Stamina", entry.foal1Stamina or 0)
        xmlFile:setFloat(historyKey .. "#foal1Health", entry.foal1Health or 0)
        xmlFile:setValue(historyKey .. "#foal2Id", entry.foal2Id or "")
        xmlFile:setValue(historyKey .. "#foal2Name", entry.foal2Name or "")
        xmlFile:setValue(historyKey .. "#foal2Coat", entry.foal2Coat or "")
        xmlFile:setFloat(historyKey .. "#foal2Speed", entry.foal2Speed or 0)
        xmlFile:setFloat(historyKey .. "#foal2Stamina", entry.foal2Stamina or 0)
        xmlFile:setFloat(historyKey .. "#foal2Health", entry.foal2Health or 0)
    end

    local pregnancies = self.pregnancies or {}
    for i, entry in ipairs(pregnancies) do
        local pregnancyKey = string.format("%s.pregnancy(%d)", key, i - 1)
        xmlFile:setValue(pregnancyKey .. "#husbandryId", entry.husbandryId or "")
        xmlFile:setValue(pregnancyKey .. "#parent1Id", entry.parent1Id or "")
        xmlFile:setValue(pregnancyKey .. "#parent2Id", entry.parent2Id or "")
        xmlFile:setInt(pregnancyKey .. "#monthsRemaining", entry.monthsRemaining or 0)
        xmlFile:setInt(pregnancyKey .. "#monthsElapsed", entry.monthsElapsed or 0)
        xmlFile:setInt(pregnancyKey .. "#farmId", entry.farmId or 0)
    end
end

function HorseGenetics:loadFromXMLFile(xmlFile, key)
    self.horses = {}
    self.breedingHistory = {}
    self.pregnancies = {}

    self.nextHorseId = xmlFile:getInt(
        key .. "#nextHorseId",
        1
    )
    HorseGenetics.applySettings(
        xmlFile:getInt(key .. "#gestationMonths", HorseGenetics.VANILLA_GESTATION_MONTHS),
        xmlFile:getInt(key .. "#valueModifierPercent", 100),
        xmlFile:getInt(key .. "#pubertyMonths", HorseGenetics.VANILLA_MATURITY_MONTHS),
        true
    )

    local index = 0

    while true do
        local horseKey = string.format(
            "%s.horse(%d)",
            key,
            index
        )
        if not xmlFile:hasProperty(horseKey .. "#id") then
            break
        end

        local horseId = xmlFile:getValue(horseKey .. "#id")

        local horse = {
            id = horseId,
            name = xmlFile:getValue(horseKey .. "#name", "Unnamed"),
            generation = xmlFile:getInt(
                horseKey .. "#generation",
                1
            ),
            coatColour = xmlFile:getValue(
                horseKey .. "#coatColour",
                "Bay"
            ),
            mareId = xmlFile:getValue(horseKey .. "#mareId"),
            stallionId = xmlFile:getValue(horseKey .. "#stallionId"),
            stats = {
                speed = xmlFile:getFloat(horseKey .. "#speed", 50),
                stamina = xmlFile:getFloat(horseKey .. "#stamina", 50),
                health = xmlFile:getFloat(horseKey .. "#health", 50)
            },
            farmId = xmlFile:getInt(horseKey .. "#farmId", 0),
            soldPrice = xmlFile:getInt(horseKey .. "#soldPrice", 0),
            lastKnownSellPrice = xmlFile:getInt(horseKey .. "#lastKnownSellPrice", 0),
            lastAgeMonths = xmlFile:getInt(horseKey .. "#lastAgeMonths", -1)
        }

        if horse.farmId == 0 then
            horse.farmId = nil
        end
        if horse.soldPrice == 0 then
            horse.soldPrice = nil
        end
        if horse.lastKnownSellPrice == 0 then
            horse.lastKnownSellPrice = nil
        end
        if horse.lastAgeMonths ~= nil and horse.lastAgeMonths < 0 then
            horse.lastAgeMonths = nil
        end

        if horse.mareId == "" then
            horse.mareId = nil
        end

        if horse.stallionId == "" then
            horse.stallionId = nil
        end

        self.horses[horseId] = horse

        index = index + 1
    end

    local historyIndex = 0
    while true do
        local historyKey = string.format("%s.history(%d)", key, historyIndex)
        if not xmlFile:hasProperty(historyKey .. "#parent1Id") then
            break
        end
        table.insert(self.breedingHistory, {
            parent1Id = xmlFile:getValue(historyKey .. "#parent1Id"),
            parent1Name = xmlFile:getValue(historyKey .. "#parent1Name", ""),
            parent2Id = xmlFile:getValue(historyKey .. "#parent2Id"),
            parent2Name = xmlFile:getValue(historyKey .. "#parent2Name", ""),
            foal1Id = xmlFile:getValue(historyKey .. "#foal1Id"),
            foal1Name = xmlFile:getValue(historyKey .. "#foal1Name", ""),
            foal1Coat = xmlFile:getValue(historyKey .. "#foal1Coat", ""),
            foal1Speed = xmlFile:getFloat(historyKey .. "#foal1Speed", 0),
            foal1Stamina = xmlFile:getFloat(historyKey .. "#foal1Stamina", 0),
            foal1Health = xmlFile:getFloat(historyKey .. "#foal1Health", 0),
            foal2Id = xmlFile:getValue(historyKey .. "#foal2Id"),
            foal2Name = xmlFile:getValue(historyKey .. "#foal2Name", ""),
            foal2Coat = xmlFile:getValue(historyKey .. "#foal2Coat", ""),
            foal2Speed = xmlFile:getFloat(historyKey .. "#foal2Speed", 0),
            foal2Stamina = xmlFile:getFloat(historyKey .. "#foal2Stamina", 0),
            foal2Health = xmlFile:getFloat(historyKey .. "#foal2Health", 0)
        })
        historyIndex = historyIndex + 1
    end

    local pregnancyIndex = 0
    while true do
        local pregnancyKey = string.format("%s.pregnancy(%d)", key, pregnancyIndex)
        if not xmlFile:hasProperty(pregnancyKey .. "#parent1Id") then
            break
        end
        table.insert(self.pregnancies, {
            husbandryId = xmlFile:getValue(pregnancyKey .. "#husbandryId", ""),
            parent1Id = xmlFile:getValue(pregnancyKey .. "#parent1Id"),
            parent2Id = xmlFile:getValue(pregnancyKey .. "#parent2Id"),
            monthsRemaining = xmlFile:getInt(pregnancyKey .. "#monthsRemaining", HorseGenetics.getGestationMonths()),
            monthsElapsed = xmlFile:getInt(pregnancyKey .. "#monthsElapsed", -1),
            farmId = xmlFile:getInt(pregnancyKey .. "#farmId", 0)
        })
        HorseGenetics.normalizePregnancy(self.pregnancies[#self.pregnancies])
        pregnancyIndex = pregnancyIndex + 1
    end
end

function HorseGenetics:saveToSavegame()
    if HorseGenetics.isAuthoritative ~= nil and not HorseGenetics.isAuthoritative() then
        return
    end
    if g_currentMission == nil
        or g_currentMission.missionInfo == nil then
        return
    end

    local savegameDirectory =
        g_currentMission.missionInfo.savegameDirectory

    if savegameDirectory == nil then
        return
    end

    local xmlPath = savegameDirectory .. "/horseGenetics.xml"
    local xmlFile = XMLFile.create(
    "horseGeneticsXML",
    xmlPath,
    "horseGenetics",
    HorseGenetics.xmlSchema
)

    if xmlFile == nil then
        return
    end

    self:saveToXMLFile(xmlFile, "horseGenetics")
    xmlFile:save()
    xmlFile:delete()
end

function HorseGenetics:loadFromSavegame()
    if HorseGenetics.isAuthoritative ~= nil and not HorseGenetics.isAuthoritative() then
        return
    end
    if g_currentMission == nil
        or g_currentMission.missionInfo == nil then
        return
    end

    local savegameDirectory =
        g_currentMission.missionInfo.savegameDirectory

    if savegameDirectory == nil then
        return
    end

    local xmlPath = savegameDirectory .. "/horseGenetics.xml"

    if not fileExists(xmlPath) then
        return
    end

    local xmlFile = XMLFile.load(
    "horseGeneticsXML",
    xmlPath,
    HorseGenetics.xmlSchema
)

    if xmlFile == nil then
        return
    end

    self:loadFromXMLFile(xmlFile, "horseGenetics")
    xmlFile:delete()
    HorseGenetics.recordsReady = true
    HorseGenetics.pruneDuplicateRecords()
    if HorseGenetics.syncAllReproductionVisuals ~= nil then
        HorseGenetics.syncAllReproductionVisuals()
    end
end

-- Save with the career save.
if FSCareerMissionInfo ~= nil
    and FSCareerMissionInfo.saveToXMLFile ~= nil then
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(
        FSCareerMissionInfo.saveToXMLFile,
        function(missionInfo)
            HorseGenetics:saveToSavegame()
        end
    )
end

-- Load (or request a multiplayer sync) when the mission starts.
if Mission00 ~= nil and Mission00.onStartMission ~= nil then
    Mission00.onStartMission = Utils.appendedFunction(
        Mission00.onStartMission,
        function(mission)
            HorseGenetics.installNetworkHooks()
            if HorseGenetics.isAuthoritative() then
                HorseGenetics:loadFromSavegame()
                HorseGenetics.recordsReady = true
                HorseGenetics.ensureLiveHorseRecords()
            else
                HorseGenetics.requestSync()
            end
            HorseGenetics:installCoreIntegrations()
            if HorseGenetics.syncAllReproductionVisuals ~= nil then
                HorseGenetics.syncAllReproductionVisuals()
            end
        end
    )
end

function HorseGenetics.installClusterPersistence()
    if AnimalClusterSystem ~= nil
        and AnimalClusterSystem.registerSavegameXMLPaths ~= nil
        and not AnimalClusterSystem.horseGeneticsSchemaInstalled then

        local originalRegisterAnimalClusterPaths =
            AnimalClusterSystem.registerSavegameXMLPaths

        AnimalClusterSystem.registerSavegameXMLPaths = function(schema, basePath, ...)
            originalRegisterAnimalClusterPaths(schema, basePath, ...)
            schema:register(
                XMLValueType.STRING,
                basePath .. ".animal(?)#horseGeneticsId",
                "Horse Genetics persistent horse identifier"
            )
        end

        AnimalClusterSystem.horseGeneticsSchemaInstalled = true
    end

    local function installClassPersistence(classTable)
        if classTable == nil
            or classTable.saveToXMLFile == nil
            or classTable.loadFromXMLFile == nil
            or classTable.horseGeneticsPersistenceInstalled then
            return
        end
        local originalSave = classTable.saveToXMLFile
        local originalLoad = classTable.loadFromXMLFile
        classTable.saveToXMLFile = function(self, xmlFile, key, usedModNames)
            local result = originalSave(self, xmlFile, key, usedModNames)
            if self.horseGeneticsId ~= nil then
                xmlFile:setValue(key .. "#horseGeneticsId", self.horseGeneticsId)
            end
            return result
        end
        classTable.loadFromXMLFile = function(self, xmlFile, key, ...)
            local result = originalLoad(self, xmlFile, key, ...)
            self.horseGeneticsId = xmlFile:getValue(key .. "#horseGeneticsId")
            return result
        end
        classTable.horseGeneticsPersistenceInstalled = true
    end

    installClassPersistence(AnimalCluster)
    installClassPersistence(AnimalClusterHorse)
end

HorseGenetics.installClusterPersistence()

-- Never wrap AnimalCluster readStream/writeStream. Extra bytes desync vanilla
-- AnimalClusterUpdateEvent on dedicated join (nil:readStream) and can leave
-- later clusters in the same packet unbound (missing age on MP clients).
-- horseGeneticsId is kept in save XML and synced with HorseGeneticsSyncEvent.

if AnimalCluster ~= nil and AnimalCluster.clone ~= nil and not AnimalCluster.horseGeneticsCloneInstalled then
    local originalClone = AnimalCluster.clone
    AnimalCluster.clone = function(self, ...)
        local copy = originalClone(self, ...)
        if copy ~= nil and self ~= nil then
            copy.horseGeneticsId = self.horseGeneticsId
        end
        return copy
    end
    AnimalCluster.horseGeneticsCloneInstalled = true
end

-- Coat from the animal subtype when a shop horse is first recorded.
function HorseGenetics.getCoatColourFromCluster(cluster)
    if cluster ~= nil and cluster.getSubTypeIndex ~= nil
        and g_currentMission ~= nil
        and g_currentMission.animalSystem ~= nil then

        local subType = g_currentMission.animalSystem:getSubTypeByIndex(
            cluster:getSubTypeIndex()
        )

        if subType ~= nil and subType.name ~= nil then
            local name = string.upper(subType.name)

            if string.find(name, "SEAL", 1, true) then return "Seal Brown" end
            if string.find(name, "BLACK", 1, true) then return "Black" end
            if string.find(name, "GRAY", 1, true)
                or string.find(name, "GREY", 1, true) then return "Grey" end
            if string.find(name, "CHESTNUT", 1, true) then return "Chestnut" end
            if string.find(name, "PALOMINO", 1, true) then return "Palomino" end
            if string.find(name, "DUN", 1, true)
                or string.find(name, "BUCKSKIN", 1, true) then return "Buckskin" end
            if string.find(name, "PINTO", 1, true) then return "Pinto" end
        end
    end

    return "Bay"
end

function HorseGenetics.getClusterName(cluster)
    if cluster == nil then
        return nil
    end
    if cluster.getName ~= nil then
        local ok, name = pcall(function()
            return cluster:getName()
        end)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(cluster.name) == "string" and cluster.name ~= "" then
        return cluster.name
    end
    return nil
end

local function hgInvoke(object, methodName)
    if object == nil or methodName == nil then
        return nil
    end
    local method = object[methodName]
    if type(method) == "function" then
        local ok, result = pcall(method, object)
        if ok then
            return result
        end
        return nil
    end
    return method
end

function HorseGenetics.isLikelyAnimalCluster(object)
    if object == nil or type(object) ~= "table" then
        return false
    end
    if object.getSubTypeIndex ~= nil or object.subTypeIndex ~= nil then
        return true
    end
    local okIsa = false
    pcall(function()
        if object.isa ~= nil then
            if AnimalClusterHorse ~= nil and object:isa(AnimalClusterHorse) then
                okIsa = true
            elseif AnimalCluster ~= nil and object:isa(AnimalCluster) then
                okIsa = true
            elseif AnimalItemHorse ~= nil and object:isa(AnimalItemHorse) then
                okIsa = true
            end
        end
    end)
    if okIsa then
        return true
    end
    return object.numAnimals ~= nil and (object.age ~= nil or object.getAge ~= nil)
end

function HorseGenetics.addClustersFromTable(list, seen, clusters, depth)
    if clusters == nil or seen == nil or list == nil then
        return
    end
    depth = depth or 0
    if depth > 4 then
        return
    end
    if HorseGenetics.isLikelyAnimalCluster(clusters) then
        if seen[clusters] ~= true then
            seen[clusters] = true
            list[#list + 1] = clusters
        end
        return
    end
    if type(clusters) ~= "table" then
        return
    end
    for _, value in pairs(clusters) do
        if HorseGenetics.isLikelyAnimalCluster(value) then
            if seen[value] ~= true then
                seen[value] = true
                list[#list + 1] = value
            end
        elseif type(value) == "table" and depth < 3 then
            if value.cluster ~= nil and HorseGenetics.isLikelyAnimalCluster(value.cluster) then
                HorseGenetics.addClustersFromTable(list, seen, value.cluster, depth + 1)
            elseif value.clusters ~= nil or value.getClusters ~= nil then
                HorseGenetics.addClustersFromTable(list, seen, hgInvoke(value, "getClusters") or value.clusters, depth + 1)
            end
        end
    end
end

function HorseGenetics.getHusbandryClusters(husbandry)
    local list, seen = {}, {}
    if husbandry == nil then
        return list
    end
    local function addFrom(object)
        if object == nil then
            return
        end
        HorseGenetics.addClustersFromTable(list, seen, hgInvoke(object, "getClusters"))
        HorseGenetics.addClustersFromTable(list, seen, hgInvoke(object, "getAnimalItems"))
        HorseGenetics.addClustersFromTable(list, seen, hgInvoke(object, "getAnimals"))
        HorseGenetics.addClustersFromTable(list, seen, object.clusters)
        HorseGenetics.addClustersFromTable(list, seen, object.animalItems)
        local specs = {
            object.spec_husbandryAnimals,
            object.spec_husbandryMeadow,
            object.spec_pasture,
            object.spec_rideable,
            object.spec_livestockTrailer
        }
        for i = 1, #specs do
            local spec = specs[i]
            if spec ~= nil then
                HorseGenetics.addClustersFromTable(list, seen, hgInvoke(spec, "getClusters"))
                HorseGenetics.addClustersFromTable(list, seen, hgInvoke(spec, "getAnimalItems"))
                HorseGenetics.addClustersFromTable(list, seen, spec.clusters)
                HorseGenetics.addClustersFromTable(list, seen, spec.animalItems)
                if spec.clusterSystem ~= nil then
                    HorseGenetics.addClustersFromTable(list, seen, hgInvoke(spec.clusterSystem, "getClusters"))
                    HorseGenetics.addClustersFromTable(list, seen, spec.clusterSystem.clusters)
                end
                HorseGenetics.addClustersFromTable(list, seen, hgInvoke(spec, "getCluster") or spec.cluster)
            end
        end
        local system = hgInvoke(object, "getClusterSystem") or object.clusterSystem
        if system ~= nil then
            HorseGenetics.addClustersFromTable(list, seen, hgInvoke(system, "getClusters"))
            HorseGenetics.addClustersFromTable(list, seen, system.clusters)
        end
        HorseGenetics.addClustersFromTable(list, seen, hgInvoke(object, "getCluster") or object.cluster)
    end
    pcall(addFrom, husbandry)
    pcall(addFrom, husbandry.placeable)
    pcall(addFrom, husbandry.owner)
    pcall(addFrom, hgInvoke(husbandry, "getPlaceable"))
    pcall(addFrom, hgInvoke(husbandry, "getOwner"))
    return list
end

local function hgNamesMatch(a, b)
    if a == nil or b == nil or a == "" or b == "" then
        return false
    end
    return string.lower(tostring(a)) == string.lower(tostring(b))
end

function HorseGenetics.getClusterNumAnimals(cluster)
    if cluster == nil then
        return 0
    end
    local count = cluster.numAnimals
    if type(count) ~= "number" and cluster.getNumAnimals ~= nil then
        local ok, value = pcall(function()
            return cluster:getNumAnimals()
        end)
        if ok then
            count = value
        end
    end
    if type(count) ~= "number" then
        return 1
    end
    return count
end

function HorseGenetics.isLiveHorseCluster(cluster)
    return cluster ~= nil
        and HorseGenetics.isHorseCluster(cluster)
        and HorseGenetics.getClusterNumAnimals(cluster) > 0
end

function HorseGenetics.getLiveHorseCluster(object)
    if object == nil then
        return nil
    end
    local nested = object.cluster
    if type(nested) ~= "table" and type(object.getCluster) == "function" then
        pcall(function()
            nested = object:getCluster()
        end)
    end
    if type(nested) == "table" and nested ~= object then
        if nested.horseGeneticsId ~= nil or HorseGenetics.isHorseCluster(nested) then
            return nested
        end
    end
    return object
end

function HorseGenetics.getHorseGeneticsId(object)
    if object == nil then
        return nil
    end
    local live = HorseGenetics.getLiveHorseCluster(object)
    local horseId = live ~= nil and live.horseGeneticsId or nil
    if (horseId == nil or horseId == "") and object.horseGeneticsId ~= nil then
        horseId = object.horseGeneticsId
    end
    if horseId ~= nil and horseId ~= "" then
        return horseId
    end
    return nil
end

function HorseGenetics.getHorseForCluster(cluster)
    if cluster == nil then
        return nil
    end
    local live = HorseGenetics.getLiveHorseCluster(cluster)
    local horseId = live ~= nil and live.horseGeneticsId or cluster.horseGeneticsId
    if horseId ~= nil and HorseGenetics.horses[horseId] ~= nil then
        local horse = HorseGenetics.horses[horseId]
        local name = HorseGenetics.getClusterName(live) or HorseGenetics.getClusterName(cluster)
        if name ~= nil and name ~= "" then
            horse.name = name
        end
        return horse
    end
    return nil
end

function HorseGenetics.horseNumericId(horse)
    if horse == nil or horse.id == nil then
        return 0
    end
    return tonumber(string.match(tostring(horse.id), "(%d+)$")) or 0
end

function HorseGenetics.hasOffspring(horseId)
    if horseId == nil or horseId == "" then
        return false
    end
    for _, other in pairs(HorseGenetics.horses or {}) do
        if other.mareId == horseId or other.stallionId == horseId then
            return true
        end
    end
    return false
end

function HorseGenetics.getBoundHorseIds()
    local bound = {}
    pcall(function()
        HorseGenetics.visitAnimalClusters(function(cluster)
            if HorseGenetics.isLiveHorseCluster(cluster) and cluster.horseGeneticsId ~= nil then
                bound[cluster.horseGeneticsId] = true
            end
        end)
    end)
    for _, entry in ipairs(HorseGenetics.pregnancies or {}) do
        if entry.parent1Id ~= nil then
            bound[entry.parent1Id] = true
        end
        if entry.parent2Id ~= nil then
            bound[entry.parent2Id] = true
        end
    end
    return bound
end

function HorseGenetics.recordHasPedigree(horse)
    if horse == nil then
        return false
    end
    if horse.mareId ~= nil and horse.mareId ~= "" then
        return true
    end
    if horse.stallionId ~= nil and horse.stallionId ~= "" then
        return true
    end
    return HorseGenetics.hasOffspring(horse.id)
end

function HorseGenetics.isFoundationDuplicate(horse)
    return horse ~= nil
        and (tonumber(horse.generation) or 1) <= 1
        and not HorseGenetics.recordHasPedigree(horse)
end

function HorseGenetics.pruneDuplicateRecords()
end

-- Bind or create the genetics record for a live cluster. Clients never roll new stats.
-- Identity is cluster.horseGeneticsId only. A rename updates the label on that ID.
function HorseGenetics.getOrCreateHorseForCluster(cluster, ownerFarmId)
    if not HorseGenetics.isLiveHorseCluster(cluster) then
        return nil
    end

    local horse = HorseGenetics.getHorseForCluster(cluster)
    if horse ~= nil then
        horse.soldPrice = nil
        if horse.farmId == nil and ownerFarmId ~= nil then
            horse.farmId = ownerFarmId
        end
        return horse
    end

    if HorseGenetics.recordsReady ~= true then
        return nil
    end

    local boundRecord = HorseGenetics.findRecordForLiveCluster(cluster, ownerFarmId)
    if boundRecord ~= nil then
        cluster.horseGeneticsId = boundRecord.id
        boundRecord.soldPrice = nil
        if boundRecord.farmId == nil and ownerFarmId ~= nil then
            boundRecord.farmId = ownerFarmId
        end
        local name = HorseGenetics.getClusterName(cluster)
        if name ~= nil and name ~= "" then
            boundRecord.name = name
        end
        return boundRecord
    end

    if cluster.horseGeneticsId ~= nil and cluster.horseGeneticsId ~= "" then
        return nil
    end

    if not HorseGenetics.isAuthoritative() then
        return nil
    end

    local horseName = HorseGenetics.getClusterName(cluster)
    if horseName == nil or horseName == "" then
        horseName = hgT("hg_unnamed")
    end

    horse = HorseGenetics.createHorse(
        horseName,
        HorseGenetics.generateInitialStats(),
        HorseGenetics.getCoatColourFromCluster(cluster),
        1,
        nil,
        nil,
        ownerFarmId
    )

    if horse ~= nil then
        cluster.horseGeneticsId = horse.id
    end

    return horse
end

-- Sale multiplier: average 50 is 1.00x, floor 0.75x, cap 1.60x, plus exceptional-stat bonuses.
function HorseGenetics.getSaleValueBreakdown(horse)
    if horse == nil or type(horse.stats) ~= "table" then
        return { average = 50, baseMultiplier = 1, statBonus = 0, multiplier = 1 }
    end

    local average = HorseGenetics.calculateAverage(horse.stats)
    local baseMultiplier = 0.75 + (average / 125)
    local statBonus = 0
    local bonusDetails = {}

    local prettyStatNames = {
        speed = hgT("hg_stat_speed"),
        stamina = hgT("hg_stat_stamina"),
        health = hgT("hg_stat_health")
    }
    for _, statName in ipairs(HorseGenetics.STAT_NAMES) do
        local value = tonumber(horse.stats[statName]) or 0
        local prettyName = prettyStatNames[statName] or statName
        if value >= 90 then
            statBonus = statBonus + 0.05
            bonusDetails[#bonusDetails + 1] = hgT("hg_bonus_high", prettyName)
        elseif value >= 80 then
            statBonus = statBonus + 0.025
            bonusDetails[#bonusDetails + 1] = hgT("hg_bonus_mid", prettyName)
        end
    end

    local multiplier = math.max(0.75, math.min(1.60, baseMultiplier + statBonus))
    local strength = HorseGenetics.getValueModifierStrength()
    if strength ~= 1 then
        multiplier = 1 + (multiplier - 1) * strength
    end
    multiplier = math.max(0.50, math.min(2.20, multiplier))
    return {
        average = average,
        baseMultiplier = baseMultiplier,
        statBonus = statBonus,
        multiplier = multiplier,
        bonusDetails = bonusDetails,
        strength = strength
    }
end

function HorseGenetics.getSaleValueMultiplier(horse)
    return HorseGenetics.getSaleValueBreakdown(horse).multiplier
end

function HorseGenetics.getPredictedStatRange(valueA, valueB)
    local average = ((tonumber(valueA) or 0) + (tonumber(valueB) or 0)) / 2
    return HorseGenetics.clampStat(average - 8), HorseGenetics.clampStat(average + 11)
end

function HorseGenetics.getPossibleCoatText(colourA, colourB)
    if colourA == nil or colourA == "" then
        colourA = "Bay"
    end
    if colourB == nil or colourB == "" then
        colourB = colourA
    end
    colourA = hgCoatText(colourA)
    colourB = hgCoatText(colourB)
    if colourA == colourB then
        return hgT("hg_coat_likely_one", colourA)
    end
    return hgT("hg_coat_likely_two", colourA, colourB)
end

function HorseGenetics.getSubTypeIndexForCoat(coatColour, fallbackIndex)
    local map = {
        Bay = "HORSE_BAY",
        Black = "HORSE_BLACK",
        Chestnut = "HORSE_CHESTNUT",
        Grey = "HORSE_GRAY",
        Palomino = "HORSE_PALOMINO",
        Pinto = "HORSE_PINTO",
        Buckskin = "HORSE_DUN",
        ["Seal Brown"] = "HORSE_SEAL_BROWN"
    }
    local animalSystem = g_currentMission ~= nil and g_currentMission.animalSystem or nil
    local name = map[coatColour]
    if name ~= nil and animalSystem ~= nil then
        local subType = nil
        if animalSystem.getSubTypeByName ~= nil then
            local ok, result = pcall(function()
                return animalSystem:getSubTypeByName(name)
            end)
            if ok then
                subType = result
            end
        end
        if subType == nil and animalSystem.nameToSubType ~= nil then
            subType = animalSystem.nameToSubType[name]
        end
        if type(subType) == "table" then
            return subType.subTypeIndex or subType.index or fallbackIndex
        end
    end
    return fallbackIndex
end

function HorseGenetics.applyThirdPartyClusterCompat(cluster)
    if cluster == nil then
        return
    end
    pcall(function()
        if cluster.changeHealth ~= nil then
            cluster:changeHealth(100)
        elseif type(cluster.health) ~= "number" then
            cluster.health = 100
        end
        if HorseGenetics.isEnhancedAnimalSystemActive() then
            cluster.isInseminated = false
            cluster.hadABirth = false
            cluster.monthsSinceLastBirth = 0
        end
    end)
end

function HorseGenetics.pickFoalSubTypeIndex(parentCluster, coatColour)
    local fallbackIndex = parentCluster ~= nil and parentCluster.getSubTypeIndex ~= nil
        and parentCluster:getSubTypeIndex() or nil
    local index = HorseGenetics.getSubTypeIndexForCoat(coatColour, fallbackIndex)
    if not HorseGenetics.isEnhancedAnimalSystemActive() then
        return index
    end
    local animalSystem = g_currentMission ~= nil and g_currentMission.animalSystem or nil
    if animalSystem == nil or animalSystem.getSubTypeByIndex == nil or index == nil then
        return index
    end
    local subType = nil
    pcall(function()
        subType = animalSystem:getSubTypeByIndex(index)
    end)
    if type(subType) ~= "table" or subType.malePart == nil or animalSystem.getSubTypeByName == nil then
        return index
    end
    if math.random() >= 0.5 then
        return index
    end
    local male = nil
    pcall(function()
        male = animalSystem:getSubTypeByName(subType.malePart)
    end)
    if type(male) == "table" then
        return male.subTypeIndex or male.index or index
    end
    return index
end

function HorseGenetics.nameTakenInHusbandry(husbandry, name)
    if husbandry == nil or name == nil or name == "" then
        return false
    end
    for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
        if HorseGenetics.getClusterName(cluster) == name then
            return true
        end
    end
    return false
end

function HorseGenetics.uniqueFoalName(husbandry, baseName)
    local name = baseName
    local n = 2
    while HorseGenetics.nameTakenInHusbandry(husbandry, name) do
        name = string.format("%s %d", baseName, n)
        n = n + 1
    end
    return name
end

function HorseGenetics.pickVanillaHorseName(husbandry, cluster)
    local function validName(name)
        return type(name) == "string" and name ~= "" and string.find(name, "Foal", 1, true) == nil
    end
    local existing = nil
    if cluster ~= nil then
        if cluster.getName ~= nil then
            local ok, name = pcall(function()
                return cluster:getName()
            end)
            if ok then
                existing = name
            end
        end
        if not validName(existing) then
            existing = cluster.name
        end
    end
    if validName(existing) and not HorseGenetics.nameTakenInHusbandry(husbandry, existing) then
        return existing
    end

    local managers = {}
    if g_currentMission ~= nil then
        table.insert(managers, g_currentMission.animalNameManager)
        table.insert(managers, g_currentMission.animalNameSystem)
        if g_currentMission.animalSystem ~= nil then
            table.insert(managers, g_currentMission.animalSystem.animalNameManager)
            table.insert(managers, g_currentMission.animalSystem.nameManager)
        end
    end
    table.insert(managers, g_animalNameManager)
    if AnimalNameManager ~= nil then
        table.insert(managers, AnimalNameManager)
    end

    for i = 1, #managers do
        local manager = managers[i]
        if manager ~= nil and manager.getRandomName ~= nil then
            for _ = 1, 16 do
                local ok, name = pcall(function()
                    return manager:getRandomName()
                end)
                if ok and validName(name) and not HorseGenetics.nameTakenInHusbandry(husbandry, name) then
                    return name
                end
            end
        end
    end

    if validName(existing) then
        return HorseGenetics.uniqueFoalName(husbandry, existing)
    end
    return nil
end

function HorseGenetics.applyHorseName(cluster, name)
    if cluster == nil or name == nil or name == "" then
        return
    end
    if cluster.setName ~= nil then
        pcall(function()
            cluster:setName(name)
        end)
    else
        cluster.name = name
    end
end

function HorseGenetics.createFoalInHusbandry(husbandry, parentCluster, parent1Record, parent2Record)
    HorseGenetics.allowModHorseBirth = true
    local ok, record, result, err = pcall(HorseGenetics.createFoalInHusbandryInner, husbandry, parentCluster, parent1Record, parent2Record)
    HorseGenetics.allowModHorseBirth = false
    if not ok then
        return nil, nil, record
    end
    if record ~= nil then
        HorseGenetics.modBirthClusters = HorseGenetics.modBirthClusters or {}
        HorseGenetics.modBirthClusters[record.id] = true
    end
    return record, result, err
end

function HorseGenetics.createFoalInHusbandryInner(husbandry, parentCluster, parent1Record, parent2Record)
    local result, breedError = HorseGenetics.breed(
        parent1Record.stats, parent2Record.stats,
        parent1Record.coatColour, parent2Record.coatColour)
    if result == nil then
        return nil, nil, breedError
    end
    local subTypeIndex = HorseGenetics.pickFoalSubTypeIndex(parentCluster, result.coatColour)
    local foalCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
    if foalCluster == nil then
        return nil, nil, "FS25 could not create a foal cluster."
    end
    foalCluster.numAnimals = 1
    foalCluster.age = 0
    HorseGenetics.applyThirdPartyClusterCompat(foalCluster)
    local foalName = HorseGenetics.pickVanillaHorseName(husbandry, foalCluster)
    if foalName ~= nil then
        HorseGenetics.applyHorseName(foalCluster, foalName)
    end
    husbandry:addCluster(foalCluster)
    if husbandry.raiseActive ~= nil then
        husbandry:raiseActive()
    end
    if foalName == nil then
        foalName = HorseGenetics.pickVanillaHorseName(husbandry, foalCluster)
        if foalName ~= nil then
            HorseGenetics.applyHorseName(foalCluster, foalName)
        end
    end
    if foalName == nil then
        local ok, name = pcall(function()
            return foalCluster.getName ~= nil and foalCluster:getName() or foalCluster.name
        end)
        if ok and type(name) == "string" and name ~= "" then
            foalName = name
        else
            foalName = "Horse"
        end
    end
    local farmId = parent1Record.farmId or parent2Record.farmId or hgGetOwnerFarmId(husbandry)
    local record, createError = HorseGenetics.createHorse(
        foalName, result.stats, result.coatColour,
        math.max(parent1Record.generation or 1, parent2Record.generation or 1) + 1,
        parent1Record.id, parent2Record.id, farmId)
    if record == nil then
        return nil, result, createError
    end
    foalCluster.horseGeneticsId = record.id
    return record, result, nil
end

function HorseGenetics.getHusbandryKey(husbandry)
    if husbandry == nil then
        return nil
    end
    if husbandry.uniqueId ~= nil and tostring(husbandry.uniqueId) ~= "" then
        return tostring(husbandry.uniqueId)
    end
    if husbandry.id ~= nil then
        return tostring(husbandry.id)
    end
    return tostring(husbandry)
end

function HorseGenetics.findClusterByHorseId(husbandry, horseId)
    if husbandry == nil or horseId == nil then
        return nil
    end
    local wantedName = nil
    local record = HorseGenetics.horses ~= nil and HorseGenetics.horses[horseId] or nil
    if record ~= nil then
        wantedName = record.name
    end
    local nameMatch = nil
    for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
        if HorseGenetics.getHorseGeneticsId(cluster) == horseId then
            return HorseGenetics.getLiveHorseCluster(cluster) or cluster
        end
        if wantedName ~= nil and nameMatch == nil then
            local clusterName = HorseGenetics.getClusterName(cluster)
            if clusterName ~= nil and string.lower(clusterName) == string.lower(wantedName) then
                nameMatch = cluster
            end
        end
    end
    return nameMatch
end

function HorseGenetics.isHorseInPregnancy(horseId)
    if horseId == nil or horseId == "" then
        return false
    end
    for _, entry in ipairs(HorseGenetics.pregnancies or {}) do
        if entry.parent1Id == horseId or entry.parent2Id == horseId then
            return true
        end
    end
    return false
end

function HorseGenetics.completePregnancy(husbandry, pregnancy)
    local parent1Cluster = HorseGenetics.findClusterByHorseId(husbandry, pregnancy.parent1Id)
    local parent2Cluster = HorseGenetics.findClusterByHorseId(husbandry, pregnancy.parent2Id)
    if parent1Cluster == nil or parent2Cluster == nil then
        return false
    end
    local parent1 = HorseGenetics.getHorseForCluster(parent1Cluster) or HorseGenetics.horses[pregnancy.parent1Id]
    local parent2 = HorseGenetics.getHorseForCluster(parent2Cluster) or HorseGenetics.horses[pregnancy.parent2Id]
    if parent1 == nil or parent2 == nil then
        return false
    end
    if husbandry.getNumOfFreeAnimalSlots ~= nil and husbandry:getNumOfFreeAnimalSlots() < 2 then
        return false
    end

    local foal1 = HorseGenetics.createFoalInHusbandry(husbandry, parent1Cluster, parent1, parent2)
    if foal1 == nil then
        return false
    end
    local foal2 = HorseGenetics.createFoalInHusbandry(husbandry, parent2Cluster, parent1, parent2)
    if foal2 == nil then
        HorseGenetics.markClusterBirth(parent1Cluster)
        HorseGenetics.markClusterBirth(parent2Cluster)
        HorseGenetics:saveToSavegame()
        return true
    end

    HorseGenetics.appendBreedingHistory({
        parent1Id = parent1.id, parent1Name = parent1.name,
        parent2Id = parent2.id, parent2Name = parent2.name,
        foal1Id = foal1.id, foal1Name = foal1.name, foal1Coat = foal1.coatColour,
        foal1Speed = foal1.stats.speed, foal1Stamina = foal1.stats.stamina, foal1Health = foal1.stats.health,
        foal2Id = foal2.id, foal2Name = foal2.name, foal2Coat = foal2.coatColour,
        foal2Speed = foal2.stats.speed, foal2Stamina = foal2.stats.stamina, foal2Health = foal2.stats.health
    })
    HorseGenetics.markClusterBirth(parent1Cluster)
    HorseGenetics.markClusterBirth(parent2Cluster)
    return true
end

function HorseGenetics.markClusterBirth(cluster)
    local live = HorseGenetics.getLiveHorseCluster(cluster) or cluster
    if live == nil then
        return
    end
    pcall(function()
        live.hadABirth = true
        live.monthsSinceLastBirth = 0
        if cluster ~= nil and cluster ~= live then
            cluster.hadABirth = true
            cluster.monthsSinceLastBirth = 0
        end
    end)
end

function HorseGenetics.normalizePregnancy(entry)
    if entry == nil then
        return
    end
    local duration = HorseGenetics.getGestationMonths()
    if duration < 1 then
        duration = 1
    end
    local elapsed = tonumber(entry.monthsElapsed)
    if elapsed == nil or elapsed < 0 then
        local remaining = tonumber(entry.monthsRemaining)
        if remaining == nil then
            elapsed = 0
        else
            elapsed = math.max(0, duration - remaining)
        end
    end
    entry.monthsElapsed = elapsed
    entry.monthsRemaining = math.max(0, duration - elapsed)
end

function HorseGenetics.getRecordCluster(record)
    if record == nil or record.id == nil then
        return nil
    end
    local map = HorseGenetics._clusterById
    if map ~= nil then
        return map[record.id]
    end
    return nil
end

function HorseGenetics.getRecordAgeMonths(record)
    local cluster = HorseGenetics.getRecordCluster(record)
    if cluster ~= nil then
        local age = cluster.age
        if type(age) ~= "number" and cluster.getAge ~= nil then
            local ok, value = pcall(function()
                return cluster:getAge()
            end)
            if ok then
                age = value
            end
        end
        if type(age) == "number" then
            return math.max(0, age)
        end
    end
    if record ~= nil and type(record.lastAgeMonths) == "number" then
        return record.lastAgeMonths
    end
    return nil
end

function HorseGenetics.formatAgeYM(age)
    if age == nil then
        return "-"
    end
    local months = math.max(0, math.floor(age + 0.5))
    local years = math.floor(months / 12)
    local rest = months % 12
    if years > 0 and rest > 0 then
        return hgT("hg_age_ym", years, rest)
    end
    if years > 0 then
        return hgT("hg_age_y", years)
    end
    return hgT("hg_age_m", rest)
end

function HorseGenetics.getRecordLifeState(record)
    if record == nil then
        return hgT("hg_label_repro"), hgT("hg_dash")
    end
    local cluster = HorseGenetics.getRecordCluster(record)
    local pregnancy = HorseGenetics.getPregnancyForHorseId(record.id)
    local age = HorseGenetics.getRecordAgeMonths(record)
    local maturity = HorseGenetics.getMaturityMonths(cluster)
    if age ~= nil and age < maturity then
        local percent = 0
        if cluster ~= nil then
            percent = HorseGenetics.getPubertyPercent(cluster)
        else
            percent = math.max(0, math.min(100, math.floor(age / math.max(1, maturity) * 100 + 0.5)))
        end
        return hgT("hg_label_puberty"), string.format("%d%%", percent)
    end
    if pregnancy ~= nil then
        return hgT("hg_label_repro"), string.format("%d%%", HorseGenetics.getReproductionPercent(pregnancy))
    end
    if cluster == nil then
        return hgT("hg_label_repro"), hgT("hg_dash")
    end
    return hgT("hg_label_repro"), "0%"
end

function HorseGenetics.getPregnancyForHorseId(horseId)
    if horseId == nil or horseId == "" then
        return nil
    end
    for _, entry in ipairs(HorseGenetics.pregnancies or {}) do
        if entry.parent1Id == horseId or entry.parent2Id == horseId then
            HorseGenetics.normalizePregnancy(entry)
            return entry
        end
    end
    return nil
end

function HorseGenetics.getReproductionPercent(pregnancy)
    HorseGenetics.normalizePregnancy(pregnancy)
    local duration = HorseGenetics.getGestationMonths()
    if duration < 1 then
        duration = 1
    end
    local elapsed = tonumber(pregnancy and pregnancy.monthsElapsed) or 0
    local remaining = tonumber(pregnancy and pregnancy.monthsRemaining) or math.max(0, duration - elapsed)
    local percent = math.max(0, math.min(100, math.floor((elapsed + 1) / duration * 100 + 0.5)))
    if remaining > 0 and percent >= 100 then
        percent = 99
    end
    if remaining <= 0 then
        percent = 100
    end
    return percent
end

function HorseGenetics.getClusterAgeMonths(cluster)
    if cluster == nil then
        return 0
    end
    local live = HorseGenetics.getLiveHorseCluster(cluster) or cluster
    local age = live.age
    if type(age) ~= "number" and live.getAge ~= nil then
        local ok, value = pcall(function()
            return live:getAge()
        end)
        if ok then
            age = value
        end
    end
    if type(age) ~= "number" and cluster ~= live then
        age = cluster.age
        if type(age) ~= "number" and cluster.getAge ~= nil then
            local ok, value = pcall(function()
                return cluster:getAge()
            end)
            if ok then
                age = value
            end
        end
    end
    if type(age) ~= "number" then
        return 0
    end
    return math.max(0, age)
end

function HorseGenetics.getMaturityMonths(cluster)
    return HorseGenetics.getPubertyMonths()
end

function HorseGenetics.forEachHorseSubType(visitor)
    if type(visitor) ~= "function" then
        return
    end
    local animalSystem = g_currentMission ~= nil and g_currentMission.animalSystem or g_animalSystem
    if animalSystem == nil then
        return
    end
    local seen = {}
    local function consider(subType)
        if type(subType) ~= "table" or seen[subType] == true then
            return
        end
        seen[subType] = true
        local label = string.upper(tostring(subType.name or "") .. " " .. tostring(subType.typeName or ""))
        pcall(function()
            if animalSystem.getTypeByIndex ~= nil and subType.typeIndex ~= nil then
                local animalType = animalSystem:getTypeByIndex(subType.typeIndex)
                if animalType ~= nil then
                    label = label .. " " .. string.upper(tostring(animalType.name or animalType.typeName or ""))
                end
            end
        end)
        if string.find(label, "HORSE", 1, true) ~= nil then
            visitor(subType)
        end
    end
    local function considerList(list)
        if type(list) ~= "table" then
            return
        end
        for _, value in pairs(list) do
            if type(value) == "table" then
                if value.reproductionMinAgeMonth ~= nil or value.subTypeIndex ~= nil or value.name ~= nil then
                    consider(value)
                else
                    considerList(value)
                end
            end
        end
    end
    considerList(animalSystem.subTypes)
    considerList(animalSystem.nameToSubType)
    considerList(animalSystem.subTypeIndexToSubType)
    considerList(animalSystem.types)
    if animalSystem.getSubTypes ~= nil then
        local ok, result = pcall(function()
            return animalSystem:getSubTypes()
        end)
        if ok then
            considerList(result)
        end
    end
end

function HorseGenetics.applyPubertyToHorseSubtypes()
    local months = HorseGenetics.getPubertyMonths()
    HorseGenetics.forEachHorseSubType(function(subType)
        subType.reproductionMinAgeMonth = months
        subType.minReproductionAgeMonth = months
        if type(subType.reproduction) == "table" then
            subType.reproduction.minAgeMonth = months
        end
    end)
    HorseGenetics._appliedPubertyMonths = months
end

function HorseGenetics.isHorseMature(cluster)
    return HorseGenetics.getClusterAgeMonths(cluster) >= HorseGenetics.getMaturityMonths(cluster)
end

function HorseGenetics.getPubertyPercent(cluster)
    local duration = HorseGenetics.getMaturityMonths(cluster)
    local age = HorseGenetics.getClusterAgeMonths(cluster)
    return math.max(0, math.min(100, math.floor(age / duration * 100 + 0.5)))
end

function HorseGenetics.setClusterReproduction(cluster, percent, duration, remaining, inseminated)
    if cluster == nil or cluster._hgReproSync == true then
        return
    end
    percent = math.max(0, math.min(100, tonumber(percent) or 0))
    duration = math.max(1, tonumber(duration) or HorseGenetics.getGestationMonths())
    remaining = math.max(0, tonumber(remaining) or duration)
    cluster._hgReproSync = true
    local originalSetDirty = cluster.setDirty
    if type(originalSetDirty) == "function" then
        cluster.setDirty = function() end
    end
    pcall(function()
        cluster.reproductionDuration = duration
        cluster.reproductionToGo = remaining
        cluster.reproduction = percent
        cluster.reproductionMinAgeMonth = HorseGenetics.getPubertyMonths()
        cluster.isInseminated = inseminated == true
        if HorseGenetics.hasOffspring(HorseGenetics.getHorseGeneticsId(cluster)) then
            cluster.hadABirth = true
            if type(cluster.monthsSinceLastBirth) ~= "number" then
                cluster.monthsSinceLastBirth = 0
            end
        end
        if cluster.setReproduction ~= nil then
            local ok = pcall(function()
                cluster:setReproduction(percent)
            end)
            if not ok then
                pcall(function()
                    cluster:setReproduction(percent / 100)
                end)
            end
        end
        if cluster.setReproductionDuration ~= nil then
            pcall(function()
                cluster:setReproductionDuration(duration)
            end)
        end
    end)
    cluster.setDirty = originalSetDirty
    cluster._hgReproSync = nil
end

function HorseGenetics.syncClusterReproduction(cluster)
    if cluster == nil then
        return
    end
    local live = HorseGenetics.getLiveHorseCluster(cluster) or cluster
    if not HorseGenetics.isHorseCluster(live) and not HorseGenetics.isHorseCluster(cluster) then
        return
    end
    local duration = HorseGenetics.getGestationMonths()
    local horseId = HorseGenetics.getHorseGeneticsId(live) or HorseGenetics.getHorseGeneticsId(cluster)
    if (horseId == nil or horseId == "") and HorseGenetics.getHorseForCluster ~= nil then
        local record = HorseGenetics.getHorseForCluster(live) or HorseGenetics.getHorseForCluster(cluster)
        if record ~= nil then
            horseId = record.id
        end
    end
    if horseId ~= nil and horseId ~= "" then
        live.horseGeneticsId = horseId
        if cluster ~= live then
            cluster.horseGeneticsId = horseId
        end
    end
    local pregnancy = HorseGenetics.getPregnancyForHorseId(horseId)
    local percent, remaining, inseminated
    if pregnancy ~= nil then
        percent = HorseGenetics.getReproductionPercent(pregnancy)
        remaining = pregnancy.monthsRemaining
        inseminated = true
        duration = HorseGenetics.getGestationMonths()
    else
        local maturity = HorseGenetics.getMaturityMonths(live)
        local age = HorseGenetics.getClusterAgeMonths(live)
        if age < maturity then
            percent = HorseGenetics.getPubertyPercent(live)
            remaining = math.max(0, maturity - age)
            inseminated = false
            duration = maturity
        else
            percent = 0
            remaining = duration
            inseminated = false
        end
    end
    HorseGenetics.setClusterReproduction(live, percent, duration, remaining, inseminated)
    if cluster ~= live then
        HorseGenetics.setClusterReproduction(cluster, percent, duration, remaining, inseminated)
    end
end

function HorseGenetics.syncHusbandryReproduction(husbandry)
    if husbandry == nil then
        return
    end
    for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
        HorseGenetics.syncClusterReproduction(cluster)
    end
end

function HorseGenetics.syncAllReproductionVisuals()
    pcall(function()
        if HorseGenetics.applyPubertyToHorseSubtypes ~= nil then
            HorseGenetics.applyPubertyToHorseSubtypes()
        end
        HorseGenetics.visitAnimalClusters(function(cluster, container)
            HorseGenetics.syncClusterReproduction(cluster)
            if container ~= nil and container.raiseActive ~= nil then
                pcall(function()
                    container:raiseActive()
                end)
            end
        end)
    end)
end

function HorseGenetics.advancePregnancies(husbandry)
    local key = HorseGenetics.getHusbandryKey(husbandry)
    if key == nil then
        return
    end
    local remaining = {}
    local duration = HorseGenetics.getGestationMonths()
    for _, entry in ipairs(HorseGenetics.pregnancies or {}) do
        if entry.husbandryId == key then
            HorseGenetics.normalizePregnancy(entry)
            entry.monthsElapsed = (tonumber(entry.monthsElapsed) or 0) + 1
            entry.monthsRemaining = math.max(0, duration - entry.monthsElapsed)
            if entry.monthsElapsed >= duration then
                if not HorseGenetics.completePregnancy(husbandry, entry) then
                    entry.monthsElapsed = duration
                    entry.monthsRemaining = 0
                    table.insert(remaining, entry)
                end
            else
                table.insert(remaining, entry)
            end
        else
            table.insert(remaining, entry)
        end
    end
    HorseGenetics.pregnancies = remaining
end

function HorseGenetics.tryStartPregnancy(husbandry)
    if husbandry == nil then
        return false
    end
    if not HorseGenetics.canRunHostCommand() then
        return false
    end
    if husbandry.isServer == false then
        return false
    end
    local key = HorseGenetics.getHusbandryKey(husbandry)
    if key == nil then
        return false
    end
    for _, entry in ipairs(HorseGenetics.pregnancies or {}) do
        if entry.husbandryId == key then
            return false
        end
    end

    local eligible = {}
    for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
        if HorseGenetics.isHorseCluster(cluster) then
            local age = HorseGenetics.getClusterAgeMonths(cluster)
            if age >= HorseGenetics.getMaturityMonths(cluster) then
                local record = HorseGenetics.getOrCreateHorseForCluster(cluster, hgGetOwnerFarmId(husbandry))
                if record ~= nil and not HorseGenetics.isHorseInPregnancy(record.id) then
                    table.insert(eligible, {cluster = cluster, record = record, age = age})
                end
            end
        end
    end
    if #eligible < 2 then
        return false
    end
    table.sort(eligible, function(a, b)
        return (a.age or 0) > (b.age or 0)
    end)
    local a, b = eligible[1], eligible[2]
    if a.record.id == b.record.id then
        return false
    end

    HorseGenetics.pregnancies = HorseGenetics.pregnancies or {}
    table.insert(HorseGenetics.pregnancies, {
        husbandryId = key,
        parent1Id = a.record.id,
        parent2Id = b.record.id,
        monthsRemaining = HorseGenetics.getGestationMonths(),
        monthsElapsed = 0,
        farmId = a.record.farmId or b.record.farmId or hgGetOwnerFarmId(husbandry) or 0
    })
    HorseGenetics.syncHusbandryReproduction(husbandry)
    HorseGenetics:saveToSavegame()
    return true
end

function HorseGenetics.advanceLastBirthMonths(husbandry)
    if husbandry == nil then
        return
    end
    for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
        local live = HorseGenetics.getLiveHorseCluster(cluster) or cluster
        if HorseGenetics.isHorseCluster(live) and live.hadABirth == true then
            local horseId = HorseGenetics.getHorseGeneticsId(live)
            if HorseGenetics.getPregnancyForHorseId(horseId) == nil then
                live.monthsSinceLastBirth = (tonumber(live.monthsSinceLastBirth) or 0) + 1
            end
        end
    end
end

function HorseGenetics.onHusbandryMonth(husbandry)
    HorseGenetics.advancePregnancies(husbandry)
    HorseGenetics.tryStartPregnancy(husbandry)
    HorseGenetics.advanceLastBirthMonths(husbandry)
    HorseGenetics.syncHusbandryReproduction(husbandry)
    HorseGenetics:saveToSavegame()
end

function HorseGenetics.appendBreedingHistory(entry)
    HorseGenetics.breedingHistory = HorseGenetics.breedingHistory or {}
    table.insert(HorseGenetics.breedingHistory, 1, entry)
    while #HorseGenetics.breedingHistory > 40 do
        table.remove(HorseGenetics.breedingHistory)
    end
end

local function hgReadClusterSellPrice(cluster)
    if cluster == nil then
        return nil
    end
    local price = nil
    if cluster.getSellPrice ~= nil then
        local ok, result = pcall(function()
            return cluster:getSellPrice()
        end)
        if ok and type(result) == "number" then
            price = result
        end
    end
    if price == nil and cluster.getValue ~= nil then
        local ok, result = pcall(function()
            return cluster:getValue()
        end)
        if ok and type(result) == "number" then
            price = result
        end
    end
    if type(price) == "number" then
        return math.floor(price + 0.5)
    end
    return nil
end

function HorseGenetics.visitAnimalClusters(visitor)
    local mission = g_currentMission
    if mission == nil or visitor == nil then
        return
    end
    local seenContainers = {}
    local function visitContainer(container)
        if container == nil or seenContainers[container] == true then
            return
        end
        seenContainers[container] = true
        for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(container)) do
            pcall(visitor, cluster, container)
        end
        local cluster = hgInvoke(container, "getCluster") or container.cluster
        if cluster ~= nil then
            pcall(visitor, cluster, container)
        end
        if type(container) == "table" then
            visitContainer(container.placeable)
            visitContainer(container.owner)
            visitContainer(hgInvoke(container, "getPlaceable"))
            visitContainer(hgInvoke(container, "getOwner"))
            if type(container.items) == "table" then
                for _, item in pairs(container.items) do
                    visitContainer(item)
                end
            end
        end
    end
    local function visitList(list)
        if type(list) ~= "table" then
            return
        end
        for _, item in pairs(list) do
            visitContainer(item)
        end
    end
    local function visitMaybe(object, methodName)
        if object == nil then
            return
        end
        if methodName ~= nil then
            visitList(hgInvoke(object, methodName))
        else
            visitList(object)
        end
    end
    local hs = mission.husbandrySystem
    if hs ~= nil then
        visitList(hs.placeables)
        visitList(hs.husbandries)
        visitList(hs.clusterHusbandries)
        visitList(hs.animalHusbandries)
        visitList(hs.pastures)
        visitMaybe(hs, "getPlaceables")
        visitMaybe(hs, "getHusbandries")
        visitMaybe(hs, "getClusterHusbandries")
        visitMaybe(hs, "getAnimalHusbandries")
        visitMaybe(hs, "getPastures")
    end
    local ps = mission.placeableSystem
    if ps ~= nil then
        visitList(ps.placeables)
        visitList(ps.placeablesByUniqueId)
        visitMaybe(ps, "getPlaceables")
    end
    visitList(mission.placeables)
    visitList(mission.husbandries)
    local vs = mission.vehicleSystem
    if vs ~= nil then
        visitList(vs.vehicles)
        visitMaybe(vs, "getVehicles")
    end
    visitList(mission.vehicles)
    visitList(mission.ownedItems)
end

function HorseGenetics.findRecordForLiveCluster(cluster, ownerFarmId, usedHorseIds)
    if cluster == nil then
        return nil
    end
    local existingId = cluster.horseGeneticsId
    if existingId ~= nil and HorseGenetics.horses[existingId] ~= nil
        and (usedHorseIds == nil or usedHorseIds[existingId] ~= true) then
        return HorseGenetics.horses[existingId]
    end
    local clusterId = cluster.id ~= nil and tostring(cluster.id) or ""
    if clusterId == "" then
        return nil
    end
    for _, binding in ipairs(HorseGenetics.clusterBindings or {}) do
        if binding.clusterId == clusterId and binding.horseId ~= nil
            and HorseGenetics.horses[binding.horseId] ~= nil
            and (usedHorseIds == nil or usedHorseIds[binding.horseId] ~= true) then
            if ownerFarmId == nil or binding.farmId == nil or binding.farmId == 0
                or tonumber(binding.farmId) == tonumber(ownerFarmId) then
                return HorseGenetics.horses[binding.horseId]
            end
        end
    end
    return nil
end

function HorseGenetics.collectClusterBindings()
    local bindings = {}
    local usedHorseIds = {}
    pcall(function()
        HorseGenetics.visitAnimalClusters(function(cluster, container)
            if cluster == nil or not HorseGenetics.isHorseCluster(cluster) then
                return
            end
            local ownerFarmId = hgGetOwnerFarmId(container) or hgGetOwnerFarmId(cluster)
            local record = HorseGenetics.getHorseForCluster(cluster)
            if record ~= nil and usedHorseIds[record.id] == true then
                record = nil
            end
            if record == nil then
                record = HorseGenetics.findRecordForLiveCluster(cluster, ownerFarmId, usedHorseIds)
            end
            if record == nil or record.id == nil then
                return
            end
            cluster.horseGeneticsId = record.id
            usedHorseIds[record.id] = true
            local age = HorseGenetics.getClusterAgeMonths(cluster)
            record.lastAgeMonths = age
            table.insert(bindings, {
                horseId = record.id,
                husbandryId = HorseGenetics.getHusbandryKey(container) or "",
                clusterId = cluster.id ~= nil and tostring(cluster.id) or "",
                name = HorseGenetics.getClusterName(cluster) or record.name or "",
                ageMonths = age,
                farmId = tonumber(ownerFarmId) or tonumber(record.farmId) or 0
            })
        end)
    end)
    return bindings
end

function HorseGenetics.applyClusterBindings(bindings)
    HorseGenetics.clusterBindings = bindings or {}
    for _, binding in ipairs(HorseGenetics.clusterBindings) do
        local record = binding.horseId ~= nil and HorseGenetics.horses[binding.horseId] or nil
        if record ~= nil and type(binding.ageMonths) == "number" then
            record.lastAgeMonths = binding.ageMonths
        end
    end
    HorseGenetics.rebindLiveClusters()
end

function HorseGenetics.rebindLiveClusters()
    HorseGenetics._clusterById = {}
    local usedHorseIds = {}
    local bindings = HorseGenetics.clusterBindings or {}
    local byPlaceAndCluster = {}
    for _, binding in ipairs(bindings) do
        if binding.horseId ~= nil and binding.husbandryId ~= nil and binding.husbandryId ~= ""
            and binding.clusterId ~= nil and binding.clusterId ~= "" then
            byPlaceAndCluster[binding.husbandryId .. "\0" .. binding.clusterId] = binding
        end
    end

    local function bindCluster(cluster, horseId)
        if cluster == nil or horseId == nil or horseId == "" or usedHorseIds[horseId] == true then
            return false
        end
        if HorseGenetics.horses[horseId] == nil then
            return false
        end
        cluster.horseGeneticsId = horseId
        usedHorseIds[horseId] = true
        HorseGenetics._clusterById[horseId] = cluster
        local record = HorseGenetics.horses[horseId]
        local age = cluster.age
        if type(age) ~= "number" and cluster.getAge ~= nil then
            local ok, value = pcall(function()
                return cluster:getAge()
            end)
            if ok and type(value) == "number" then
                age = value
            end
        end
        if type(age) == "number" then
            record.lastAgeMonths = math.max(0, age)
        end
        return true
    end

    pcall(function()
        HorseGenetics.visitAnimalClusters(function(cluster, container)
            if cluster == nil or not HorseGenetics.isHorseCluster(cluster) then
                return
            end
            local ownerFarmId = hgGetOwnerFarmId(container) or hgGetOwnerFarmId(cluster)
            local key = (HorseGenetics.getHusbandryKey(container) or "") .. "\0"
                .. (cluster.id ~= nil and tostring(cluster.id) or "")
            local binding = byPlaceAndCluster[key]
            if binding ~= nil and bindCluster(cluster, binding.horseId) then
                return
            end
            if cluster.horseGeneticsId ~= nil and bindCluster(cluster, cluster.horseGeneticsId) then
                return
            end
            local record = HorseGenetics.findRecordForLiveCluster(cluster, ownerFarmId, usedHorseIds)
            if record ~= nil then
                bindCluster(cluster, record.id)
            end
        end)
    end)
    return usedHorseIds
end

-- Bind live horse clusters on the host/dedicated server and push new records.
function HorseGenetics.ensureLiveHorseRecords()
    if not HorseGenetics.isAuthoritative() then
        return 0
    end
    local created = 0
    pcall(function()
        HorseGenetics.visitAnimalClusters(function(cluster, container)
            if cluster == nil or not HorseGenetics.isHorseCluster(cluster) then
                return
            end
            local ownerFarmId = hgGetOwnerFarmId(container) or hgGetOwnerFarmId(cluster)
            local beforeId = cluster.horseGeneticsId
            local record = HorseGenetics.getOrCreateHorseForCluster(cluster, ownerFarmId)
            if record ~= nil and (beforeId == nil or beforeId ~= record.id) then
                created = created + 1
            end
        end)
    end)
    pcall(function()
        HorseGenetics.finalizeSoldPrices()
    end)
    if created > 0 then
        HorseGenetics:saveToSavegame()
        if HorseGenetics.isMultiplayer() then
            HorseGenetics.broadcastFullSync()
        end
        HorseGenetics.notifyUiDirty()
    end
    return created
end

-- IDs of horses currently in stables or spawned.
function HorseGenetics.collectOwnedHorseIds()
    local owned = {}
    local scanned = 0
    local localFarmId = HorseGenetics.getLocalFarmId ~= nil and HorseGenetics.getLocalFarmId() or nil
    local mp = HorseGenetics.isMultiplayer ~= nil and HorseGenetics.isMultiplayer()
    local authoritative = HorseGenetics.isAuthoritative()
    local dedicated = HorseGenetics.isDedicatedServer ~= nil and HorseGenetics.isDedicatedServer()
    HorseGenetics._clusterById = {}
    local usedHorseIds = {}
    if not authoritative then
        usedHorseIds = HorseGenetics.rebindLiveClusters() or {}
    end

    local function farmOk(ownerFarmId)
        if not mp then
            return true
        end
        if authoritative and dedicated then
            return true
        end
        if localFarmId == nil then
            return true
        end
        if ownerFarmId == nil then
            return true
        end
        return ownerFarmId == localFarmId
    end

    HorseGenetics.visitAnimalClusters(function(cluster, container)
        scanned = scanned + 1
        if cluster == nil then
            return
        end
        if HorseGenetics.isHorseCluster ~= nil and not HorseGenetics.isHorseCluster(cluster) then
            return
        end
        local ownerFarmId = hgGetOwnerFarmId(container) or hgGetOwnerFarmId(cluster)
        if not farmOk(ownerFarmId) then
            return
        end
        local record
        if authoritative then
            record = HorseGenetics.getOrCreateHorseForCluster(cluster, ownerFarmId)
        else
            record = HorseGenetics.getHorseForCluster(cluster)
            local alreadyBound = record ~= nil and usedHorseIds[record.id] == true
                and HorseGenetics._clusterById[record.id] ~= nil
                and HorseGenetics._clusterById[record.id] ~= cluster
            if record == nil or alreadyBound then
                record = HorseGenetics.findRecordForLiveCluster(cluster, ownerFarmId, usedHorseIds)
                if record ~= nil then
                    cluster.horseGeneticsId = record.id
                end
            end
        end
        if record == nil and cluster.horseGeneticsId ~= nil then
            record = HorseGenetics.horses[cluster.horseGeneticsId]
        end
        if record ~= nil and record.id ~= nil then
            if not authoritative and usedHorseIds[record.id] == true
                and HorseGenetics._clusterById[record.id] ~= nil
                and HorseGenetics._clusterById[record.id] ~= cluster then
                return
            end
            record.soldPrice = nil
            owned[record.id] = true
            HorseGenetics._clusterById[record.id] = cluster
            usedHorseIds[record.id] = true
            local age = cluster.age
            if type(age) ~= "number" and cluster.getAge ~= nil then
                local ok, value = pcall(function()
                    return cluster:getAge()
                end)
                if ok then
                    age = value
                end
            end
            if type(age) == "number" then
                record.lastAgeMonths = math.max(0, age)
            end
            if record.farmId == nil and ownerFarmId ~= nil then
                record.farmId = ownerFarmId
            end
        end
    end)
    HorseGenetics._lastClusterScanCount = scanned

    -- Dedicated clients never create records; list unsold farm horses from the sync.
    if not authoritative then
        for id, record in pairs(HorseGenetics.horses or {}) do
            if type(record) == "table" and record.soldPrice == nil
                and HorseGenetics.recordVisibleToLocalFarm(record) then
                owned[id] = true
            end
        end
    end

    if scanned > 0 and authoritative then
        HorseGenetics.pruneDuplicateRecords()
    end
    return owned
end

-- Shop sell price for a live cluster; otherwise genetics multiplier times a known horse base.
function HorseGenetics.collectHorseSellPrices()
    local pricesById = {}
    local pricesByName = {}
    local sampleBase = nil
    HorseGenetics.quietSalePrice = true
    pcall(function()
        HorseGenetics.visitAnimalClusters(function(cluster)
            local horse = nil
            local horseId = cluster ~= nil and cluster.horseGeneticsId or nil
            if horseId ~= nil and HorseGenetics.horses[horseId] ~= nil then
                horse = HorseGenetics.horses[horseId]
            end
            if horse == nil then
                return
            end
            local price = hgReadClusterSellPrice(cluster)
            if price == nil then
                return
            end
            pricesById[horse.id] = price
            if horse.name ~= nil and horse.name ~= "" then
                pricesByName[horse.name] = price
            end
            HorseGenetics.rememberSellPrice(horse, price)
            local multiplier = HorseGenetics.getSaleValueMultiplier(horse)
            if multiplier ~= nil and multiplier > 0 then
                sampleBase = price / multiplier
            end
        end)
    end)
    HorseGenetics.quietSalePrice = nil
    HorseGenetics.finalizeSoldPrices()
    return {
        byId = pricesById,
        byName = pricesByName,
        sampleBase = sampleBase
    }
end

function HorseGenetics.rememberSellPrice(horse, price)
    price = tonumber(price)
    if horse == nil or price == nil or price <= 0 then
        return
    end
    horse.lastKnownSellPrice = math.floor(price + 0.5)
end

function HorseGenetics.finalizeSoldPrices(ownedIds)
    if HorseGenetics.isAuthoritative ~= nil and not HorseGenetics.isAuthoritative() then
        return
    end
    ownedIds = ownedIds or HorseGenetics.collectOwnedHorseIds()
    if (HorseGenetics._lastClusterScanCount or 0) <= 0 then
        return
    end
    for _, horse in pairs(HorseGenetics.horses or {}) do
        if type(horse) == "table" and horse.id ~= nil and ownedIds[horse.id] ~= true then
            if horse.soldPrice == nil then
                horse.soldPrice = horse.lastKnownSellPrice
            end
        end
    end
end

function HorseGenetics.getHorseDisplayValue(horse, priceIndex, ownedIds)
    if horse == nil then
        return nil, false
    end
    local owned = ownedIds ~= nil and horse.id ~= nil and ownedIds[horse.id] == true
    if owned then
        return HorseGenetics.getHorseSellPrice(horse, priceIndex), false
    end
    if horse.soldPrice == nil and horse.lastKnownSellPrice ~= nil then
        horse.soldPrice = horse.lastKnownSellPrice
    end
    if horse.soldPrice ~= nil then
        return horse.soldPrice, true
    end
    if horse.lastKnownSellPrice ~= nil then
        return horse.lastKnownSellPrice, true
    end
    return nil, true
end

function HorseGenetics.getHorseSellPrice(horse, priceIndex)
    if horse == nil then
        return nil
    end
    if priceIndex ~= nil then
        if horse.id ~= nil and priceIndex.byId ~= nil and priceIndex.byId[horse.id] ~= nil then
            return priceIndex.byId[horse.id]
        end
        if horse.name ~= nil and priceIndex.byName ~= nil and priceIndex.byName[horse.name] ~= nil then
            return priceIndex.byName[horse.name]
        end
        local sampleBase = tonumber(priceIndex.sampleBase)
        if sampleBase ~= nil and sampleBase > 0 then
            local multiplier = HorseGenetics.getSaleValueMultiplier(horse)
            return math.floor(sampleBase * (tonumber(multiplier) or 1) + 0.5)
        end
    end
    return nil
end

function HorseGenetics.formatHorseMoney(amount)
    amount = tonumber(amount)
    if amount == nil then
        return "-"
    end
    amount = math.floor(amount + 0.5)
    if g_i18n ~= nil and g_i18n.formatMoney ~= nil then
        local ok, text = pcall(function()
            return g_i18n:formatMoney(amount, 0, true, true)
        end)
        if ok and type(text) == "string" and text ~= "" then
            return text
        end
        ok, text = pcall(function()
            return g_i18n:formatMoney(amount)
        end)
        if ok and type(text) == "string" and text ~= "" then
            return text
        end
    end
    local sign = ""
    if amount < 0 then
        sign = "-"
        amount = -amount
    end
    local grouped = string.reverse(tostring(amount))
    grouped = string.gsub(grouped, "(%d%d%d)", "%1,")
    grouped = string.reverse(grouped)
    grouped = string.gsub(grouped, "^,", "")
    return sign .. "$" .. grouped
end

-- Multiply the vanilla horse sell price by the genetics modifier.
function HorseGenetics:installSaleValueIntegration()
    if AnimalClusterHorse == nil or AnimalClusterHorse.getSellPrice == nil then
        return false
    end

    if AnimalClusterHorse.horseGeneticsSaleValueInstalled then
        return true
    end

    local originalGetSellPrice = AnimalClusterHorse.getSellPrice
    AnimalClusterHorse.getSellPrice = function(cluster, ...)
        local basePrice = originalGetSellPrice(cluster, ...)
        if type(basePrice) ~= "number" then
            return basePrice
        end

        local horse
        if HorseGenetics.isAuthoritative() then
            horse = HorseGenetics.getOrCreateHorseForCluster(cluster, hgGetOwnerFarmId(cluster))
        else
            horse = HorseGenetics.getHorseForCluster(cluster)
        end
        if horse == nil then
            return basePrice
        end

        if cluster ~= nil then
            cluster.horseGeneticsId = horse.id
        end
        local breakdown = HorseGenetics.getSaleValueBreakdown(horse)
        local finalPrice = math.floor(basePrice * breakdown.multiplier + 0.5)
        HorseGenetics.rememberSellPrice(horse, finalPrice)
        return finalPrice
    end

    AnimalClusterHorse.horseGeneticsSaleValueInstalled = true
    return true
end

local function hgHookHorseClusterAdd(classTable, methodName)
    if classTable == nil or type(classTable[methodName]) ~= "function" then
        return
    end
    local flag = "horseGeneticsHook_" .. methodName
    if classTable[flag] then
        return
    end
    local original = classTable[methodName]
    classTable[methodName] = function(self, cluster, ...)
        if HorseGenetics.isAuthoritative() and HorseGenetics.isHorseCluster(cluster) then
            local ownerFarmId = hgGetOwnerFarmId(self) or hgGetOwnerFarmId(cluster)
            if ownerFarmId == nil and self ~= nil then
                ownerFarmId = hgGetOwnerFarmId(self.owner) or hgGetOwnerFarmId(self.husbandry)
                    or hgGetOwnerFarmId(self.placeable)
            end
            HorseGenetics.getOrCreateHorseForCluster(cluster, ownerFarmId)
        end
        return original(self, cluster, ...)
    end
    classTable[flag] = true
end

-- Hook sale price, new clusters, and mounting a horse.
function HorseGenetics:installCoreIntegrations()
    HorseGenetics.installClusterPersistence()
    self:installSaleValueIntegration()
    hgHookHorseClusterAdd(PlaceableHusbandryAnimals, "addCluster")
    hgHookHorseClusterAdd(AnimalClusterSystem, "addCluster")
    hgHookHorseClusterAdd(AnimalClusterHusbandry, "addCluster")

    if Rideable == nil or Rideable.getCluster == nil or Rideable.onEnterVehicle == nil then
        return
    end

    if Rideable.horseGeneticsRideableInstalled then
        return
    end

    local originalOnEnterVehicle = Rideable.onEnterVehicle
    Rideable.onEnterVehicle = function(self, isControlling)
        local result = originalOnEnterVehicle(self, isControlling)
        local cluster = self:getCluster()
        if HorseGenetics.isAuthoritative() then
            HorseGenetics.getOrCreateHorseForCluster(cluster, hgGetOwnerFarmId(self) or hgGetOwnerFarmId(cluster))
        end
        return result
    end

    Rideable.horseGeneticsRideableInstalled = true
end

function HorseGenetics.isHorseCluster(cluster)
    if cluster == nil then
        return false
    end
    local isHorse = false
    pcall(function()
        if AnimalClusterHorse ~= nil and cluster.isa ~= nil and cluster:isa(AnimalClusterHorse) then
            isHorse = true
        elseif AnimalItemHorse ~= nil and cluster.isa ~= nil and cluster:isa(AnimalItemHorse) then
            isHorse = true
        elseif AnimalItemStock ~= nil and cluster.isa ~= nil and cluster:isa(AnimalItemStock) then
            local nested = cluster.cluster
            if nested == nil and cluster.getCluster ~= nil then
                nested = cluster:getCluster()
            end
            if nested ~= nil and nested ~= cluster and AnimalClusterHorse ~= nil and nested.isa ~= nil and nested:isa(AnimalClusterHorse) then
                isHorse = true
            end
        end
    end)
    if isHorse then
        return true
    end
    local function hasHorseToken(value)
        return type(value) == "string" and string.find(string.upper(value), "HORSE", 1, true) ~= nil
    end
    if hasHorseToken(cluster.typeName) or hasHorseToken(cluster.animalType) then
        return true
    end
    if g_currentMission == nil or g_currentMission.animalSystem == nil then
        return false
    end
    local ok, label = pcall(function()
        local index = nil
        if cluster.getSubTypeIndex ~= nil then
            index = cluster:getSubTypeIndex()
        else
            index = cluster.subTypeIndex
        end
        if index == nil then
            return ""
        end
        local subtype = g_currentMission.animalSystem:getSubTypeByIndex(index)
        if subtype == nil then
            return ""
        end
        local animalType = subtype.typeIndex ~= nil
            and g_currentMission.animalSystem:getTypeByIndex(subtype.typeIndex) or nil
        return string.upper(tostring(subtype.name or subtype.title or "") .. " "
            .. tostring(animalType ~= nil and (animalType.name or animalType.title) or ""))
    end)
    return ok and string.find(label, "HORSE", 1, true) ~= nil
end

local function hgClearHorseReproduction(cluster)
    HorseGenetics.setClusterReproduction(cluster, 0, HorseGenetics.getGestationMonths(), HorseGenetics.getGestationMonths())
end

local function hgEnsureHorseClusterNumbers(cluster)
    if cluster == nil then
        return
    end
    pcall(function()
        local age = cluster.age
        if type(age) ~= "number" and cluster.getAge ~= nil then
            age = cluster:getAge()
        end
        if type(age) ~= "number" then
            age = 0
        end
        cluster.age = age
        if type(cluster.reproduction) ~= "number" then
            cluster.reproduction = 0
        end
        if type(cluster.numAnimals) ~= "number" then
            cluster.numAnimals = 1
        end
    end)
end

local function hgWrapSkipHorseReproduction(classTable, methodName)
    if type(classTable) ~= "table" or type(classTable[methodName]) ~= "function" then
        return false
    end
    local flag = "horseGeneticsWrapped_" .. methodName
    if classTable[flag] then
        return true
    end
    local original = classTable[methodName]
    classTable[methodName] = function(self, ...)
        if HorseGenetics.allowModHorseBirth ~= true and HorseGenetics.isHorseCluster(self) then
            if methodName == "getSupportsReproduction" then
                return true
            end
            if methodName == "getReproduction" then
                if self._hgReproSync ~= true then
                    HorseGenetics.syncClusterReproduction(self)
                end
                local horseId = HorseGenetics.getHorseGeneticsId(self)
                local pregnancy = HorseGenetics.getPregnancyForHorseId(horseId)
                if pregnancy ~= nil then
                    return HorseGenetics.getReproductionPercent(pregnancy)
                end
                if not HorseGenetics.isHorseMature(self) then
                    return HorseGenetics.getPubertyPercent(self)
                end
                return 0
            end
            if methodName == "getReproductionDuration" then
                if not HorseGenetics.isHorseMature(self) then
                    return HorseGenetics.getMaturityMonths(self)
                end
                return HorseGenetics.getGestationMonths()
            end
            if methodName == "getCanReproduce" then
                HorseGenetics.syncClusterReproduction(self)
                return HorseGenetics.getPregnancyForHorseId(HorseGenetics.getHorseGeneticsId(self)) ~= nil
            end
            if methodName == "getHadABirth" then
                local live = HorseGenetics.getLiveHorseCluster(self)
                if live ~= nil and live.hadABirth == true then
                    return true
                end
                return HorseGenetics.hasOffspring(HorseGenetics.getHorseGeneticsId(self))
            end
            if methodName == "getCanStartReproduction" or methodName == "reproduce" then
                return false
            end
            if methodName == "updateReproduction" then
                HorseGenetics.syncClusterReproduction(self)
                return 0
            end
            if methodName == "changeReproduction" or methodName == "addReproduction" then
                if self._hgReproSync == true then
                    return original(self, ...)
                end
                HorseGenetics.syncClusterReproduction(self)
                return
            end
        end
        return original(self, ...)
    end
    classTable[flag] = true
    return true
end

function HorseGenetics.installHorseReproductionBlock()
    local wrapped = 0
    local classes = {
        AnimalCluster, AnimalClusterHorse, AnimalItem, AnimalItemHorse, AnimalItemStock,
        AnimalClusterHusbandry, PlaceableHusbandryAnimals
    }
    local methods = {
        "updateReproduction", "changeReproduction", "reproduce",
        "addReproduction", "getCanReproduce", "getSupportsReproduction",
        "getCanStartReproduction", "getReproduction", "getReproductionDuration", "getHadABirth"
    }
    for i = 1, #classes do
        for j = 1, #methods do
            if hgWrapSkipHorseReproduction(classes[i], methods[j]) then
                wrapped = wrapped + 1
            end
        end
    end

    if PlaceableHusbandryAnimals ~= nil and PlaceableHusbandryAnimals.onPeriodChanged ~= nil
        and not PlaceableHusbandryAnimals.horseGeneticsBlockPeriod then
        local originalOnPeriodChanged = PlaceableHusbandryAnimals.onPeriodChanged
        PlaceableHusbandryAnimals.onPeriodChanged = function(husbandry, ...)
            local before = {}
            for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
                before[cluster] = true
                if HorseGenetics.isHorseCluster(cluster) then
                    hgEnsureHorseClusterNumbers(cluster)
                end
            end
            local ok, result = pcall(originalOnPeriodChanged, husbandry, ...)
            if not ok then
                result = nil
            end
            if HorseGenetics.allowModHorseBirth ~= true then
                for _, cluster in ipairs(HorseGenetics.getHusbandryClusters(husbandry)) do
                    if HorseGenetics.isHorseCluster(cluster) and before[cluster] ~= true then
                        local tracked = cluster.horseGeneticsId ~= nil
                            and HorseGenetics.modBirthClusters ~= nil
                            and HorseGenetics.modBirthClusters[cluster.horseGeneticsId]
                        if not tracked then
                            pcall(function()
                                if husbandry.removeCluster ~= nil and cluster.id ~= nil then
                                    husbandry:removeCluster(cluster.id)
                                elseif cluster.setNumAnimals ~= nil then
                                    cluster:setNumAnimals(0)
                                else
                                    cluster.numAnimals = 0
                                end
                            end)
                        end
                    elseif HorseGenetics.isHorseCluster(cluster) then
                        HorseGenetics.syncClusterReproduction(cluster)
                    end
                end
            end
            pcall(HorseGenetics.onHusbandryMonth, husbandry)
            pcall(HorseGenetics.syncHusbandryReproduction, husbandry)
            return result
        end
        PlaceableHusbandryAnimals.horseGeneticsBlockPeriod = true
        wrapped = wrapped + 1
    end

    if wrapped > 0 then
        HorseGenetics.horseReproductionBlockInstalled = true
        return true
    end
    return false
end

function HorseGenetics:loadMap()
    HorseGenetics.registerEventClasses()
    HorseGenetics.installNetworkHooks()
    HorseGenetics.installClusterPersistence()
    HorseGenetics.installHorseReproductionBlock()
    HorseGenetics:installCoreIntegrations()
end

function HorseGenetics:update(dt)
    pcall(function()
        HorseGenetics.registerEventClasses()
        HorseGenetics.installNetworkHooks()
        HorseGenetics.installClusterPersistence()
        HorseGenetics.installHorseReproductionBlock()
        HorseGenetics:installCoreIntegrations()
        if HorseGenetics._appliedPubertyMonths ~= HorseGenetics.getPubertyMonths() then
            HorseGenetics.applyPubertyToHorseSubtypes()
            HorseGenetics.syncAllReproductionVisuals()
        end
        dt = tonumber(dt) or 0
        if HorseGenetics.isAuthoritative() then
            HorseGenetics._liveScanAcc = (HorseGenetics._liveScanAcc or 0) + dt
            if HorseGenetics._liveScanAcc >= 2000 then
                HorseGenetics._liveScanAcc = 0
                HorseGenetics.ensureLiveHorseRecords()
            end
        elseif HorseGenetics.clientHasSync ~= true then
            HorseGenetics._clientSyncAcc = (HorseGenetics._clientSyncAcc or 0) + dt
            if HorseGenetics._clientSyncAcc >= 2500 then
                HorseGenetics._clientSyncAcc = 0
                HorseGenetics.requestSync()
            end
        end
    end)
end

addModEventListener(HorseGenetics)

-- Host/server only. Single player always counts as host.
function HorseGenetics.canRunHostCommand()
    if g_server ~= nil then return true end
    if g_currentMission == nil then return false end
    if g_currentMission.isServer == true then return true end
    if g_currentMission.getIsServer ~= nil then
        local ok, isServer = pcall(function()
            return g_currentMission:getIsServer()
        end)
        if ok and isServer == true then return true end
    end
    local missionInfo = g_currentMission.missionInfo
    if missionInfo ~= nil and missionInfo.isMultiplayer == false then return true end
    local dynamicInfo = g_currentMission.missionDynamicInfo
    if dynamicInfo ~= nil and dynamicInfo.isMultiplayer == false then return true end
    return false
end

function HorseGenetics.isAuthoritative()
    return HorseGenetics.canRunHostCommand()
end

function HorseGenetics.isMultiplayer()
    if g_currentMission == nil then
        return false
    end
    local dynamicInfo = g_currentMission.missionDynamicInfo
    if dynamicInfo ~= nil and dynamicInfo.isMultiplayer == true then
        return true
    end
    local missionInfo = g_currentMission.missionInfo
    if missionInfo ~= nil and missionInfo.isMultiplayer == true then
        return true
    end
    return false
end

function HorseGenetics.isDedicatedServer()
    if g_dedicatedServer ~= nil then
        return true
    end
    if g_server ~= nil and g_client == nil then
        return true
    end
    return false
end

function HorseGenetics.getLocalFarmId()
    local function validFarmId(farmId)
        return type(farmId) == "number" and farmId > 0 and farmId
    end
    if g_localPlayer ~= nil then
        local farmId = validFarmId(g_localPlayer.farmId)
        if farmId then
            return farmId
        end
    end
    if g_currentMission ~= nil then
        if g_currentMission.player ~= nil then
            local farmId = validFarmId(g_currentMission.player.farmId)
            if farmId then
                return farmId
            end
        end
        if g_currentMission.getFarmId ~= nil then
            local ok, farmId = pcall(function()
                return g_currentMission:getFarmId()
            end)
            if ok then
                farmId = validFarmId(farmId)
                if farmId then
                    return farmId
                end
            end
        end
    end
    return nil
end

function HorseGenetics.recordVisibleToLocalFarm(record)
    if record == nil then
        return false
    end
    if not HorseGenetics.isMultiplayer() then
        return true
    end
    local localFarmId = HorseGenetics.getLocalFarmId()
    if localFarmId == nil or localFarmId == 0 then
        return false
    end
    if record.farmId == nil or record.farmId == 0 then
        return true
    end
    return record.farmId == localFarmId
end

function HorseGenetics.notifyUiDirty()
    local page = HorseGenetics.hgMenuPage
    if page == nil then
        return
    end
    pcall(function()
        if page.refreshRecords ~= nil then
            page:refreshRecords()
        end
        if page.fillStaticPages ~= nil then
            page:fillStaticPages()
        end
        if page.renderBreedingPage ~= nil then
            page:renderBreedingPage()
        end
        if page.renderSettingsPage ~= nil then
            page:renderSettingsPage()
        end
    end)
end

local function hgWriteOptionalString(streamId, value)
    local text = tostring(value or "")
    streamWriteBool(streamId, text ~= "")
    if text ~= "" then
        streamWriteString(streamId, text)
    end
end

local function hgReadOptionalString(streamId)
    if not streamReadBool(streamId) then
        return nil
    end
    local text = streamReadString(streamId)
    if text == nil or text == "" then
        return nil
    end
    return text
end

local function hgWriteHorseToStream(streamId, horse)
    streamWriteString(streamId, horse.id or "")
    streamWriteString(streamId, horse.name or "")
    streamWriteInt32(streamId, horse.generation or 1)
    streamWriteString(streamId, horse.coatColour or "Bay")
    hgWriteOptionalString(streamId, horse.mareId)
    hgWriteOptionalString(streamId, horse.stallionId)
    streamWriteInt32(streamId, tonumber(horse.stats and horse.stats.speed) or 50)
    streamWriteInt32(streamId, tonumber(horse.stats and horse.stats.stamina) or 50)
    streamWriteInt32(streamId, tonumber(horse.stats and horse.stats.health) or 50)
    streamWriteInt32(streamId, tonumber(horse.farmId) or 0)
    streamWriteInt32(streamId, tonumber(horse.soldPrice) or 0)
    streamWriteInt32(streamId, tonumber(horse.lastKnownSellPrice) or 0)
    local ageMonths = tonumber(horse.lastAgeMonths)
    streamWriteBool(streamId, ageMonths ~= nil)
    if ageMonths ~= nil then
        streamWriteInt32(streamId, math.max(0, math.floor(ageMonths + 0.5)))
    end
end

local function hgReadHorseFromStream(streamId)
    local horse = {
        id = streamReadString(streamId),
        name = streamReadString(streamId),
        generation = streamReadInt32(streamId),
        coatColour = streamReadString(streamId),
        mareId = hgReadOptionalString(streamId),
        stallionId = hgReadOptionalString(streamId),
        stats = {
            speed = streamReadInt32(streamId),
            stamina = streamReadInt32(streamId),
            health = streamReadInt32(streamId)
        },
        farmId = streamReadInt32(streamId),
        soldPrice = streamReadInt32(streamId),
        lastKnownSellPrice = streamReadInt32(streamId)
    }
    if streamReadBool(streamId) then
        horse.lastAgeMonths = streamReadInt32(streamId)
    end
    if horse.farmId == 0 then
        horse.farmId = nil
    end
    if horse.soldPrice == 0 then
        horse.soldPrice = nil
    end
    if horse.lastKnownSellPrice == 0 then
        horse.lastKnownSellPrice = nil
    end
    if horse.id == "" then
        return nil
    end
    return horse
end

function HorseGenetics.applyHorseRecord(horse)
    if horse == nil or horse.id == nil or horse.id == "" then
        return
    end
    HorseGenetics.clientHasSync = true
    HorseGenetics.horses[horse.id] = horse
    local numeric = string.match(horse.id, "(%d+)$")
    if numeric ~= nil then
        local n = tonumber(numeric)
        if n ~= nil and n >= HorseGenetics.nextHorseId then
            HorseGenetics.nextHorseId = n + 1
        end
    end
end

function HorseGenetics.applyFullSync(horses, nextHorseId, breedingHistory, pregnancies, settings, clusterBindings)
    HorseGenetics.horses = horses or {}
    HorseGenetics.clientHasSync = true
    HorseGenetics.recordsReady = true
    if type(nextHorseId) == "number" and nextHorseId > 0 then
        HorseGenetics.nextHorseId = nextHorseId
    end
    HorseGenetics.breedingHistory = breedingHistory or {}
    HorseGenetics.pregnancies = pregnancies or {}
    for _, entry in ipairs(HorseGenetics.pregnancies) do
        HorseGenetics.normalizePregnancy(entry)
    end
    if type(settings) == "table" then
        HorseGenetics.applySettings(
            settings.gestationMonths,
            settings.valueModifierPercent,
            settings.pubertyMonths,
            true
        )
    end
    HorseGenetics.applyClusterBindings(clusterBindings)
    HorseGenetics.notifyUiDirty()
    if HorseGenetics.syncAllReproductionVisuals ~= nil then
        HorseGenetics.syncAllReproductionVisuals()
    end
end

function HorseGenetics.broadcastHorseRecord(horse)
    if horse == nil or not HorseGenetics.isAuthoritative() or not HorseGenetics.isMultiplayer() then
        return
    end
    if g_server == nil or HorseGeneticsHorseEvent == nil then
        return
    end
    g_server:broadcastEvent(HorseGeneticsHorseEvent.new(horse), false)
end

function HorseGenetics.broadcastFullSync(connection)
    if not HorseGenetics.isAuthoritative() or HorseGeneticsSyncEvent == nil then
        return
    end
    local event = HorseGeneticsSyncEvent.newFromCurrent()
    if connection ~= nil then
        connection:sendEvent(event)
    elseif g_server ~= nil and HorseGenetics.isMultiplayer() then
        g_server:broadcastEvent(event, false)
    end
end

function HorseGenetics.requestSync()
    if HorseGenetics.isAuthoritative() then
        return
    end
    if g_client == nil or HorseGeneticsRequestEvent == nil then
        return
    end
    local connection = g_client.getServerConnection ~= nil and g_client:getServerConnection() or nil
    if connection ~= nil then
        connection:sendEvent(HorseGeneticsRequestEvent.new())
    end
end

function HorseGenetics.installNetworkHooks()
    if HorseGenetics.networkHooksInstalled then
        return true
    end
    if FSBaseMission ~= nil and FSBaseMission.sendInitialClientState ~= nil then
        FSBaseMission.sendInitialClientState = Utils.appendedFunction(
            FSBaseMission.sendInitialClientState,
            function(mission, connection, user, farm)
                if connection ~= nil then
                    HorseGenetics.ensureLiveHorseRecords()
                    HorseGenetics.broadcastFullSync(connection)
                end
            end
        )
        HorseGenetics.networkHooksInstalled = true
        return true
    end
    return false
end

function HorseGenetics.registerEventClasses()
    if HorseGeneticsSyncEvent ~= nil or Event == nil or InitEventClass == nil then
        return
    end
    HorseGeneticsSyncEvent = {}
    local HorseGeneticsSyncEvent_mt = Class(HorseGeneticsSyncEvent, Event)
    InitEventClass(HorseGeneticsSyncEvent, "HorseGeneticsSyncEvent")

    function HorseGeneticsSyncEvent.emptyNew()
        return Event.new(HorseGeneticsSyncEvent_mt)
    end

    function HorseGeneticsSyncEvent.new(horses, nextHorseId, breedingHistory, pregnancies, settings, clusterBindings)
        local self = HorseGeneticsSyncEvent.emptyNew()
        self.horses = horses or {}
        self.nextHorseId = nextHorseId or 1
        self.breedingHistory = breedingHistory or {}
        self.pregnancies = pregnancies or {}
        self.settings = settings or HorseGenetics.settings
        self.clusterBindings = clusterBindings or {}
        return self
    end

    function HorseGeneticsSyncEvent.newFromCurrent()
        local horses = {}
        for _, horse in pairs(HorseGenetics.horses or {}) do
            table.insert(horses, horse)
        end
        table.sort(horses, function(a, b)
            return tostring(a.id) < tostring(b.id)
        end)
        return HorseGeneticsSyncEvent.new(
            horses,
            HorseGenetics.nextHorseId,
            HorseGenetics.breedingHistory or {},
            HorseGenetics.pregnancies or {},
            {
                gestationMonths = HorseGenetics.getGestationMonths(),
                valueModifierPercent = HorseGenetics.getValueModifierPercent(),
                pubertyMonths = HorseGenetics.getPubertyMonths()
            },
            HorseGenetics.collectClusterBindings()
        )
    end

    function HorseGeneticsSyncEvent:writeStream(streamId, connection)
        local horses = self.horses or {}
        streamWriteInt32(streamId, self.nextHorseId or 1)
        streamWriteInt32(streamId, #horses)
        for i = 1, #horses do
            hgWriteHorseToStream(streamId, horses[i])
        end
        local history = self.breedingHistory or {}
        streamWriteInt32(streamId, #history)
        for i = 1, #history do
            local entry = history[i]
            hgWriteOptionalString(streamId, entry.parent1Id)
            hgWriteOptionalString(streamId, entry.parent1Name)
            hgWriteOptionalString(streamId, entry.parent2Id)
            hgWriteOptionalString(streamId, entry.parent2Name)
            hgWriteOptionalString(streamId, entry.foal1Id)
            hgWriteOptionalString(streamId, entry.foal1Name)
            hgWriteOptionalString(streamId, entry.foal1Coat)
            streamWriteInt32(streamId, tonumber(entry.foal1Speed) or 0)
            streamWriteInt32(streamId, tonumber(entry.foal1Stamina) or 0)
            streamWriteInt32(streamId, tonumber(entry.foal1Health) or 0)
            hgWriteOptionalString(streamId, entry.foal2Id)
            hgWriteOptionalString(streamId, entry.foal2Name)
            hgWriteOptionalString(streamId, entry.foal2Coat)
            streamWriteInt32(streamId, tonumber(entry.foal2Speed) or 0)
            streamWriteInt32(streamId, tonumber(entry.foal2Stamina) or 0)
            streamWriteInt32(streamId, tonumber(entry.foal2Health) or 0)
        end
        local pregnancies = self.pregnancies or {}
        streamWriteInt32(streamId, #pregnancies)
        for i = 1, #pregnancies do
            local entry = pregnancies[i]
            hgWriteOptionalString(streamId, entry.husbandryId)
            hgWriteOptionalString(streamId, entry.parent1Id)
            hgWriteOptionalString(streamId, entry.parent2Id)
            streamWriteInt32(streamId, tonumber(entry.monthsRemaining) or 0)
            streamWriteInt32(streamId, tonumber(entry.farmId) or 0)
            streamWriteInt32(streamId, tonumber(entry.monthsElapsed) or 0)
        end
        local settings = self.settings or HorseGenetics.settings or {}
        streamWriteInt32(streamId, tonumber(settings.gestationMonths) or HorseGenetics.VANILLA_GESTATION_MONTHS)
        streamWriteInt32(streamId, tonumber(settings.valueModifierPercent) or 100)
        streamWriteInt32(streamId, tonumber(settings.pubertyMonths) or HorseGenetics.VANILLA_MATURITY_MONTHS)
        local bindings = self.clusterBindings or {}
        streamWriteInt32(streamId, #bindings)
        for i = 1, #bindings do
            local binding = bindings[i]
            hgWriteOptionalString(streamId, binding.horseId)
            hgWriteOptionalString(streamId, binding.husbandryId)
            hgWriteOptionalString(streamId, binding.clusterId)
            hgWriteOptionalString(streamId, binding.name)
            streamWriteInt32(streamId, tonumber(binding.ageMonths) or 0)
            streamWriteInt32(streamId, tonumber(binding.farmId) or 0)
        end
    end

    function HorseGeneticsSyncEvent:readStream(streamId, connection)
        self.nextHorseId = streamReadInt32(streamId)
        local horseCount = streamReadInt32(streamId)
        self.horses = {}
        for _ = 1, horseCount do
            local horse = hgReadHorseFromStream(streamId)
            if horse ~= nil then
                table.insert(self.horses, horse)
            end
        end
        local historyCount = streamReadInt32(streamId)
        self.breedingHistory = {}
        for _ = 1, historyCount do
            table.insert(self.breedingHistory, {
                parent1Id = hgReadOptionalString(streamId),
                parent1Name = hgReadOptionalString(streamId) or "",
                parent2Id = hgReadOptionalString(streamId),
                parent2Name = hgReadOptionalString(streamId) or "",
                foal1Id = hgReadOptionalString(streamId),
                foal1Name = hgReadOptionalString(streamId) or "",
                foal1Coat = hgReadOptionalString(streamId) or "",
                foal1Speed = streamReadInt32(streamId),
                foal1Stamina = streamReadInt32(streamId),
                foal1Health = streamReadInt32(streamId),
                foal2Id = hgReadOptionalString(streamId),
                foal2Name = hgReadOptionalString(streamId) or "",
                foal2Coat = hgReadOptionalString(streamId) or "",
                foal2Speed = streamReadInt32(streamId),
                foal2Stamina = streamReadInt32(streamId),
                foal2Health = streamReadInt32(streamId)
            })
        end
        local pregnancyCount = streamReadInt32(streamId)
        self.pregnancies = {}
        for _ = 1, pregnancyCount do
            table.insert(self.pregnancies, {
                husbandryId = hgReadOptionalString(streamId) or "",
                parent1Id = hgReadOptionalString(streamId),
                parent2Id = hgReadOptionalString(streamId),
                monthsRemaining = streamReadInt32(streamId),
                farmId = streamReadInt32(streamId),
                monthsElapsed = streamReadInt32(streamId)
            })
            HorseGenetics.normalizePregnancy(self.pregnancies[#self.pregnancies])
        end
        self.settings = {
            gestationMonths = streamReadInt32(streamId),
            valueModifierPercent = streamReadInt32(streamId),
            pubertyMonths = streamReadInt32(streamId)
        }
        local bindingCount = streamReadInt32(streamId)
        self.clusterBindings = {}
        for _ = 1, bindingCount do
            table.insert(self.clusterBindings, {
                horseId = hgReadOptionalString(streamId),
                husbandryId = hgReadOptionalString(streamId) or "",
                clusterId = hgReadOptionalString(streamId) or "",
                name = hgReadOptionalString(streamId) or "",
                ageMonths = streamReadInt32(streamId),
                farmId = streamReadInt32(streamId)
            })
        end
        self:run(connection)
    end

    function HorseGeneticsSyncEvent:run(connection)
        if connection ~= nil and connection:getIsServer() then
            local byId = {}
            for _, horse in ipairs(self.horses or {}) do
                byId[horse.id] = horse
            end
            HorseGenetics.applyFullSync(byId, self.nextHorseId, self.breedingHistory, self.pregnancies, self.settings, self.clusterBindings)
        end
    end

    HorseGeneticsHorseEvent = {}
    local HorseGeneticsHorseEvent_mt = Class(HorseGeneticsHorseEvent, Event)
    InitEventClass(HorseGeneticsHorseEvent, "HorseGeneticsHorseEvent")

    function HorseGeneticsHorseEvent.emptyNew()
        return Event.new(HorseGeneticsHorseEvent_mt)
    end

    function HorseGeneticsHorseEvent.new(horse)
        local self = HorseGeneticsHorseEvent.emptyNew()
        self.horse = horse
        return self
    end

    function HorseGeneticsHorseEvent:writeStream(streamId, connection)
        hgWriteHorseToStream(streamId, self.horse or {id = "", name = "", stats = {}})
    end

    function HorseGeneticsHorseEvent:readStream(streamId, connection)
        self.horse = hgReadHorseFromStream(streamId)
        self:run(connection)
    end

    function HorseGeneticsHorseEvent:run(connection)
        if connection ~= nil and connection:getIsServer() and self.horse ~= nil then
            HorseGenetics.applyHorseRecord(self.horse)
            HorseGenetics.notifyUiDirty()
        end
    end

    HorseGeneticsRequestEvent = {}
    local HorseGeneticsRequestEvent_mt = Class(HorseGeneticsRequestEvent, Event)
    InitEventClass(HorseGeneticsRequestEvent, "HorseGeneticsRequestEvent")

    function HorseGeneticsRequestEvent.emptyNew()
        return Event.new(HorseGeneticsRequestEvent_mt)
    end

    function HorseGeneticsRequestEvent.new()
        return HorseGeneticsRequestEvent.emptyNew()
    end

    function HorseGeneticsRequestEvent:writeStream(streamId, connection)
    end

    function HorseGeneticsRequestEvent:readStream(streamId, connection)
        self:run(connection)
    end

    function HorseGeneticsRequestEvent:run(connection)
        if g_server ~= nil and connection ~= nil and not connection:getIsServer() then
            HorseGenetics.ensureLiveHorseRecords()
            HorseGenetics.broadcastFullSync(connection)
        end
    end

    HorseGeneticsSettingsEvent = {}
    local HorseGeneticsSettingsEvent_mt = Class(HorseGeneticsSettingsEvent, Event)
    InitEventClass(HorseGeneticsSettingsEvent, "HorseGeneticsSettingsEvent")

    function HorseGeneticsSettingsEvent.emptyNew()
        return Event.new(HorseGeneticsSettingsEvent_mt)
    end

    function HorseGeneticsSettingsEvent.new(gestationMonths, valueModifierPercent, pubertyMonths)
        local self = HorseGeneticsSettingsEvent.emptyNew()
        self.gestationMonths = gestationMonths
        self.valueModifierPercent = valueModifierPercent
        self.pubertyMonths = pubertyMonths
        return self
    end

    function HorseGeneticsSettingsEvent.newFromCurrent()
        return HorseGeneticsSettingsEvent.new(
            HorseGenetics.getGestationMonths(),
            HorseGenetics.getValueModifierPercent(),
            HorseGenetics.getPubertyMonths()
        )
    end

    function HorseGeneticsSettingsEvent:writeStream(streamId, connection)
        streamWriteInt32(streamId, tonumber(self.gestationMonths) or HorseGenetics.VANILLA_GESTATION_MONTHS)
        streamWriteInt32(streamId, tonumber(self.valueModifierPercent) or 100)
        streamWriteInt32(streamId, tonumber(self.pubertyMonths) or HorseGenetics.VANILLA_MATURITY_MONTHS)
    end

    function HorseGeneticsSettingsEvent:readStream(streamId, connection)
        self.gestationMonths = streamReadInt32(streamId)
        self.valueModifierPercent = streamReadInt32(streamId)
        self.pubertyMonths = streamReadInt32(streamId)
        self:run(connection)
    end

    function HorseGeneticsSettingsEvent:run(connection)
        if g_server ~= nil and connection ~= nil and not connection:getIsServer() then
            HorseGenetics.applySettings(self.gestationMonths, self.valueModifierPercent, self.pubertyMonths)
            return
        end
        if connection ~= nil and connection:getIsServer() then
            HorseGenetics.applySettings(self.gestationMonths, self.valueModifierPercent, self.pubertyMonths, true)
        end
    end

end
HorseGenetics.registerEventClasses()

-- Esc-menu Horse Genetics page.
HorseGeneticsMenu = {}
HorseGeneticsMenu._mt = Class(HorseGeneticsMenu, TabbedMenuFrameElement)
HorseGeneticsMenu.LIST_ROWS = 13
HorseGeneticsMenu.BREED_PICK_ROWS = 12
HorseGeneticsMenu.HIST_LIST_ROWS = 12
HorseGeneticsMenu.TREE_CHILD_SLOTS = 4

local HG_COLOR_TEXT = {0.90, 0.90, 0.90, 1}
local HG_COLOR_SELECTED = {0.55, 0.82, 0.12, 1}
local HG_COLOR_MUTED = {0.70, 0.70, 0.70, 1}

local function hgSetText(element, text)
    if element ~= nil and element.setText ~= nil then
        element:setText(tostring(text or ""))
    end
end

local function hgSetColor(element, color)
    if element ~= nil and element.setTextColor ~= nil then
        element:setTextColor(color[1], color[2], color[3], color[4])
    end
end

local HG_BAR_TRACK_WIDTH = 240
local HG_BAR_TRACK_HEIGHT = 14
local HG_BAR_SIZE_API = nil
local HG_PORTRAIT_SIZE_STR = "260px 200px"
local HG_PORTRAIT_POS_X = 255
local HG_PORTRAIT_POS_Y = -179
local HG_PORTRAIT_POS_STR = "255px -179px"
local HG_PORTRAIT_SIZE_N = {260 / 1920, 200 / 1080}

local function hgApplyPxSize(element, widthPx, heightPx)
    if element == nil then
        return
    end
    local sizeStr = string.format("%.1fpx %dpx", widthPx, heightPx)
    local applied = false
    if element.setSize ~= nil then
        applied = pcall(function()
            element:setSize(sizeStr)
        end)
        if not applied then
            applied = pcall(function()
                element:setSize(string.format("%.1fpx", widthPx), string.format("%dpx", heightPx))
            end)
        end
        if not applied then
            pcall(function()
                element:setSize(widthPx / 1920, heightPx / 1080)
            end)
        end
    end
    pcall(function()
        if element.setAbsoluteSize ~= nil then
            element:setAbsoluteSize(widthPx / 1920, heightPx / 1080)
        end
        if element.overlay ~= nil then
            element.overlay.width = widthPx / 1920
            element.overlay.height = heightPx / 1080
        end
        if element.updateAbsoluteSize ~= nil then
            element:updateAbsoluteSize()
        end
        if element.updateAbsolutePosition ~= nil then
            element:updateAbsolutePosition()
        end
    end)
end

local function hgApplyPxPosition(element, xPx, yPx)
    if element == nil or element.setPosition == nil then
        return
    end
    local posStr = string.format("%.1fpx %dpx", xPx, yPx)
    local applied = pcall(function()
        element:setPosition(posStr)
    end)
    if not applied then
        pcall(function()
            element:setPosition(string.format("%.1fpx", xPx), string.format("%dpx", yPx))
        end)
    end
end

local function hgReadAbsSize(element)
    if element == nil then
        return nil, nil
    end
    if element.absSize ~= nil then
        return tonumber(element.absSize[1]), tonumber(element.absSize[2])
    end
    if element.size ~= nil then
        return tonumber(element.size[1]), tonumber(element.size[2])
    end
    return nil, nil
end

local function hgSyncOverlaySize(element, wNorm, hNorm)
    if element == nil or element.overlay == nil then
        return
    end
    pcall(function()
        if element.overlay.setDimension ~= nil then
            element.overlay:setDimension(wNorm, hNorm)
        else
            element.overlay.width = wNorm
            element.overlay.height = hNorm
        end
    end)
end

local function hgSizeChanged(beforeW, beforeH, afterW, afterH)
    if afterW == nil then
        return false
    end
    if beforeW == nil then
        return true
    end
    return math.abs(afterW - beforeW) > 1e-6 or math.abs((afterH or 0) - (beforeH or 0)) > 1e-6
end

local function hgBarWidthPlausible(afterW, trackAbsW, screenW)
    if afterW == nil or afterW < 0 then
        return false
    end
    local maxW = screenW
    if trackAbsW ~= nil and trackAbsW > 0 then
        maxW = math.max(trackAbsW * 1.08, screenW)
    end
    return afterW <= maxW + 1e-4
end

local function hgTrySetBarSize(element, name, value, widthPx, heightPx)
    local screenW = widthPx / 1920
    local screenH = heightPx / 1080
    local parentW = 1
    local parentH = 1
    local trackAbsW, trackAbsH = nil, nil
    if element.parent ~= nil then
        trackAbsW, trackAbsH = hgReadAbsSize(element.parent)
        if trackAbsW ~= nil and trackAbsW > 1e-6 then
            parentW = (widthPx / 1920) / trackAbsW
        else
            parentW = value / 100
        end
        if trackAbsH ~= nil and trackAbsH > 1e-6 then
            parentH = (heightPx / 1080) / trackAbsH
        else
            parentH = 1
        end
    else
        parentW = value / 100
        parentH = 1
    end
    if parentW < 0 then
        parentW = 0
    end

    local attempts = {
        {
            name = "screenNorm",
            apply = function()
                element:setSize(screenW, screenH)
            end,
            overlayW = screenW,
            overlayH = screenH
        },
        {
            name = "parentNorm",
            apply = function()
                element:setSize(parentW, parentH)
            end,
            overlayW = screenW,
            overlayH = screenH
        },
        {
            name = "pxString",
            apply = function()
                element:setSize(string.format("%dpx %dpx", widthPx, heightPx))
            end,
            overlayW = screenW,
            overlayH = screenH
        },
        {
            name = "sizeTable",
            apply = function()
                element.size = {screenW, screenH}
                if element.updateAbsolutePosition ~= nil then
                    element:updateAbsolutePosition()
                end
            end,
            overlayW = screenW,
            overlayH = screenH
        }
    }

    local function runAttempt(attempt)
        local beforeW, beforeH = hgReadAbsSize(element)
        local ok = pcall(attempt.apply)
        if not ok then
            return false, beforeW, beforeH, nil, nil
        end
        if element.updateAbsolutePosition ~= nil then
            pcall(element.updateAbsolutePosition, element)
        end
        hgSyncOverlaySize(element, attempt.overlayW, attempt.overlayH)
        local afterW, afterH = hgReadAbsSize(element)
        local plausible = hgBarWidthPlausible(afterW, trackAbsW, screenW)
        local changed = hgSizeChanged(beforeW, beforeH, afterW, afterH)
        return plausible and (changed or HG_BAR_SIZE_API == attempt.name), beforeW, beforeH, afterW, afterH
    end

    if HG_BAR_SIZE_API ~= nil then
        for i = 1, #attempts do
            if attempts[i].name == HG_BAR_SIZE_API then
                local ok, _, _, afterW = runAttempt(attempts[i])
                if ok then
                    return attempts[i].name, afterW
                end
                HG_BAR_SIZE_API = nil
                break
            end
        end
    end

    for i = 1, #attempts do
        local ok, _, _, afterW = runAttempt(attempts[i])
        if ok then
            HG_BAR_SIZE_API = attempts[i].name
            return attempts[i].name, afterW
        end
    end

    -- Fallback if absSize did not change.
    pcall(function()
        element.size = {screenW, screenH}
        if element.updateAbsolutePosition ~= nil then
            element:updateAbsolutePosition()
        end
        hgSyncOverlaySize(element, screenW, screenH)
    end)
    local afterW = select(1, hgReadAbsSize(element))
    return HG_BAR_SIZE_API or "fallback", afterW
end

local function hgSetBarFill(bar, value, name)
    pcall(function()
        if bar == nil then
            return
        end
        value = math.max(0, math.min(100, tonumber(value) or 0))
        local widthPx = HG_BAR_TRACK_WIDTH * value / 100
        if widthPx < 1 then
            widthPx = 1
            if bar.setVisible ~= nil then
                bar:setVisible(false)
            end
        elseif bar.setVisible ~= nil then
            bar:setVisible(true)
        end
        -- Nested fills stay at 0,0 (left of the track). Do not re-center; shrinking the
        -- fill bitmap is what makes the bar read as a percentage.
        pcall(function()
            if bar.setPosition ~= nil then
                local ok = pcall(function()
                    bar:setPosition("0px 0px")
                end)
                if not ok then
                    bar:setPosition(0, 0)
                end
            end
        end)
        hgTrySetBarSize(bar, name, value, widthPx, HG_BAR_TRACK_HEIGHT)
    end)
end

local function hgApplyPortraitLayout(element)
    if element == nil then
        return
    end
    pcall(function()
        if element.setSize ~= nil then
            local ok = pcall(function()
                element:setSize(HG_PORTRAIT_SIZE_STR)
            end)
            if not ok then
                pcall(function()
                    element:setSize(HG_PORTRAIT_SIZE_N[1], HG_PORTRAIT_SIZE_N[2])
                end)
            end
        end
        hgApplyPxSize(element, 260, 200)
        hgApplyPxPosition(element, HG_PORTRAIT_POS_X, HG_PORTRAIT_POS_Y)
        pcall(function()
            if element.setPosition ~= nil then
                element:setPosition(HG_PORTRAIT_POS_STR)
            end
        end)
    end)
end

local function hgHideLeftoverScrollChrome(page)
    if page == nil then
        return
    end
    for _, id in ipairs({ "horseScrollBar", "horseScrollOutline", "horseScrollTrack", "horseScrollThumb" }) do
        local element = page[id]
        if element ~= nil and element.setVisible ~= nil then
            pcall(element.setVisible, element, false)
        end
    end
end

local function hgBindStatBarTextures(page)
    if page == nil or page.hgStatBarsBound then
        return
    end
    local directory = HorseGenetics.modDirectory or g_currentModDirectory
    if directory == nil then
        return
    end
    if not string.match(directory, "[/\\]$") then
        directory = directory .. "/"
    end
    local function bind(element, relativePath)
        if element ~= nil and element.setImageFilename ~= nil then
            pcall(element.setImageFilename, element, directory .. relativePath)
        end
    end
    bind(page.speedTrack, "gui/bars/track.dds")
    bind(page.staminaTrack, "gui/bars/track.dds")
    bind(page.healthTrack, "gui/bars/track.dds")
    bind(page.averageTrack, "gui/bars/track.dds")
    bind(page.speedBar, "gui/bars/speed.dds")
    bind(page.staminaBar, "gui/bars/stamina.dds")
    bind(page.healthBar, "gui/bars/health.dds")
    bind(page.averageBar, "gui/bars/speed.dds")
    if page.averageBar ~= nil and page.averageBar.setImageColor ~= nil then
        pcall(page.averageBar.setImageColor, page.averageBar, nil, 0.82, 0.82, 0.82, 1)
    end
    bind(page.hgHeaderIcon, "gui/icons/horse_genetics_menu_icon.dds")
    bind(page.hgHeaderBadge, "gui/decor/header_badge.dds")
    pcall(function()
        if page.hgHeaderIcon ~= nil and page.hgHeaderIcon.setImageUVs ~= nil and GuiUtils ~= nil then
            page.hgHeaderIcon:setImageUVs(nil, unpack(GuiUtils.getUVs({0, 0, 256, 256}, 256)))
        end
    end)
    local function bindStatIcon(ids, relativePath)
        for i = 1, #ids do
            bind(page[ids[i]], relativePath)
        end
    end
    bindStatIcon({
        "iconHealth", "iconBreedP1Health", "iconBreedP2Health",
        "iconCompatHealth", "iconBreedF1Health", "iconBreedF2Health",
        "treeFocusIconHealth", "treeP1IconHealth", "treeP2IconHealth",
        "treeC1IconHealth", "treeC2IconHealth", "treeC3IconHealth", "treeC4IconHealth"
    }, "gui/icons/stat_health.dds")
    bindStatIcon({
        "iconStamina", "iconBreedP1Stamina", "iconBreedP2Stamina",
        "iconCompatStamina", "iconBreedF1Stamina", "iconBreedF2Stamina",
        "treeFocusIconStamina", "treeP1IconStamina", "treeP2IconStamina",
        "treeC1IconStamina", "treeC2IconStamina", "treeC3IconStamina", "treeC4IconStamina"
    }, "gui/icons/stat_stamina.dds")
    bindStatIcon({
        "iconSpeed", "iconBreedP1Speed", "iconBreedP2Speed",
        "iconCompatSpeed", "iconBreedF1Speed", "iconBreedF2Speed",
        "treeFocusIconSpeed", "treeP1IconSpeed", "treeP2IconSpeed",
        "treeC1IconSpeed", "treeC2IconSpeed", "treeC3IconSpeed", "treeC4IconSpeed"
    }, "gui/icons/stat_speed.dds")
    bindStatIcon({
        "iconAverage", "iconBreedP1Average", "iconBreedP2Average",
        "iconCompatAverage", "iconBreedF1Average", "iconBreedF2Average",
        "treeFocusIconAverage", "treeP1IconAverage", "treeP2IconAverage",
        "treeC1IconAverage", "treeC2IconAverage", "treeC3IconAverage", "treeC4IconAverage"
    }, "gui/icons/stat_average.dds")
    local accentIds = {
        "accentOwned", "accentProfile", "accentStats", "accentSale",
        "accentBreedPicker", "accentHorse1", "accentCompat", "accentHorse2",
        "accentOffspring", "accentFoal1", "accentFoal2",
        "accentGeneticInfo", "accentFamilyTree", "accentSettings"
    }
    for i = 1, #accentIds do
        bind(page[accentIds[i]], "gui/decor/card_accent.dds")
    end
    if page.healthBar ~= nil and page.staminaBar ~= nil and page.speedBar ~= nil and page.averageBar ~= nil then
        page.hgStatBarsBound = true
    end
    hgHideLeftoverScrollChrome(page)
end

local function hgReadMouseWheelDelta(page)
    local delta = 0
    pcall(function()
        if g_inputBinding ~= nil then
            if g_inputBinding.getMouseWheelValue ~= nil then
                delta = tonumber(g_inputBinding:getMouseWheelValue()) or 0
            elseif g_inputBinding.getMouseWheelDelta ~= nil then
                delta = tonumber(g_inputBinding:getMouseWheelDelta()) or 0
            elseif g_inputBinding.mouseWheelValue ~= nil then
                delta = tonumber(g_inputBinding.mouseWheelValue) or 0
            end
            if delta == 0 and InputAction ~= nil and g_inputBinding.getAxisValue ~= nil then
                local axis = InputAction.AXIS_MOUSE_WHEEL or InputAction.MOUSE_WHEEL or InputAction.AXIS_MAP_SCROLL_VERT
                if axis ~= nil then
                    delta = tonumber(g_inputBinding:getAxisValue(axis)) or 0
                end
            end
        end
        if delta == 0 and Input ~= nil then
            delta = tonumber(Input.mouseWheel or Input.MOUSE_WHEEL_DELTA) or 0
        end
    end)
    delta = tonumber(delta) or 0
    if page ~= nil then
        local last = page.hgLastWheelValue
        if last ~= nil and math.abs(delta) > 0 and math.abs(delta - last) < 0.0001 then
            -- Ignore an unchanged sticky wheel axis.
        end
        page.hgLastWheelValue = delta
    end
    return delta
end

function HorseGeneticsMenu.new()
    local self = HorseGeneticsMenu:superClass().new(nil, HorseGeneticsMenu._mt)
    self.name = "horseGeneticsMenu"
    self.records = {}
    self.selectedRecord = nil
    self.breedParent1 = nil
    self.breedParent2 = nil
    self.breedPickerSelected = nil
    self.breedPickOffset = 0
    self.listOffset = 0
    self.historyRecords = {}
    self.historySelected = nil
    self.historyOffset = 0
    self.treeChildOffset = 0
    self.treeChildren = {}
    self.currentTab = "horses"
    self.hgWheelHandledFrame = nil
    self.hasCustomMenuButtons = true
    self.btnBack = {inputAction = InputAction.MENU_BACK}
    self:setMenuButtonInfo({self.btnBack})
    if self.setTitle ~= nil then
        self:setTitle(hgT("hg_title"))
    end
    return self
end

function HorseGeneticsMenu:onFrameOpen()
    HorseGeneticsMenu:superClass().onFrameOpen(self)
    if self.setTitle ~= nil then
        self:setTitle(hgT("hg_title"))
    end
    self:showTab(self.currentTab or "horses")
    self:styleSectionTitles()
    self:refreshRecords()
    self:fillStaticPages()
end

function HorseGeneticsMenu:showTab(tabName)
    self.currentTab = tabName
    if self.panelMyHorses ~= nil then self.panelMyHorses:setVisible(tabName == "horses") end
    if self.panelBreeding ~= nil then self.panelBreeding:setVisible(tabName == "breeding") end
    if self.panelGeneticInfo ~= nil then self.panelGeneticInfo:setVisible(tabName == "info") end
    if self.panelSettings ~= nil then self.panelSettings:setVisible(tabName == "settings") end
    hgSetColor(self.tabMyHorses, tabName == "horses" and HG_COLOR_SELECTED or HG_COLOR_MUTED)
    hgSetColor(self.tabBreeding, tabName == "breeding" and HG_COLOR_SELECTED or HG_COLOR_MUTED)
    hgSetColor(self.tabGeneticInfo, tabName == "info" and HG_COLOR_SELECTED or HG_COLOR_MUTED)
    hgSetColor(self.tabSettings, tabName == "settings" and HG_COLOR_SELECTED or HG_COLOR_MUTED)
end

function HorseGeneticsMenu:onClickTabMyHorses()
    self:showTab("horses")
    self:refreshRecords()
end

function HorseGeneticsMenu:onClickTabBreeding()
    self:showTab("breeding")
    self:refreshRecords()
    self:renderBreedingPage()
end

function HorseGeneticsMenu:onClickTabGeneticInfo()
    self:showTab("info")
    self:renderGeneticInfoPage()
end

function HorseGeneticsMenu:onClickTabSettings()
    self:showTab("settings")
    self:renderSettingsPage()
end

function HorseGeneticsMenu:renderSettingsPage()
    hgSetText(self.gestationValue, HorseGenetics.gestationLabel(HorseGenetics.getGestationMonths()))
    hgSetText(self.pubertyValue, HorseGenetics.pubertyLabel(HorseGenetics.getPubertyMonths()))
    hgSetText(self.valueModifierValue, HorseGenetics.valueModifierLabel(HorseGenetics.getValueModifierPercent()))
end

function HorseGeneticsMenu:onClickGestationDown()
    HorseGenetics.requestSetSettings(
        HorseGenetics.cycleSetting(HorseGenetics.GESTATION_OPTIONS, HorseGenetics.getGestationMonths(), -1),
        HorseGenetics.getValueModifierPercent(),
        HorseGenetics.getPubertyMonths()
    )
    self:renderSettingsPage()
end

function HorseGeneticsMenu:onClickGestationUp()
    HorseGenetics.requestSetSettings(
        HorseGenetics.cycleSetting(HorseGenetics.GESTATION_OPTIONS, HorseGenetics.getGestationMonths(), 1),
        HorseGenetics.getValueModifierPercent(),
        HorseGenetics.getPubertyMonths()
    )
    self:renderSettingsPage()
end

function HorseGeneticsMenu:onClickPubertyDown()
    HorseGenetics.requestSetSettings(
        HorseGenetics.getGestationMonths(),
        HorseGenetics.getValueModifierPercent(),
        HorseGenetics.cycleSetting(HorseGenetics.MATURITY_OPTIONS, HorseGenetics.getPubertyMonths(), -1)
    )
    self:renderSettingsPage()
end

function HorseGeneticsMenu:onClickPubertyUp()
    HorseGenetics.requestSetSettings(
        HorseGenetics.getGestationMonths(),
        HorseGenetics.getValueModifierPercent(),
        HorseGenetics.cycleSetting(HorseGenetics.MATURITY_OPTIONS, HorseGenetics.getPubertyMonths(), 1)
    )
    self:renderSettingsPage()
end

function HorseGeneticsMenu:onClickValueDown()
    HorseGenetics.requestSetSettings(
        HorseGenetics.getGestationMonths(),
        HorseGenetics.cycleSetting(HorseGenetics.VALUE_MODIFIER_OPTIONS, HorseGenetics.getValueModifierPercent(), -1),
        HorseGenetics.getPubertyMonths()
    )
    self:renderSettingsPage()
end

function HorseGeneticsMenu:onClickValueUp()
    HorseGenetics.requestSetSettings(
        HorseGenetics.getGestationMonths(),
        HorseGenetics.cycleSetting(HorseGenetics.VALUE_MODIFIER_OPTIONS, HorseGenetics.getValueModifierPercent(), 1),
        HorseGenetics.getPubertyMonths()
    )
    self:renderSettingsPage()
end

local function hgApplyBold(element)
    if element == nil then
        return
    end
    if element.setBold ~= nil then
        pcall(element.setBold, element, true)
    end
    if element.setTextBold ~= nil then
        pcall(element.setTextBold, element, true)
    end
    if element.textBold ~= nil then
        element.textBold = true
    end
end

local function hgStyleSectionTitle(element)
    if element == nil then
        return
    end
    hgSetColor(element, HG_COLOR_SELECTED)
    if element.setTextSize ~= nil then
        pcall(element.setTextSize, element, 30 / 1080)
    end
    hgApplyBold(element)
    if element.setTextAlignment ~= nil and RenderText ~= nil and RenderText.ALIGN_LEFT ~= nil then
        pcall(element.setTextAlignment, element, RenderText.ALIGN_LEFT)
    end
end

local function hgStyleColumnHeader(element)
    if element == nil then
        return
    end
    hgSetColor(element, HG_COLOR_SELECTED)
    if element.setTextSize ~= nil then
        pcall(element.setTextSize, element, 16 / 1080)
    end
    hgApplyBold(element)
end

function HorseGeneticsMenu:styleSectionTitles()
    hgStyleSectionTitle(self.titleRegisteredHorses)
    hgStyleSectionTitle(self.titleHorseProfile)
    hgStyleSectionTitle(self.titleGeneticStats)
    hgStyleSectionTitle(self.titleSaleModifiers)
    hgStyleSectionTitle(self.titleBreeding)
    hgStyleSectionTitle(self.titleGeneticInfo)
    hgStyleSectionTitle(self.titleHorse1)
    hgStyleSectionTitle(self.titleHorse2)
    hgStyleSectionTitle(self.titleCompat)
    hgStyleSectionTitle(self.titleOffspring)
    hgStyleSectionTitle(self.titleFoal1)
    hgStyleSectionTitle(self.titleFoal2)
    hgStyleSectionTitle(self.titleBreedingHistory)
    hgStyleSectionTitle(self.titleFamilyTree)
    hgStyleSectionTitle(self.titleSettings)
    hgStyleSectionTitle(self.titleBreedPicker)
    hgSetColor(self.settingsHint, HG_COLOR_MUTED)
    hgSetColor(self.gestationHelp, HG_COLOR_MUTED)
    hgSetColor(self.pubertyHelp, HG_COLOR_MUTED)
    hgSetColor(self.valueModifierHelp, HG_COLOR_MUTED)
    hgStyleColumnHeader(self.histHeaderName)
    hgStyleColumnHeader(self.histHeaderAge)
    hgStyleColumnHeader(self.histHeaderSpeed)
    hgStyleColumnHeader(self.histHeaderStamina)
    hgStyleColumnHeader(self.histHeaderHealth)
    hgStyleColumnHeader(self.histHeaderAverage)
    hgStyleColumnHeader(self.treeParentsLabel)
    hgStyleColumnHeader(self.treeFocusLabel)
    hgStyleColumnHeader(self.treeKidsLabel)
    hgSetColor(self.treeHint, HG_COLOR_MUTED)
    hgSetColor(self.breedPickerHint, {1, 1, 1, 1})
    hgApplyBold(self.breedPickerHint)
    if self.breedPickerHint ~= nil and self.breedPickerHint.setTextSize ~= nil then
        pcall(self.breedPickerHint.setTextSize, self.breedPickerHint, 16 / 1080)
    end
    hgStyleColumnHeader(self.breedPickHeaderName)
    hgStyleColumnHeader(self.breedPickHeaderAge)
    hgStyleColumnHeader(self.breedPickHeaderSpeed)
    hgStyleColumnHeader(self.breedPickHeaderStamina)
    hgStyleColumnHeader(self.breedPickHeaderHealth)
    hgStyleColumnHeader(self.breedPickHeaderAverage)
    hgStyleColumnHeader(self.compatHeadStat)
    hgStyleColumnHeader(self.compatHeadComb)
    hgStyleColumnHeader(self.tableHeaderName)
    hgStyleColumnHeader(self.tableHeaderAge)
    hgStyleColumnHeader(self.tableHeaderSpeed)
    hgStyleColumnHeader(self.tableHeaderStamina)
    hgStyleColumnHeader(self.tableHeaderHealth)
    hgStyleColumnHeader(self.tableHeaderAverage)
    hgStyleColumnHeader(self.tableHeaderSale)
    hgStyleColumnHeader(self.tableHeaderValue)
end

function HorseGeneticsMenu:fillStaticPages()
    self:renderGeneticInfoPage()
    self:renderSettingsPage()
end

function HorseGeneticsMenu:refreshRecords()
    self.records = {}
    self.sellPriceIndex = HorseGenetics.collectHorseSellPrices()
    local ownedIds = HorseGenetics.collectOwnedHorseIds()
    for _, record in pairs(HorseGenetics.horses or {}) do
        if type(record) == "table" and type(record.stats) == "table" and ownedIds[record.id] == true then
            record._hgUiBreakdown = HorseGenetics.getSaleValueBreakdown(record)
            table.insert(self.records, record)
        end
    end
    table.sort(self.records, function(a, b)
        return tostring(a.name or a.id) < tostring(b.name or b.id)
    end)

    if self.selectedRecord ~= nil then
        local selectedId = self.selectedRecord.id
        self.selectedRecord = nil
        for _, record in ipairs(self.records) do
            if record.id == selectedId then
                self.selectedRecord = record
                break
            end
        end
    end
    if self.selectedRecord == nil and #self.records > 0 then
        self.selectedRecord = self.records[1]
    end
    self:syncBreedParentsToOwned()

    local maxOffset = math.max(0, #self.records - HorseGeneticsMenu.LIST_ROWS)
    if self.listOffset > maxOffset then
        self.listOffset = maxOffset
    end
    self:renderOverview()
end

function HorseGeneticsMenu:renderOverview()
    hgSetText(self.overviewText, hgT("hg_horses_owned", #self.records))

    for i = 1, HorseGeneticsMenu.LIST_ROWS do
        local record = self.records[self.listOffset + i]
        local selected = record ~= nil and self.selectedRecord ~= nil and record.id == self.selectedRecord.id
        local color = selected and HG_COLOR_SELECTED or HG_COLOR_TEXT
        local name, age, speed, stamina, health, average, sale, value = "", "", "", "", "", "", "", ""
        if record ~= nil then
            local stats = record.stats or {}
            local breakdown = record._hgUiBreakdown or HorseGenetics.getSaleValueBreakdown(record)
            name = tostring(record.name or record.id or hgT("hg_unnamed"))
            age = HorseGenetics.formatAgeYM(HorseGenetics.getRecordAgeMonths(record))
            speed = tostring(tonumber(stats.speed) or 0)
            stamina = tostring(tonumber(stats.stamina) or 0)
            health = tostring(tonumber(stats.health) or 0)
            average = string.format("%.1f", tonumber(breakdown.average) or 0)
            sale = string.format("%+.1f%%", ((tonumber(breakdown.multiplier) or 1) - 1) * 100)
            value = HorseGenetics.formatHorseMoney(HorseGenetics.getHorseSellPrice(record, self.sellPriceIndex))
        end
        hgSetText(self["horse" .. i .. "Name"], name)
        hgSetText(self["horse" .. i .. "Age"], age)
        hgSetText(self["horse" .. i .. "Speed"], speed)
        hgSetText(self["horse" .. i .. "Stamina"], stamina)
        hgSetText(self["horse" .. i .. "Health"], health)
        hgSetText(self["horse" .. i .. "Average"], average)
        hgSetText(self["horse" .. i .. "Sale"], sale)
        hgSetText(self["horse" .. i .. "Value"], value)
        hgSetColor(self["horse" .. i .. "Name"], color)
        hgSetColor(self["horse" .. i .. "Age"], color)
        hgSetColor(self["horse" .. i .. "Speed"], color)
        hgSetColor(self["horse" .. i .. "Stamina"], color)
        hgSetColor(self["horse" .. i .. "Health"], color)
        hgSetColor(self["horse" .. i .. "Average"], color)
        hgSetColor(self["horse" .. i .. "Sale"], color)
        hgSetColor(self["horse" .. i .. "Value"], color)
        local button = self["btnHorse" .. i]
        if button ~= nil then
            if button.setDisabled ~= nil then
                button:setDisabled(record == nil)
            end
            if button.setSelected ~= nil then
                pcall(button.setSelected, button, selected)
            end
        end
    end

    if #self.records > HorseGeneticsMenu.LIST_ROWS then
        hgSetText(self.moreRecordsText, hgT("hg_showing_scroll", self.listOffset + 1, math.min(#self.records, self.listOffset + HorseGeneticsMenu.LIST_ROWS), #self.records))
    else
        hgSetText(self.moreRecordsText, "")
    end
    self:renderProfile()
end

function HorseGeneticsMenu:getMaxListOffset()
    return math.max(0, #self.records - HorseGeneticsMenu.LIST_ROWS)
end

function HorseGeneticsMenu:setListOffset(offset, skipRender)
    local maxOffset = self:getMaxListOffset()
    offset = math.floor((tonumber(offset) or 0) + 0.5)
    offset = math.max(0, math.min(maxOffset, offset))
    if offset ~= self.listOffset then
        self.listOffset = offset
        if not skipRender then
            self:renderOverview()
        end
    end
end

function HorseGeneticsMenu:hgIsMyHorsesScrollActive()
    local ok, active = pcall(function()
        if self.currentTab ~= nil and self.currentTab ~= "horses" and self.currentTab ~= "info" then
            return false
        end
        local listPanel = self.currentTab == "info" and self.panelGeneticInfo or self.panelMyHorses
        if listPanel ~= nil then
            if listPanel.getIsVisible ~= nil and not listPanel:getIsVisible() then
                return false
            end
            if listPanel.visible == false then
                return false
            end
        end
        if self.getIsVisible ~= nil and not self:getIsVisible() then
            return false
        end
        if g_inGameMenu ~= nil then
            if g_inGameMenu.isOpen == false then
                return false
            end
            local current = g_inGameMenu.currentPage
            if current == nil and g_inGameMenu.pagingElement ~= nil then
                current = g_inGameMenu.pagingElement.currentPage or g_inGameMenu.pagingElement.currentPageElement
            end
            if current ~= nil and current ~= self then
                return false
            end
        end
        return true
    end)
    return ok and active == true
end

function HorseGeneticsMenu:hgApplyWheelDelta(raw)
    raw = tonumber(raw) or 0
    if math.abs(raw) < 0.15 then
        return false
    end
    local now = g_time or (g_currentMission ~= nil and g_currentMission.time) or 0
    if self.hgWheelHandledFrame ~= nil and self.hgWheelHandledFrame == now then
        return true
    end
    local steps = math.max(1, math.min(5, math.floor(math.abs(raw) + 0.5)))
    if raw > 0 then
        steps = -steps
    end
    if self.currentTab == "info" then
        local mouseX = tonumber(self.hgLastMouseX) or 0
        local rightSide = (mouseX > 1 and mouseX > 0.52 * 1920) or (mouseX <= 1 and mouseX > 0.52)
        local kidMax = math.max(0, #(self.treeChildren or {}) - HorseGeneticsMenu.TREE_CHILD_SLOTS)
        if rightSide and kidMax > 0 then
            self.treeChildOffset = math.max(0, math.min(kidMax, (self.treeChildOffset or 0) + steps))
            self:renderFamilyTree()
        else
            local maxOffset = math.max(0, #(self.historyRecords or {}) - HorseGeneticsMenu.HIST_LIST_ROWS)
            self.historyOffset = math.max(0, math.min(maxOffset, (self.historyOffset or 0) + steps))
            self:renderHistoryList()
        end
    else
        self:setListOffset(self.listOffset + steps)
    end
    self.hgWheelHandledFrame = now
    return true
end

function HorseGeneticsMenu:hgHandleScrollMouse(posX, posY, isDown, isUp, button)
    self.hgLastMouseX = posX
    if isUp or not self:hgIsMyHorsesScrollActive() then
        return false
    end
    local wheelUp = false
    local wheelDown = false
    pcall(function()
        if Input ~= nil then
            wheelUp = button == Input.MOUSE_BUTTON_WHEEL_UP or button == Input.MOUSE_WHEEL_UP
            wheelDown = button == Input.MOUSE_BUTTON_WHEEL_DOWN or button == Input.MOUSE_WHEEL_DOWN
        end
    end)
    if button == 4 or button == -1 then
        wheelUp = true
    elseif button == 5 or button == -2 then
        wheelDown = true
    end
    if wheelUp or wheelDown then
        return self:hgApplyWheelDelta(wheelUp and 1 or -1)
    end
    return false
end

function HorseGeneticsMenu:hgPollScrollInput()
    if not self:hgIsMyHorsesScrollActive() then
        return
    end
    local raw = hgReadMouseWheelDelta(self)
    if math.abs(raw) >= 0.15 then
        self:hgApplyWheelDelta(raw)
    end
end

-- Shop portraits: prefer dataS store horse DDS, then local coat fallbacks.
local HG_HORSE_STORE_ICON_DIR = "$dataS/character/animals/domesticated/horse/"
local HG_HORSE_STORE_ICON_STEMS = {
    bay = "store_horseBay",
    black = "store_horseBlack",
    chestnut = "store_horseChestnut",
    grey = "store_horseGray",
    palomino = "store_horsePalomino",
    pinto = "store_horsePinto",
    dun = "store_horseDun",
    sealbrown = "store_horseSealBrown"
}
local HG_HORSE_STORE_SUBTYPES = {
    bay = "HORSE_BAY",
    black = "HORSE_BLACK",
    chestnut = "HORSE_CHESTNUT",
    grey = "HORSE_GRAY",
    palomino = "HORSE_PALOMINO",
    pinto = "HORSE_PINTO",
    dun = "HORSE_DUN",
    sealbrown = "HORSE_SEAL_BROWN"
}

local function hgNormalizeCoatKey(coatColour)
    local key = string.lower(tostring(coatColour or "bay"))
    key = string.gsub(key, "[%s_%-]+", "")
    if key == "gray" then
        key = "grey"
    elseif key == "buckskin" then
        key = "dun"
    end
    if HG_HORSE_STORE_ICON_STEMS[key] == nil then
        key = "bay"
    end
    return key
end

local function hgIsUsableFilename(value)
    return type(value) == "string" and value ~= ""
end

local function hgIsCoatPhotoPath(filename)
    if not hgIsUsableFilename(filename) then
        return false
    end
    local lower = string.lower(filename)
    -- Packed local DDS coats are valid fallbacks. Reject leftover png/jpg paths
    -- that animal-system visuals might still point at.
    if string.find(lower, "%.dds", 1, true) ~= nil then
        return false
    end
    return string.find(lower, "gui/coats", 1, true) ~= nil
        or string.find(lower, "hg_ui_portrait", 1, true) ~= nil
end

local function hgIsStoreHorsePath(filename)
    return hgIsUsableFilename(filename)
        and not hgIsCoatPhotoPath(filename)
        and string.find(string.lower(filename), "store_horse", 1, true) ~= nil
end

local function hgExtractVisualStoreImage(visual)
    if type(visual) ~= "table" then
        return nil
    end
    local store = visual.store
    local candidates = {
        visual.image,
        visual.imageFilename,
        visual.filename,
        visual.storeIcon,
        type(store) == "table" and (store.imageFilename or store.image or store.icon or store.filename) or nil
    }
    for i = 1, #candidates do
        if hgIsStoreHorsePath(candidates[i]) then
            return candidates[i]
        end
    end
    for i = 1, #candidates do
        if hgIsUsableFilename(candidates[i]) and not hgIsCoatPhotoPath(candidates[i]) then
            return candidates[i]
        end
    end
    return nil
end

local function hgExtractSubTypeStoreImage(subType)
    if type(subType) ~= "table" then
        return nil
    end
    local visuals = subType.visuals or subType.visual
    if type(visuals) == "table" then
        if visuals[1] ~= nil then
            local fromList = hgExtractVisualStoreImage(visuals[1])
            if fromList ~= nil then
                return fromList
            end
        end
        local fromSelf = hgExtractVisualStoreImage(visuals)
        if fromSelf ~= nil then
            return fromSelf
        end
        for _, visual in pairs(visuals) do
            local image = hgExtractVisualStoreImage(visual)
            if image ~= nil then
                return image
            end
        end
    end
    local fallback = hgExtractVisualStoreImage(subType)
        or (type(subType.store) == "table" and (subType.store.imageFilename or subType.store.icon))
        or subType.storeIcon
        or subType.imageFilename
    if hgIsCoatPhotoPath(fallback) then
        return nil
    end
    return fallback
end

local function hgGetAnimalSystem()
    if g_currentMission ~= nil and g_currentMission.animalSystem ~= nil then
        return g_currentMission.animalSystem
    end
    return g_animalSystem
end

local function hgPickVisualForAge(subType, age)
    if type(subType) ~= "table" then
        return nil
    end
    age = tonumber(age) or 0
    local visuals = subType.visuals or subType.visual
    if type(visuals) ~= "table" then
        return nil
    end
    local best, bestAge = nil, -1
    local function consider(visual)
        if type(visual) ~= "table" then
            return
        end
        local minAge = tonumber(visual.minAge) or tonumber(visual.age) or 0
        if minAge <= age and minAge >= bestAge then
            best = visual
            bestAge = minAge
        end
    end
    if visuals[1] ~= nil then
        for i = 1, #visuals do
            consider(visuals[i])
        end
    else
        for _, visual in pairs(visuals) do
            consider(visual)
        end
    end
    return best
end

local function hgGetSubTypeImageForAge(subType, age)
    if type(subType) ~= "table" then
        return nil
    end
    age = tonumber(age) or 0
    local animalSystem = hgGetAnimalSystem()
    local index = subType.subTypeIndex or subType.index
    if animalSystem ~= nil and animalSystem.getVisualByAge ~= nil and index ~= nil then
        local visual = nil
        pcall(function()
            visual = animalSystem:getVisualByAge(index, age)
        end)
        local image = hgExtractVisualStoreImage(visual)
        if image ~= nil then
            return image
        end
    end
    local visual = hgPickVisualForAge(subType, age)
    return hgExtractVisualStoreImage(visual) or hgExtractSubTypeStoreImage(subType)
end

local function hgNameLooksLikeHorseFoal(name, coatKey)
    if type(name) ~= "string" or name == "" then
        return false
    end
    local upper = string.upper(name)
    if string.find(upper, "HORSE", 1, true) == nil or string.find(upper, "FOAL", 1, true) == nil then
        return false
    end
    if coatKey == nil or coatKey == "" then
        return true
    end
    local lower = string.lower(name)
    local coat = string.lower(tostring(coatKey))
    if string.find(lower, coat, 1, true) ~= nil then
        return true
    end
    if coat == "grey" and string.find(lower, "gray", 1, true) ~= nil then
        return true
    end
    if coat == "sealbrown" and string.find(lower, "seal", 1, true) ~= nil then
        return true
    end
    return false
end

local function hgFindFoalSubTypeForCoat(coatKey)
    local animalSystem = hgGetAnimalSystem()
    if animalSystem == nil then
        return nil
    end
    local collections = {
        animalSystem.subTypes,
        animalSystem.nameToSubType,
        animalSystem.subTypeByName
    }
    for i = 1, #collections do
        local collection = collections[i]
        if type(collection) == "table" then
            for name, candidate in pairs(collection) do
                local subType = candidate
                local label = type(name) == "string" and name or nil
                if type(subType) == "table" then
                    label = label or subType.name
                    if hgNameLooksLikeHorseFoal(label, coatKey) then
                        return subType
                    end
                end
            end
        end
    end
    return nil
end

local function hgGetSubTypeByName(name)
    local animalSystem = hgGetAnimalSystem()
    if animalSystem == nil or name == nil then
        return nil
    end
    local subType = nil
    pcall(function()
        if animalSystem.getSubTypeByName ~= nil then
            subType = animalSystem:getSubTypeByName(name)
        end
    end)
    if subType ~= nil then
        return subType
    end
    local collections = {
        animalSystem.subTypes,
        animalSystem.nameToSubType,
        animalSystem.subTypeByName
    }
    for i = 1, #collections do
        local collection = collections[i]
        if type(collection) == "table" then
            if collection[name] ~= nil then
                return collection[name]
            end
            for _, candidate in pairs(collection) do
                if type(candidate) == "table" and candidate.name == name then
                    return candidate
                end
            end
        end
    end
    return nil
end

local function hgToDdsFilename(filename)
    if not hgIsUsableFilename(filename) then
        return filename
    end
    local swapped = string.gsub(filename, "%.png$", ".dds")
    swapped = string.gsub(swapped, "%.PNG$", ".dds")
    swapped = string.gsub(swapped, "%.jpe?g$", ".dds")
    swapped = string.gsub(swapped, "%.JPE?G$", ".dds")
    return swapped
end

local function hgAddPortraitCandidate(list, seen, filename)
    if not hgIsUsableFilename(filename) or hgIsCoatPhotoPath(filename) or seen[filename] then
        return
    end
    seen[filename] = true
    list[#list + 1] = filename
end

local function hgAddPortraitPathVariants(list, seen, filename)
    if not hgIsUsableFilename(filename) then
        return
    end
    -- Packed store icons load as dataS/...dds. The $dataS/...dds form logs
    -- "Missing dds file" even when the same packed texture exists.
    local normalized = string.gsub(filename, "\\", "/")
    normalized = string.gsub(normalized, "^%$", "")
    hgAddPortraitCandidate(list, seen, hgToDdsFilename(normalized))
    hgAddPortraitCandidate(list, seen, normalized)
end

local function hgAddLocalCoatPortraitPaths(list, seen, key)
    local directory = HorseGenetics.modDirectory or g_currentModDirectory
    if directory == nil then
        return
    end
    if not string.match(directory, "[/\\]$") then
        directory = directory .. "/"
    end
    local stems = { key }
    if key == "dun" then
        stems = { "dun", "buckskin" }
    elseif key == "sealbrown" then
        stems = { "sealbrown" }
    end
    for i = 1, #stems do
        local stem = stems[i]
        hgAddPortraitPathVariants(list, seen, directory .. "gui/coats/hg_portrait_" .. stem .. "_v26.dds")
        hgAddPortraitPathVariants(list, seen, directory .. "gui/coats/hg_ui_portrait_" .. stem .. ".dds")
        hgAddPortraitPathVariants(list, seen, directory .. "gui/coats/" .. stem .. ".dds")
    end
end

local function hgCollectHorseStoreIconPaths(coatColour)
    local key = hgNormalizeCoatKey(coatColour)
    local list, seen = {}, {}
    local useFoalVisual = HorseGenetics.isEnhancedAnimalSystemActive()
    local age = useFoalVisual and 0 or HorseGenetics.VANILLA_MATURITY_MONTHS
    pcall(function()
        local subType = hgGetSubTypeByName(HG_HORSE_STORE_SUBTYPES[key])
        if useFoalVisual then
            hgAddPortraitPathVariants(list, seen, hgGetSubTypeImageForAge(hgFindFoalSubTypeForCoat(key), 0))
            hgAddPortraitPathVariants(list, seen, hgGetSubTypeImageForAge(subType, 0))
        end
        hgAddPortraitPathVariants(list, seen, hgGetSubTypeImageForAge(subType, age))
        hgAddPortraitPathVariants(list, seen, hgExtractSubTypeStoreImage(subType))
    end)
    local stem = HG_HORSE_STORE_ICON_STEMS[key] or HG_HORSE_STORE_ICON_STEMS.bay
    hgAddPortraitPathVariants(list, seen, HG_HORSE_STORE_ICON_DIR .. stem .. ".dds")
    hgAddPortraitPathVariants(list, seen, HG_HORSE_STORE_ICON_DIR .. stem .. ".png")
    hgAddLocalCoatPortraitPaths(list, seen, key)
    return list, key
end

local function hgCreatePortraitOverlay(path)
    local overlayId = nil
    local ok = pcall(function()
        overlayId = createImageOverlay(path)
    end)
    if ok and overlayId ~= nil and overlayId ~= 0 then
        return overlayId
    end
    return nil
end

local function hgBindHorsePortraitPath(element, path)
    if not hgIsUsableFilename(path) then
        return false
    end
    local probeId = hgCreatePortraitOverlay(path)
    if probeId == nil then
        return false
    end
    pcall(delete, probeId)

    local bound = false
    pcall(function()
        if element.setImageFilename ~= nil then
            element:setImageFilename(path)
            bound = true
        end
    end)
    if not bound then
        pcall(function()
            element:setImageFilename("overlay", path)
            bound = true
        end)
    end
    return bound
end

function HorseGeneticsMenu:updateHorsePortrait(coatColour)
    local element = self.horsePortrait
    if element == nil or element.setImageFilename == nil then
        return
    end
    pcall(hgApplyPortraitLayout, element)
    pcall(hgApplyPortraitLayout, self.portraitPlaceholder)

    local paths, key = nil, hgNormalizeCoatKey(coatColour)
    pcall(function()
        paths, key = hgCollectHorseStoreIconPaths(coatColour)
    end)
    if type(paths) ~= "table" or paths[1] == nil then
        paths = { HG_HORSE_STORE_ICON_DIR .. (HG_HORSE_STORE_ICON_STEMS[key] or "store_horseBay") .. ".dds" }
    end

    local overlayFile = nil
    pcall(function()
        overlayFile = element.overlay ~= nil and element.overlay.filename or nil
    end)
    if self.hgPortraitBoundPath ~= nil
        and self.hgPortraitBoundCoat == key
        and not hgIsCoatPhotoPath(self.hgPortraitBoundPath)
        and not hgIsCoatPhotoPath(overlayFile) then
        hgSetText(self.portraitPlaceholder, "")
        return
    end
    if self.hgPortraitBindFailedCoat == key then
        hgSetText(self.portraitPlaceholder, string.upper(tostring(key or "BAY")))
        return
    end

    self.hgPortraitBoundPath = nil

    local boundPath = nil
    for i = 1, #paths do
        local okBind = false
        pcall(function()
            okBind = hgBindHorsePortraitPath(element, paths[i])
        end)
        if okBind then
            boundPath = paths[i]
            break
        end
    end

    if boundPath ~= nil then
        self.hgPortraitBoundPath = boundPath
        self.hgPortraitBoundCoat = key
        self.hgPortraitBindFailedCoat = nil
        hgSetText(self.portraitPlaceholder, "")
        if element.setVisible ~= nil then
            pcall(element.setVisible, element, true)
        end
    else
        self.hgPortraitBoundCoat = nil
        self.hgPortraitBindFailedCoat = key
        hgSetText(self.portraitPlaceholder, string.upper(tostring(key or "BAY")))
    end
    pcall(hgApplyPortraitLayout, element)
    pcall(hgApplyPortraitLayout, self.portraitPlaceholder)
end

function HorseGeneticsMenu:renderProfile()
    local r = self.selectedRecord
    pcall(HorseGeneticsMenu.updateHorsePortrait, self, r ~= nil and r.coatColour or "Bay")
    local stats = r ~= nil and (r.stats or {}) or {}
    local speed = tonumber(stats.speed) or 0
    local stamina = tonumber(stats.stamina) or 0
    local health = tonumber(stats.health) or 0
    local breakdown = r ~= nil and (r._hgUiBreakdown or HorseGenetics.getSaleValueBreakdown(r)) or nil
    local average = breakdown ~= nil and (tonumber(breakdown.average) or 0) or 0

    hgSetText(self.speedValue, string.format("%d / 100", speed))
    hgSetText(self.staminaValue, string.format("%d / 100", stamina))
    hgSetText(self.healthValue, string.format("%d / 100", health))
    hgSetText(self.averageText, string.format("%.1f / 100", average))
    -- Bind once (texture bind can reset bitmap size). Always set fill width AFTER bind.
    pcall(hgBindStatBarTextures, self)
    pcall(hgSetBarFill, self.healthBar, health, "healthBar")
    pcall(hgSetBarFill, self.staminaBar, stamina, "staminaBar")
    pcall(hgSetBarFill, self.speedBar, speed, "speedBar")
    pcall(hgSetBarFill, self.averageBar, average, "averageBar")

    if r == nil then
        hgSetText(self.profileName, hgT("hg_dash"))
        hgSetText(self.profileId, hgT("hg_dash"))
        hgSetText(self.profileGeneration, hgT("hg_dash"))
        hgSetText(self.profileCoat, hgT("hg_dash"))
        hgSetText(self.profileAgeLabel, hgT("hg_label_age"))
        hgSetText(self.profileAge, hgT("hg_dash"))
        hgSetText(self.profileReproLabel, hgT("hg_label_repro"))
        hgSetText(self.profileRepro, hgT("hg_dash"))
        hgSetText(self.portraitPlaceholder, "")
        hgSetText(self.saleBaseValue, "1.000x")
        hgSetText(self.saleBonusValue, "+0.0%")
        hgSetText(self.saleTraitsValue, hgT("hg_none"))
        hgSetText(self.saleTotalText, "+0.0%")
        hgSetColor(self.saleTotalLabel, HG_COLOR_SELECTED)
        hgSetColor(self.saleTotalText, HG_COLOR_SELECTED)
        return
    end

    local bonuses = #(breakdown.bonusDetails or {}) > 0 and table.concat(breakdown.bonusDetails, ", ") or hgT("hg_none")
    hgSetText(self.profileName, r.name or hgT("hg_unnamed"))
    hgSetText(self.profileId, r.id or hgT("hg_unknown"))
    hgSetText(self.profileGeneration, r.generation or 1)
    hgSetText(self.profileCoat, hgCoatText(r.coatColour))
    hgSetText(self.profileAgeLabel, hgT("hg_label_age"))
    hgSetText(self.profileAge, HorseGenetics.formatAgeYM(HorseGenetics.getRecordAgeMonths(r)))
    local reproLabel, reproValue = HorseGenetics.getRecordLifeState(r)
    hgSetText(self.profileReproLabel, reproLabel)
    hgSetText(self.profileRepro, reproValue)
    hgSetText(self.saleBaseValue, string.format("%.3fx", tonumber(breakdown.baseMultiplier) or 1))
    hgSetText(self.saleBonusValue, string.format("+%.1f%%", (tonumber(breakdown.statBonus) or 0) * 100))
    hgSetText(self.saleTraitsValue, bonuses)
    hgSetText(self.saleTotalText, string.format("%+.1f%%", ((tonumber(breakdown.multiplier) or 1) - 1) * 100))
    hgSetColor(self.saleTotalLabel, HG_COLOR_SELECTED)
    hgSetColor(self.saleTotalText, HG_COLOR_SELECTED)
end

function HorseGeneticsMenu:selectRecord(index)
    local record = self.records[self.listOffset + index]
    if record == nil then
        return
    end
    self.selectedRecord = record
    self:renderOverview()
end

function HorseGeneticsMenu:onSelectHorse1() self:selectRecord(1) end
function HorseGeneticsMenu:onSelectHorse2() self:selectRecord(2) end
function HorseGeneticsMenu:onSelectHorse3() self:selectRecord(3) end
function HorseGeneticsMenu:onSelectHorse4() self:selectRecord(4) end
function HorseGeneticsMenu:onSelectHorse5() self:selectRecord(5) end
function HorseGeneticsMenu:onSelectHorse6() self:selectRecord(6) end
function HorseGeneticsMenu:onSelectHorse7() self:selectRecord(7) end
function HorseGeneticsMenu:onSelectHorse8() self:selectRecord(8) end
function HorseGeneticsMenu:onSelectHorse9() self:selectRecord(9) end
function HorseGeneticsMenu:onSelectHorse10() self:selectRecord(10) end
function HorseGeneticsMenu:onSelectHorse11() self:selectRecord(11) end
function HorseGeneticsMenu:onSelectHorse12() self:selectRecord(12) end
function HorseGeneticsMenu:onSelectHorse13() self:selectRecord(13) end

function HorseGeneticsMenu:onRefreshClick()
    if HorseGenetics.requestSync ~= nil then
        HorseGenetics.requestSync()
    end
    if HorseGenetics.ensureLiveHorseRecords ~= nil then
        HorseGenetics.ensureLiveHorseRecords()
    end
    self:refreshRecords()
    if self.currentTab == "breeding" then
        self:renderBreedingPage()
    elseif self.currentTab == "info" then
        self:renderGeneticInfoPage()
    end
end

local HG_COAT_PORTRAIT_LAYOUT = {
    breedP1Portrait = {190, -40, 110, 95},
    breedP2Portrait = {190, -40, 110, 95},
    breedF1Portrait = {80, -230, 160, 140},
    breedF2Portrait = {80, -230, 160, 140},
    treeC1Portrait = {4, 0, 36, 36},
    treeC2Portrait = {4, 0, 36, 36},
    treeC3Portrait = {4, 0, 36, 36},
    treeC4Portrait = {4, 0, 36, 36}
}

function HorseGeneticsMenu:bindCoatPortrait(element, coatColour)
    if element == nil then
        return
    end
    local paths, key = nil, hgNormalizeCoatKey(coatColour)
    pcall(function()
        paths, key = hgCollectHorseStoreIconPaths(coatColour)
    end)
    if type(paths) ~= "table" or paths[1] == nil then
        paths = { HG_HORSE_STORE_ICON_DIR .. (HG_HORSE_STORE_ICON_STEMS[key] or "store_horseBay") .. ".dds" }
    end
    for i = 1, #paths do
        local ok = false
        pcall(function()
            ok = hgBindHorsePortraitPath(element, paths[i])
        end)
        if ok then
            break
        end
    end
    local layout = nil
    if element.id ~= nil then
        layout = HG_COAT_PORTRAIT_LAYOUT[element.id]
    end
    if layout == nil then
        for id, box in pairs(HG_COAT_PORTRAIT_LAYOUT) do
            if self[id] == element then
                layout = box
                break
            end
        end
    end
    if layout ~= nil then
        pcall(function()
            if element.setPosition ~= nil then
                element:setPosition(string.format("%dpx %dpx", layout[1], layout[2]))
            end
            if element.setSize ~= nil then
                element:setSize(string.format("%dpx %dpx", layout[3], layout[4]))
            end
        end)
    end
    if element.setVisible ~= nil then
        pcall(element.setVisible, element, true)
    end
end

local function hgSetPortraitVisible(element, visible)
    if element ~= nil and element.setVisible ~= nil then
        pcall(element.setVisible, element, visible == true)
    end
end

function HorseGeneticsMenu:renderParentPanel(prefix, record)
    if record == nil then
        hgSetText(self["breed" .. prefix .. "Name"], hgT("hg_field_name", hgT("hg_dash")))
        hgSetText(self["breed" .. prefix .. "Id"], hgT("hg_field_id", hgT("hg_dash")))
        hgSetText(self["breed" .. prefix .. "Age"], hgT("hg_field_age", hgT("hg_dash")))
        hgSetText(self["breed" .. prefix .. "Speed"], hgT("hg_field_speed", hgT("hg_dash")))
        hgSetText(self["breed" .. prefix .. "Stamina"], hgT("hg_field_stamina", hgT("hg_dash")))
        hgSetText(self["breed" .. prefix .. "Health"], hgT("hg_field_health", hgT("hg_dash")))
        hgSetText(self["breed" .. prefix .. "Average"], hgT("hg_field_average", hgT("hg_dash")))
        hgSetPortraitVisible(self["breed" .. prefix .. "Portrait"], false)
        return
    end
    local stats = record.stats or {}
    local average = HorseGenetics.calculateAverage(stats)
    hgSetText(self["breed" .. prefix .. "Name"], hgT("hg_field_name", tostring(record.name or hgT("hg_unnamed"))))
    hgSetText(self["breed" .. prefix .. "Id"], hgT("hg_field_id", tostring(record.id or hgT("hg_dash"))))
    hgSetText(self["breed" .. prefix .. "Age"], hgT("hg_field_age", HorseGenetics.formatAgeYM(HorseGenetics.getRecordAgeMonths(record))))
    hgSetText(self["breed" .. prefix .. "Speed"], hgT("hg_field_speed", tostring(tonumber(stats.speed) or 0)))
    hgSetText(self["breed" .. prefix .. "Stamina"], hgT("hg_field_stamina", tostring(tonumber(stats.stamina) or 0)))
    hgSetText(self["breed" .. prefix .. "Health"], hgT("hg_field_health", tostring(tonumber(stats.health) or 0)))
    hgSetText(self["breed" .. prefix .. "Average"], hgT("hg_field_average", string.format("%.1f", average)))
    self:bindCoatPortrait(self["breed" .. prefix .. "Portrait"], record.coatColour)
end

function HorseGeneticsMenu:renderBreedingPage()
    local p1, p2 = self.breedParent1, self.breedParent2
    self:renderParentPanel("P1", p1)
    self:renderParentPanel("P2", p2)

    local warning = ""
    if p1 ~= nil and p2 ~= nil and p1.id == p2.id then
        warning = hgT("hg_warn_self")
    elseif p1 == nil or p2 == nil then
        warning = hgT("hg_warn_need_two")
    end
    hgSetText(self.breedWarningText, warning)
    hgSetColor(self.breedWarningText, HG_COLOR_SELECTED)

    local function setCompatRow(prefix, combText)
        hgSetText(self["compat" .. prefix .. "Comb"], combText)
    end
    hgSetText(self.compatSpeed, hgT("hg_stat_speed"))
    hgSetText(self.compatStamina, hgT("hg_stat_stamina"))
    hgSetText(self.compatHealth, hgT("hg_stat_health"))
    hgSetText(self.compatAverage, hgT("hg_stat_average"))
    if p1 ~= nil and p2 ~= nil then
        local s1, s2 = p1.stats or {}, p2.stats or {}
        local function fillInt(prefix, a, b)
            local va, vb = tonumber(a) or 0, tonumber(b) or 0
            setCompatRow(prefix, string.format("%.1f", (va + vb) / 2))
        end
        fillInt("Speed", s1.speed, s2.speed)
        fillInt("Stamina", s1.stamina, s2.stamina)
        fillInt("Health", s1.health, s2.health)
        local a1 = HorseGenetics.calculateAverage(s1)
        local a2 = HorseGenetics.calculateAverage(s2)
        setCompatRow("Average", string.format("%.1f", (a1 + a2) / 2))
    else
        setCompatRow("Speed", "-")
        setCompatRow("Stamina", "-")
        setCompatRow("Health", "-")
        setCompatRow("Average", "-")
    end

    self:renderOffspringPanels()
    self:renderBreedPicker()
    if self.breedStatusText ~= nil and (self.breedStatusText.text == nil or self.breedStatusText.text == "") then
        hgSetText(self.breedStatusText, hgT("hg_breed_hint_list"))
    end
end

function HorseGeneticsMenu:renderBreedPicker()
    local maxOffset = math.max(0, #self.records - HorseGeneticsMenu.BREED_PICK_ROWS)
    self.breedPickOffset = math.max(0, math.min(maxOffset, self.breedPickOffset or 0))
    for i = 1, HorseGeneticsMenu.BREED_PICK_ROWS do
        local record = self.records[self.breedPickOffset + i]
        local selected = false
        local name, age, speed, stamina, health, average = "", "", "", "", "", ""
        if record ~= nil then
            local stats = record.stats or {}
            name = tostring(record.name or record.id or hgT("hg_unnamed"))
            if self.breedParent1 ~= nil and record.id == self.breedParent1.id then
                name = name .. "  [H1]"
            end
            if self.breedParent2 ~= nil and record.id == self.breedParent2.id then
                name = name .. "  [H2]"
            end
            age = HorseGenetics.formatAgeYM(HorseGenetics.getRecordAgeMonths(record))
            speed = tostring(tonumber(stats.speed) or 0)
            stamina = tostring(tonumber(stats.stamina) or 0)
            health = tostring(tonumber(stats.health) or 0)
            average = string.format("%.1f", HorseGenetics.calculateAverage(stats))
            selected = (self.breedPickerSelected ~= nil and record.id == self.breedPickerSelected.id)
                or (self.breedParent1 ~= nil and record.id == self.breedParent1.id)
                or (self.breedParent2 ~= nil and record.id == self.breedParent2.id)
        end
        local color = selected and HG_COLOR_SELECTED or HG_COLOR_TEXT
        local function styleCell(element)
            hgSetColor(element, color)
            if element ~= nil and element.setTextSize ~= nil then
                pcall(element.setTextSize, element, 16 / 1080)
            end
        end
        hgSetText(self["breedPick" .. i .. "Name"], name)
        hgSetText(self["breedPick" .. i .. "Age"], age)
        hgSetText(self["breedPick" .. i .. "Speed"], speed)
        hgSetText(self["breedPick" .. i .. "Stamina"], stamina)
        hgSetText(self["breedPick" .. i .. "Health"], health)
        hgSetText(self["breedPick" .. i .. "Average"], average)
        styleCell(self["breedPick" .. i .. "Name"])
        styleCell(self["breedPick" .. i .. "Age"])
        styleCell(self["breedPick" .. i .. "Speed"])
        styleCell(self["breedPick" .. i .. "Stamina"])
        styleCell(self["breedPick" .. i .. "Health"])
        styleCell(self["breedPick" .. i .. "Average"])
        local button = self["btnBreedPick" .. i]
        if button ~= nil and button.setDisabled ~= nil then
            button:setDisabled(record == nil)
        end
    end
end

function HorseGeneticsMenu:resolveOwnedBreedRecord(parent)
    if parent == nil or parent.id == nil then
        return nil
    end
    for _, record in ipairs(self.records or {}) do
        if record.id == parent.id then
            return record
        end
    end
    return nil
end

function HorseGeneticsMenu:syncBreedParentsToOwned()
    self.breedParent1 = self:resolveOwnedBreedRecord(self.breedParent1)
    self.breedParent2 = self:resolveOwnedBreedRecord(self.breedParent2)
    self.breedPickerSelected = self:resolveOwnedBreedRecord(self.breedPickerSelected)
end

function HorseGeneticsMenu:clearBreedParent(slot)
    local removed = nil
    if slot == 1 then
        removed = self.breedParent1
        self.breedParent1 = nil
    else
        removed = self.breedParent2
        self.breedParent2 = nil
    end
    if removed ~= nil then
        hgSetText(self.breedStatusText, hgT("hg_status_removed", tostring(removed.name), slot))
    end
    self:renderBreedingPage()
end

function HorseGeneticsMenu:onClickBreedPick(index)
    local record = self.records[(self.breedPickOffset or 0) + index]
    if record == nil then
        return
    end
    self.breedPickerSelected = record
    self.selectedRecord = record
    if self.breedParent1 ~= nil and record.id == self.breedParent1.id then
        self:clearBreedParent(1)
        return
    end
    if self.breedParent2 ~= nil and record.id == self.breedParent2.id then
        self:clearBreedParent(2)
        return
    end
    if self.breedParent1 == nil then
        self:assignBreedParent(1)
        return
    end
    if self.breedParent2 == nil then
        self:assignBreedParent(2)
        return
    end
    self:assignBreedParent(1)
end

function HorseGeneticsMenu:onClickBreedPick1() self:onClickBreedPick(1) end
function HorseGeneticsMenu:onClickBreedPick2() self:onClickBreedPick(2) end
function HorseGeneticsMenu:onClickBreedPick3() self:onClickBreedPick(3) end
function HorseGeneticsMenu:onClickBreedPick4() self:onClickBreedPick(4) end
function HorseGeneticsMenu:onClickBreedPick5() self:onClickBreedPick(5) end
function HorseGeneticsMenu:onClickBreedPick6() self:onClickBreedPick(6) end
function HorseGeneticsMenu:onClickBreedPick7() self:onClickBreedPick(7) end
function HorseGeneticsMenu:onClickBreedPick8() self:onClickBreedPick(8) end
function HorseGeneticsMenu:onClickBreedPick9() self:onClickBreedPick(9) end
function HorseGeneticsMenu:onClickBreedPick10() self:onClickBreedPick(10) end
function HorseGeneticsMenu:onClickBreedPick11() self:onClickBreedPick(11) end
function HorseGeneticsMenu:onClickBreedPick12() self:onClickBreedPick(12) end

local function hgBreedSourceRecord(menu)
    return menu.breedPickerSelected or menu.selectedRecord
end

function HorseGeneticsMenu:assignBreedParent(slot)
    local record = hgBreedSourceRecord(self)
    if record == nil then
        hgSetText(self.breedStatusText, hgT("hg_status_pick_first"))
        self:renderBreedingPage()
        return
    end
    if slot == 1 then
        self.breedParent1 = record
    else
        self.breedParent2 = record
    end
    hgSetText(self.breedStatusText, hgT("hg_status_set", slot, tostring(record.name)))
    self:renderBreedingPage()
end

function HorseGeneticsMenu:renderOffspringPanels()
    local p1, p2 = self.breedParent1, self.breedParent2
    hgSetText(self.breedPreviewNote, hgT("hg_preview_note_alt"))

    local function renderRange(prefix, parent)
        if p1 == nil or p2 == nil then
            hgSetText(self["breed" .. prefix .. "Name"], hgT("hg_field_name", hgT("hg_dash")))
            hgSetText(self["breed" .. prefix .. "Id"], hgT("hg_id_on_breed"))
            hgSetText(self["breed" .. prefix .. "Stats"], hgT("hg_field_speed_blank"))
            hgSetText(self["breed" .. prefix .. "Stamina"], hgT("hg_field_stamina_blank"))
            hgSetText(self["breed" .. prefix .. "Health"], hgT("hg_field_health_blank"))
            hgSetText(self["breed" .. prefix .. "Average"], hgT("hg_field_average", hgT("hg_dash")))
            hgSetText(self["breed" .. prefix .. "AvgNote"], "")
            hgSetText(self["breed" .. prefix .. "Coat"], hgT("hg_field_coat", hgT("hg_dash")))
            hgSetText(self["breed" .. prefix .. "Sale"], hgT("hg_field_sale", hgT("hg_dash")))
            hgSetPortraitVisible(self["breed" .. prefix .. "Portrait"], false)
            return
        end
        local s1, s2 = p1.stats or {}, p2.stats or {}
        local spMin, spMax = HorseGenetics.getPredictedStatRange(s1.speed, s2.speed)
        local stMin, stMax = HorseGenetics.getPredictedStatRange(s1.stamina, s2.stamina)
        local heMin, heMax = HorseGenetics.getPredictedStatRange(s1.health, s2.health)
        local avgMin = (spMin + stMin + heMin) / 3
        local avgMax = (spMax + stMax + heMax) / 3
        hgSetText(self["breed" .. prefix .. "Name"], hgT("hg_name_at_birth"))
        hgSetText(self["breed" .. prefix .. "Id"], hgT("hg_id_on_breed"))
        hgSetText(self["breed" .. prefix .. "Stats"], hgT("hg_field_speed", string.format("%d-%d", spMin, spMax)))
        hgSetText(self["breed" .. prefix .. "Stamina"], hgT("hg_field_stamina", string.format("%d-%d", stMin, stMax)))
        hgSetText(self["breed" .. prefix .. "Health"], hgT("hg_field_health", string.format("%d-%d", heMin, heMax)))
        hgSetText(self["breed" .. prefix .. "Average"], hgT("hg_field_average", string.format("%.1f-%.1f", avgMin, avgMax)))
        hgSetText(self["breed" .. prefix .. "AvgNote"], hgT("hg_not_guaranteed"))
        hgSetText(self["breed" .. prefix .. "Coat"], hgT("hg_field_coat", HorseGenetics.getPossibleCoatText(p1.coatColour, p2.coatColour)))
        hgSetText(self["breed" .. prefix .. "Sale"], hgT("hg_field_sale", hgT("hg_sale_depends")))
        self:bindCoatPortrait(self["breed" .. prefix .. "Portrait"], parent ~= nil and parent.coatColour or p1.coatColour)
    end

    renderRange("F1", p1)
    renderRange("F2", p2)
end

function HorseGeneticsMenu:onClickPreviewOffspring()
    if self.breedParent1 == nil or self.breedParent2 == nil then
        hgSetText(self.breedStatusText, hgT("hg_status_need_pair"))
        self:renderBreedingPage()
        return
    end
    if self.breedParent1.id == self.breedParent2.id then
        hgSetText(self.breedStatusText, hgT("hg_status_different"))
        self:renderBreedingPage()
        return
    end
    hgSetText(self.breedStatusText, hgT("hg_status_preview"))
    self:renderBreedingPage()
end

local function hgCollectAllHorseRecords()
    local list = {}
    for _, record in pairs(HorseGenetics.horses or {}) do
        if type(record) == "table" and type(record.stats) == "table" then
            if HorseGenetics.recordVisibleToLocalFarm == nil or HorseGenetics.recordVisibleToLocalFarm(record) then
                table.insert(list, record)
            end
        end
    end
    table.sort(list, function(a, b)
        return tostring(a.name or a.id) < tostring(b.name or b.id)
    end)
    return list
end

local function hgFindHorseById(id)
    if id == nil or id == "" then
        return nil
    end
    return HorseGenetics.horses[id]
end

local function hgCollectOffspring(parentId)
    local kids = {}
    if parentId == nil or parentId == "" then
        return kids
    end
    for _, record in pairs(HorseGenetics.horses or {}) do
        if type(record) == "table" and (record.mareId == parentId or record.stallionId == parentId) then
            table.insert(kids, record)
        end
    end
    table.sort(kids, function(a, b)
        return tostring(a.name or a.id) < tostring(b.name or b.id)
    end)
    return kids
end

local function hgTreeValueLine(menu, record)
    if record == nil then
        return ""
    end
    local amount, sold = HorseGenetics.getHorseDisplayValue(record, menu.sellPriceIndex, menu.ownedIds)
    local money = HorseGenetics.formatHorseMoney(amount)
    if sold then
        return hgT("hg_sold", money)
    end
    return hgT("hg_value_line", money)
end

function HorseGeneticsMenu:renderGeneticInfoPage()
    self.ownedIds = HorseGenetics.collectOwnedHorseIds()
    self.sellPriceIndex = HorseGenetics.collectHorseSellPrices()
    HorseGenetics.finalizeSoldPrices(self.ownedIds)
    self.historyRecords = hgCollectAllHorseRecords()
    if self.historySelected ~= nil then
        local selectedId = self.historySelected.id
        self.historySelected = nil
        for _, record in ipairs(self.historyRecords) do
            if record.id == selectedId then
                self.historySelected = record
                break
            end
        end
    end
    if self.historySelected == nil and #self.historyRecords > 0 then
        self.historySelected = self.historyRecords[1]
    end
    local maxOffset = math.max(0, #self.historyRecords - HorseGeneticsMenu.HIST_LIST_ROWS)
    self.historyOffset = math.max(0, math.min(maxOffset, self.historyOffset or 0))
    self:renderHistoryList()
    self:renderFamilyTree()
end

function HorseGeneticsMenu:renderHistoryList()
    hgSetText(self.histOverviewText, hgT("hg_all_recorded", #self.historyRecords))
    for i = 1, HorseGeneticsMenu.HIST_LIST_ROWS do
        local record = self.historyRecords[(self.historyOffset or 0) + i]
        local selected = record ~= nil and self.historySelected ~= nil and record.id == self.historySelected.id
        local color = selected and HG_COLOR_SELECTED or HG_COLOR_TEXT
        local name, age, speed, stamina, health, average = "", "", "", "", "", ""
        if record ~= nil then
            local stats = record.stats or {}
            name = tostring(record.name or record.id or hgT("hg_unnamed"))
            age = HorseGenetics.formatAgeYM(HorseGenetics.getRecordAgeMonths(record))
            speed = tostring(tonumber(stats.speed) or 0)
            stamina = tostring(tonumber(stats.stamina) or 0)
            health = tostring(tonumber(stats.health) or 0)
            average = string.format("%.1f", HorseGenetics.calculateAverage(stats))
        end
        hgSetText(self["hist" .. i .. "Name"], name)
        hgSetText(self["hist" .. i .. "Age"], age)
        hgSetText(self["hist" .. i .. "Speed"], speed)
        hgSetText(self["hist" .. i .. "Stamina"], stamina)
        hgSetText(self["hist" .. i .. "Health"], health)
        hgSetText(self["hist" .. i .. "Average"], average)
        hgSetColor(self["hist" .. i .. "Name"], color)
        hgSetColor(self["hist" .. i .. "Age"], color)
        hgSetColor(self["hist" .. i .. "Speed"], color)
        hgSetColor(self["hist" .. i .. "Stamina"], color)
        hgSetColor(self["hist" .. i .. "Health"], color)
        hgSetColor(self["hist" .. i .. "Average"], color)
        local button = self["btnHist" .. i]
        if button ~= nil and button.setDisabled ~= nil then
            button:setDisabled(record == nil)
        end
    end
end

local function hgSetTreeStatRow(menu, prefix, record)
    local show = record ~= nil and type(record.stats) == "table"
    local stats = show and record.stats or {}
    hgSetText(menu[prefix .. "Speed"], show and tostring(tonumber(stats.speed) or 0) or "")
    hgSetText(menu[prefix .. "Stamina"], show and tostring(tonumber(stats.stamina) or 0) or "")
    hgSetText(menu[prefix .. "Health"], show and tostring(tonumber(stats.health) or 0) or "")
    hgSetText(menu[prefix .. "Average"], show and string.format("%.1f", HorseGenetics.calculateAverage(stats)) or "")
    hgSetText(menu[prefix .. "Stats"], "")
    for _, key in ipairs({ "Speed", "Stamina", "Health", "Average" }) do
        hgSetPortraitVisible(menu[prefix .. "Icon" .. key], show)
        hgSetColor(menu[prefix .. key], HG_COLOR_TEXT)
    end
end

function HorseGeneticsMenu:fillTreeRelative(prefix, record, emptyLabel)
    local portrait = self[prefix .. "Portrait"]
    if record == nil then
        hgSetText(self[prefix .. "Name"], emptyLabel or hgT("hg_unknown"))
        hgSetText(self[prefix .. "Value"], "")
        hgSetColor(self[prefix .. "Name"], HG_COLOR_MUTED)
        hgSetTreeStatRow(self, prefix, nil)
        hgSetPortraitVisible(portrait, false)
        return
    end
    hgSetText(self[prefix .. "Name"], tostring(record.name or hgT("hg_unnamed")))
    hgSetText(self[prefix .. "Value"], hgTreeValueLine(self, record))
    hgSetColor(self[prefix .. "Name"], HG_COLOR_TEXT)
    hgSetColor(self[prefix .. "Value"], HG_COLOR_TEXT)
    hgSetTreeStatRow(self, prefix, record)
    if portrait ~= nil then
        self:bindCoatPortrait(portrait, record.coatColour)
        hgSetPortraitVisible(portrait, true)
    end
end

function HorseGeneticsMenu:renderFamilyTree()
    local record = self.historySelected
    if record == nil then
        hgSetText(self.treeFocusName, hgT("hg_select_horse"))
        hgSetText(self.treeFocusId, "")
        hgSetText(self.treeFocusValue, "")
        hgSetTreeStatRow(self, "treeFocus", nil)
        hgSetText(self.treeFocusAverage, "")
        hgSetPortraitVisible(self.treeFocusPortrait, false)
        self:fillTreeRelative("treeP1", nil, hgT("hg_unknown"))
        self:fillTreeRelative("treeP2", nil, hgT("hg_unknown"))
        for i = 1, HorseGeneticsMenu.TREE_CHILD_SLOTS do
            self:fillTreeRelative("treeC" .. i, nil, "")
        end
        hgSetText(self.treeKidsLabel, hgT("hg_offspring"))
        return
    end

    local stats = record.stats or {}
    local average = HorseGenetics.calculateAverage(stats)
    hgSetText(self.treeFocusName, tostring(record.name or hgT("hg_unnamed")))
    hgSetText(self.treeFocusId, hgT("hg_id_gen", tostring(record.id or hgT("hg_dash")), tonumber(record.generation) or 1))
    hgSetTreeStatRow(self, "treeFocus", record)
    hgSetText(self.treeFocusAverage, string.format("%.1f", average))
    hgSetText(self.treeFocusValue, hgTreeValueLine(self, record))
    hgSetColor(self.treeFocusName, HG_COLOR_SELECTED)
    self:bindCoatPortrait(self.treeFocusPortrait, record.coatColour)
    hgSetPortraitVisible(self.treeFocusPortrait, true)

    local parent1 = hgFindHorseById(record.mareId) or hgFindHorseById(record.stallionId)
    local parent2 = nil
    if record.mareId ~= nil and record.stallionId ~= nil then
        parent1 = hgFindHorseById(record.mareId)
        parent2 = hgFindHorseById(record.stallionId)
    end
    self.treeParent1 = parent1
    self.treeParent2 = parent2
    self:fillTreeRelative("treeP1", parent1, hgT("hg_unknown_parent"))
    self:fillTreeRelative("treeP2", parent2, hgT("hg_unknown_parent"))

    self.treeChildren = hgCollectOffspring(record.id)
    local maxOffset = math.max(0, #self.treeChildren - HorseGeneticsMenu.TREE_CHILD_SLOTS)
    self.treeChildOffset = math.max(0, math.min(maxOffset, self.treeChildOffset or 0))
    for i = 1, HorseGeneticsMenu.TREE_CHILD_SLOTS do
        local child = self.treeChildren[self.treeChildOffset + i]
        self:fillTreeRelative("treeC" .. i, child, "")
        local button = self["btnTreeC" .. i]
        if button ~= nil and button.setDisabled ~= nil then
            button:setDisabled(child == nil)
        end
    end
    if #self.treeChildren == 0 then
        hgSetText(self.treeKidsLabel, hgT("hg_offspring_none"))
    elseif #self.treeChildren > HorseGeneticsMenu.TREE_CHILD_SLOTS then
        hgSetText(self.treeKidsLabel, hgT("hg_offspring_scroll", #self.treeChildren))
    else
        hgSetText(self.treeKidsLabel, hgT("hg_offspring_n", #self.treeChildren))
    end
    local p1Btn = self.btnTreeP1
    local p2Btn = self.btnTreeP2
    if p1Btn ~= nil and p1Btn.setDisabled ~= nil then
        p1Btn:setDisabled(parent1 == nil)
    end
    if p2Btn ~= nil and p2Btn.setDisabled ~= nil then
        p2Btn:setDisabled(parent2 == nil)
    end
end

function HorseGeneticsMenu:focusHistoryHorse(record)
    if record == nil then
        return
    end
    self.historySelected = record
    self.treeChildOffset = 0
    for i, rec in ipairs(self.historyRecords) do
        if rec.id == record.id then
            local maxOff = math.max(0, #self.historyRecords - HorseGeneticsMenu.HIST_LIST_ROWS)
            if i <= self.historyOffset or i > self.historyOffset + HorseGeneticsMenu.HIST_LIST_ROWS then
                self.historyOffset = math.max(0, math.min(maxOff, i - 1))
            end
            break
        end
    end
    self:renderHistoryList()
    self:renderFamilyTree()
end

function HorseGeneticsMenu:onClickHist(index)
    local record = self.historyRecords[(self.historyOffset or 0) + index]
    self:focusHistoryHorse(record)
end

function HorseGeneticsMenu:onClickHist1() self:onClickHist(1) end
function HorseGeneticsMenu:onClickHist2() self:onClickHist(2) end
function HorseGeneticsMenu:onClickHist3() self:onClickHist(3) end
function HorseGeneticsMenu:onClickHist4() self:onClickHist(4) end
function HorseGeneticsMenu:onClickHist5() self:onClickHist(5) end
function HorseGeneticsMenu:onClickHist6() self:onClickHist(6) end
function HorseGeneticsMenu:onClickHist7() self:onClickHist(7) end
function HorseGeneticsMenu:onClickHist8() self:onClickHist(8) end
function HorseGeneticsMenu:onClickHist9() self:onClickHist(9) end
function HorseGeneticsMenu:onClickHist10() self:onClickHist(10) end
function HorseGeneticsMenu:onClickHist11() self:onClickHist(11) end
function HorseGeneticsMenu:onClickHist12() self:onClickHist(12) end

function HorseGeneticsMenu:onClickTreeP1()
    self:focusHistoryHorse(self.treeParent1)
end

function HorseGeneticsMenu:onClickTreeP2()
    self:focusHistoryHorse(self.treeParent2)
end

function HorseGeneticsMenu:onClickTreeC(index)
    local child = self.treeChildren[(self.treeChildOffset or 0) + index]
    self:focusHistoryHorse(child)
end

function HorseGeneticsMenu:onClickTreeC1() self:onClickTreeC(1) end
function HorseGeneticsMenu:onClickTreeC2() self:onClickTreeC(2) end
function HorseGeneticsMenu:onClickTreeC3() self:onClickTreeC(3) end
function HorseGeneticsMenu:onClickTreeC4() self:onClickTreeC(4) end

function HorseGeneticsMenu:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    self.hgLastMouseX = posX
    local okSuper, superUsed = pcall(function()
        local superClass = HorseGeneticsMenu:superClass()
        if superClass ~= nil and superClass.mouseEvent ~= nil then
            return superClass.mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) or eventUsed
        end
        return eventUsed
    end)
    if okSuper then
        eventUsed = superUsed or eventUsed
    end
    local ok, used = pcall(HorseGeneticsMenu.hgHandleScrollMouse, self, posX, posY, isDown, isUp, button)
    if ok and used then
        eventUsed = true
    end
    return eventUsed
end

function HorseGeneticsMenu:mouseWheelEvent(delta, eventUsed)
    local ok, used = pcall(function()
        if self:hgIsMyHorsesScrollActive() then
            return self:hgApplyWheelDelta(delta)
        end
        return false
    end)
    if ok and used then
        return true
    end
    local okSuper, superUsed = pcall(function()
        local superClass = HorseGeneticsMenu:superClass()
        if superClass ~= nil and superClass.mouseWheelEvent ~= nil then
            return superClass.mouseWheelEvent(self, delta, eventUsed)
        end
        return eventUsed
    end)
    if okSuper then
        return superUsed
    end
    return eventUsed
end

function HorseGeneticsMenu:update(dt)
    pcall(function()
        local superClass = HorseGeneticsMenu:superClass()
        if superClass ~= nil and superClass.update ~= nil then
            superClass.update(self, dt)
        end
    end)
    pcall(HorseGeneticsMenu.hgPollScrollInput, self)
end

local function hgInstallScrollInputHooks(page)
    HorseGenetics.hgMenuPage = page
    if HorseGenetics.hgScrollHooksInstalled or Utils == nil then
        return
    end
    HorseGenetics.hgScrollHooksInstalled = true
    if InGameMenu ~= nil and InGameMenu.mouseEvent ~= nil then
        InGameMenu.mouseEvent = Utils.appendedFunction(InGameMenu.mouseEvent, function(menu, posX, posY, isDown, isUp, button, eventUsed)
            pcall(function()
                local hgPage = HorseGenetics.hgMenuPage
                if hgPage == nil or menu == nil then
                    return
                end
                if menu.currentPage ~= nil and menu.currentPage ~= hgPage then
                    return
                end
                if hgPage.getIsVisible ~= nil and not hgPage:getIsVisible() then
                    return
                end
                hgPage:hgHandleScrollMouse(posX, posY, isDown, isUp, button)
            end)
        end)
    end
    if InGameMenu ~= nil and InGameMenu.mouseWheelEvent ~= nil then
        InGameMenu.mouseWheelEvent = Utils.appendedFunction(InGameMenu.mouseWheelEvent, function(menu, delta, eventUsed)
            pcall(function()
                local hgPage = HorseGenetics.hgMenuPage
                if hgPage ~= nil and hgPage:hgIsMyHorsesScrollActive() then
                    hgPage:hgApplyWheelDelta(delta)
                    return
                end
                local tabList = menu ~= nil and menu.pagingTabList or nil
                if tabList == nil or tabList.absPosition == nil or tabList.absSize == nil then
                    return
                end
                local mouseX, mouseY = nil, nil
                pcall(function()
                    if g_inputBinding ~= nil and g_inputBinding.getMousePosition ~= nil then
                        mouseX, mouseY = g_inputBinding:getMousePosition()
                    elseif g_inputBinding ~= nil then
                        mouseX = g_inputBinding.mousePosX
                        mouseY = g_inputBinding.mousePosY
                    end
                end)
                if mouseX == nil or mouseY == nil then
                    return
                end
                local x, y = tabList.absPosition[1], tabList.absPosition[2]
                local w, h = tabList.absSize[1], tabList.absSize[2]
                if mouseX < x or mouseX > x + w or mouseY < y or mouseY > y + h then
                    return
                end
                local step = 0
                if tonumber(delta) ~= nil then
                    if tonumber(delta) > 0 then
                        step = -1
                    elseif tonumber(delta) < 0 then
                        step = 1
                    end
                end
                if step == 0 then
                    return
                end
                local first = tabList.firstVisibleItem or 1
                local visible = tabList.maxNumVisibleItems or tabList.visibleItems or 7
                local total = 0
                if menu.enabledPages ~= nil then
                    total = #menu.enabledPages
                elseif tabList.getItemCount ~= nil then
                    total = tonumber(tabList:getItemCount()) or 0
                end
                local maxFirst = math.max(1, total - visible + 1)
                local nextFirst = math.max(1, math.min(maxFirst, first + step))
                if tabList.setFirstVisibleItem ~= nil then
                    tabList:setFirstVisibleItem(nextFirst)
                else
                    tabList.firstVisibleItem = nextFirst
                    if tabList.updateView ~= nil then
                        tabList:updateView(true)
                    end
                end
            end)
        end)
    end
end

-- Extra InGameMenu page overflows the left rail (Settings sits below Finances).
-- FS25 SmoothListElement centres items in MP, so the list will not scroll far
-- enough to show the last tab. Force start alignment and keep the selection in view.
local function hgFixInGameMenuTabScroll()
    local menu = g_inGameMenu
    local tabList = menu ~= nil and menu.pagingTabList or nil
    if tabList == nil then
        return
    end

    local alignStart = 1
    if SmoothListElement ~= nil and SmoothListElement.ALIGN_START ~= nil then
        alignStart = SmoothListElement.ALIGN_START
    elseif ListElement ~= nil and ListElement.ALIGN_START ~= nil then
        alignStart = ListElement.ALIGN_START
    end
    tabList.listItemAlignment = alignStart

    if tabList.setIsScrollAllowed ~= nil then
        pcall(tabList.setIsScrollAllowed, tabList, true)
    else
        tabList.isScrollAllowed = true
    end
    if tabList.supportsMouseScrolling ~= nil then
        tabList.supportsMouseScrolling = true
    end

    if tabList.updateAbsolutePosition ~= nil then
        tabList:updateAbsolutePosition()
    end
    if tabList.reloadData ~= nil then
        tabList:reloadData()
    end
    if tabList.updateView ~= nil then
        tabList:updateView(true)
    end
    if tabList.updateItemPositions ~= nil then
        tabList:updateItemPositions()
    end

    local idx = menu.currentPageListIndex
    if idx == nil and tabList.selectedIndex ~= nil then
        idx = tabList.selectedIndex
    end
    if idx ~= nil then
        if tabList.setSelectedIndex ~= nil then
            pcall(tabList.setSelectedIndex, tabList, idx)
        end
        if tabList.makeCellVisible ~= nil then
            pcall(tabList.makeCellVisible, tabList, idx)
        elseif tabList.scrollTo ~= nil then
            pcall(tabList.scrollTo, tabList, idx)
        elseif tabList.setFirstVisibleItem ~= nil then
            local visible = tabList.maxNumVisibleItems or tabList.visibleItems or 7
            local first = math.max(1, idx - math.max(0, visible - 1))
            pcall(tabList.setFirstVisibleItem, tabList, first)
        end
    end
end

local function hgInstallTabScrollFix()
    if HorseGenetics.hgTabScrollFixInstalled or Utils == nil then
        pcall(hgFixInGameMenuTabScroll)
        return
    end
    HorseGenetics.hgTabScrollFixInstalled = true
    if InGameMenu ~= nil then
        if InGameMenu.updatePages ~= nil then
            InGameMenu.updatePages = Utils.appendedFunction(InGameMenu.updatePages, function()
                pcall(hgFixInGameMenuTabScroll)
            end)
        end
        if InGameMenu.onOpen ~= nil then
            InGameMenu.onOpen = Utils.appendedFunction(InGameMenu.onOpen, function()
                pcall(hgFixInGameMenuTabScroll)
            end)
        end
        if InGameMenu.rebuildTabList ~= nil then
            InGameMenu.rebuildTabList = Utils.appendedFunction(InGameMenu.rebuildTabList, function()
                pcall(hgFixInGameMenuTabScroll)
            end)
        end
    end
    pcall(hgFixInGameMenuTabScroll)
end

local function hgPageListEntryMatches(entry, page)
    if entry == nil or page == nil then
        return false
    end
    return entry == page or entry.element == page or entry.page == page
end

local function hgMovePageInList(list, page, position)
    if list == nil or page == nil or position == nil then
        return
    end
    for i = 1, #list do
        if hgPageListEntryMatches(list[i], page) then
            local entry = table.remove(list, i)
            local insertAt = math.max(1, math.min(#list + 1, position))
            table.insert(list, insertAt, entry)
            return
        end
    end
end

local function hgFindAnimalsTabInsertPosition()
    local menu = g_inGameMenu
    local paging = menu ~= nil and menu.pagingElement or nil
    if paging == nil then
        return 4
    end

    local animalsPage = menu.pageAnimals
    if animalsPage == nil then
        local lists = { paging.elements, paging.pages }
        for _, list in ipairs(lists) do
            if list ~= nil then
                for i = 1, #list do
                    local child = list[i]
                    local element = child
                    if child ~= nil and type(child) == "table" and child.element ~= nil then
                        element = child.element
                    end
                    if element ~= nil then
                        local id = string.lower(tostring(element.id or ""))
                        local name = string.lower(tostring(element.name or ""))
                        if string.find(id, "animal", 1, true) or string.find(name, "animal", 1, true) then
                            animalsPage = element
                            break
                        end
                    end
                end
            end
            if animalsPage ~= nil then
                break
            end
        end
    end

    if animalsPage ~= nil and paging.pages ~= nil then
        for i = 1, #paging.pages do
            if hgPageListEntryMatches(paging.pages[i], animalsPage) then
                return i + 1
            end
        end
    end
    if animalsPage ~= nil and paging.elements ~= nil then
        for i = 1, #paging.elements do
            if paging.elements[i] == animalsPage then
                return i + 1
            end
        end
    end

    -- After Map, Calendar, Animals.
    return 4
end

function HorseGenetics.installGeneticsMenu()
    if HorseGenetics.geneticsMenuInstalled then return true end
    if g_dedicatedServer ~= nil then
        HorseGenetics.geneticsMenuInstalled = true
        return true
    end
    if g_gui == nil or g_inGameMenu == nil or g_inGameMenu.pagingElement == nil then return false end
    if TabbedMenuFrameElement == nil or g_gui.loadGui == nil then return false end
    local page = HorseGeneticsMenu.new()
    local modDirectory = HorseGenetics.modDirectory
    if modDirectory == nil then
        return false
    end
    local root = g_gui:loadGui(modDirectory .. "gui/HorseGeneticsMenu.xml", "horseGeneticsMenu", page, true)
    if root == nil then
        HorseGenetics.geneticsMenuInstallFailed = true
        return false
    end
    local pageName = "horseGeneticsMenu"
    if g_inGameMenu.controlIDs ~= nil then
        g_inGameMenu.controlIDs[pageName] = nil
    end
    g_inGameMenu[pageName] = page
    g_inGameMenu:exposeControlsAsFields(pageName)

    local insertPosition = hgFindAnimalsTabInsertPosition()
    g_inGameMenu.pagingElement:addElement(page)
    hgMovePageInList(g_inGameMenu.pagingElement.elements, page, insertPosition)
    hgMovePageInList(g_inGameMenu.pagingElement.pages, page, insertPosition)
    g_inGameMenu.pagingElement:updateAbsolutePosition()
    g_inGameMenu.pagingElement:updatePageMapping()
    g_inGameMenu:registerPage(page, insertPosition, function() return true end)

    local tabOk = false
    if GuiUtils ~= nil then
        local iconPath = Utils.getFilename("gui/icons/horse_genetics_menu_icon.dds", modDirectory)
        tabOk = pcall(function()
            g_inGameMenu:addPageTab(page, iconPath, GuiUtils.getUVs({0, 0, 256, 256}, 256))
        end)
        if not tabOk then
            tabOk = pcall(function()
                g_inGameMenu:addPageTab(page, iconPath, GuiUtils.getUVs({0, 0, 1024, 1024}))
            end)
        end
    end
    if not tabOk and g_iconsUIFilename ~= nil and GuiUtils ~= nil then
        pcall(function()
            g_inGameMenu:addPageTab(page, g_iconsUIFilename, GuiUtils.getUVs({0, 0, 64, 64}))
        end)
    end
    hgMovePageInList(g_inGameMenu.pageFrames, page, insertPosition)
    if g_inGameMenu.rebuildTabList ~= nil then
        g_inGameMenu:rebuildTabList()
    end
    pcall(hgFixInGameMenuTabScroll)
    pcall(hgInstallTabScrollFix)

    HorseGenetics.geneticsMenuInstalled = true

    -- Bind textures after the tab is registered.
    pcall(hgBindStatBarTextures, page)
    pcall(function()
        if page.setTitle ~= nil then
            page:setTitle(hgT("hg_title"))
        end
    end)
    pcall(function()
        if page.updateAbsolutePosition ~= nil then
            page:updateAbsolutePosition()
        end
    end)
    pcall(hgInstallScrollInputHooks, page)
    pcall(hgHideLeftoverScrollChrome, page)

    return true
end

-- Install the menu when InGameMenu is ready; retry from mission update if needed.
local function horseGeneticsTryInstallMenu()
    if HorseGenetics.geneticsMenuInstalled then
        return true
    end
    if g_dedicatedServer ~= nil then
        HorseGenetics.geneticsMenuInstalled = true
        return true
    end
    if g_inGameMenu == nil or g_inGameMenu.pagingElement == nil then
        return false
    end

    local ok, result = pcall(HorseGenetics.installGeneticsMenu)
    if not ok then
        HorseGenetics.geneticsMenuInstallFailed = true
        return false
    end
    return result == true
end

if InGameMenu ~= nil and InGameMenu.onGuiSetupFinished ~= nil and Utils ~= nil then
    InGameMenu.onGuiSetupFinished = Utils.appendedFunction(InGameMenu.onGuiSetupFinished, function(menu, ...)
        if g_inGameMenu == nil and menu ~= nil and menu.pagingElement ~= nil then
            g_inGameMenu = menu
        end
        horseGeneticsTryInstallMenu()
    end)
end

if FSBaseMission ~= nil and FSBaseMission.update ~= nil and Utils ~= nil then
    FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(mission, dt)
        if not HorseGenetics.horseReproductionBlockInstalled then
            pcall(HorseGenetics.installHorseReproductionBlock)
        end
        if not HorseGenetics.geneticsMenuInstalled and not HorseGenetics.geneticsMenuInstallFailed then
            HorseGenetics.geneticsMenuInstallAttempts = (HorseGenetics.geneticsMenuInstallAttempts or 0) + 1
            if not horseGeneticsTryInstallMenu()
                and HorseGenetics.geneticsMenuInstallAttempts >= 300 then
                HorseGenetics.geneticsMenuInstallFailed = true
            end
        end
        pcall(function()
            local page = HorseGenetics.hgMenuPage
            if page ~= nil and page.hgPollScrollInput ~= nil then
                page:hgPollScrollInput()
            end
        end)
    end)
end

