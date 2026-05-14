--[[
    BorcaUIHub — Managers/SaveManager.lua

    FIX:
    - SaveManager.Init() TIDAK lagi memanggil ThemeManager.Init()
      (sebelumnya menyebabkan double init karena Loader juga memanggilnya)
    - SaveManager hanya baca + tulis data; Loader yang memutuskan kapan
      ThemeManager.Init() dipanggil menggunakan data dari SaveManager
    - Fungsi GetValue() ditambahkan untuk Loader bisa baca themeName & accentHex
]]

local SaveManager = {}

local Config = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

SaveManager._folder     = Config.Save.FolderName or "BorcaUIHub"
SaveManager._configName = Config.Save.DefaultConfig or "default.json"
SaveManager._data       = {}
SaveManager._components = {}
SaveManager._loaded     = false

-- ============================================================
-- FILE SYSTEM HELPERS
-- ============================================================

local function FileExists(path)
    local ok, result = pcall(function() return isfile(path) end)
    return ok and result
end

local function MakeFolder(path)
    pcall(function()
        if not isfolder(path) then makefolder(path) end
    end)
end

local function WriteFile(path, content)
    return pcall(function() writefile(path, content) end)
end

local function ReadFile(path)
    local ok, content = pcall(function() return readfile(path) end)
    return ok and content or nil
end

local function EncodeJSON(tbl)
    local function encode(val, depth)
        depth = depth or 0
        local t = type(val)
        if t == "nil" then return "null"
        elseif t == "boolean" then return val and "true" or "false"
        elseif t == "number"  then return tostring(val)
        elseif t == "string"  then
            val = val:gsub('\\','\\\\'):gsub('"','\\"')
                     :gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
            return '"' .. val .. '"'
        elseif t == "table" then
            local isArray = true
            local maxN = 0
            for k, _ in pairs(val) do
                if type(k) ~= "number" then isArray = false; break end
                if k > maxN then maxN = k end
            end
            isArray = isArray and maxN == #val
            local parts = {}
            if isArray then
                for _, v in ipairs(val) do table.insert(parts, encode(v, depth+1)) end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                for k, v in pairs(val) do
                    table.insert(parts, '"' .. tostring(k) .. '":' .. encode(v, depth+1))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
        return "null"
    end
    return encode(tbl)
end

local function DecodeJSON(str)
    if not str or str == "" then return {} end
    local fn, _ = loadstring("return " .. str)
    if fn then
        local ok, result = pcall(fn)
        if ok and type(result) == "table" then return result end
    end
    warn("[BorcaUIHub][SaveManager] Gagal decode JSON, menggunakan data kosong")
    return {}
end

-- ============================================================
-- INIT
-- FIX: TIDAK memanggil ThemeManager.Init() di sini
--      Loader yang bertanggung jawab memanggil ThemeManager.Init()
--      menggunakan data yang dibaca via SaveManager.GetValue()
-- ============================================================

function SaveManager.Init(options)
    options = options or {}

    if options.Folder     then SaveManager._folder     = options.Folder end
    if options.ConfigName then SaveManager._configName = options.ConfigName end

    MakeFolder(SaveManager._folder)
    SaveManager.Load()

    -- Auto-save
    local autoSave = options.AutoSave
    if autoSave == nil then autoSave = Config.Save.AutoSave end
    if autoSave then SaveManager._StartAutoSave() end

    -- FIX: DIHAPUS — SaveManager tidak lagi memanggil ThemeManager.Init()
    -- Sebelumnya:
    --   local themeData = SaveManager._data._theme
    --   if themeData then ThemeManager.Init(themeData.theme, themeData.accent) end
    -- Sekarang: Loader membaca via SaveManager.GetValue("_theme") sendiri

    SaveManager._loaded = true
end

-- ============================================================
-- COMPONENT REGISTRATION
-- ============================================================

function SaveManager.Register(id, getter, setter, defaultValue)
    SaveManager._components[id] = {
        getter  = getter,
        setter  = setter,
        default = defaultValue,
    }
    if SaveManager._data[id] ~= nil then
        pcall(setter, SaveManager._data[id])
    elseif defaultValue ~= nil then
        pcall(setter, defaultValue)
    end
