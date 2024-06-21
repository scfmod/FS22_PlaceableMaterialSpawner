---@class AreaLine
---@field sx number
---@field sy number
---@field sz number
---@field ex number
---@field ey number
---@field ez number
---@field radius number

---@class MaterialSpawnerArea
---@field index number
---@field placeable PlaceableMaterialSpawner
---
---@field name string
---@field state number
---@field enabled boolean
---@field currentFillType FillTypeObject
---@field litersPerHour number
---@field litersPerMs number
---@field buffer number
---@field lineOffset number
---@field fillTypes FillTypeObject[]
---@field useProductionStorage boolean
---@field minValidLiters number
---@field areaLine AreaLine
---
---@field startNode number
---@field widthNode number
---@field heightNode number
---
---@field effects table
---@field animationNodes table
---@field samples table
---
---@field isClient boolean
---@field isServer boolean
MaterialSpawnerArea = {}

MaterialSpawnerArea.STATE_OFF = 0
MaterialSpawnerArea.STATE_ON = 1

MaterialSpawnerArea.BUFFER_MAX_SIZE = 500

MaterialSpawnerArea.SEND_NUM_BITS_STATE = 1
MaterialSpawnerArea.SEND_NUM_BITS_INDEX = 4
MaterialSpawnerArea.MAX_NUM_INDEX = 2 ^ MaterialSpawnerArea.SEND_NUM_BITS_INDEX - 1

local MaterialSpawnerArea_mt = Class(MaterialSpawnerArea)

---@param schema XMLSchema
---@param key string
function MaterialSpawnerArea.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '.name', 'Name to show in control panel GUI', nil, true)
    schema:register(XMLValueType.STRING, key .. '.fillTypes', 'Filltype(s)', 'STONE', true)
    schema:register(XMLValueType.INT, key .. '.litersPerHour', 'Liters produced per hour', 1000, true)
    schema:register(XMLValueType.BOOL, key .. '#defaultEnabled', 'Set to false to disable spawn area by default', true, false)
    schema:register(XMLValueType.BOOL, key .. '#useProductionStorage', 'Spawn material from production point storage', false)

    schema:register(XMLValueType.NODE_INDEX, key .. '.area#startNode', '', nil, true)
    schema:register(XMLValueType.NODE_INDEX, key .. '.area#widthNode', '', nil, true)
    schema:register(XMLValueType.NODE_INDEX, key .. '.area#heightNode', '', nil, true)

    EffectManager.registerEffectXMLPaths(schema, key .. '.effectNodes')
    SoundManager.registerSampleXMLPaths(schema, key .. '.sounds', 'work')
    SoundManager.registerSampleXMLPaths(schema, key .. '.sounds', 'work2')
    SoundManager.registerSampleXMLPaths(schema, key .. '.sounds', 'dropping')
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. '.animationNodes')
end

---@param schema XMLSchema
---@param key string
function MaterialSpawnerArea.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#fillType')
    schema:register(XMLValueType.BOOL, key .. '#enabled')
end

---@param placeable PlaceableMaterialSpawner
---@param index number
---@param customMt table|nil
---@return MaterialSpawnerArea
---@nodiscard
function MaterialSpawnerArea.new(placeable, index, customMt)
    ---@type MaterialSpawnerArea
    local self = setmetatable({}, customMt or MaterialSpawnerArea_mt)

    self.placeable = placeable
    self.index = index

    self.name = string.format('Output #%i', index)
    self.state = MaterialSpawnerArea.STATE_OFF
    self.enabled = true
    self.fillTypes = {}
    self.litersPerHour = 1000
    self.buffer = 0
    self.useProductionStorage = false
    self.minValidLiters = 0

    self.effects = {}
    self.animationNodes = {}
    self.samples = {}

    self.isClient = placeable.isClient
    self.isServer = placeable.isServer

    return self
end

function MaterialSpawnerArea:delete()
    g_soundManager:deleteSamples(self.samples)
    g_animationManager:deleteAnimations(self.animationNodes)
    g_effectManager:deleteEffects(self.effects)
end

