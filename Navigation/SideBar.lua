--[[
    BorcaUIHub — Navigation/Sidebar.lua
    Panel navigasi kiri: logo, nama hub, badge, dan daftar menu.
    Titik orientasi pertama pengguna dalam UI.
]]

local Sidebar = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)
local Tabs       = require(script.Parent.Tabs)
local TabManager = require(script.Parent.TabManager)

-- ============================================================
-- STATE
-- ============================================================

Sidebar._collapsed = false
Sidebar._frame     = nil

-- ============================================================
-- BUILD
-- ============================================================

--[[
    Sidebar.Build(sidebarFrame, options)
    Bangun seluruh isi sidebar ke dalam frame yang diberikan.
    
    @param sidebarFrame  Frame  -- sidebar frame dari Main.lua
    @param options {
        HubName:    string   -- nama hub (contoh: "BorcaHub")
        HubVersion: string   -- versi (contoh: "v1.0")
        Premium:    boolean  -- apakah user premium
        Username:   string   -- nama user (opsional)
    }
]]
function Sidebar.Build(sidebarFrame, options)
    options = options or {}
    Sidebar._frame = sidebarFrame

    -- Bersihkan frame jika sudah ada isi
    for _, child in ipairs(sidebarFrame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    -- Layout vertikal di sidebar
    Functions.ApplyListLayout(sidebarFrame, {
        FillDirection      = Enum.FillDirection.Vertical,
        Padding            = UDim.new(0, 2),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    Functions.ApplyPadding(sidebarFrame, {
        Top = 0, Bottom = 8, Left = 0, Right = 0,
    })

    -- Stroke kanan sidebar sebagai separator
    Functions.ApplyStroke(sidebarFrame, {
        Color       = Theme.Get("Stroke"),
        Thickness   = 1,
        Transparency = 0.5,
    })

    -- ── BRANDING SECTION ──────────────────────────────────
    local brandFrame = Functions.CreateFrame({
        Name       = "BrandingFrame",
        Parent     = sidebarFrame,
        Size       = UDim2.new(1, 0, 0, Config.Sidebar.BrandingHeight),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    })

    -- Logo box
    local logoBox = Functions.CreateFrame({
        Name            = "LogoBox",
        Parent          = brandFrame,
        Size            = UDim2.new(0, 36, 0, 36),
        Position        = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("Accent"),
        CornerRadius    = UDim.new(0, 9),
    })

    -- Gradient di logo
    Functions.ApplyGradient(logoBox, {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Functions.LightenColor(Theme.Get("Accent"), 0.15)),
            ColorSequenceKeypoint.new(1, Theme.Get("AccentDim")),
        }),
        Rotation = 135,
    })

    -- Ikon logo
    Functions.CreateLabel({
        Name      = "LogoIcon",
        Parent    = logoBox,
        Text      = "◈",
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = 18,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 3,
    })

    -- Nama hub
    local nameLabel = Functions.CreateLabel({
        Name      = "HubName",
        Parent    = brandFrame,
        Text      = options.HubName or "BorcaHub",
        Size      = UDim2.new(1, -60, 0, 18),
        Position  = UDim2.new(0, 54, 0.5, -10),
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.Title - 2,
        TextColor = Theme.Get("TextPrimary"),
    })

    -- Versi
    local versionLabel = Functions.CreateLabel({
        Name      = "Version",
        Parent    = brandFrame,
        Text      = options.HubVersion or ("v" .. Config.Flags.Version),
        Size      = UDim2.new(1, -60, 0, 14),
        Position  = UDim2.new(0, 54, 0.5, 8),
        Font      = Config.Font.Small,
        TextSize  = Config.Font.Size.ComponentHint,
        TextColor = Theme.Get("TextSecondary"),
    })

    -- Badge premium (jika user premium)
    if options.Premium then
        local badge = Functions.CreateFrame({
            Name            = "PremiumBadge",
            Parent          = brandFrame,
            Size            = UDim2.new(0, 54, 0, 16),
            Position        = UDim2.new(0, 54, 0.5, 24),
            BackgroundColor = Theme.Get("Accent"),
            CornerRadius    = UDim.new(0, 4),
        })

        Functions.ApplyGradient(badge, {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 140, 40)),
            }),
            Rotation = 90,
        })

        Functions.CreateLabel({
            Name      = "BadgeText",
            Parent    = badge,
            Text      = "✦ PREMIUM",
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = Config.Font.Size.BadgeText,
            TextColor = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 3,
        })
    end

    -- Separator bawah branding
    Sidebar._BuildSeparator(sidebarFrame, 1)

    -- ── NAVIGATION ITEMS ─────────────────────────────────
    local navContainer = Functions.CreateFrame({
        Name       = "NavContainer",
        Parent     = sidebarFrame,
        Size       = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    })

    Functions.ApplyListLayout(navContainer, {
        Padding = UDim.new(0, Config.Sidebar.ItemGap),
    })

    Functions.ApplyPadding(navContainer, {
        Top = 6, Bottom = 6, Left = 6, Right = 6,
    })

    -- Buat item untuk setiap tab
    for i, tabDef in ipairs(Tabs.GetAll()) do
        Sidebar._BuildNavItem(navContainer, tabDef, i)
    end

    -- ── FOOTER (user info / logout) ───────────────────────
    Sidebar._BuildFooter(sidebarFrame, options)
