---@class MaterialSpawnerSpecialization
---@field areas MaterialSpawnerArea[]
---@field activatable MaterialSpawnerActivatable

---@class PlaceableProductionPointSpecialization
---@field productionPoint ProductionPoint

source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetMaterialSpawnerAreaEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetMaterialSpawnerAreaFilltypeEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetMaterialSpawnerAreaStateEvent.lua')

---@class PlaceableMaterialSpawner : Placeable
---@field spec_productionPoint PlaceableProductionPointSpecialization
PlaceableMaterialSpawner = {}

---@type string
PlaceableMaterialSpawner.SPEC_NAME = 'spec_' .. g_currentModName .. '.materialSpawner'

function PlaceableMaterialSpawner.prerequisitesPresent()
    return true
end

---@param schema XMLSchema
function PlaceableMaterialSpawner.registerXMLPaths(schema)
    schema:setXMLSpecializationType('MaterialSpawner')
    MaterialSpawnerActivatable.registerXMLPaths(schema, 'placeable.materialSpawner.activationTrigger')
    MaterialSpawnerArea.registerXMLPaths(schema, 'placeable.materialSpawner.spawnAreas.spawnArea(?)')
    schema:setXMLSpecializationType()
end

---@param schema XMLSchema
---@param key string
function PlaceableMaterialSpawner.registerSavegameXMLPaths(schema, key)
    schema:setXMLSpecializationType('MaterialSpawner')
    MaterialSpawnerArea.registerSavegameXMLPaths(schema, key .. '.spawnArea(?)')
    schema:setXMLSpecializationType()
end

function PlaceableMaterialSpawner.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, 'getMaterialSpawnerAreas', PlaceableMaterialSpawner.getMaterialSpawnerAreas)
    SpecializationUtil.registerFunction(placeableType, 'getMaterialSpawnerAreaByIndex', PlaceableMaterialSpawner.getMaterialSpawnerAreaByIndex)
end

function PlaceableMaterialSpawner.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, 'onLoad', PlaceableMaterialSpawner)
    SpecializationUtil.registerEventListener(placeableType, 'onFinalizePlacement', PlaceableMaterialSpawner)
    SpecializationUtil.registerEventListener(placeableType, 'onDelete', PlaceableMaterialSpawner)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdateTick', PlaceableMaterialSpawner)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteStream', PlaceableMaterialSpawner)
    SpecializationUtil.registerEventListener(placeableType, 'onReadStream', PlaceableMaterialSpawner)
end

function PlaceableMaterialSpawner:onLoad()
    local xmlFile = self.xmlFile

    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    spec.areas = {}

    xmlFile:iterate('placeable.materialSpawner.spawnAreas.spawnArea', function(_, areaKey)
        local index = #spec.areas + 1

        if index > MaterialSpawnerArea.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of spawnAreas (%i)', index)
            return false
        end

        local area = MaterialSpawnerArea.new(self, index)

        if area:load(xmlFile, areaKey) then
            table.insert(spec.areas, area)
        end
    end)

    if #spec.areas == 0 then
        Logging.xmlWarning(xmlFile, 'No valid spawnAreas registered: placeable.materialSpawner.spawnAreas')
    end

    spec.activatable = MaterialSpawnerActivatable.new(self)
    spec.activatable:load(xmlFile, 'placeable.materialSpawner.activationTrigger')
end

function PlaceableMaterialSpawner:onDelete()
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    if spec.activatable ~= nil then
        spec.activatable:delete()
    end

    for _, area in ipairs(spec.areas) do
        area:delete()
    end

    spec.activatable = nil
    spec.areas = {}
end

function PlaceableMaterialSpawner:onFinalizePlacement()
    if self.isServer then
        self:raiseActive()
    end
end

---@param xmlFile XMLFile
---@param key string
function PlaceableMaterialSpawner:loadFromXMLFile(xmlFile, key)
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    xmlFile:iterate(key .. '.spawnArea', function(index, areaKey)
        local area = spec.areas[index]

        if area ~= nil then
            area:loadFromXMLFile(xmlFile, areaKey)
        end
    end)
end

---@param xmlFile XMLFile
---@param key string
function PlaceableMaterialSpawner:saveToXMLFile(xmlFile, key)
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    for i, area in ipairs(spec.areas) do
        local areaKey = string.format('%s.spawnArea(%i)', key, i - 1)

        area:saveToXMLFile(xmlFile, areaKey)
    end
end

---@param dt number
function PlaceableMaterialSpawner:onUpdateTick(dt)
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    if self.isServer then
        for _, area in ipairs(spec.areas) do
            area:onUpdateTick(dt)
        end

        self:raiseActive()
    end
end

---@return MaterialSpawnerArea[]
---@nodiscard
function PlaceableMaterialSpawner:getMaterialSpawnerAreas()
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    return spec.areas
end

---@param index number
---@return MaterialSpawnerArea | nil
---@nodiscard
function PlaceableMaterialSpawner:getMaterialSpawnerAreaByIndex(index)
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    return spec.areas[index]
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialSpawner:onWriteStream(streamId, connection)
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    for _, area in ipairs(spec.areas) do
        area:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialSpawner:onReadStream(streamId, connection)
    ---@type MaterialSpawnerSpecialization
    local spec = self[PlaceableMaterialSpawner.SPEC_NAME]

    for _, area in ipairs(spec.areas) do
        area:readStream(streamId, connection)
    end
end
