--[[
    BorcaUIHub — Managers/SettingsManager.lua
    Mengatur semua setting global UI: blur, animasi, transparansi, skala, dll.
    Menjadi pusat kontrol untuk fitur-fitur umum yang mempengaruhi seluruh interface.
    Perubahan melalui SettingsManager berdampak ke seluruh sistem secara terpusat.
]]

local SettingsManager = {}

local Config     = require(script.Parent.Parent.UI.Config)
local Theme      = require(script.Parent.Parent.UI.Theme)
local ThemeManager = require(script.Parent.ThemeManager)

-- ============================================================
-- DEFAULT SETTINGS
-- ============================================================

local DEFAULTS = {
    -- Animasi
    AnimationsEnabled  = true,
    AnimationSpeed     = 1.0,       -- multiplier (0.5 = lambat, 2.0 = cepat)

    -- Blur
    BlurEnabled        = true,
    BlurIntensity      = 24,        -- 1-56

    -- Transparansi
    BackgroundAlpha    = 0,         -- transparansi background (0 = solid)
    CardAlpha          = 0,

    -- UI Scale
    UIScale            = 1.0,       -- 0.8 - 1.2
    CornerRadius       = 12,        -- pixel

    -- Notifikasi
    NotifEnabled       = true,
    NotifDuration      = 3.5,
    NotifPosition      = "BottomRight",
    NotifMaxVisible    = 4,

    -- Font
    FontFamily         = "Gotham",  -- nama font (untuk info saja)
    FontScale          = 1.0,

    -- Sidebar
    SidebarCollapsed   = false,

    -- Scroll
    ScrollBarVisible   = true,
    ScrollBarThickness = 3,

    -- Search
    SearchEnabled      = true,

    -- Save
    AutoSave           = true,
    AutoSaveInterval   = 30,

    -- Debug
    DebugMode          = false,
    ShowFPS            = false,
}

-- ============================================================
-- STATE
-- ============================================================

SettingsManager._settings  = {}
SettingsManager._listeners = {}   -- { key = {callbacks} }
SettingsManager._globalListeners = {}

-- Salin defaults ke state awal
for k, v in pairs(DEFAULTS) do
    SettingsManager._settings[k] = v
end

-- ============================================================
-- INIT
-- ============================================================

--[[
    SettingsManager.Init(savedSettings)
    Inisialisasi dengan settings yang dimuat dari SaveManager.

    @param savedSettings  table | nil
]]
function SettingsManager.Init(savedSettings)
    if type(savedSettings) == "table" then
        for k, v in pairs(savedSettings) do
            if DEFAULTS[k] ~= nil then
                SettingsManager._settings[k] = v
            end
        end
    end

    -- Terapkan semua setting ke sistem
    SettingsManager._ApplyAll()
end

-- ============================================================
-- GET / SET
-- ============================================================

--[[
    SettingsManager.Get(key) → any
    Ambil nilai setting.
]]
function SettingsManager.Get(key)
    local val = SettingsManager._settings[key]
    if val == nil then val = DEFAULTS[key] end
    return val
end

--[[
    SettingsManager.Set(key, value, silent)
    Ubah nilai setting dan terapkan ke sistem.

    @param key    string
    @param value  any
    @param silent boolean  -- jika true, tidak trigger listener
]]
function SettingsManager.Set(key, value, silent)
    if DEFAULTS[key] == nil then
        warn("[BorcaUIHub][SettingsManager] Key tidak dikenal: " .. tostring(key))
        return false
    end

    local old = SettingsManager._settings[key]
    SettingsManager._settings[key] = value

    -- Terapkan perubahan ke sistem yang relevan
    SettingsManager._Apply(key, value)

    if not silent then
        SettingsManager._Notify(key, value, old)
    end

    return true
end

--[[
    SettingsManager.Reset(key)
    Kembalikan satu setting ke nilai default.
]]
function SettingsManager.Reset(key)
    if key then
        SettingsManager.Set(key, DEFAULTS[key])
    else
        -- Reset semua
        for k, v in pairs(DEFAULTS) do
            SettingsManager._settings[k] = v
        end
        SettingsManager._ApplyAll()
        SettingsManager._NotifyAll()
    end
end

--[[
    SettingsManager.GetAll() → table
    Kembalikan salinan seluruh settings saat ini.
]]
function SettingsManager.GetAll()
    local copy = {}
    for k, v in pairs(SettingsManager._settings) do
        copy[k] = v
    end
    return copy
end

--[[
    SettingsManager.GetDefaults() → table
    Kembalikan nilai-nilai default.
]]
function SettingsManager.GetDefaults()
    local copy = {}
    for k, v in pairs(DEFAULTS) do
        copy[k] = v
    end
    return copy
end

-- ============================================================
-- APPLY LOGIC
-- Terapkan perubahan setting ke sistem yang relevan
-- ============================================================

