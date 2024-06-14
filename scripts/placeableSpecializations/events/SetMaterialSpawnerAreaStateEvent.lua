---@class SetMaterialSpawnerAreaStateEvent : Event
---@field placeable PlaceableMaterialSpawner
---@field areaIndex number
---@field state number
SetMaterialSpawnerAreaStateEvent = {}

local SetMaterialSpawnerAreaStateEvent_mt = Class(SetMaterialSpawnerAreaStateEvent, Event)

InitEventClass(SetMaterialSpawnerAreaStateEvent, 'SetMaterialSpawnerAreaStateEvent')

function SetMaterialSpawnerAreaStateEvent.emptyNew()
    ---@type SetMaterialSpawnerAreaStateEvent
    local self = Event.new(SetMaterialSpawnerAreaStateEvent_mt)
    return self
end

---@param placeable PlaceableMaterialSpawner
---@param areaIndex number
---@param state number
---@return SetMaterialSpawnerAreaStateEvent
---@nodiscard
function SetMaterialSpawnerAreaStateEvent.new(placeable, areaIndex, state)
    local self = SetMaterialSpawnerAreaStateEvent.emptyNew()

    self.placeable = placeable
    self.areaIndex = areaIndex
    self.state = state

    return self
end

---@param streamId number
---@param connection Connection
function SetMaterialSpawnerAreaStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.areaIndex, MaterialSpawnerArea.SEND_NUM_BITS_INDEX)
    streamWriteUIntN(streamId, self.state, MaterialSpawnerArea.SEND_NUM_BITS_STATE)
end

---@param streamId number
---@param connection Connection
function SetMaterialSpawnerAreaStateEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.areaIndex = streamReadUIntN(streamId, MaterialSpawnerArea.SEND_NUM_BITS_INDEX)
    self.state = streamReadUIntN(streamId, MaterialSpawnerArea.SEND_NUM_BITS_STATE)

    self:run(connection)
end

---@param connection Connection
function SetMaterialSpawnerAreaStateEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        local area = self.placeable:getMaterialSpawnerAreaByIndex(self.areaIndex)

        if area ~= nil then
            area:setState(self.state)
        end
    end
end
