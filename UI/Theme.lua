--[[
    BorcaUIHub — UI/Theme.lua
    Pusat warna seluruh UI. Semua elemen visual mengambil warna dari sini.
    Mendukung multiple tema dan perubahan accent real-time.
]]

local Theme = {}

-- ============================================================
-- PRESET TEMA
-- Setiap preset adalah tabel warna lengkap.
-- Warna disimpan sebagai Color3 agar langsung bisa dipakai.
-- ============================================================

Theme.Presets = {

    -- ── DARK (default) ──────────────────────────────────────
    Dark = {
        -- Backgrounds
        Background        = Color3.fromRGB(15, 15, 20),
        HeaderBackground  = Color3.fromRGB(20, 20, 28),
        SidebarBackground = Color3.fromRGB(18, 18, 25),
        ContentBackground = Color3.fromRGB(15, 15, 20),
        CardBackground    = Color3.fromRGB(22, 22, 32),
        InputBackground   = Color3.fromRGB(25, 25, 36),
        ModalBackground   = Color3.fromRGB(20, 20, 30),

        -- Accent (bisa diubah real-time oleh ColorPicker)
        Accent            = Color3.fromRGB(100, 160, 255),
        AccentHover       = Color3.fromRGB(130, 185, 255),
        AccentDim         = Color3.fromRGB(60, 100, 180),
        AccentGlow        = Color3.fromRGB(80, 130, 220),

        -- Text
        TextPrimary       = Color3.fromRGB(235, 235, 245),
        TextSecondary     = Color3.fromRGB(140, 140, 165),
        TextDisabled      = Color3.fromRGB(75, 75, 95),
        TextAccent        = Color3.fromRGB(100, 160, 255),

        -- Buttons
        ButtonPrimary     = Color3.fromRGB(100, 160, 255),
        ButtonSecondary   = Color3.fromRGB(35, 35, 50),
        ButtonHover       = Color3.fromRGB(45, 45, 65),
        ButtonActive      = Color3.fromRGB(30, 30, 45),
        CloseButton       = Color3.fromRGB(180, 60, 60),

        -- Borders / Strokes
        Stroke            = Color3.fromRGB(45, 45, 65),
        StrokeLight       = Color3.fromRGB(60, 60, 85),
        StrokeAccent      = Color3.fromRGB(100, 160, 255),

        -- States
        Success           = Color3.fromRGB(80, 200, 120),
        Warning           = Color3.fromRGB(255, 190, 70),
        Error             = Color3.fromRGB(220, 80, 80),
        Info              = Color3.fromRGB(80, 160, 240),

        -- Toggle / Slider
        ToggleOff         = Color3.fromRGB(45, 45, 65),
        ToggleOn          = Color3.fromRGB(100, 160, 255),
        ToggleThumb       = Color3.fromRGB(220, 220, 235),
        SliderTrack       = Color3.fromRGB(35, 35, 50),
        SliderFill        = Color3.fromRGB(100, 160, 255),
        SliderThumb       = Color3.fromRGB(255, 255, 255),

        -- Scrollbar
        ScrollbarTrack    = Color3.fromRGB(25, 25, 38),
        ScrollbarThumb    = Color3.fromRGB(70, 70, 100),

        -- Notifications
        NotifBackground   = Color3.fromRGB(22, 22, 32),
        NotifBorder       = Color3.fromRGB(100, 160, 255),

        -- Misc
        Separator         = Color3.fromRGB(35, 35, 52),
        Overlay           = Color3.fromRGB(0, 0, 0),   -- untuk modal dimming
        Shadow            = Color3.fromRGB(0, 0, 0),
    },

    -- ── MIDNIGHT ────────────────────────────────────────────
    Midnight = {
        Background        = Color3.fromRGB(8, 8, 16),
        HeaderBackground  = Color3.fromRGB(12, 12, 22),
        SidebarBackground = Color3.fromRGB(10, 10, 18),
        ContentBackground = Color3.fromRGB(8, 8, 16),
        CardBackground    = Color3.fromRGB(14, 14, 26),
        InputBackground   = Color3.fromRGB(16, 16, 30),
        ModalBackground   = Color3.fromRGB(12, 12, 24),

        Accent            = Color3.fromRGB(180, 100, 255),
        AccentHover       = Color3.fromRGB(200, 130, 255),
        AccentDim         = Color3.fromRGB(120, 60, 200),
        AccentGlow        = Color3.fromRGB(150, 80, 230),

        TextPrimary       = Color3.fromRGB(230, 230, 245),
        TextSecondary     = Color3.fromRGB(130, 120, 165),
        TextDisabled      = Color3.fromRGB(65, 60, 90),
        TextAccent        = Color3.fromRGB(180, 100, 255),

        ButtonPrimary     = Color3.fromRGB(180, 100, 255),
        ButtonSecondary   = Color3.fromRGB(25, 20, 45),
        ButtonHover       = Color3.fromRGB(35, 28, 60),
        ButtonActive      = Color3.fromRGB(22, 18, 40),
        CloseButton       = Color3.fromRGB(180, 60, 60),

        Stroke            = Color3.fromRGB(35, 30, 60),
        StrokeLight       = Color3.fromRGB(50, 44, 80),
        StrokeAccent      = Color3.fromRGB(180, 100, 255),

        Success           = Color3.fromRGB(80, 200, 120),
        Warning           = Color3.fromRGB(255, 190, 70),
        Error             = Color3.fromRGB(220, 80, 80),
        Info              = Color3.fromRGB(80, 160, 240),

        ToggleOff         = Color3.fromRGB(35, 30, 60),
        ToggleOn          = Color3.fromRGB(180, 100, 255),
        ToggleThumb       = Color3.fromRGB(220, 210, 235),
        SliderTrack       = Color3.fromRGB(25, 20, 48),
        SliderFill        = Color3.fromRGB(180, 100, 255),
        SliderThumb       = Color3.fromRGB(255, 255, 255),

        ScrollbarTrack    = Color3.fromRGB(14, 12, 28),
        ScrollbarThumb    = Color3.fromRGB(80, 60, 120),

        NotifBackground   = Color3.fromRGB(14, 14, 26),
        NotifBorder       = Color3.fromRGB(180, 100, 255),

        Separator         = Color3.fromRGB(28, 24, 50),
        Overlay           = Color3.fromRGB(0, 0, 0),
        Shadow            = Color3.fromRGB(0, 0, 0),
    },

    -- ── LIGHT ───────────────────────────────────────────────
    Light = {
        Background        = Color3.fromRGB(245, 245, 252),
        HeaderBackground  = Color3.fromRGB(255, 255, 255),
        SidebarBackground = Color3.fromRGB(238, 238, 248),
        ContentBackground = Color3.fromRGB(245, 245, 252),
        CardBackground    = Color3.fromRGB(255, 255, 255),
        InputBackground   = Color3.fromRGB(235, 235, 248),
        ModalBackground   = Color3.fromRGB(255, 255, 255),

        Accent            = Color3.fromRGB(70, 130, 230),
        AccentHover       = Color3.fromRGB(50, 110, 210),
        AccentDim         = Color3.fromRGB(100, 155, 245),
        AccentGlow        = Color3.fromRGB(80, 140, 235),

        TextPrimary       = Color3.fromRGB(25, 25, 40),
        TextSecondary     = Color3.fromRGB(100, 100, 130),
        TextDisabled      = Color3.fromRGB(170, 170, 195),
        TextAccent        = Color3.fromRGB(70, 130, 230),

        ButtonPrimary     = Color3.fromRGB(70, 130, 230),
        ButtonSecondary   = Color3.fromRGB(225, 225, 240),
        ButtonHover       = Color3.fromRGB(215, 215, 235),
        ButtonActive      = Color3.fromRGB(205, 205, 228),
        CloseButton       = Color3.fromRGB(220, 70, 70),

        Stroke            = Color3.fromRGB(210, 210, 228),
        StrokeLight       = Color3.fromRGB(225, 225, 240),
        StrokeAccent      = Color3.fromRGB(70, 130, 230),

        Success           = Color3.fromRGB(45, 170, 90),
        Warning           = Color3.fromRGB(210, 150, 30),
        Error             = Color3.fromRGB(200, 60, 60),
        Info              = Color3.fromRGB(50, 130, 210),

        ToggleOff         = Color3.fromRGB(200, 200, 220),
        ToggleOn          = Color3.fromRGB(70, 130, 230),
        ToggleThumb       = Color3.fromRGB(255, 255, 255),
        SliderTrack       = Color3.fromRGB(215, 215, 235),
        SliderFill        = Color3.fromRGB(70, 130, 230),
        SliderThumb       = Color3.fromRGB(255, 255, 255),

        ScrollbarTrack    = Color3.fromRGB(230, 230, 245),
        ScrollbarThumb    = Color3.fromRGB(170, 170, 200),

        NotifBackground   = Color3.fromRGB(255, 255, 255),
        NotifBorder       = Color3.fromRGB(70, 130, 230),

        Separator         = Color3.fromRGB(220, 220, 238),
        Overlay           = Color3.fromRGB(30, 30, 50),
        Shadow            = Color3.fromRGB(50, 50, 80),
    },
}

