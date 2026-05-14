--[[
    BorcaUIHub — UI/Responsive.lua
    Menyesuaikan UI dengan ukuran layar yang berbeda.
    Menjaga proporsionalitas layout di resolusi apapun.
]]

local Responsive = {}

local RunService = game:GetService("RunService")
local Config     = require(script.Parent.Config)

-- ============================================================
-- BREAKPOINTS
-- Definisikan batas resolusi untuk setiap kategori layar.
-- ============================================================

Responsive.Breakpoints = {
    -- Layar sangat kecil (tablet kecil, window kecil)
    XSmall = { maxWidth = 600,  maxHeight = 400 },

    -- Layar kecil (laptop 720p)
    Small  = { maxWidth = 900,  maxHeight = 600 },

    -- Layar medium (laptop 1080p)
    Medium = { maxWidth = 1280, maxHeight = 800 },

    -- Layar besar (monitor 1440p+)
    Large  = { maxWidth = math.huge, maxHeight = math.huge },
}

-- ============================================================
-- STATE
-- ============================================================

Responsive._currentBreakpoint = "Medium"
Responsive._screenSize         = Vector2.new(1280, 720)
Responsive._listeners          = {}
Responsive._connection         = nil

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- Tentukan breakpoint berdasarkan ukuran layar
local function GetBreakpoint(width, height)
    if width <= Responsive.Breakpoints.XSmall.maxWidth
    or height <= Responsive.Breakpoints.XSmall.maxHeight then
        return "XSmall"
    elseif width <= Responsive.Breakpoints.Small.maxWidth
        or height <= Responsive.Breakpoints.Small.maxHeight then
        return "Small"
    elseif width <= Responsive.Breakpoints.Medium.maxWidth
        or height <= Responsive.Breakpoints.Medium.maxHeight then
        return "Medium"
    else
        return "Large"
    end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Responsive.Init(screenGui)
    Inisialisasi sistem responsif. Panggil setelah ScreenGui dibuat.
    Akan mulai memantau perubahan ukuran layar.
    
    @param screenGui  ScreenGui
]]
function Responsive.Init(screenGui)
    -- Ambil ukuran layar awal
    local camera = workspace.CurrentCamera
    Responsive._screenSize = camera.ViewportSize
    Responsive._currentBreakpoint = GetBreakpoint(
        Responsive._screenSize.X,
        Responsive._screenSize.Y
    )

    -- Pantau perubahan ukuran viewport
    Responsive._connection = RunService.RenderStepped:Connect(function()
        local newSize = workspace.CurrentCamera.ViewportSize
        if newSize ~= Responsive._screenSize then
            local prev = Responsive._currentBreakpoint
            Responsive._screenSize = newSize
            Responsive._currentBreakpoint = GetBreakpoint(newSize.X, newSize.Y)

            -- Notify hanya jika breakpoint berubah
            if Responsive._currentBreakpoint ~= prev then
                Responsive._NotifyListeners(Responsive._currentBreakpoint, prev)
            end
        end
    end)
end

--[[
    Responsive.Stop()
    Hentikan pemantauan ukuran layar.
]]
function Responsive.Stop()
    if Responsive._connection then
        Responsive._connection:Disconnect()
        Responsive._connection = nil
    end
end

--[[
    Responsive.GetScreenSize() → Vector2
    Kembalikan ukuran layar saat ini.
]]
function Responsive.GetScreenSize()
    return Responsive._screenSize
end

--[[
    Responsive.GetBreakpoint() → string
    Kembalikan breakpoint aktif: "XSmall" | "Small" | "Medium" | "Large"
]]
function Responsive.GetBreakpoint()
    return Responsive._currentBreakpoint
end

--[[
    Responsive.IsSmall() → boolean
    True jika layar tergolong kecil (XSmall atau Small).
]]
function Responsive.IsSmall()
    return Responsive._currentBreakpoint == "XSmall"
        or Responsive._currentBreakpoint == "Small"
end

--[[
    Responsive.OnBreakpointChanged(callback)
    Daftarkan callback yang dipanggil saat breakpoint berubah.
    
    @param callback  function(newBreakpoint, oldBreakpoint)
    @return disconnectFn
]]
function Responsive.OnBreakpointChanged(callback)
    table.insert(Responsive._listeners, callback)
    return function()
        for i, cb in ipairs(Responsive._listeners) do
            if cb == callback then
                table.remove(Responsive._listeners, i)
                break
            end
        end
    end
end

function Responsive._NotifyListeners(new, old)
    for _, cb in ipairs(Responsive._listeners) do
        pcall(cb, new, old)
    end
end

-- ============================================================
-- SCALE HELPERS
-- Fungsi untuk menghitung ukuran responsif secara otomatis.
-- ============================================================

--[[
    Responsive.ScaleValue(baseValue, referenceWidth) → number
    Skala nilai berdasarkan lebar layar relatif terhadap referensi.
    
    Contoh: tombol lebar 120px di 1280px layar
    → di layar 900px jadi ~84px
    
    @param baseValue       number  -- nilai pixel di resolusi referensi
    @param referenceWidth  number  -- resolusi referensi (default 1280)
]]
function Responsive.ScaleValue(baseValue, referenceWidth)
    referenceWidth = referenceWidth or 1280
    local ratio = Responsive._screenSize.X / referenceWidth
    -- Clamp ratio agar tidak terlalu kecil atau terlalu besar
    ratio = math.max(0.7, math.min(1.3, ratio))
    return math.floor(baseValue * ratio)
