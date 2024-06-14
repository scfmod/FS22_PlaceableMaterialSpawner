---@class MaterialSpawnerDialog : MessageDialog
---@field areas MaterialSpawnerArea[]
---@field placeable PlaceableMaterialSpawner | nil
---@field list SmoothListElement
---@field outputButton ButtonElement
---@field toggleEnableButton ButtonElement
---
---@field superClass fun(): MessageDialog
MaterialSpawnerDialog = {}

MaterialSpawnerDialog.CLASS_NAME = 'MaterialSpawnerDialog'
MaterialSpawnerDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/MaterialSpawnerDialog.xml'
MaterialSpawnerDialog.CONTROLS = {
    'list',
    'outputButton',
    'toggleEnableButton',
}

MaterialSpawnerDialog.L10N_TEXTS = {
    ENABLE_OUTPUT = g_i18n:getText('action_enableOutput'),
    DISABLE_OUTPUT = g_i18n:getText('action_disableOutput'),
}

local MaterialSpawnerDialog_mt = Class(MaterialSpawnerDialog, MessageDialog)

function MaterialSpawnerDialog.new()
    ---@type MaterialSpawnerDialog
    local self = MessageDialog.new(nil, MaterialSpawnerDialog_mt)

    self:registerControls(MaterialSpawnerDialog.CONTROLS)

    self.areas = {}

    return self
end

function MaterialSpawnerDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[MaterialSpawnerDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function MaterialSpawnerDialog:load()
    g_gui:loadGui(MaterialSpawnerDialog.XML_FILENAME, MaterialSpawnerDialog.CLASS_NAME, self)
end

function MaterialSpawnerDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

function MaterialSpawnerDialog:show(placeable)
    if placeable ~= nil then
        self.placeable = placeable
        g_gui:showDialog(MaterialSpawnerDialog.CLASS_NAME)
    end
end

function MaterialSpawnerDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateAreas()
    self:updateMenuButtons()

    g_messageCenter:subscribe(MessageType.MATERIAL_SPAWNER_AREA_CHANGED, self.onSpawnAreaChanged, self)
end

function MaterialSpawnerDialog:onClose()
    self:superClass().onClose(self)

    self.areas = {}
    self.placeable = nil

    g_messageCenter:unsubscribeAll(self)
end

function MaterialSpawnerDialog:updateAreas()
    self.areas = self.placeable:getMaterialSpawnerAreas()
    self.list:reloadData()
end

function MaterialSpawnerDialog:updateMenuButtons()
    local area = self.areas[self.list:getSelectedIndexInSection()]

    if area ~= nil then
        self.outputButton:setVisible(#area.fillTypes > 1)

        if area.enabled then
            self.toggleEnableButton:setText(MaterialSpawnerDialog.L10N_TEXTS.DISABLE_OUTPUT)
        else
            self.toggleEnableButton:setText(MaterialSpawnerDialog.L10N_TEXTS.ENABLE_OUTPUT)
        end
    end
end

function MaterialSpawnerDialog:onClickToggleEnable()
    local area = self.areas[self.list:getSelectedIndexInSection()]

    if area ~= nil then
        if g_server ~= nil then
            area:setEnabled(not area.enabled)
        else
            local event = SetMaterialSpawnerAreaEnabledEvent.new(area.placeable, area.index, not area.enabled)
            g_client:getServerConnection():sendEvent(event)
        end
    end
end

---@param area MaterialSpawnerArea
function MaterialSpawnerDialog:onSpawnAreaChanged(area)
    if self.isOpen and area ~= nil and area.placeable == self.placeable then
        self:updateAreas()
        self:updateMenuButtons()
    end
end

---@return MaterialSpawnerArea | nil
function MaterialSpawnerDialog:getSelectedArea()
    return self.areas[self.list:getSelectedIndexInSection()]
end

---@return number
function MaterialSpawnerDialog:getNumberOfItemsInSection()
    return #self.areas
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function MaterialSpawnerDialog:populateCellForItemInSection(list, section, index, cell)
    local area = self.areas[index]

    if area ~= nil then
        cell:getAttribute('name'):setText(area.name)
        cell:getAttribute('litersPerHour'):setText(MaterialSpawnerUtils.formatNumber(area.litersPerHour))
        cell:getAttribute('fillType'):setText(area:getFillTypeName() or 'Invalid')

        local state = cell:getAttribute('state')

        if area.enabled ~= true then
            state:setDisabled(true)
            state:setText('Disabled')
        else
            state:setDisabled(false)
            state:setText('Enabled')
        end
    end
end

function MaterialSpawnerDialog:onListSelectionChanged()
    self:updateMenuButtons()
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function MaterialSpawnerDialog:onItemDoubleClick(list, section, index, cell)
    self:openAreaDialog(index)
end

function MaterialSpawnerDialog:onClickOutput()
    self:openAreaDialog()
end

---@param index number | nil
function MaterialSpawnerDialog:openAreaDialog(index)
    index = index or self.list:getSelectedIndexInSection()

    local area = self.areas[index]

    if area ~= nil and #area.fillTypes > 1 then
        g_materialSpawnerAreaDialog:show(area)
    end
end
