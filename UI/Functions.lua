--[[
    BorcaUIHub — UI/Functions.lua
    Kumpulan helper yang dipakai ulang di seluruh komponen.
    Tujuan: menghindari duplikasi kode dan menjaga konsistensi visual.

    FIX (Bug 1):
    - Tambah Functions.Create(className, properties, parent)
      SEBELUMNYA: tidak ada → Loading.lua, Modals.lua, Notifications.lua,
                  Tooltips.lua, SearchBar.lua, Cards.lua, Separators.lua crash
                  saat dipanggil karena fungsi ini nil
      SEKARANG:   ada dan konsisten dengan pola Instance.new Roblox
    - Tambah Functions.Tween(instance, goals, duration, style, direction)
      SEBELUMNYA: tidak ada → semua modul overlay tidak bisa membuat animasi
      SEKARANG:   shortcut TweenService:Create(...):Play() yang aman
    - Tambah Functions.SafeCall(fn, ...)
      SEBELUMNYA: tidak ada → Modals.lua, Notifications.lua crash saat callback
      SEKARANG:   wrapper pcall yang mengembalikan ok, result
    - Tambah Functions.TableRemove(tbl, value)
      SEBELUMNYA: tidak ada → Notifications.lua crash saat dismiss notif
      SEKARANG:   hapus value dari array (bukan index)
    - Tambah Functions.Trim(str)
      SEBELUMNYA: tidak ada → FeedbackUI.lua, BugReport.lua, SuggestionReport.lua crash
      SEKARANG:   strip whitespace di awal dan akhir string
    - Tambah Functions.ParentGui(gui)
      SEBELUMNYA: tidak ada → Notifications.lua crash saat ensureGui()
      SEKARANG:   coba CoreGui dulu, fallback ke PlayerGui
]]

local Functions = {}

local Theme = require(script.Parent.Theme)
local Config = require(script.Parent.Config)

-- ============================================================
-- INSTANCE CREATION HELPERS
-- ============================================================

--[[
    Functions.CreateFrame(options) → Frame
    Buat Frame dengan shortcut property lengkap.

    @param options {
        Name, Parent, Size, Position, AnchorPoint,
        BackgroundColor, BackgroundTransparency,
        CornerRadius, ClipDescendants, ZIndex,
        LayoutOrder, Visible
    }
]]
function Functions.CreateFrame(options)
    local frame = Instance.new("Frame")
    frame.Name                   = options.Name or "Frame"
    frame.Parent                 = options.Parent
    frame.Size                   = options.Size or UDim2.new(1, 0, 1, 0)
    frame.Position               = options.Position or UDim2.new(0, 0, 0, 0)
    frame.AnchorPoint            = options.AnchorPoint or Vector2.new(0, 0)
    frame.BackgroundColor3       = options.BackgroundColor or Theme.Get("CardBackground")
    frame.BackgroundTransparency = options.BackgroundTransparency or 0
    frame.ClipDescendants        = options.ClipDescendants or false
    frame.ZIndex                 = options.ZIndex or 1
    frame.LayoutOrder            = options.LayoutOrder or 0
    frame.Visible                = options.Visible ~= nil and options.Visible or true
    frame.BorderSizePixel        = 0

    if options.CornerRadius then
        Functions.ApplyCorner(frame, options.CornerRadius)
    end

    return frame
end

--[[
    Functions.CreateLabel(options) → TextLabel
    Buat TextLabel dengan property umum.
]]
function Functions.CreateLabel(options)
    local label = Instance.new("TextLabel")
    label.Name                    = options.Name or "Label"
    label.Parent                  = options.Parent
    label.Size                    = options.Size or UDim2.new(1, 0, 0, 20)
    label.Position                = options.Position or UDim2.new(0, 0, 0, 0)
    label.AnchorPoint             = options.AnchorPoint or Vector2.new(0, 0)
    label.Text                    = options.Text or ""
    label.Font                    = options.Font or Config.Font.Body
    label.TextSize                = options.TextSize or Config.Font.Size.ComponentLabel
    label.TextColor3              = options.TextColor or Theme.Get("TextPrimary")
    label.BackgroundTransparency  = 1
    label.TextXAlignment          = options.TextXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment          = options.TextYAlignment or Enum.TextYAlignment.Center
    label.TextTruncate            = options.TextTruncate or Enum.TextTruncate.None
    label.RichText                = options.RichText or false
    label.ZIndex                  = options.ZIndex or 2
    label.LayoutOrder             = options.LayoutOrder or 0
    label.Visible                 = options.Visible ~= nil and options.Visible or true

    return label
end