-- ============================================================
-- STATE AKTIF
-- ============================================================

Theme._active     = "Dark"
Theme._current    = {}
Theme._listeners  = {}  -- callback yang dipanggil saat tema berubah

-- Salin preset aktif ke _current saat modul dimuat
for k, v in pairs(Theme.Presets.Dark) do
    Theme._current[k] = v
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Theme.Get(key) → Color3
    Ambil warna berdasarkan key. Ini fungsi paling sering dipanggil.
    
    Contoh: Theme.Get("Accent") → Color3.fromRGB(100, 160, 255)
]]
function Theme.Get(key)
    local color = Theme._current[key]
    if not color then
        warn("[BorcaUIHub][Theme] Key tidak ditemukan: " .. tostring(key))
        return Color3.fromRGB(255, 0, 255)  -- magenta sebagai indikator error
    end
    return color
end

--[[
    Theme.Set(presetName)
    Ganti seluruh tema ke preset yang tersedia.
    Semua listener akan dipanggil setelah perubahan.
    
    @param presetName  "Dark" | "Midnight" | "Light"
]]
function Theme.Set(presetName)
    local preset = Theme.Presets[presetName]
    if not preset then
        warn("[BorcaUIHub][Theme] Preset tidak ditemukan: " .. tostring(presetName))
        return
    end
    Theme._active = presetName
    for k, v in pairs(preset) do
        Theme._current[k] = v
    end
    Theme._NotifyListeners()