---@param xmlFile XMLFile
---@param path string
---@return boolean
---@nodiscard
function MaterialSpawnerArea:load(xmlFile, path)
    self.name = MaterialSpawnerUtils.getPlaceableText(self.placeable, xmlFile:getValue(path .. '.name'), self.name)

    local defaultEnabled = xmlFile:getValue(path .. '#defaultEnabled', true)

    if not defaultEnabled then
        self.enabled = false
    end

    if not xmlFile:hasProperty(path .. '.litersPerHour') then
        Logging.xmlWarning(xmlFile, 'Missing litersPerHour in spawnArea: %s (defaulting to 1000)', path)
    end

    self.startNode = xmlFile:getValue(path .. '.area#startNode', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.startNode == nil then
        Logging.xmlError(xmlFile, 'Missing area#startNode in spawnArea: %s', path)
        return false
    end

    self.widthNode = xmlFile:getValue(path .. '.area#widthNode', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.widthNode == nil then
        Logging.xmlError(xmlFile, 'Missing area#widthNode in spawnArea: %s', path)
        return false
    end

    self.heightNode = xmlFile:getValue(path .. '.area#heightNode', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.heightNode == nil then
        Logging.xmlError(xmlFile, 'Missing area#heightNode in spawnArea: %s', path)
        return false
    end

    self.litersPerHour = xmlFile:getValue(path .. '.litersPerHour', self.litersPerHour)
    self.litersPerMs = self.litersPerHour / 3600 / 1000

    self.fillTypes = MaterialSpawnerUtils.loadFillTypesFromXML(xmlFile, path .. '.fillTypes')

    if #self.fillTypes == 0 then
        Logging.xmlWarning(xmlFile, 'No valid fillTypes in spawnArea: %s (defaulting to STONE)', path)

        table.insert(self.fillTypes, g_fillTypeManager:getFillTypeByName('STONE'))
    end

    if self.isClient then
        self.samples = {
            work = g_soundManager:loadSampleFromXML(xmlFile, path .. '.sounds', 'work', self.placeable.baseDirectory, self.placeable.components, 1, AudioGroup.ENVIRONMENT, self.placeable.i3dMappings, self.placeable),
            work2 = g_soundManager:loadSampleFromXML(xmlFile, path .. '.sounds', 'work2', self.placeable.baseDirectory, self.placeable.components, 1, AudioGroup.ENVIRONMENT, self.placeable.i3dMappings, self.placeable),
            dropping = g_soundManager:loadSampleFromXML(xmlFile, path .. '.sounds', 'dropping', self.placeable.baseDirectory, self.placeable.components, 1, AudioGroup.ENVIRONMENT, self.placeable.i3dMappings, self.placeable)
        }

        self.animationNodes = g_animationManager:loadAnimations(xmlFile, path .. '.animationNodes', self.placeable.components, self.placeable, self.placeable.i3dMappings)
        self.effects = g_effectManager:loadEffect(xmlFile, path .. '.effectNodes', self.placeable.components, self.placeable, self.placeable.i3dMappings)
    end

    self.areaLine = MaterialSpawnerUtils.getAreaLine(self.startNode, self.widthNode, self.heightNode)

    self:setFillType(self.fillTypes[1])

    self.useProductionStorage = xmlFile:getValue(path .. '#useProductionStorage', self.useProductionStorage)

    if self.useProductionStorage then
        if not SpecializationUtil.hasSpecialization(PlaceableProductionPoint, self.placeable.specializations) then
            Logging.xmlWarning(xmlFile, 'The "useProductionStorage" attribute requires PlaceableProductionPoint specialization: %s', path .. '#useProductionStorage')

            self.useProductionStorage = false
        end
    end

    return true
end

---@param xmlFile XMLFile
---@param key string
function MaterialSpawnerArea:loadFromXMLFile(xmlFile, key)
    local fillTypeName = xmlFile:getValue(key .. '#fillType')

    if fillTypeName ~= nil then
        ---@type FillTypeObject | nil
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

        if fillType ~= nil and self:getIsValidFillType(fillType) then
            self:setFillType(fillType)
        end
    end

    local enabled = xmlFile:getValue(key .. '#enabled')

    if enabled ~= nil then
        self:setEnabled(enabled)
    end
end

---@param xmlFile XMLFile
---@param key string
function MaterialSpawnerArea:saveToXMLFile(xmlFile, key)
    if self.currentFillType ~= nil then
        xmlFile:setValue(key .. '#fillType', self.currentFillType.name)
    end

    xmlFile:setValue(key .. '#enabled', self.enabled)
end

---@param fillType FillTypeObject
function MaterialSpawnerArea:setFillType(fillType)
    if self.currentFillType ~= fillType then
        if self.isServer then
            local event = SetMaterialSpawnerAreaFilltypeEvent.new(self.placeable, self.index, fillType.index)
            g_server:broadcastEvent(event)
        end

        self.currentFillType = fillType

        self.minValidLiters = g_densityMapHeightManager:getMinValidLiterValue(fillType.index)

        if self.isClient then
            g_effectManager:setFillType(self.effects, fillType.index)
        end

        g_messageCenter:publish(MessageType.MATERIAL_SPAWNER_AREA_CHANGED, self)
    end
end

function MaterialSpawnerArea:setFillTypeIndex(fillTypeIndex)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType ~= nil then
        self:setFillType(fillType)
    end
end

---@param fillType FillTypeObject
---@return boolean
---@nodiscard
function MaterialSpawnerArea:getIsValidFillType(fillType)
    if fillType ~= nil then
        for _, entry in ipairs(self.fillTypes) do
            if fillType == entry then
                return true
            end
        end
    end

    return false
end

---@return string | nil
function MaterialSpawnerArea:getFillTypeName()
    if self.currentFillType ~= nil then
        return self.currentFillType.name
    end
end

---@param state number
function MaterialSpawnerArea:setState(state)
    if self.state ~= state then
        if self.isServer then
            local event = SetMaterialSpawnerAreaStateEvent.new(self.placeable, self.index, state)
            g_server:broadcastEvent(event)
        end

        self.state = state

        if state == MaterialSpawnerArea.STATE_ON then
            self:onStart()
        else
            self:onStop()
        end

        g_messageCenter:publish(MessageType.MATERIAL_SPAWNER_AREA_CHANGED, self)
    end
end

---@param enabled boolean
function MaterialSpawnerArea:setEnabled(enabled)
    if self.enabled ~= enabled then
        if self.isServer then
            local event = SetMaterialSpawnerAreaEnabledEvent.new(self.placeable, self.index, enabled)
            g_server:broadcastEvent(event)
        end

        self.enabled = enabled

        if self.isServer and not self.enabled then
            self:setState(MaterialSpawnerArea.STATE_OFF)
        end

        g_messageCenter:publish(MessageType.MATERIAL_SPAWNER_AREA_CHANGED, self)
    end
end

---@param dt number
function MaterialSpawnerArea:onUpdateTick(dt)
    if self.enabled and self.currentFillType ~= nil then
        local amount = g_currentMission:getEffectiveTimeScale() * dt * self.litersPerMs

        self.buffer = math.min(self.buffer + amount, MaterialSpawnerArea.BUFFER_MAX_SIZE)

        if self.buffer > self.minValidLiters then
            local dropped = 0

            if self.useProductionStorage then
                dropped = self:dischargeFromProductionPoint(self.buffer)
            else
                dropped = self:discharge(self.buffer)
            end

            if dropped > 0 then
                self.buffer = math.max(0, self.buffer - dropped)

                if self.state ~= MaterialSpawnerArea.STATE_ON then
                    self:setState(MaterialSpawnerArea.STATE_ON)
                end
            end
        end
    end
end

---@param litersToDrop number
---@return number
---@nodiscard
function MaterialSpawnerArea:dischargeFromProductionPoint(litersToDrop)
    local storage = self:getProductionPointStorage()

    if storage == nil then
        Logging.warning('MaterialSpawnerArea:dischargeFromProductionPoint() Could not find production point storage, disabling and reverting to default behaviour.')
        self.useProductionStorage = false

        return 0
    end

    local fillLevel = storage:getFillLevel(self.currentFillType.index)

    if fillLevel > self.minValidLiters then
        local targetLiters = math.min(fillLevel, self:getAvailableGroundDischargeAmount(litersToDrop))

        if targetLiters > self.minValidLiters then
            local dropped = self:discharge(targetLiters)

            storage:setFillLevel(fillLevel - dropped, self.currentFillType.index)

            return dropped
        end
    end

    return 0
end

---@return Storage | nil
function MaterialSpawnerArea:getProductionPointStorage()
    return self.placeable.spec_productionPoint.productionPoint and self.placeable.spec_productionPoint.productionPoint.storage
end

function MaterialSpawnerArea:getAvailableGroundDischargeAmount(litersToDrop)
    local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(
        nil, litersToDrop, self.currentFillType.index,
        self.areaLine.sx, self.areaLine.sy, self.areaLine.sz,
        self.areaLine.ex, self.areaLine.ey, self.areaLine.ez,
        self.areaLine.radius, self.areaLine.radius,
        self.lineOffset, nil, nil, nil, false
    )

    self.lineOffset = lineOffset

    return dropped
end

---@param litersToDrop number
---@return number
---@nodiscard
function MaterialSpawnerArea:discharge(litersToDrop)
    local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(
        nil, litersToDrop, self.currentFillType.index,
        self.areaLine.sx, self.areaLine.sy, self.areaLine.sz,
        self.areaLine.ex, self.areaLine.ey, self.areaLine.ez,
        self.areaLine.radius, self.areaLine.radius,
        self.lineOffset, nil, nil, nil
    )

    self.lineOffset = lineOffset

    return dropped
end

function MaterialSpawnerArea:onStart()
    if self.isClient then
        g_soundManager:playSamples(self.samples)
        g_effectManager:startEffects(self.effects)
        g_animationManager:startAnimations(self.animationNodes)
    end
end

function MaterialSpawnerArea:onStop()
    if self.isClient then
        g_soundManager:stopSamples(self.samples)
        g_effectManager:stopEffects(self.effects)
        g_animationManager:stopAnimations(self.animationNodes)
    end
end

---@param streamId number
---@param connection Connection
function MaterialSpawnerArea:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enabled)
    streamWriteUIntN(streamId, self.state, MaterialSpawnerArea.SEND_NUM_BITS_STATE)

    local fillTypeIndex = FillType.UNKNOWN

    if self.currentFillType ~= nil then
        fillTypeIndex = self.currentFillType.index
    end

    streamWriteUIntN(streamId, fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function MaterialSpawnerArea:readStream(streamId, connection)
    self:setEnabled(streamReadBool(streamId))
    self:setState(streamReadUIntN(streamId, MaterialSpawnerArea.SEND_NUM_BITS_STATE))
    self:setFillTypeIndex(streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS))
end