--[[
    Functions.CreateButton(options) → TextButton
    Buat TextButton yang siap dipakai.
]]
function Functions.CreateButton(options)
    local btn = Instance.new("TextButton")
    btn.Name                    = options.Name or "Button"
    btn.Parent                  = options.Parent
    btn.Size                    = options.Size or UDim2.new(0, 120, 0, 36)
    btn.Position                = options.Position or UDim2.new(0, 0, 0, 0)
    btn.AnchorPoint             = options.AnchorPoint or Vector2.new(0, 0)
    btn.Text                    = options.Text or ""
    btn.Font                    = options.Font or Config.Font.Body
    btn.TextSize                = options.TextSize or Config.Font.Size.ComponentLabel
    btn.TextColor3              = options.TextColor or Theme.Get("TextPrimary")
    btn.BackgroundColor3        = options.BackgroundColor or Theme.Get("ButtonSecondary")
    btn.BackgroundTransparency  = options.BackgroundTransparency or 0
    btn.AutoButtonColor         = false
    btn.ZIndex                  = options.ZIndex or 2
    btn.LayoutOrder             = options.LayoutOrder or 0
    btn.Visible                 = options.Visible ~= nil and options.Visible or true
    btn.BorderSizePixel         = 0

    if options.CornerRadius then
        Functions.ApplyCorner(btn, options.CornerRadius)
    end

    return btn
end

--[[
    Functions.CreateTextBox(options) → TextBox
    Buat TextBox dengan styling yang konsisten.
]]
function Functions.CreateTextBox(options)
    local box = Instance.new("TextBox")
    box.Name                    = options.Name or "TextBox"
    box.Parent                  = options.Parent
    box.Size                    = options.Size or UDim2.new(1, 0, 0, 36)
    box.Position                = options.Position or UDim2.new(0, 0, 0, 0)
    box.AnchorPoint             = options.AnchorPoint or Vector2.new(0, 0)
    box.PlaceholderText         = options.PlaceholderText or ""
    box.PlaceholderColor3       = options.PlaceholderColor or Theme.Get("TextDisabled")
    box.Text                    = options.Text or ""
    box.Font                    = options.Font or Config.Font.Body
    box.TextSize                = options.TextSize or Config.Font.Size.ComponentLabel
    box.TextColor3              = options.TextColor or Theme.Get("TextPrimary")
    box.BackgroundColor3        = options.BackgroundColor or Theme.Get("InputBackground")
    box.BackgroundTransparency  = 0
    box.TextXAlignment          = options.TextXAlignment or Enum.TextXAlignment.Left
    box.ClearTextOnFocus        = options.ClearTextOnFocus or false
    box.MultiLine               = options.MultiLine or false
    box.ZIndex                  = options.ZIndex or 2
    box.Visible                 = options.Visible ~= nil and options.Visible or true
    box.BorderSizePixel         = 0

    if options.CornerRadius then
        Functions.ApplyCorner(box, options.CornerRadius)
    end

    -- Padding teks dalam textbox
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft  = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent       = box

    return box
end

--[[
    Functions.CreateImageLabel(options) → ImageLabel
    Buat ImageLabel untuk ikon atau gambar dekoratif.
]]
function Functions.CreateImageLabel(options)
    local img = Instance.new("ImageLabel")
    img.Name                   = options.Name or "Image"
    img.Parent                 = options.Parent
    img.Size                   = options.Size or UDim2.new(0, 20, 0, 20)
    img.Position               = options.Position or UDim2.new(0, 0, 0, 0)
    img.AnchorPoint            = options.AnchorPoint or Vector2.new(0, 0)
    img.Image                  = options.Image or ""
    img.ImageColor3            = options.ImageColor or Theme.Get("TextPrimary")
    img.BackgroundTransparency = 1
    img.ScaleType              = options.ScaleType or Enum.ScaleType.Fit
    img.ZIndex                 = options.ZIndex or 2
    return img
end

-- ============================================================
-- GENERIC INSTANCE CREATOR (dibutuhkan oleh overlay & card modules)
-- FIX (Bug 1): fungsi ini sebelumnya tidak ada, menyebabkan crash pada
-- Loading.lua, Modals.lua, Notifications.lua, Tooltips.lua,
-- SearchBar.lua, SearchSystem.lua, Cards.lua, Separators.lua
-- ============================================================

