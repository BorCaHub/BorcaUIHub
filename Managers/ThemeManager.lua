--[[
    BorcaUIHub — Managers/ThemeManager.lua

    FIX (Fix 7):
    - Tambah flag _initialized: Init() hanya jalan sekali
    - Cegah double-init dari SaveManager.Init() lalu Loader.Init() (dua kali)
      SEBELUMNYA: Init() bisa dipanggil 2x → listener fire 2x, UI state kacau
      SEKARANG:   Panggilan kedua hanya apply tema/accent tanpa reset listener
    - Listeners tidak lagi fire dua kali untuk set tema/accent yang sama
]]

local ThemeManager = {}

local Theme  = require(script.Parent.Parent.UI.Theme)
local Config = require(script.Parent.Parent.UI.Config)

-- ============================================================
-- STATE
-- ============================================================

ThemeManager._currentTheme  = "Dark"
ThemeManager._currentAccent = nil
ThemeManager._listeners     = {}
ThemeManager._listenerCount = 0

-- FIX (Fix 7): flag untuk cegah double init
-- SEBELUMNYA: tidak ada guard → Init() bisa jalan berkali-kali
-- SEKARANG:   _initialized = true setelah pertama kali init
ThemeManager._initialized = false

-- ============================================================
-- INIT
--
-- FIX (Fix 7): Hanya jalankan penuh sekali
-- Panggilan kedua (dari Loader setelah SaveManager) hanya apply
-- tema/accent yang diberikan tanpa reset listener yang sudah ada
-- ============================================================

function ThemeManager.Init(savedTheme, savedAccent)

    if ThemeManager._initialized then
        -- FIX: sudah pernah init — hanya apply ulang tanpa reset
        -- Ini mencegah listener dihapus lalu semua OnChanged jadi tidak bekerja
        if savedTheme and Theme.Presets[savedTheme] then
            ThemeManager.Apply(savedTheme, true)  -- silent = tidak fire listener
        end
        if savedAccent then
            local ok, color = pcall(function()
                local hex = savedAccent:gsub("#", "")
                return Color3.new(
                    tonumber(hex:sub(1,2), 16) / 255,
                    tonumber(hex:sub(3,4), 16) / 255,
                    tonumber(hex:sub(5,6), 16) / 255
                )
            end)
            if ok then ThemeManager.SetAccent(color, true) end  -- silent
        end
        return
    end

    -- Pertama kali init — set flag lalu lanjutkan
    ThemeManager._initialized = true

    if savedTheme and Theme.Presets[savedTheme] then
        ThemeManager.Apply(savedTheme, true)
    end

    if savedAccent then
        local ok, color = pcall(function()
            local hex = savedAccent:gsub("#", "")
            return Color3.new(
                tonumber(hex:sub(1,2), 16) / 255,
                tonumber(hex:sub(3,4), 16) / 255,
                tonumber(hex:sub(5,6), 16) / 255
            )
        end)
        if ok then ThemeManager.SetAccent(color, true) end
    end
end

-- ============================================================
-- THEME SWITCHING
-- ============================================================

function ThemeManager.Apply(themeName, silent)
    if not Theme.Presets[themeName] then
        warn("[BorcaUIHub][ThemeManager] Tema tidak ditemukan: " .. tostring(themeName))
        return false
    end

    ThemeManager._currentTheme = themeName
    Theme.Set(themeName)

    -- Re-apply accent jika sudah ada custom accent
    if ThemeManager._currentAccent then
        Theme.SetAccent(ThemeManager._currentAccent)
    end

    if not silent then
        ThemeManager._Notify("theme", themeName)
    end

    return true
end

function ThemeManager.Next()
    local names   = Theme.GetPresetNames()
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

function ThemeManager.ResetAccent()
    ThemeManager._currentAccent = nil
    local preset = Theme.Presets[ThemeManager._currentTheme]
    if preset and preset.Accent then
        Theme.SetAccent(preset.Accent)
        ThemeManager._Notify("accent", preset.Accent)
    end
end

function ThemeManager.GetAccent()
    return ThemeManager._currentAccent or Theme.Get("Accent")
end

-- ============================================================
-- OVERRIDE
-- ============================================================

function ThemeManager.OverrideColor(key, color)
    Theme.Override(key, color)
    ThemeManager._Notify("override", { key = key, color = color })
end

-- ============================================================
-- CUSTOM PRESETS
-- ============================================================

function ThemeManager.AddPreset(name, colorTable)
    Theme.AddPreset(name, colorTable)
end

function ThemeManager.GetPresets()
    return Theme.GetPresetNames()
end

function ThemeManager.GetCurrentTheme()
    return ThemeManager._currentTheme
end

-- ============================================================
-- LISTENERS
-- ============================================================

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

-- ============================================================
-- RESET (untuk testing / logout)
-- FIX: Reset juga mengosongkan _initialized agar bisa init ulang
-- ============================================================

function ThemeManager.Reset()
    ThemeManager._initialized   = false   -- FIX: izinkan init ulang setelah reset
    ThemeManager._currentTheme  = "Dark"
    ThemeManager._currentAccent = nil
    ThemeManager._listeners     = {}
    ThemeManager._listenerCount = 0
end

return ThemeManager