end

-- ============================================================
-- NAV ITEM BUILDER
-- ============================================================

function Sidebar._BuildNavItem(parent, tabDef, layoutOrder)
    -- Container item
    local item = Functions.CreateButton({
        Name            = "NavItem_" .. tabDef.Id,
        Parent          = parent,
        Size            = UDim2.new(1, 0, 0, Config.Sidebar.ItemHeight),
        BackgroundColor = Theme.Get("SidebarBackground"),
        BackgroundTransparency = 1,
        CornerRadius    = Config.Sidebar.ItemRadius,
        LayoutOrder     = layoutOrder,
        ZIndex          = 3,
    })

    -- Indikator aktif (strip kiri)
    local indicator = Functions.CreateFrame({
        Name            = "ActiveIndicator",
        Parent          = item,
        Size            = UDim2.new(0, 0, 1, -8),
        Position        = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("Accent"),
        CornerRadius    = UDim.new(0, 2),
        ZIndex          = 4,
    })

    -- Ikon tab
    local iconLabel = Functions.CreateLabel({
        Name      = "TabIcon",
        Parent    = item,
        Text      = tabDef.Icon,
        Size      = UDim2.new(0, 24, 1, 0),
        Position  = UDim2.new(0, Config.Sidebar.ItemPaddingX + 4, 0, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = 14,
        TextColor = Theme.Get("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 4,
    })

    -- Label teks tab
    local textLabel = Functions.CreateLabel({
        Name      = "TabLabel",
        Parent    = item,
        Text      = tabDef.Label,
        Size      = UDim2.new(1, -50, 1, 0),
        Position  = UDim2.new(0, Config.Sidebar.ItemPaddingX + 30, 0, 0),
        Font      = Config.Font.Body,
        TextSize  = Config.Font.Size.SidebarItem,
        TextColor = Theme.Get("TextSecondary"),
        ZIndex    = 4,
    })

    -- Badge premium di sebelah kanan (jika tab premium)
    if tabDef.Premium then
        local premBadge = Functions.CreateFrame({
            Name            = "PremBadge",
            Parent          = item,
            Size            = UDim2.new(0, 14, 0, 14),
            Position        = UDim2.new(1, -20, 0.5, 0),
            AnchorPoint     = Vector2.new(0.5, 0.5),
            BackgroundColor = Color3.fromRGB(240, 170, 40),
            CornerRadius    = UDim.new(0, 3),
            ZIndex          = 4,
        })

        Functions.CreateLabel({
            Name      = "Star",
            Parent    = premBadge,
            Text      = "✦",
            Size      = UDim2.new(1, 0, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = 8,
            TextColor = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = 5,
        })
    end

    -- Hover effects pada item (warna teks)
    item.MouseEnter:Connect(function()
        if not TabManager.IsActive(tabDef.Id) then
            local hInfo = game:GetService("TweenService"):Create(item,
                TweenInfo.new(0.12), { BackgroundTransparency = 0.7 }
            )
            hInfo:Play()
            game:GetService("TweenService"):Create(iconLabel,
                TweenInfo.new(0.12), { TextColor3 = Theme.Get("TextPrimary") }
            ):Play()
            game:GetService("TweenService"):Create(textLabel,
                TweenInfo.new(0.12), { TextColor3 = Theme.Get("TextPrimary") }
            ):Play()
        end
    end)

    item.MouseLeave:Connect(function()
        if not TabManager.IsActive(tabDef.Id) then
            game:GetService("TweenService"):Create(item,
                TweenInfo.new(0.12), { BackgroundTransparency = 1 }
            ):Play()
            game:GetService("TweenService"):Create(iconLabel,
                TweenInfo.new(0.12), { TextColor3 = Theme.Get("TextSecondary") }
            ):Play()
            game:GetService("TweenService"):Create(textLabel,
                TweenInfo.new(0.12), { TextColor3 = Theme.Get("TextSecondary") }
            ):Play()
        end
    end)

    -- Daftarkan ke TabManager
    TabManager.RegisterSidebarItem(tabDef.Id, item, indicator)

    -- Sync warna teks saat tab aktif berubah
    TabManager.OnTabChanged(function(newId, prevId)
        local active = newId == tabDef.Id
        local tInfo  = TweenInfo.new(0.15)
        local ts     = game:GetService("TweenService")

        ts:Create(iconLabel, tInfo, {
            TextColor3 = active and Theme.Get("Accent") or Theme.Get("TextSecondary"),
        }):Play()
        ts:Create(textLabel, tInfo, {
            TextColor3 = active and Theme.Get("TextPrimary") or Theme.Get("TextSecondary"),
        }):Play()
    end)
end

-- ============================================================
-- FOOTER
-- ============================================================

function Sidebar._BuildFooter(sidebarFrame, options)
    -- Spacer agar footer tetap di bawah
    local spacer = Functions.CreateFrame({
        Name       = "FooterSpacer",
        Parent     = sidebarFrame,
        Size       = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        LayoutOrder = 98,
    })

    -- Separator atas footer
    Sidebar._BuildSeparator(sidebarFrame, 99)

    -- Footer frame
    local footer = Functions.CreateFrame({
        Name       = "Footer",
        Parent     = sidebarFrame,
        Size       = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        LayoutOrder = 100,
    })

    -- Avatar / user icon
    local avatarBox = Functions.CreateFrame({
        Name            = "AvatarBox",
        Parent          = footer,
        Size            = UDim2.new(0, 28, 0, 28),
        Position        = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint     = Vector2.new(0, 0.5),
        BackgroundColor = Theme.Get("ButtonSecondary"),
        CornerRadius    = UDim.new(1, 0),
    })

    Functions.CreateLabel({
        Name      = "AvatarIcon",
        Parent    = avatarBox,
        Text      = "◉",
        Size      = UDim2.new(1, 0, 1, 0),
        TextSize  = 12,
        TextColor = Theme.Get("Accent"),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 3,
    })

    -- Username
    Functions.CreateLabel({
        Name      = "Username",
        Parent    = footer,
        Text      = options.Username or game.Players.LocalPlayer.Name,
        Size      = UDim2.new(1, -60, 0, 16),
        Position  = UDim2.new(0, 44, 0.5, -8),
        Font      = Config.Font.Body,
        TextSize  = 11,
        TextColor = Theme.Get("TextSecondary"),
    })

    Functions.CreateLabel({
        Name      = "StatusLabel",
        Parent    = footer,
        Text      = options.Premium and "✦ Premium" or "Free",
        Size      = UDim2.new(1, -60, 0, 12),
        Position  = UDim2.new(0, 44, 0.5, 6),
        Font      = Config.Font.Small,
        TextSize  = 10,
        TextColor = options.Premium and Color3.fromRGB(240, 170, 40) or Theme.Get("TextDisabled"),
    })
end

-- ============================================================
-- SEPARATOR HELPER
-- ============================================================

function Sidebar._BuildSeparator(parent, layoutOrder)
    local sep = Functions.CreateFrame({
        Name       = "Separator_" .. layoutOrder,
        Parent     = parent,
        Size       = UDim2.new(1, -16, 0, 1),
        BackgroundColor = Theme.Get("Separator"),
        BackgroundTransparency = 0.3,
        LayoutOrder = layoutOrder,
    })
    return sep
end

-- ============================================================
-- COLLAPSE (untuk mode layar kecil)
-- ============================================================

--[[
    Sidebar.Collapse()
    Sembunyikan teks, tampilkan hanya ikon.
]]
function Sidebar.Collapse()
    Sidebar._collapsed = true
    if not Sidebar._frame then return end

    local ts = game:GetService("TweenService")
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- Animate lebar sidebar
    ts:Create(Sidebar._frame, info, {
        Size = UDim2.new(0, 48, 1, 0),
    }):Play()

    -- Sembunyikan label teks semua nav item
    for _, item in ipairs(Sidebar._frame:GetDescendants()) do
        if item.Name == "TabLabel" or item.Name == "HubName"
        or item.Name == "Version" or item.Name == "Username"
        or item.Name == "StatusLabel" or item.Name == "PremiumBadge" then
            ts:Create(item, info, { TextTransparency = 1 }):Play()
            if item:IsA("Frame") then
                ts:Create(item, info, { BackgroundTransparency = 1 }):Play()
            end
        end
    end
end

--[[
    Sidebar.Expand()
    Tampilkan kembali teks sidebar setelah collapse.
]]
function Sidebar.Expand()
    Sidebar._collapsed = false
    if not Sidebar._frame then return end

    local ts = game:GetService("TweenService")
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    ts:Create(Sidebar._frame, info, {
        Size = UDim2.new(0, Config.UI.SidebarWidth, 1, 0),
    }):Play()

    for _, item in ipairs(Sidebar._frame:GetDescendants()) do
        if item.Name == "TabLabel" or item.Name == "HubName"
        or item.Name == "Username" or item.Name == "StatusLabel" then
            ts:Create(item, info, { TextTransparency = 0 }):Play()
        end
        if item.Name == "PremiumBadge" then
            ts:Create(item, info, { BackgroundTransparency = 0 }):Play()
        end
    end
end

return Sidebar