function SettingsManager._Apply(key, value)
    if key == "AnimationsEnabled" then
        Config.Animation.Enabled = value

    elseif key == "AnimationSpeed" then
        Config.Animation.Speed = math.max(0.1, math.min(3.0, value))

    elseif key == "BlurEnabled" then
        Config.Blur.Enabled = value
        SettingsManager._ApplyBlur()

    elseif key == "BlurIntensity" then
        Config.Blur.Intensity = math.clamp(value, 1, 56)
        SettingsManager._ApplyBlur()

    elseif key == "BackgroundAlpha" then
        Config.Transparency.MainBackground = math.clamp(value, 0, 0.95)

    elseif key == "CornerRadius" then
        Config.UI.CornerRadius = math.clamp(value, 0, 24)

    elseif key == "NotifDuration" then
        Config.Notification.DisplayTime = value

    elseif key == "NotifPosition" then
        Config.Notification.Position = value

    elseif key == "NotifMaxVisible" then
        Config.Notification.MaxVisible = math.clamp(value, 1, 10)

    elseif key == "ScrollBarThickness" then
        Config.UI.ScrollBarThickness = value

    elseif key == "AutoSaveInterval" then
        Config.Save.AutoSaveInterval = value

    elseif key == "DebugMode" then
        Config.Flags.Debug = value

    elseif key == "ShowFPS" then
        Config.Flags.ShowFPS = value
    end
end

function SettingsManager._ApplyAll()
    for k, v in pairs(SettingsManager._settings) do
        pcall(SettingsManager._Apply, k, v)
    end
end

function SettingsManager._ApplyBlur()
    local blurRef = nil
    pcall(function()
        blurRef = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
    end)

    if not blurRef then return end

    local enabled   = SettingsManager._settings.BlurEnabled
    local intensity = SettingsManager._settings.BlurIntensity or 24

    local ts = game:GetService("TweenService")
    ts:Create(blurRef, TweenInfo.new(0.3), {
        Size = enabled and intensity or 0,
    }):Play()
end

-- ============================================================
-- LISTENERS
-- ============================================================

--[[
    SettingsManager.OnChanged(key, callback) → disconnectFn
    Daftarkan callback untuk perubahan satu setting tertentu.

    @param key      string
    @param callback function(newValue, oldValue)
]]
function SettingsManager.OnChanged(key, callback)
    if not SettingsManager._listeners[key] then
        SettingsManager._listeners[key] = {}
    end
    table.insert(SettingsManager._listeners[key], callback)

    return function()
        local list = SettingsManager._listeners[key]
        if not list then return end
        for i, cb in ipairs(list) do
            if cb == callback then
                table.remove(list, i)
                break
            end
        end
    end
end

--[[
    SettingsManager.OnAnyChanged(callback) → disconnectFn
    Callback dipanggil saat setting apapun berubah.

    @param callback  function(key, newValue, oldValue)
]]
function SettingsManager.OnAnyChanged(callback)
    table.insert(SettingsManager._globalListeners, callback)
    return function()
        for i, cb in ipairs(SettingsManager._globalListeners) do
            if cb == callback then
                table.remove(SettingsManager._globalListeners, i)
                break
            end
        end
    end
end

function SettingsManager._Notify(key, newVal, oldVal)
    -- Per-key listeners
    local list = SettingsManager._listeners[key]
    if list then
        for _, cb in ipairs(list) do
            pcall(cb, newVal, oldVal)
        end
    end
    -- Global listeners
    for _, cb in ipairs(SettingsManager._globalListeners) do
        pcall(cb, key, newVal, oldVal)
    end
end

function SettingsManager._NotifyAll()
    for key, val in pairs(SettingsManager._settings) do
        SettingsManager._Notify(key, val, val)
    end
end

-- ============================================================
-- PRESETS / PROFILES
-- ============================================================

SettingsManager._profiles = {
    Performance = {
        AnimationsEnabled  = false,
        BlurEnabled        = false,
        ScrollBarThickness = 2,
    },
    Aesthetic = {
        AnimationsEnabled  = true,
        AnimationSpeed     = 0.8,
        BlurEnabled        = true,
        BlurIntensity      = 32,
    },
    Minimal = {
        AnimationsEnabled  = true,
        AnimationSpeed     = 1.5,
        BlurEnabled        = false,
        CornerRadius       = 6,
    },
}

--[[
    SettingsManager.ApplyProfile(profileName)
    Terapkan profil settings preset.
]]
function SettingsManager.ApplyProfile(profileName)
    local profile = SettingsManager._profiles[profileName]
    if not profile then
        warn("[BorcaUIHub][SettingsManager] Profil tidak ditemukan: " .. tostring(profileName))
        return false
    end

    for k, v in pairs(profile) do
        SettingsManager.Set(k, v)
    end

    return true
end

--[[
    SettingsManager.AddProfile(name, settings)
    Tambah profil kustom.
]]
function SettingsManager.AddProfile(name, settings)
    SettingsManager._profiles[name] = settings
end

--[[
    SettingsManager.GetProfileNames() → {string}
]]
function SettingsManager.GetProfileNames()
    local names = {}
    for k, _ in pairs(SettingsManager._profiles) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

return SettingsManager
