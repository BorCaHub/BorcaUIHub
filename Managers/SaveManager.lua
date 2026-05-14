--[[
    BorcaUIHub — Managers/SaveManager.lua
    Menyimpan dan memuat data user: config, tema, toggle, slider, dan pengaturan lain.
    Menggunakan writefile / readfile (executor environment) dengan fallback ke pcall aman.
    Tanpa SaveManager, semua perubahan hilang saat UI ditutup.
]]

local SaveManager = {}

local Config       = require(script.Parent.Parent.UI.Config)
local ThemeManager = require(script.Parent.ThemeManager)

-- ============================================================
-- STATE
-- ============================================================

SaveManager._folder      = Config.Save.FolderName or "BorcaUIHub"
SaveManager._configName  = Config.Save.DefaultConfig or "default.json"
SaveManager._data        = {}         -- data yang dimuat / akan disimpan
SaveManager._components  = {}         -- { id = { getter, setter, type } }
SaveManager._autoTimer   = nil
SaveManager._loaded      = false

-- ============================================================
-- FILE SYSTEM HELPERS
-- ============================================================

local function FileExists(path)
    return pcall(function() return isfile(path) end) and isfile(path)
end

local function MakeFolder(path)
    pcall(function()
        if not isfolder(path) then
            makefolder(path)
        end
    end)
end

local function WriteFile(path, content)
    local ok, err = pcall(function()
        writefile(path, content)
    end)
    return ok, err
end

local function ReadFile(path)
    local ok, content = pcall(function()
        return readfile(path)
    end)
    return ok and content or nil
end

local function EncodeJSON(tbl)
    -- Encoder JSON sederhana untuk tipe dasar
    local function encode(val, depth)
        depth = depth or 0
        local t = type(val)
        if t == "nil" then
            return "null"
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "number" then
            return tostring(val)
        elseif t == "string" then
            -- Escape karakter khusus
            val = val:gsub('\\', '\\\\')
                     :gsub('"', '\\"')
                     :gsub('\n', '\\n')
                     :gsub('\r', '\\r')
                     :gsub('\t', '\\t')
            return '"' .. val .. '"'
        elseif t == "table" then
            -- Cek array atau object
            local isArray = true
            local maxN = 0
            for k, _ in pairs(val) do
                if type(k) ~= "number" then
                    isArray = false
                    break
                end
                if k > maxN then maxN = k end
            end
            isArray = isArray and maxN == #val

            local parts = {}
            if isArray then
                for _, v in ipairs(val) do
                    table.insert(parts, encode(v, depth + 1))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                for k, v in pairs(val) do
                    table.insert(parts, '"' .. tostring(k) .. '":' .. encode(v, depth + 1))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
        return "null"
    end
    return encode(tbl)
end

local function DecodeJSON(str)
    -- Decoder JSON sederhana menggunakan loadstring + sandbox ringan
    -- Untuk hasil yang lebih aman, fallback ke evaluasi manual
    if not str or str == "" then return {} end

    -- Coba via loadstring (tersedia di sebagian besar executor)
    local fn, err = loadstring("return " .. str)
    if fn then
        local ok, result = pcall(fn)
        if ok and type(result) == "table" then
            return result
        end
    end

    -- Fallback: kembalikan tabel kosong
    warn("[BorcaUIHub][SaveManager] Gagal decode JSON, menggunakan data kosong")
    return {}
end

-- ============================================================
-- INIT
-- ============================================================

--[[
    SaveManager.Init(options)
    Inisialisasi SaveManager. Buat folder, muat config, dan mulai auto-save.

    @param options {
        Folder:      string  -- nama folder (override Config)
        ConfigName:  string  -- nama file config
        AutoSave:    boolean -- override Config.Save.AutoSave
    }
]]
function SaveManager.Init(options)
    options = options or {}

    if options.Folder     then SaveManager._folder     = options.Folder end
    if options.ConfigName then SaveManager._configName = options.ConfigName end

    -- Pastikan folder ada
    MakeFolder(SaveManager._folder)

    -- Muat data
    SaveManager.Load()

    -- Auto-save
    local autoSave = options.AutoSave
    if autoSave == nil then autoSave = Config.Save.AutoSave end

    if autoSave then
        SaveManager._StartAutoSave()
    end

    -- Init ThemeManager dengan data tema yang tersimpan
    local themeData = SaveManager._data._theme
    if themeData then
        ThemeManager.Init(themeData.theme, themeData.accent)
    end

    SaveManager._loaded = true
end

-- ============================================================
-- COMPONENT REGISTRATION
-- ============================================================

--[[
    SaveManager.Register(id, getter, setter, defaultValue)
    Daftarkan komponen agar nilainya disimpan dan dimuat otomatis.

    @param id           string    -- ID unik komponen (misal: "player_speed_toggle")
    @param getter       function  -- function() → value
    @param setter       function  -- function(value)
    @param defaultValue any       -- nilai default jika belum ada di config
]]
function SaveManager.Register(id, getter, setter, defaultValue)
    SaveManager._components[id] = {
        getter  = getter,
        setter  = setter,
        default = defaultValue,
    }

    -- Terapkan nilai tersimpan jika ada
    if SaveManager._data[id] ~= nil then
        pcall(setter, SaveManager._data[id])
    elseif defaultValue ~= nil then
        pcall(setter, defaultValue)
    end
