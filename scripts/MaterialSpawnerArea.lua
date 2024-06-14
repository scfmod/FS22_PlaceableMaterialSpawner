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

MaterialSpawnerArea.SEND_NUM_BITS_STATE = 1
MaterialSpawnerArea.SEND_NUM_BITS_INDEX = 4

local MaterialSpawnerArea_mt = Class(MaterialSpawnerArea)

---@param schema XMLSchema
---@param key string
function MaterialSpawnerArea.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '.name', 'Name to show in control panel GUI', nil, true)
    schema:register(XMLValueType.STRING, key .. '.fillTypes', 'Filltype(s)', 'STONE', true)
    schema:register(XMLValueType.INT, key .. '.litersPerHour', 'Liters produced per hour', 1000, true)
    schema:register(XMLValueType.BOOL, key .. '#defaultEnabled', 'Set to false to disable spawn area by default', true, false)

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
    end

    self.widthNode = xmlFile:getValue(path .. '.area#widthNode', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.widthNode == nil then
        Logging.xmlError(xmlFile, 'Missing area#widthNode in spawnArea: %s', path)
    end

    self.heightNode = xmlFile:getValue(path .. '.area#heightNode', nil, self.placeable.components, self.placeable.i3dMappings)

    if self.heightNode == nil then
        Logging.xmlError(xmlFile, 'Missing area#heightNode in spawnArea: %s', path)
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

    self:setFillType(self.fillTypes[1])
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
        -- Logging.info('MaterialSpawnerArea:setState() %s', tostring(state))

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
        -- Logging.info('MaterialSpawnerArea:setEnabled() %s', tostring(enabled))

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

        self.buffer = self.buffer + amount

        if self.buffer > g_densityMapHeightManager:getMinValidLiterValue(self.currentFillType.index) then
            local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(self.startNode, self.widthNode, self.heightNode, false)
            local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, self.buffer, self.currentFillType.index, lsx, lsy, lsz, lex, ley, lez, radius, radius, self.lineOffset, nil, nil, nil)

            self.lineOffset = lineOffset

            if dropped > 0 then
                self.buffer = 0

                if self.state ~= MaterialSpawnerArea.STATE_ON then
                    self:setState(MaterialSpawnerArea.STATE_ON)
                end
            end
        end
    end
end

function MaterialSpawnerArea:onStart()
    -- Logging.info('MaterialSpawnerArea:onStart()')

    if self.isClient then
        g_soundManager:playSamples(self.samples)
        g_effectManager:startEffects(self.effects)
        g_animationManager:startAnimations(self.animationNodes)
    end
end

function MaterialSpawnerArea:onStop()
    -- Logging.info('MaterialSpawnerArea:onStop()')

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