--[[
    Functions.Create(className, properties, parent) → Instance
    Buat instance Roblox apapun dengan properties dari tabel.
    Dipakai oleh modul overlay (Loading, Modals, Notifications, dll)
    yang menerima Functions via dependency injection (Init(deps)).

    Contoh penggunaan di Loading.lua:
        Functions.Create("Frame", {BackgroundColor3 = Theme.Get("SecondaryBG")}, card)
        Functions.Create("UICorner", {CornerRadius = UDim.new(0,12)}, frame)
        Functions.Create("TextLabel", {Text = "Loading..."}, card)

    @param className  string    -- nama class Roblox (Frame, TextLabel, dll)
    @param properties table     -- property → value
    @param parent     Instance  -- parent instance (opsional)
    @return Instance
]]
function Functions.Create(className, properties, parent)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        -- pcall agar property yang tidak dikenal tidak crash seluruh proses
        pcall(function()
            instance[key] = value
        end)
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

-- ============================================================
-- STYLE APPLIERS
-- ============================================================

--[[
    Functions.ApplyCorner(instance, radius)
    Tambahkan UICorner ke instance.

    @param instance   GuiObject
    @param radius     UDim | number  (number dikonversi ke UDim.new(0, n))
]]
function Functions.ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    if typeof(radius) == "number" then
        corner.CornerRadius = UDim.new(0, radius)
    else
        corner.CornerRadius = radius
    end
    corner.Parent = instance
    return corner
end

--[[
    Functions.ApplyStroke(instance, options)
    Tambahkan UIStroke ke instance.

    @param options {
        Color: Color3,
        Thickness: number,
        Transparency: number,
        LineJoinMode: Enum
    }
]]
function Functions.ApplyStroke(instance, options)
    options = options or {}
    local stroke = Instance.new("UIStroke")
    stroke.Color           = options.Color or Theme.Get("Stroke")
    stroke.Thickness       = options.Thickness or 1
    stroke.Transparency    = options.Transparency or Config.Transparency.Stroke
    stroke.LineJoinMode    = options.LineJoinMode or Enum.LineJoinMode.Round
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent          = instance
    return stroke
end

--[[
    Functions.ApplyShadow(instance, options)
    Simulasi drop shadow menggunakan ImageLabel dengan gradient radial.

    @param options {
        Color: Color3,
        Opacity: number (0–1),
        Size: number (pixel spread),
        Offset: Vector2,
    }
]]
function Functions.ApplyShadow(instance, options)
    options = options or {}
    local size    = options.Size    or 16
    local opacity = options.Opacity or 0.35
    local offset  = options.Offset  or Vector2.new(0, 6)

    local shadow = Instance.new("ImageLabel")
    shadow.Name                   = "_Shadow"
    shadow.AnchorPoint            = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image                  = "rbxassetid://6014261993"
    shadow.ImageColor3            = options.Color or Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency      = 1 - opacity
    shadow.ScaleType              = Enum.ScaleType.Slice
    shadow.SliceCenter            = Rect.new(49, 49, 450, 450)
    shadow.Size                   = UDim2.new(1, size * 2, 1, size * 2)
    shadow.Position               = UDim2.new(0.5, offset.X, 0.5, offset.Y)
    shadow.ZIndex                 = math.max(1, instance.ZIndex - 1)
    shadow.Parent                 = instance.Parent

    return shadow
end

--[[
    Functions.ApplyGradient(instance, options)
    Tambahkan UIGradient ke instance.

    @param options {
        Color: ColorSequence,
        Transparency: NumberSequence,
        Rotation: number,
        Offset: Vector2,
    }
]]
function Functions.ApplyGradient(instance, options)
    options = options or {}
    local gradient = Instance.new("UIGradient")

    if options.Color then
        gradient.Color = options.Color
    else
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
        })
    end

    if options.Transparency then
        gradient.Transparency = options.Transparency
    end

    gradient.Rotation = options.Rotation or 0
    gradient.Offset   = options.Offset or Vector2.new(0, 0)
    gradient.Parent   = instance
    return gradient
end

--[[
    Functions.ApplyPadding(instance, paddings)
    Tambahkan UIPadding ke instance.

    @param paddings {
        Top: number, Bottom: number, Left: number, Right: number
    }
    Atau satu angka untuk semua sisi.
]]
function Functions.ApplyPadding(instance, paddings)
    local pad = Instance.new("UIPadding")
    if type(paddings) == "number" then
        pad.PaddingTop    = UDim.new(0, paddings)
        pad.PaddingBottom = UDim.new(0, paddings)
        pad.PaddingLeft   = UDim.new(0, paddings)
        pad.PaddingRight  = UDim.new(0, paddings)
    else
        paddings = paddings or {}
        pad.PaddingTop    = UDim.new(0, paddings.Top    or 0)
        pad.PaddingBottom = UDim.new(0, paddings.Bottom or 0)
        pad.PaddingLeft   = UDim.new(0, paddings.Left   or 0)
        pad.PaddingRight  = UDim.new(0, paddings.Right  or 0)
    end
    pad.Parent = instance
    return pad
