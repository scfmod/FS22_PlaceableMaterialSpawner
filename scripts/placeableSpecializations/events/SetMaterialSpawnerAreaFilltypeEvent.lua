---@class SetMaterialSpawnerAreaFilltypeEvent : Event
---@field placeable PlaceableMaterialSpawner
---@field areaIndex number
---@field fillTypeIndex number
SetMaterialSpawnerAreaFilltypeEvent = {}

local SetMaterialSpawnerAreaFilltypeEvent_mt = Class(SetMaterialSpawnerAreaFilltypeEvent, Event)

InitEventClass(SetMaterialSpawnerAreaFilltypeEvent, 'SetMaterialSpawnerAreaFilltypeEvent')

function SetMaterialSpawnerAreaFilltypeEvent.emptyNew()
    ---@type SetMaterialSpawnerAreaFilltypeEvent
    local self = Event.new(SetMaterialSpawnerAreaFilltypeEvent_mt)
    return self
end

---@param placeable PlaceableMaterialSpawner
---@param areaIndex number
---@param fillTypeIndex number
---@return SetMaterialSpawnerAreaFilltypeEvent
---@nodiscard
function SetMaterialSpawnerAreaFilltypeEvent.new(placeable, areaIndex, fillTypeIndex)
    local self = SetMaterialSpawnerAreaFilltypeEvent.emptyNew()

    self.placeable = placeable
    self.areaIndex = areaIndex
    self.fillTypeIndex = fillTypeIndex

    return self
end

---@param streamId number
---@param connection Connection
function SetMaterialSpawnerAreaFilltypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.areaIndex, MaterialSpawnerArea.SEND_NUM_BITS_INDEX)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetMaterialSpawnerAreaFilltypeEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.areaIndex = streamReadUIntN(streamId, MaterialSpawnerArea.SEND_NUM_BITS_INDEX)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetMaterialSpawnerAreaFilltypeEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local area = self.placeable:getMaterialSpawnerAreaByIndex(self.areaIndex)

        if area ~= nil then
            area:setFillTypeIndex(self.fillTypeIndex)
        end
    end
end
