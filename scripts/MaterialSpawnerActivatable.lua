---@class MaterialSpawnerActivatable
---@field placeable PlaceableMaterialSpawner
---@field triggerNode number | nil
---@field activateText string
MaterialSpawnerActivatable = {}

MaterialSpawnerActivatable.L10N_TEXTS = {
    ACTIVATE = g_i18n:getText('action_openControlPanel')
}

local MaterialSpawnerActivatable_mt = Class(MaterialSpawnerActivatable)

---@param schema XMLSchema
---@param key string
function MaterialSpawnerActivatable.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Activation trigger node for opening control panel', nil, false)
end

---@param placeable PlaceableMaterialSpawner
---@return MaterialSpawnerActivatable
---@nodiscard
function MaterialSpawnerActivatable.new(placeable)
    ---@type MaterialSpawnerActivatable
    local self = setmetatable({}, MaterialSpawnerActivatable_mt)

    self.placeable = placeable
    self.activateText = MaterialSpawnerActivatable.L10N_TEXTS.ACTIVATE

    return self
end

function MaterialSpawnerActivatable:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self)

    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
    end
end

---@param xmlFile XMLFile
---@param path string
function MaterialSpawnerActivatable:load(xmlFile, path)
    if self.placeable.isClient then
        self.triggerNode = xmlFile:getValue(path .. '#node', nil, self.placeable.components, self.placeable.i3dMappings)

        if self.triggerNode ~= nil then
            if CollisionFlag.getHasFlagSet(self.triggerNode, CollisionFlag.TRIGGER_PLAYER) then
                addTrigger(self.triggerNode, 'activationTriggerCallback', self)
            else
                Logging.xmlWarning(xmlFile, 'Missing TRIGGER_PLAYER collision flag (bit 20) on node: %s', path .. '#node')
            end
        end
    end
end

function MaterialSpawnerActivatable:run()
    g_materialSpawnerDialog:show(self.placeable)
end

---@return boolean
function MaterialSpawnerActivatable:getIsActivatable()
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        return g_currentMission.isMasterUser
    end

    return true
end

---@param x number
---@param y number
---@param z number
function MaterialSpawnerActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.triggerNode)

    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function MaterialSpawnerActivatable:activationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self)
        end
    end
end