end

--[[
    Functions.ApplyListLayout(instance, options)
    Tambahkan UIListLayout ke instance.
]]
function Functions.ApplyListLayout(instance, options)
    options = options or {}
    local layout = Instance.new("UIListLayout")
    layout.SortOrder           = options.SortOrder or Enum.SortOrder.LayoutOrder
    layout.FillDirection       = options.FillDirection or Enum.FillDirection.Vertical
    layout.HorizontalAlignment = options.HorizontalAlignment or Enum.HorizontalAlignment.Left
    layout.VerticalAlignment   = options.VerticalAlignment or Enum.VerticalAlignment.Top
    layout.Padding             = options.Padding or UDim.new(0, Config.UI.ComponentGap)
    layout.Parent              = instance
    return layout
end

--[[
    Functions.ApplyGridLayout(instance, options)
    Tambahkan UIGridLayout ke instance.
]]
function Functions.ApplyGridLayout(instance, options)
    options = options or {}
    local grid = Instance.new("UIGridLayout")
    grid.SortOrder             = options.SortOrder or Enum.SortOrder.LayoutOrder
    grid.CellSize              = options.CellSize or UDim2.new(0.5, -6, 0, 40)
    grid.CellPadding           = options.CellPadding or UDim2.new(0, 6, 0, 6)
    grid.FillDirectionMaxCells = options.MaxCells or 2
    grid.Parent                = instance
    return grid
end

-- ============================================================
-- TWEEN SHORTCUT
-- FIX (Bug 1): sebelumnya tidak ada, dibutuhkan oleh Loading.lua,
-- Modals.lua, Notifications.lua, SearchBar.lua, Tooltips.lua
-- ============================================================