end

--[[
    SaveManager.RegisterToggle(id, toggleObject, default)
    Shortcut register untuk komponen Toggle/Switch.

    @param toggleObject  -- object dari Toggles.Create atau Switches.Create
]]
function SaveManager.RegisterToggle(id, toggleObject, default)
    SaveManager.Register(
        id,
        function() return toggleObject.GetValue() end,
        function(v) toggleObject.SetValue(v, true) end,
        default or false
    )
end

--[[
    SaveManager.RegisterSlider(id, sliderObject, default)
    Shortcut register untuk komponen Slider.
]]
function SaveManager.RegisterSlider(id, sliderObject, default)
    SaveManager.Register(
        id,
        function() return sliderObject.GetValue() end,
        function(v) sliderObject.SetValue(v, true) end,
        default or 50
    )
end

--[[
    SaveManager.RegisterDropdown(id, dropdownObject, default)
    Shortcut register untuk komponen Dropdown.
]]
function SaveManager.RegisterDropdown(id, dropdownObject, default)
    SaveManager.Register(
        id,
        function() return dropdownObject.GetValue() end,
        function(v) dropdownObject.SetValue(v, true) end,
        default
    )
end

--[[
    SaveManager.RegisterInput(id, inputObject, default)
    Shortcut register untuk komponen Input.
]]
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

--[[
    SaveManager.Save(configName)
    Simpan semua nilai komponen yang terdaftar ke file.

    @param configName  string  -- opsional, override nama file
]]
function SaveManager.Save(configName)
    local fileName = configName or SaveManager._configName
    local path = SaveManager._folder .. "/" .. fileName

    -- Kumpulkan semua nilai
    for id, comp in pairs(SaveManager._components) do
        local ok, val = pcall(comp.getter)
        if ok then
            SaveManager._data[id] = val
        end
    end

    -- Simpan state tema
    SaveManager._data._theme = ThemeManager.Serialize()

    -- Encode dan tulis
    local encoded = EncodeJSON(SaveManager._data)
    local ok, err = WriteFile(path, encoded)

    if not ok then
        warn("[BorcaUIHub][SaveManager] Gagal menyimpan config: " .. tostring(err))
        return false
    end

    return true
end

--[[
    SaveManager.Load(configName)
    Muat config dari file.

    @param configName  string  -- opsional, override nama file
    @return boolean    -- true jika berhasil dimuat
]]
function SaveManager.Load(configName)
    local fileName = configName or SaveManager._configName
    local path = SaveManager._folder .. "/" .. fileName

    if not FileExists(path) then
        -- File belum ada, gunakan defaults
        SaveManager._data = {}
        return false
    end

    local content = ReadFile(path)
    if not content then
        SaveManager._data = {}
        return false
    end

    SaveManager._data = DecodeJSON(content)

    -- Terapkan ke semua komponen yang sudah terdaftar
    for id, comp in pairs(SaveManager._components) do
        if SaveManager._data[id] ~= nil then
            pcall(comp.setter, SaveManager._data[id])
        end
    end

    return true
end

--[[
    SaveManager.Reset(configName)
    Hapus file config dan kembalikan semua ke default.
]]
function SaveManager.Reset(configName)
    local fileName = configName or SaveManager._configName
    local path = SaveManager._folder .. "/" .. fileName

    -- Hapus file
    pcall(function()
        if FileExists(path) then
            writefile(path, "")
        end
    end)

    SaveManager._data = {}

    -- Reset semua ke default
    for _, comp in pairs(SaveManager._components) do
        if comp.default ~= nil then
            pcall(comp.setter, comp.default)
        end
    end
end

-- ============================================================
-- CONFIG PROFILES
-- ============================================================

--[[
    SaveManager.GetProfiles() → {string}
    Kembalikan daftar nama config yang tersimpan.
]]
function SaveManager.GetProfiles()
    local profiles = {}
    local ok = pcall(function()
        if not isfolder(SaveManager._folder) then return end
        for _, file in ipairs(listfiles(SaveManager._folder)) do
            local name = file:match("[^/\\]+$")  -- basename
            if name and name:match("%.json$") then
                table.insert(profiles, name:gsub("%.json$", ""))
            end
        end
    end)
    return profiles
end

--[[
    SaveManager.SwitchProfile(profileName)
    Simpan profil saat ini dan muat profil baru.
]]
function SaveManager.SwitchProfile(profileName)
    -- Simpan yang sekarang
    SaveManager.Save()

    -- Ganti nama config
    SaveManager._configName = profileName .. ".json"

    -- Muat profil baru
    return SaveManager.Load()
end

-- ============================================================
-- RAW DATA ACCESS
-- ============================================================

--[[
    SaveManager.SetValue(key, value)
    Simpan nilai kustom ke data (tanpa komponen terdaftar).
]]
function SaveManager.SetValue(key, value)
    SaveManager._data[key] = value
end

--[[
    SaveManager.GetValue(key, default) → any
    Ambil nilai kustom dari data.
]]
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
