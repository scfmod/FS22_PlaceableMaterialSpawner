---@class MaterialSpawnerUtils
MaterialSpawnerUtils = {}

---@param placeable PlaceableMaterialSpawner
---@param str string | nil
---@param default string
---@return string
---@nodiscard
function MaterialSpawnerUtils.getPlaceableText(placeable, str, default)
    if str ~= nil then
        if str:startsWith('$l10n_') then
            str = str:sub(7)

            local i18n = g_i18n.modEnvironments[placeable.customEnvironment]

            if i18n ~= nil and i18n.texts[str] ~= nil then
                return i18n.texts[str]
            end

            return g_i18n:getText(str)
        end

        return str
    end

    return default
end

---@param value number
---@return string
---@nodiscard
function MaterialSpawnerUtils.formatNumber(value)
    local str = string.format("%d", math.floor(value))
    local pos = string.len(str) % 3

    if pos == 0 then
        pos = 3
    end

    return string.sub(str, 1, pos) .. string.gsub(string.sub(str, pos + 1), "(...)", ",%1")
end

---@param xmlFile XMLFile
---@param key string
---@return FillTypeObject[]
---@nodiscard
function MaterialSpawnerUtils.loadFillTypesFromXML(xmlFile, key)
    local str = xmlFile:getValue(key)

    ---@type FillTypeObject[]
    local fillTypes = {}

    if str ~= nil then
        ---@type string[]
        local fillTypeNames = string.split(str, ' ')
        ---@type table<number, boolean>
        local registered = {}

        for _, name in ipairs(fillTypeNames) do
            name = name:upper()

            ---@type FillTypeObject | nil
            local fillType = g_fillTypeManager.nameToFillType[name]

            if fillType ~= nil and registered[fillType.index] ~= true then
                table.insert(fillTypes, fillType)
                registered[fillType.index] = true
            end
        end
    end

    return fillTypes
end
