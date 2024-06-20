-- Register new message types
MessageType.MATERIAL_SPAWNER_AREA_CHANGED = nextMessageTypeId()

---@diagnostic disable-next-line: lowercase-global
g_materialSpawnerUIFilename = g_currentModDirectory .. 'textures/ui_elements.png'

---@param path string
local function load(path)
    source(g_currentModDirectory .. 'scripts/' .. path)
end

---@diagnostic disable-next-line: lowercase-global
g_debugMaterialSpawner = fileExists(g_currentModDirectory .. 'scripts/debug.lua')

-- Utils
load('utils/MaterialSpawnerUtils.lua')

-- Base classes
load('MaterialSpawnerActivatable.lua')
load('MaterialSpawnerArea.lua')

-- GUI
load('gui/dialogs/MaterialSpawnerAreaDialog.lua')
load('gui/dialogs/MaterialSpawnerDialog.lua')
load('gui/MaterialSpawnerGUI.lua')

-- Base game extensions
load('extensions/GuiOverlayExtension.lua')

---@diagnostic disable-next-line: lowercase-global
g_materialSpawnerGUI = MaterialSpawnerGUI.new()

if g_client ~= nil then
    g_materialSpawnerGUI:load()
end