end

--[[
    Theme.SetAccent(color)
    Override warna accent saja tanpa mengganti seluruh preset.
    Sangat berguna untuk ColorPicker.
    
    @param color  Color3
]]
function Theme.SetAccent(color)
    if typeof(color) ~= "Color3" then
        warn("[BorcaUIHub][Theme] SetAccent membutuhkan Color3")
        return
    end
    Theme._current.Accent         = color
    Theme._current.AccentHover    = Color3.new(
        math.min(color.R + 0.1, 1),
        math.min(color.G + 0.1, 1),
        math.min(color.B + 0.1, 1)
    )
    Theme._current.AccentDim      = Color3.new(
        math.max(color.R - 0.15, 0),
        math.max(color.G - 0.15, 0),
        math.max(color.B - 0.15, 0)
    )
    Theme._current.TextAccent     = color
    Theme._current.ToggleOn       = color
    Theme._current.SliderFill     = color
    Theme._current.ButtonPrimary  = color
    Theme._current.StrokeAccent   = color
    Theme._current.NotifBorder    = color
    Theme._current.AccentGlow     = Color3.new(
        math.max(color.R - 0.05, 0),
        math.max(color.G - 0.05, 0),
        math.max(color.B - 0.05, 0)
    )
    Theme._NotifyListeners()
end

--[[
    Theme.Override(key, color)
    Override satu warna saja secara manual.
    
    @param key    string   -- nama warna (contoh: "CardBackground")
    @param color  Color3
]]
function Theme.Override(key, color)
    if typeof(color) ~= "Color3" then
        warn("[BorcaUIHub][Theme] Override membutuhkan Color3")
        return
    end
    Theme._current[key] = color
    Theme._NotifyListeners()
end

--[[
    Theme.GetPresetNames() → {string}
    Mengembalikan daftar nama preset yang tersedia.
]]
function Theme.GetPresetNames()
    local names = {}
    for name, _ in pairs(Theme.Presets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--[[
    Theme.GetActiveName() → string
    Mengembalikan nama preset yang sedang aktif.
]]
function Theme.GetActiveName()
    return Theme._active
end

--[[
    Theme.GetAll() → table
    Mengembalikan salinan tabel warna saat ini (untuk serialisasi).
]]
function Theme.GetAll()
    local copy = {}
    for k, v in pairs(Theme._current) do
        copy[k] = v
    end
    return copy
end

--[[
    Theme.OnChanged(callback)
    Daftarkan callback yang dipanggil setiap kali tema berubah.
    Digunakan oleh ThemeManager untuk update UI secara real-time.
    
    @param callback  function(changedColors: table)
    @return disconnectFn  -- panggil untuk hentikan listener
]]
function Theme.OnChanged(callback)
    if type(callback) ~= "function" then
        warn("[BorcaUIHub][Theme] OnChanged membutuhkan function")
        return function() end
    end
    table.insert(Theme._listeners, callback)
    return function()
        for i, cb in ipairs(Theme._listeners) do
            if cb == callback then
                table.remove(Theme._listeners, i)
                break
            end
        end
    end
end

-- Internal: notify semua listener
function Theme._NotifyListeners()
    local snapshot = Theme.GetAll()
    for _, cb in ipairs(Theme._listeners) do
        pcall(cb, snapshot)
    end
end

--[[
    Theme.AddPreset(name, colorTable)
    Tambahkan preset kustom dari luar modul.
    Berguna jika script hub ingin menambahkan tema unik per game.
    
    @param name       string
    @param colorTable table  -- tabel Color3 dengan key yang sama seperti preset bawaan
]]
function Theme.AddPreset(name, colorTable)
    if type(name) ~= "string" or type(colorTable) ~= "table" then
        warn("[BorcaUIHub][Theme] AddPreset: parameter tidak valid")
        return
    end
    -- Isi key yang tidak ada dengan fallback dari Dark preset
    local filled = {}
    for k, v in pairs(Theme.Presets.Dark) do
        filled[k] = colorTable[k] or v
    end
    Theme.Presets[name] = filled
end

return Theme