end

--[[
    Responsive.GetWindowSize() → UDim2
    Kembalikan ukuran window yang sesuai dengan layar saat ini.
]]
function Responsive.GetWindowSize()
    local bp = Responsive._currentBreakpoint
    local screenW = Responsive._screenSize.X
    local screenH = Responsive._screenSize.Y

    if bp == "XSmall" then
        -- Hampir fullscreen di layar sangat kecil
        return UDim2.new(0, math.min(screenW - 40, 620), 0, math.min(screenH - 40, 440))
    elseif bp == "Small" then
        return UDim2.new(0, math.min(screenW - 60, 720), 0, math.min(screenH - 60, 480))
    elseif bp == "Medium" then
        return Config.Window.DefaultSize
    else
        -- Large: bisa sedikit lebih besar
        return UDim2.new(0, 860, 0, 560)
    end
end

--[[
    Responsive.GetSidebarWidth() → number
    Kembalikan lebar sidebar yang sesuai dengan breakpoint.
]]
function Responsive.GetSidebarWidth()
    local bp = Responsive._currentBreakpoint
    if bp == "XSmall" then
        return 48  -- ikon saja, tanpa teks
    elseif bp == "Small" then
        return 140
    else
        return Config.UI.SidebarWidth
    end
end

--[[
    Responsive.GetComponentHeight() → number
    Tinggi standar komponen (toggle, slider, dll) per breakpoint.
]]
function Responsive.GetComponentHeight()
    if Responsive._currentBreakpoint == "XSmall" then
        return 36
    else
        return Config.UI.ComponentHeight
    end
end

--[[
    Responsive.GetFontSize(key) → number
    Kembalikan ukuran font yang menyesuaikan breakpoint.
    
    @param key  string  -- key dari Config.Font.Size
]]
function Responsive.GetFontSize(key)
    local base = Config.Font.Size[key] or 13
    local bp   = Responsive._currentBreakpoint
    if bp == "XSmall" then
        return math.max(base - 2, 10)
    elseif bp == "Small" then
        return math.max(base - 1, 10)
    elseif bp == "Large" then
        return base + 1
    end
    return base
end

-- ============================================================
-- AUTO-RESIZE APPLIER
-- ============================================================

--[[
    Responsive.BindWindowResize(window, body, sidebar, contentPanel)
    Ikat window utama ke sistem responsif sehingga otomatis resize
    saat breakpoint berubah.
    
    @param window        Frame  -- frame utama window
    @param body          Frame  -- body (sidebar + content)
    @param sidebar       Frame  -- sidebar kiri
    @param contentPanel  Frame  -- panel konten tengah
]]
function Responsive.BindWindowResize(window, body, sidebar, contentPanel)
    local function ApplyLayout()
        local newSize = Responsive.GetWindowSize()
        local sidebarW = Responsive.GetSidebarWidth()

        -- Animasi perubahan ukuran
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        TweenService:Create(window, tweenInfo, { Size = newSize }):Play()

        TweenService:Create(sidebar, tweenInfo, {
            Size = UDim2.new(0, sidebarW, 1, 0),
        }):Play()

        TweenService:Create(contentPanel, tweenInfo, {
            Size = UDim2.new(1, -sidebarW, 1, 0),
            Position = UDim2.new(0, sidebarW, 0, 0),
        }):Play()
    end

    -- Terapkan langsung
    ApplyLayout()

    -- Daftar ke listener breakpoint
    Responsive.OnBreakpointChanged(function()
        ApplyLayout()
    end)
end

--[[
    Responsive.BindTextResize(labelOrButton, fontKey)
    Ikat TextLabel/TextButton ke sistem responsif untuk auto-resize font.
    
    @param labelOrButton  TextLabel | TextButton
    @param fontKey        string  -- key dari Config.Font.Size
]]
function Responsive.BindTextResize(labelOrButton, fontKey)
    local function Apply()
        labelOrButton.TextSize = Responsive.GetFontSize(fontKey)
    end

    Apply()
    Responsive.OnBreakpointChanged(function()
        Apply()
    end)
end

--[[
    Responsive.BindSidebarCollapse(sidebar, onCollapse, onExpand)
    Otomatis collapse sidebar ke icon-only mode saat layar XSmall.
    
    @param onCollapse  function()  -- dipanggil saat sidebar collapse
    @param onExpand    function()  -- dipanggil saat sidebar expand
]]
function Responsive.BindSidebarCollapse(sidebar, onCollapse, onExpand)
    local function Apply(bp)
        if bp == "XSmall" then
            if onCollapse then pcall(onCollapse) end
        else
            if onExpand then pcall(onExpand) end
        end
    end

    Apply(Responsive._currentBreakpoint)
    Responsive.OnBreakpointChanged(function(new)
        Apply(new)
    end)
end

-- ============================================================
-- UTILITY
-- ============================================================

--[[
    Responsive.GetSafeArea() → {top, bottom, left, right}
    Kembalikan safe area padding yang aman untuk semua layar.
    Berguna untuk menghindari konten tersembunyi di tepi layar.
]]
function Responsive.GetSafeArea()
    local bp = Responsive._currentBreakpoint
    if bp == "XSmall" then
        return { top = 8, bottom = 8, left = 8, right = 8 }
    else
        return { top = 16, bottom = 16, left = 16, right = 16 }
    end
end

return Responsive
