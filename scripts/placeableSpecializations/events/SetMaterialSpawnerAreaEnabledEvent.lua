---@class SetMaterialSpawnerAreaEnabledEvent : Event
---@field placeable PlaceableMaterialSpawner
---@field areaIndex number
---@field enabled boolean
SetMaterialSpawnerAreaEnabledEvent = {}

local SetMaterialSpawnerAreaEnabledEvent_mt = Class(SetMaterialSpawnerAreaEnabledEvent, Event)

InitEventClass(SetMaterialSpawnerAreaEnabledEvent, 'SetMaterialSpawnerAreaEnabledEvent')

function SetMaterialSpawnerAreaEnabledEvent.emptyNew()
    ---@type SetMaterialSpawnerAreaEnabledEvent
    local self = Event.new(SetMaterialSpawnerAreaEnabledEvent_mt)
    return self
end

---@param placeable PlaceableMaterialSpawner
---@param areaIndex number
---@param enabled boolean
---@return SetMaterialSpawnerAreaEnabledEvent
---@nodiscard
function SetMaterialSpawnerAreaEnabledEvent.new(placeable, areaIndex, enabled)
    local self = SetMaterialSpawnerAreaEnabledEvent.emptyNew()

    self.placeable = placeable
    self.areaIndex = areaIndex
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetMaterialSpawnerAreaEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.areaIndex, MaterialSpawnerArea.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetMaterialSpawnerAreaEnabledEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.areaIndex = streamReadUIntN(streamId, MaterialSpawnerArea.SEND_NUM_BITS_INDEX)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetMaterialSpawnerAreaEnabledEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local area = self.placeable:getMaterialSpawnerAreaByIndex(self.areaIndex)

        if area ~= nil then
            area:setEnabled(self.enabled)
        end
    end
end