--[[
    Functions.Tween(instance, goals, duration, style, direction)
    Shortcut membuat dan langsung memainkan tween.
    Menggunakan pcall agar tidak crash jika instance sudah dihapus.

    @param instance  Instance
    @param goals     table           -- { Property = targetValue }
    @param duration  number          -- detik (default 0.2)
    @param style     Enum.EasingStyle
    @param direction Enum.EasingDirection
]]
function Functions.Tween(instance, goals, duration, style, direction)
    if not instance or not instance.Parent then return end
    local ts = game:GetService("TweenService")
    local info = TweenInfo.new(
        duration  or 0.2,
        style     or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local ok, tween = pcall(function()
        return ts:Create(instance, info, goals)
    end)
    if ok and tween then
        tween:Play()
        return tween
    end
end

-- ============================================================
-- SAFE CALL
-- FIX (Bug 1): sebelumnya tidak ada, dibutuhkan oleh Modals.lua,
-- Notifications.lua, SearchBar.lua sebagai wrapper callback
-- ============================================================

--[[
    Functions.SafeCall(fn, ...) → ok, result
    Panggil fungsi dengan pcall.
    Tidak crash jika fn = nil atau bukan function.

    @param fn   function | any
    @param ...  argumen
    @return ok boolean, result any
]]
function Functions.SafeCall(fn, ...)
    if type(fn) ~= "function" then return false, nil end
    return pcall(fn, ...)
end

-- ============================================================
-- TABLE REMOVE BY VALUE
-- FIX (Bug 1): sebelumnya tidak ada, dibutuhkan oleh Notifications.lua
-- (hapus notif dari activeNotifs), Cards.lua, Separators.lua
-- ============================================================

--[[
    Functions.TableRemove(tbl, value) → boolean
    Hapus value pertama yang cocok dari array tbl.
    Berbeda dari table.remove() yang pakai index.

    @param tbl    table
    @param value  any  -- nilai yang ingin dihapus
    @return true jika ditemukan dan dihapus, false jika tidak ada
]]
function Functions.TableRemove(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

-- ============================================================
-- STRING TRIM
-- FIX (Bug 1): sebelumnya tidak ada, dibutuhkan oleh FeedbackUI.lua,
-- BugReport.lua, SuggestionReport.lua sebelum validasi input user
-- ============================================================

--[[
    Functions.Trim(str) → string
    Hapus whitespace (spasi, tab, newline) di awal dan akhir string.

    @param str  string | any  (non-string di-tostring dulu)
    @return string tanpa whitespace di kedua ujung
]]
function Functions.Trim(str)
    return tostring(str or ""):match("^%s*(.-)%s*$")
end

-- ============================================================
-- PARENT GUI HELPER
-- FIX (Bug 1): sebelumnya tidak ada, dibutuhkan oleh Notifications.lua
-- di fungsi ensureGui() untuk memasang ScreenGui ke CoreGui/PlayerGui
-- ============================================================

--[[
    Functions.ParentGui(gui)
    Pasang ScreenGui ke CoreGui (lebih stabil), fallback ke PlayerGui
    jika CoreGui tidak tersedia (misal bukan executor environment).

    @param gui  ScreenGui
]]
function Functions.ParentGui(gui)
    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not ok then
        local player = game:GetService("Players").LocalPlayer
        gui.Parent = player:WaitForChild("PlayerGui", 5)
    end
end

-- ============================================================
-- UTILITY FUNCTIONS (tidak berubah dari versi sebelumnya)
-- ============================================================

--[[
    Functions.SafeDestroy(instance)
    Hapus instance secara aman tanpa error.
]]
function Functions.SafeDestroy(instance)
    if instance and instance.Parent then
        pcall(function() instance:Destroy() end)
    end
end

--[[
    Functions.IsValid(instance) → boolean
    Cek apakah instance masih valid dan belum dihapus.
]]
function Functions.IsValid(instance)
    return instance ~= nil
        and typeof(instance) == "Instance"
        and instance.Parent ~= nil
end

--[[
    Functions.Clamp(value, min, max) → number
    Batasi nilai dalam range tertentu.
]]
function Functions.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

--[[
    Functions.Round(value, decimals) → number
    Bulatkan angka ke desimal tertentu.
]]
function Functions.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

--[[
    Functions.Lerp(a, b, t) → number
    Linear interpolasi antara dua angka.
]]
function Functions.Lerp(a, b, t)
    return a + (b - a) * t
end

--[[
    Functions.ColorToHex(color) → string
    Konversi Color3 ke string hex (contoh: "#64A0FF").
]]
function Functions.ColorToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

--[[
    Functions.HexToColor(hex) → Color3
    Konversi string hex ke Color3.
    Mendukung format "#RRGGBB" dan "RRGGBB".
]]
function Functions.HexToColor(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

--[[
    Functions.LightenColor(color, amount) → Color3
    Cerahkan warna. amount: 0–1.
]]
function Functions.LightenColor(color, amount)
    amount = amount or 0.1
    return Color3.new(
        math.min(color.R + amount, 1),
        math.min(color.G + amount, 1),
        math.min(color.B + amount, 1)
    )
end

--[[
    Functions.DarkenColor(color, amount) → Color3
    Gelapkan warna. amount: 0–1.
]]
function Functions.DarkenColor(color, amount)
    amount = amount or 0.1
    return Color3.new(
        math.max(color.R - amount, 0),
        math.max(color.G - amount, 0),
        math.max(color.B - amount, 0)
    )
end

--[[
    Functions.GetTextSize(text, fontSize, font, frameSize) → Vector2
    Hitung ukuran teks secara akurat menggunakan TextService.
]]
function Functions.GetTextSize(text, fontSize, font, frameSize)
    local TextService = game:GetService("TextService")
    return TextService:GetTextSize(
        text,
        fontSize or Config.Font.Size.ComponentLabel,
        font or Config.Font.Body,
        frameSize or Vector2.new(1000, 1000)
    )
end

--[[
    Functions.TruncateText(text, maxLength) → string
    Potong teks jika terlalu panjang dan tambah "...".
]]
function Functions.TruncateText(text, maxLength)
    if #text <= maxLength then return text end
    return text:sub(1, maxLength - 3) .. "..."
end

--[[
    Functions.FormatNumber(number, decimals) → string
    Format angka dengan pemisah ribuan.
    Contoh: 1234567 → "1,234,567"
]]
function Functions.FormatNumber(number, decimals)
    decimals = decimals or 0
    local formatted = string.format("%." .. decimals .. "f", number)
    local result = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if result:sub(1, 1) == "," then result = result:sub(2) end
    return result
end

--[[
    Functions.Debounce(fn, delay) → function
    Bungkus fungsi dengan debounce agar tidak spam-call.

    @param fn     function  -- fungsi asli
    @param delay  number    -- cooldown dalam detik
]]
function Functions.Debounce(fn, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall < delay then return end
        lastCall = now
        return fn(...)
    end
end

--[[
    Functions.TableContains(tbl, value) → boolean
    Cek apakah sebuah nilai ada di dalam tabel array.
]]
function Functions.TableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

--[[
    Functions.DeepCopy(tbl) → table
    Salin tabel secara rekursif.
]]
function Functions.DeepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = Functions.DeepCopy(v)
    end
    return copy
end

return Functions