end

function SaveManager.RegisterToggle(id, toggleObject, default)
    SaveManager.Register(
        id,
        function() return toggleObject.GetValue() end,
        function(v) toggleObject.SetValue(v, true) end,
        default or false
    )
end

function SaveManager.RegisterSlider(id, sliderObject, default)
    SaveManager.Register(
        id,
        function() return sliderObject.GetValue() end,
        function(v) sliderObject.SetValue(v, true) end,
        default or 50
    )
end

function SaveManager.RegisterDropdown(id, dropdownObject, default)
    SaveManager.Register(
        id,
        function() return dropdownObject.GetValue() end,
        function(v) dropdownObject.SetValue(v, true) end,
        default
    )
end

function SaveManager.RegisterInput(id, inputObject, default)
    SaveManager.Register(
        id,
        function() return inputObject.GetValue() end,
        function(v) inputObject.SetValue(v) end,
        default or ""
    )
end

-- ============================================================
-- SAVE / LOAD
-- ============================================================

function SaveManager.Save(configName)
    local fileName = configName or SaveManager._configName
    local path     = SaveManager._folder .. "/" .. fileName

    for id, comp in pairs(SaveManager._components) do
        local ok, val = pcall(comp.getter)
        if ok then SaveManager._data[id] = val end
    end

    -- Simpan state tema via ThemeManager jika tersedia
    local ok, ThemeManager = pcall(require, script.Parent.ThemeManager)
    if ok then
        SaveManager._data._theme = ThemeManager.Serialize()
    end

    local encoded = EncodeJSON(SaveManager._data)
    local writeOk, _ = WriteFile(path, encoded)
    return writeOk
end

function SaveManager.Load(configName)
    local fileName = configName or SaveManager._configName
    local path     = SaveManager._folder .. "/" .. fileName

    if not FileExists(path) then
        SaveManager._data = {}
        return false
    end

    local content = ReadFile(path)
    if not content then
        SaveManager._data = {}
        return false
    end

    SaveManager._data = DecodeJSON(content)

    for id, comp in pairs(SaveManager._components) do
        if SaveManager._data[id] ~= nil then
            pcall(comp.setter, SaveManager._data[id])
        end
    end

    return true
end

function SaveManager.Reset(configName)
    local fileName = configName or SaveManager._configName
    local path     = SaveManager._folder .. "/" .. fileName

    pcall(function()
        if FileExists(path) then writefile(path, "") end
    end)

    SaveManager._data = {}

    for _, comp in pairs(SaveManager._components) do
        if comp.default ~= nil then
            pcall(comp.setter, comp.default)
        end
    end
end

-- ============================================================
-- CONFIG PROFILES
-- ============================================================

function SaveManager.GetProfiles()
    local profiles = {}
    pcall(function()
        if not isfolder(SaveManager._folder) then return end
        for _, file in ipairs(listfiles(SaveManager._folder)) do
            local name = file:match("[^/\\]+$")
            if name and name:match("%.json$") then
                table.insert(profiles, name:gsub("%.json$", ""))
            end
        end
    end)
    return profiles
end

function SaveManager.SwitchProfile(profileName)
    SaveManager.Save()
    SaveManager._configName = profileName .. ".json"
    return SaveManager.Load()
end

-- ============================================================
-- RAW DATA ACCESS
-- ============================================================

function SaveManager.SetValue(key, value)
    SaveManager._data[key] = value
end

function SaveManager.GetValue(key, default)
    local val = SaveManager._data[key]
    if val == nil then return default end
    return val
end

-- ============================================================
-- AUTO SAVE
-- ============================================================

function SaveManager._StartAutoSave()
    local interval = Config.Save.AutoSaveInterval or 30
    task.spawn(function()
        while true do
            task.wait(interval)
            if SaveManager._loaded then
                SaveManager.Save()
            end
        end
    end)
end

-- ============================================================
-- STATUS
-- ============================================================

function SaveManager.IsLoaded()
    return SaveManager._loaded
end

function SaveManager.GetPath()
    return SaveManager._folder .. "/" .. SaveManager._configName
end

return SaveManager
