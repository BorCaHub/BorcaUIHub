--[[
    BorcaUIHub — UI/Main.lua
    Kerangka utama window, layout global, dan penyatu semua modul.
    Dibuat sebagai fondasi dari seluruh sistem UI.
]]

local Main = {}

-- Service references
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Modul internal (lazy-load untuk performa)
local Theme    = require(script.Parent.Theme)
local Config   = require(script.Parent.Config)
local Functions = require(script.Parent.Functions)
local Animations = require(script.Parent.Animations)

-- State utama UI
Main._state = {
    visible    = true,
    minimized  = false,
    activeTab  = nil,
    windowPos  = nil,
}

--[[
    Main.CreateWindow(options)
    Membuat window utama BorcaUIHub.
    
    @param options {
        Title: string       -- Nama hub yang ditampilkan di header
        SubTitle: string    -- Subtitle / tagline kecil
        Size: UDim2         -- Ukuran window (default dari Config)
        Position: UDim2     -- Posisi awal (default tengah layar)
        Icon: string        -- ID ikon (opsional)
    }
    @return windowObject    -- Reference ke window yang dibuat
]]
function Main.CreateWindow(options)
    options = options or {}

    local title     = options.Title    or "BorcaHub"
    local subtitle  = options.SubTitle or "Premium UI Framework"
    local size      = options.Size     or Config.Window.DefaultSize
    local position  = options.Position or Config.Window.DefaultPosition

    -- ScreenGui root
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name             = "BorcaUIHub"
    screenGui.ResetOnSpawn     = false
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder     = Config.Window.DisplayOrder
    screenGui.IgnoreGuiInset   = true
    screenGui.Parent           = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Blur background (dikelola BlurSystem, diaktifkan jika Config mengizinkan)
    if Config.Blur.Enabled then
        local blur = Instance.new("BlurEffect")
        blur.Size   = 0
        blur.Parent = game:GetService("Lighting")
        -- Simpan referensi untuk BlurSystem
        Main._blurRef = blur
    end

    -- === MAIN WINDOW FRAME ===
    local mainFrame = Functions.CreateFrame({
        Name         = "MainWindow",
        Parent       = screenGui,
        Size         = size,
        Position     = position,
        AnchorPoint  = Vector2.new(0.5, 0.5),
        BackgroundColor = Theme.Get("Background"),
        CornerRadius = UDim.new(0, Config.UI.CornerRadius),
        ClipDescendants = true,
    })

    -- Drop shadow
    Functions.ApplyShadow(mainFrame, {
        Color     = Color3.fromRGB(0, 0, 0),
        Opacity   = 0.4,
        Size      = 20,
        Offset    = Vector2.new(0, 8),
    })

    -- === HEADER BAR ===
    local header = Functions.CreateFrame({
        Name            = "Header",
        Parent          = mainFrame,
        Size            = UDim2.new(1, 0, 0, Config.UI.HeaderHeight),
        Position        = UDim2.new(0, 0, 0, 0),
        BackgroundColor = Theme.Get("HeaderBackground"),
        ZIndex          = 5,
    })

    -- Logo / ikon kiri
    local iconFrame = Functions.CreateFrame({
        Name   = "IconFrame",
        Parent = header,
        Size   = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("Accent"),
        CornerRadius = UDim.new(0, 8),
    })

    local iconLabel = Functions.CreateLabel({
        Name   = "Icon",
        Parent = iconFrame,
        Text   = options.Icon or "◈",
        Size   = UDim2.new(1, 0, 1, 0),
        Font   = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor = Theme.Get("TextPrimary"),
    })

    -- Title text
    local titleLabel = Functions.CreateLabel({
        Name      = "Title",
        Parent    = header,
        Text      = title,
        Size      = UDim2.new(0, 200, 0, 20),
        Position  = UDim2.new(0, 54, 0, 10),
        Font      = Enum.Font.GothamBold,
        TextSize  = 14,
        TextColor = Theme.Get("TextPrimary"),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local subtitleLabel = Functions.CreateLabel({
        Name      = "SubTitle",
        Parent    = header,
        Text      = subtitle,
        Size      = UDim2.new(0, 200, 0, 14),
        Position  = UDim2.new(0, 54, 0, 28),
        Font      = Enum.Font.Gotham,
        TextSize  = 11,
        TextColor = Theme.Get("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Control buttons (minimize, close) di kanan header
    local controlFrame = Functions.CreateFrame({
        Name     = "Controls",
        Parent   = header,
        Size     = UDim2.new(0, 60, 0, 30),
        Position = UDim2.new(1, -70, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
    })

    -- Minimize button
    local minBtn = Functions.CreateButton({
        Name   = "MinimizeBtn",
        Parent = controlFrame,
        Size   = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Text   = "─",
        BackgroundColor = Theme.Get("ButtonSecondary"),
        TextColor = Theme.Get("TextSecondary"),
        CornerRadius = UDim.new(0, 6),
    })

    -- Close button
    local closeBtn = Functions.CreateButton({
        Name   = "CloseBtn",
        Parent = controlFrame,
        Size   = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 30, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Text   = "✕",
        BackgroundColor = Theme.Get("CloseButton"),
        TextColor = Theme.Get("TextPrimary"),
        CornerRadius = UDim.new(0, 6),
    })

    -- === BODY (sidebar + content) ===
    local body = Functions.CreateFrame({
        Name            = "Body",
        Parent          = mainFrame,
        Size            = UDim2.new(1, 0, 1, -Config.UI.HeaderHeight),
        Position        = UDim2.new(0, 0, 0, Config.UI.HeaderHeight),
        BackgroundTransparency = 1,
    })

    -- Sidebar kiri (diisi oleh Navigation/Sidebar.lua)
    local sidebar = Functions.CreateFrame({
        Name            = "Sidebar",
        Parent          = body,
        Size            = UDim2.new(0, Config.UI.SidebarWidth, 1, 0),
        Position        = UDim2.new(0, 0, 0, 0),
        BackgroundColor = Theme.Get("SidebarBackground"),
    })

    -- Content panel tengah (diisi oleh tab aktif)
    local contentPanel = Functions.CreateFrame({
        Name            = "ContentPanel",
        Parent          = body,
        Size            = UDim2.new(1, -Config.UI.SidebarWidth, 1, 0),
        Position        = UDim2.new(0, Config.UI.SidebarWidth, 0, 0),
        BackgroundColor = Theme.Get("ContentBackground"),
        ClipDescendants = true,
    })

    -- Scrolling container di dalam content
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name              = "ScrollContent"
    scrollFrame.Parent            = contentPanel
    scrollFrame.Size              = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position          = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = Theme.Get("Accent")
    scrollFrame.CanvasSize        = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent          = scrollFrame
    listLayout.SortOrder       = Enum.SortOrder.LayoutOrder
    listLayout.Padding         = UDim.new(0, Config.UI.SectionGap)
    listLayout.FillDirection   = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local paddingInset = Instance.new("UIPadding")
    paddingInset.PaddingTop    = UDim.new(0, 12)
    paddingInset.PaddingBottom = UDim.new(0, 12)
    paddingInset.PaddingLeft   = UDim.new(0, 12)
    paddingInset.PaddingRight  = UDim.new(0, 12)
    paddingInset.Parent        = scrollFrame

    -- === DRAG SYSTEM ===
    -- DragSystem akan di-attach ke header oleh Utilities/DragSystem.lua
    -- Disimpan referensi untuk kemudian
    Main._state.headerRef = header

    -- === BUTTON EVENTS ===
    minBtn.MouseButton1Click:Connect(function()
        Main.ToggleMinimize(mainFrame, body)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Animations.FadeOut(mainFrame, function()
            screenGui:Destroy()
            if Main._blurRef then
                Main._blurRef:Destroy()
            end
        end)
    end)

    -- Hover effect pada control buttons
    Animations.ApplyHoverEffect(minBtn, Theme.Get("ButtonHover"))
    Animations.ApplyHoverEffect(closeBtn, Color3.fromRGB(220, 60, 60))

    -- === OPENING ANIMATION ===
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    Animations.WindowOpen(mainFrame, size)

    -- === WINDOW OBJECT (return) ===
    local windowObject = {
        ScreenGui     = screenGui,
        Window        = mainFrame,
        Header        = header,
        Sidebar       = sidebar,
        ContentPanel  = contentPanel,
        ScrollContent = scrollFrame,
        Body          = body,
    }

    -- Simpan referensi global
    Main._windowRef = windowObject

    return windowObject
end

--[[
    Main.ToggleMinimize(frame, body)
    Toggle antara tampilan penuh dan minimize (hanya header tampil).
]]
function Main.ToggleMinimize(frame, body)
    Main._state.minimized = not Main._state.minimized
    if Main._state.minimized then
        Animations.Minimize(frame, body)
    else
        Animations.Restore(frame, body, Main._windowRef and Main._windowRef.Window.Size)
    end
end

--[[
    Main.Toggle()
    Toggle visibilitas seluruh UI (hide / show).
]]
function Main.Toggle()
    if not Main._windowRef then return end
    Main._state.visible = not Main._state.visible
    local frame = Main._windowRef.Window
    if Main._state.visible then
        Animations.FadeIn(frame)
    else
        Animations.FadeOut(frame)
    end
end

--[[
    Main.SetTheme(themeName)
    Ganti tema secara langsung (diteruskan ke ThemeManager).
]]
function Main.SetTheme(themeName)
    local ThemeManager = require(script.Parent.Parent.Managers.ThemeManager)
    ThemeManager.Apply(themeName)
end

--[[
    Main.GetWindow()
    Mengembalikan reference window aktif.
]]
function Main.GetWindow()
    return Main._windowRef
end

return Main
