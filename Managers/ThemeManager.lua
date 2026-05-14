--[[
    BorcaUIHub — Managers/ThemeManager.lua
    Pengatur perubahan warna real-time di seluruh UI.
    Menjadi jembatan antara Theme.lua dan semua komponen visual.
    Ketika accent color atau tema diganti, semua elemen yang terhubung ikut berubah.
]]

local ThemeManager = {}

local Theme  = require(script.Parent.Parent.UI.Theme)
local Config = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

ThemeManager._currentTheme  = "Dark"
ThemeManager._currentAccent = nil   -- Color3 | nil (nil = pakai preset default)
ThemeManager._listeners     = {}    -- { id = string, fn = function }
ThemeManager._listenerCount = 0

-- ============================================================
-- INIT
-- ============================================================

--[[
    ThemeManager.Init(savedTheme, savedAccent)
    Inisialisasi ThemeManager dengan tema dan accent yang tersimpan.
    Dipanggil oleh SaveManager saat memuat config.

    @param savedTheme   string | nil   -- nama preset
    @param savedAccent  string | nil   -- hex string accent (#RRGGBB)
]]
function ThemeManager.Init(savedTheme, savedAccent)
    if savedTheme and Theme.Presets[savedTheme] then
        ThemeManager.Apply(savedTheme, true)
    end

    if savedAccent then
        local ok, color = pcall(function()
            local hex = savedAccent:gsub("#", "")
            local r = tonumber(hex:sub(1,2), 16) / 255
            local g = tonumber(hex:sub(3,4), 16) / 255
            local b = tonumber(hex:sub(5,6), 16) / 255
            return Color3.new(r, g, b)
        end)
        if ok then
            ThemeManager.SetAccent(color, true)
        end
    end
end

-- ============================================================
-- THEME SWITCHING
-- ============================================================

--[[
    ThemeManager.Apply(themeName, silent)
    Terapkan preset tema ke seluruh UI.

    @param themeName  string   -- "Dark" | "Midnight" | "Light" | nama kustom
    @param silent     boolean  -- jika true, tidak trigger listener
]]
function ThemeManager.Apply(themeName, silent)
    if not Theme.Presets[themeName] then
        warn("[BorcaUIHub][ThemeManager] Tema tidak ditemukan: " .. tostring(themeName))
        return false
    end

    ThemeManager._currentTheme = themeName
    Theme.Set(themeName)

    -- Terapkan ulang accent kustom jika ada
    if ThemeManager._currentAccent then
        Theme.SetAccent(ThemeManager._currentAccent)
    end

    if not silent then
        ThemeManager._Notify("theme", themeName)
    end

    return true
end

--[[
    ThemeManager.Next()
    Rotasi ke tema berikutnya dalam daftar preset.
    Berguna untuk tombol cycle theme.
]]
function ThemeManager.Next()
    local names = Theme.GetPresetNames()
    local current = ThemeManager._currentTheme
    local nextTheme = names[1]

    for i, name in ipairs(names) do
        if name == current then
            nextTheme = names[i + 1] or names[1]
            break
        end
    end

    ThemeManager.Apply(nextTheme)
    return nextTheme
end

-- ============================================================
-- ACCENT COLOR
-- ============================================================

--[[
    ThemeManager.SetAccent(color, silent)
    Ubah warna accent secara real-time.
    Semua komponen yang menggunakan Theme.Get("Accent") akan ikut berubah.

    @param color   Color3
    @param silent  boolean
]]
function ThemeManager.SetAccent(color, silent)
    if typeof(color) ~= "Color3" then
        warn("[BorcaUIHub][ThemeManager] SetAccent membutuhkan Color3")
        return
    end

    ThemeManager._currentAccent = color
    Theme.SetAccent(color)

    if not silent then
        ThemeManager._Notify("accent", color)
    end
end

--[[
    ThemeManager.ResetAccent()
    Kembalikan warna accent ke default preset yang aktif.
]]
function ThemeManager.ResetAccent()
    ThemeManager._currentAccent = nil
    local preset = Theme.Presets[ThemeManager._currentTheme]
    if preset and preset.Accent then
        Theme.SetAccent(preset.Accent)
        ThemeManager._Notify("accent", preset.Accent)
    end
end

--[[
    ThemeManager.GetAccent() → Color3
    Kembalikan warna accent saat ini.
]]
function ThemeManager.GetAccent()
    return ThemeManager._currentAccent or Theme.Get("Accent")
end

-- ============================================================
-- OVERRIDE INDIVIDUAL COLOR
-- ============================================================

--[[
    ThemeManager.OverrideColor(key, color)
    Override satu warna saja tanpa mengganti tema.

    @param key    string
    @param color  Color3
]]
function ThemeManager.OverrideColor(key, color)
    Theme.Override(key, color)
    ThemeManager._Notify("override", { key = key, color = color })
end

-- ============================================================
-- CUSTOM PRESETS
-- ============================================================

--[[
    ThemeManager.AddPreset(name, colorTable)
    Tambahkan preset tema kustom.

    @param name        string
    @param colorTable  table  -- { Key = Color3, ... }
]]
function ThemeManager.AddPreset(name, colorTable)
    Theme.AddPreset(name, colorTable)
end

--[[
    ThemeManager.GetPresets() → {string}
    Kembalikan daftar semua nama preset.
]]
function ThemeManager.GetPresets()
    return Theme.GetPresetNames()
end

--[[
    ThemeManager.GetCurrentTheme() → string
    Nama tema yang sedang aktif.
]]
function ThemeManager.GetCurrentTheme()
    return ThemeManager._currentTheme
end

-- ============================================================
-- LISTENERS
-- ============================================================

--[[
    ThemeManager.OnChanged(callback) → disconnectFn
    Daftarkan callback yang dipanggil saat tema atau accent berubah.

    @param callback  function(changeType: string, value: any)
        changeType: "theme" | "accent" | "override"
    @return disconnectFn
]]
function ThemeManager.OnChanged(callback)
    ThemeManager._listenerCount += 1
    local id = "listener_" .. ThemeManager._listenerCount
    ThemeManager._listeners[id] = callback

    return function()
        ThemeManager._listeners[id] = nil
    end
end

function ThemeManager._Notify(changeType, value)
    for _, fn in pairs(ThemeManager._listeners) do
        pcall(fn, changeType, value)
    end
end

-- ============================================================
-- SERIALIZATION
-- ============================================================

--[[
    ThemeManager.Serialize() → table
    Kembalikan state tema saat ini dalam format yang bisa disimpan.
]]
function ThemeManager.Serialize()
    local accentHex = nil
    if ThemeManager._currentAccent then
        local c = ThemeManager._currentAccent
        accentHex = string.format("#%02X%02X%02X",
            math.floor(c.R * 255),
            math.floor(c.G * 255),
            math.floor(c.B * 255)
        )
    end

    return {
        theme  = ThemeManager._currentTheme,
        accent = accentHex,
    }
end

return ThemeManager
