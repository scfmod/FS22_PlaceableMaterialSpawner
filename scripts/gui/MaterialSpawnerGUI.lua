---@class MaterialSpawnerGUI
MaterialSpawnerGUI = {}

MaterialSpawnerGUI.PROFILES_FILENAME = g_currentModDirectory .. 'xml/guiProfiles.xml'

local MaterialSpawnerGUI_mt = Class(MaterialSpawnerGUI)

---@return MaterialSpawnerGUI
---@nodiscard
function MaterialSpawnerGUI.new()
    ---@type MaterialSpawnerGUI
    local self = setmetatable({}, MaterialSpawnerGUI_mt)

    if g_debugMaterialSpawner then
        addConsoleCommand('msReloadGui', '', 'consoleReloadGui', self)
    end

    return self
end

function MaterialSpawnerGUI:consoleReloadGui()
    self:reload()

    return 'GUI reloaded'
end

function MaterialSpawnerGUI:load()
    self:loadProfiles()
    self:loadDialogs()
end

function MaterialSpawnerGUI:delete()
    if g_materialSpawnerAreaDialog.isOpen then
        g_materialSpawnerAreaDialog:close()
    end

    if g_materialSpawnerDialog.isOpen then
        g_materialSpawnerDialog:close()
    end

    g_materialSpawnerAreaDialog:delete()
    g_materialSpawnerDialog:delete()
end

function MaterialSpawnerGUI:reload()
    local selectedPlaceable

    if g_materialSpawnerDialog.isOpen then
        selectedPlaceable = g_materialSpawnerDialog.placeable
    end

    self:delete()

    Logging.info('Reloading GUI ..')

    self:loadProfiles()
    self:loadDialogs()

    if selectedPlaceable ~= nil then
        g_materialSpawnerDialog:show(selectedPlaceable)
    end
end

function MaterialSpawnerGUI:loadProfiles()
    g_gui.currentlyReloading = true

    if not g_gui:loadProfiles(MaterialSpawnerGUI.PROFILES_FILENAME) then
        Logging.error('Failed to load profiles: %s', MaterialSpawnerGUI.PROFILES_FILENAME)
    end

    g_gui.currentlyReloading = false
end

function MaterialSpawnerGUI:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_materialSpawnerDialog = MaterialSpawnerDialog.new()
    g_materialSpawnerDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_materialSpawnerAreaDialog = MaterialSpawnerAreaDialog.new()
    g_materialSpawnerAreaDialog:load()
end
