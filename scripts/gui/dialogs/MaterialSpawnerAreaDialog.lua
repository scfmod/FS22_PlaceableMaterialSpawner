---@class MaterialSpawnerAreaDialog : MessageDialog
---@field area MaterialSpawnerArea | nil
---@field fillTypes FillTypeObject[]
---@field list SmoothListElement
---
---@field superClass fun(): MessageDialog
MaterialSpawnerAreaDialog = {}

MaterialSpawnerAreaDialog.CLASS_NAME = 'MaterialSpawnerAreaDialog'
MaterialSpawnerAreaDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/MaterialSpawnerAreaDialog.xml'
MaterialSpawnerAreaDialog.CONTROLS = {
    'list'
}

local MaterialSpawnerAreaDialog_mt = Class(MaterialSpawnerAreaDialog, MessageDialog)

function MaterialSpawnerAreaDialog.new()
    ---@type MaterialSpawnerAreaDialog
    local self = MessageDialog.new(nil, MaterialSpawnerAreaDialog_mt)

    self:registerControls(MaterialSpawnerAreaDialog.CONTROLS)

    self.fillTypes = {}

    return self
end

function MaterialSpawnerAreaDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[MaterialSpawnerAreaDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function MaterialSpawnerAreaDialog:load()
    g_gui:loadGui(MaterialSpawnerAreaDialog.XML_FILENAME, MaterialSpawnerAreaDialog.CLASS_NAME, self)
end

function MaterialSpawnerAreaDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param area MaterialSpawnerArea
function MaterialSpawnerAreaDialog:show(area)
    if area ~= nil then
        self.area = area
        g_gui:showDialog(MaterialSpawnerAreaDialog.CLASS_NAME)
    end
end

function MaterialSpawnerAreaDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateFilltypes()

    for index, fillType in ipairs(self.fillTypes) do
        if fillType == self.area.currentFillType then
            self.list:setSelectedIndex(index)
            break
        end
    end
end

function MaterialSpawnerAreaDialog:onClose()
    self:superClass().onClose(self)

    self.fillTypes = {}
    self.area = nil
end

function MaterialSpawnerAreaDialog:updateFilltypes()
    self.fillTypes = self.area.fillTypes
    self.list:reloadData()
end

function MaterialSpawnerAreaDialog:onClickApply()
    self:applyFillTypeItem()
end

---@return number
function MaterialSpawnerAreaDialog:getNumberOfItemsInSection()
    return #self.fillTypes
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function MaterialSpawnerAreaDialog:populateCellForItemInSection(list, section, index, cell)
    local fillType = self.fillTypes[index]

    if fillType ~= nil then
        cell:getAttribute('title'):setText(fillType.title)
        cell:getAttribute('icon'):setImageFilename(fillType.hudOverlayFilename)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function MaterialSpawnerAreaDialog:onItemDoubleClick(list, section, index, cell)
    self:applyFillTypeItem(index)
end

---@param index number | nil
function MaterialSpawnerAreaDialog:applyFillTypeItem(index)
    index = index or self.list:getSelectedIndexInSection()

    local fillType = self.fillTypes[index]

    if fillType ~= nil then
        if g_server ~= nil then
            self.area:setFillType(fillType)
        else
            local event = SetMaterialSpawnerAreaFilltypeEvent.new(self.area.placeable, self.area.index, fillType.index)
            g_client:getServerConnection():sendEvent(event)
        end
    end

    self:close()
end
