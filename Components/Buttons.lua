--[[
    BorcaUIHub — Components/Buttons.lua
    Komponen tombol aksi: primary, secondary, danger, ghost, icon.
    Setiap tombol punya hover, click feedback, dan animasi halus.
]]

local Buttons = {}

local Theme      = require(script.Parent.Parent.UI.Theme)
local Config     = require(script.Parent.Parent.UI.Config)
local Functions  = require(script.Parent.Parent.UI.Functions)
local Animations = require(script.Parent.Parent.UI.Animations)

-- ============================================================
-- INTERNAL BUILDER
-- ============================================================

local function BuildButton(parent, options)
    options = options or {}

    local variant  = options.Variant  or "secondary"   -- "primary"|"secondary"|"danger"|"ghost"|"icon"
    local text      = options.Text     or "Button"
    local icon      = options.Icon     or ""            -- karakter unicode opsional di kiri teks
    local width     = options.Width    or 0
    local autoWidth = options.AutoWidth ~= false
    local height    = options.Height   or Config.UI.ComponentHeight - 6
    local disabled  = options.Disabled or false
    local callback  = options.OnClick
    local layoutOrder = options.LayoutOrder or 0
    local tooltip   = options.Tooltip  or ""

    -- Warna berdasarkan variant
    local bgColor, textColor, hoverColor, activeColor
    if variant == "primary" then
        bgColor     = Theme.Get("ButtonPrimary")
        textColor   = Color3.fromRGB(255, 255, 255)
        hoverColor  = Theme.Get("AccentHover")
        activeColor = Theme.Get("AccentDim")
    elseif variant == "danger" then
        bgColor     = Theme.Get("Error")
        textColor   = Color3.fromRGB(255, 255, 255)
        hoverColor  = Color3.new(
            math.min(Theme.Get("Error").R + 0.08, 1),
            math.max(Theme.Get("Error").G - 0.02, 0),
            math.max(Theme.Get("Error").B - 0.02, 0)
        )
        activeColor = Color3.new(
            math.max(Theme.Get("Error").R - 0.06, 0),
            math.max(Theme.Get("Error").G - 0.02, 0),
            math.max(Theme.Get("Error").B - 0.02, 0)
        )
    elseif variant == "ghost" then
        bgColor     = Color3.fromRGB(0, 0, 0)
        textColor   = Theme.Get("Accent")
        hoverColor  = Theme.Get("ButtonHover")
        activeColor = Theme.Get("ButtonActive")
    else
        -- secondary (default)
        bgColor     = Theme.Get("ButtonSecondary")
        textColor   = Theme.Get("TextPrimary")
        hoverColor  = Theme.Get("ButtonHover")
        activeColor = Theme.Get("ButtonActive")
    end

    -- Ukuran
    local sizeX = autoWidth and UDim2.new(0, 0, 0, height) or UDim2.new(0, width, 0, height)
    local autoSz = autoWidth and Enum.AutomaticSize.X or Enum.AutomaticSize.None

    local btn = Functions.CreateButton({
        Name                   = options.Name or ("Btn_" .. text),
        Parent                 = parent,
        Size                   = sizeX,
        AutomaticSize          = autoSz,
        BackgroundColor        = bgColor,
        BackgroundTransparency = variant == "ghost" and 1 or 0,
        CornerRadius           = Config.UI.ButtonRadius,
        LayoutOrder            = layoutOrder,
        ZIndex                 = options.ZIndex or 3,
        Text                   = "",
    })

    -- Stroke untuk ghost / secondary
    if variant == "ghost" then
        Functions.ApplyStroke(btn, {
            Color        = Theme.Get("Accent"),
            Thickness    = 1,
            Transparency = 0.4,
        })
    elseif variant == "secondary" then
        Functions.ApplyStroke(btn, {
            Color        = Theme.Get("Stroke"),
            Thickness    = 1,
            Transparency = 0.5,
        })
    end

    -- Padding dalam tombol
    Functions.ApplyPadding(btn, { Left = 14, Right = 14, Top = 0, Bottom = 0 })

    -- Layout horizontal ikon + teks
    local layout = Instance.new("UIListLayout")
    layout.FillDirection        = Enum.FillDirection.Horizontal
    layout.VerticalAlignment    = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    layout.SortOrder            = Enum.SortOrder.LayoutOrder
    layout.Padding              = UDim.new(0, 6)
    layout.Parent               = btn

    -- Ikon (jika ada)
    if icon ~= "" then
        local iconLbl = Functions.CreateLabel({
            Name      = "BtnIcon",
            Parent    = btn,
            Text      = icon,
            Size      = UDim2.new(0, 16, 1, 0),
            Font      = Enum.Font.GothamBold,
            TextSize  = 13,
            TextColor = textColor,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex    = btn.ZIndex + 1,
            LayoutOrder = 0,
        })
    end

    -- Label teks
    local textLbl = Functions.CreateLabel({
        Name      = "BtnText",
        Parent    = btn,
        Text      = text,
        Size      = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.ComponentLabel,
        TextColor = textColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = btn.ZIndex + 1,
        LayoutOrder = 1,
    })

    -- State disabled
    if disabled then
        btn.BackgroundTransparency = 0.5
        textLbl.TextTransparency   = 0.5
        btn.Active = false
    else
        -- Hover & click animations
        local ts = game:GetService("TweenService")
        local hInfo = TweenInfo.new(Config.Animation.HoverDuration)
        local cInfo = TweenInfo.new(0.08)

        btn.MouseEnter:Connect(function()
            if variant ~= "ghost" then
                ts:Create(btn, hInfo, { BackgroundColor3 = hoverColor }):Play()
            else
                ts:Create(btn, hInfo, { BackgroundTransparency = 0.85 }):Play()
            end
            Animations.ApplyScaleHover(btn, 1)
        end)

        btn.MouseLeave:Connect(function()
            if variant ~= "ghost" then
                ts:Create(btn, hInfo, { BackgroundColor3 = bgColor }):Play()
            else
                ts:Create(btn, hInfo, { BackgroundTransparency = 1 }):Play()
            end
        end)

        btn.MouseButton1Down:Connect(function()
            if variant ~= "ghost" then
                ts:Create(btn, cInfo, { BackgroundColor3 = activeColor }):Play()
            end
            ts:Create(btn, cInfo, { Size = UDim2.new(
                sizeX.X.Scale, sizeX.X.Offset - 2,
                0, height - 2
            )}):Play()
        end)

        btn.MouseButton1Up:Connect(function()
            ts:Create(btn, hInfo, { BackgroundColor3 = hoverColor }):Play()
            ts:Create(btn, hInfo, { Size = sizeX }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            if callback then
                pcall(callback)
            end
        end)
    end

    -- Tooltip singkat (opsional)
    if tooltip ~= "" then
        btn:SetAttribute("Tooltip", tooltip)
    end

    -- Theme update
    Theme.OnChanged(function()
        if variant == "primary" then
            btn.BackgroundColor3 = Theme.Get("ButtonPrimary")
        elseif variant == "secondary" then
            btn.BackgroundColor3 = Theme.Get("ButtonSecondary")
        end
        if not disabled then
            textLbl.TextColor3 = variant == "primary" and Color3.fromRGB(255,255,255)
                or (variant == "ghost" and Theme.Get("Accent") or Theme.Get("TextPrimary"))
        end
    end)

    return btn
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Buttons.Create(parent, options) → TextButton
    Buat tombol aksi yang bisa dikustomisasi penuh.

    @param options {
        Variant:      "primary" | "secondary" | "danger" | "ghost"
        Text:         string
        Icon:         string   -- karakter unicode opsional
        Width:        number   -- lebar tetap (jika AutoWidth false)
        AutoWidth:    boolean  -- otomatis sesuai teks (default true)
        Height:       number
        Disabled:     boolean
        OnClick:      function
        LayoutOrder:  number
        Tooltip:      string
    }
]]
function Buttons.Create(parent, options)
    return BuildButton(parent, options)
end

--[[
    Buttons.Primary(parent, text, onClick, options) → TextButton
    Shortcut: tombol primary (accent color).
]]
function Buttons.Primary(parent, text, onClick, options)
    options = options or {}
    options.Variant = "primary"
    options.Text    = text
    options.OnClick = onClick
    return BuildButton(parent, options)
end

--[[
    Buttons.Secondary(parent, text, onClick, options) → TextButton
    Shortcut: tombol secondary (netral).
]]
function Buttons.Secondary(parent, text, onClick, options)
    options = options or {}
    options.Variant = "secondary"
    options.Text    = text
    options.OnClick = onClick
    return BuildButton(parent, options)
end

--[[
    Buttons.Danger(parent, text, onClick, options) → TextButton
    Shortcut: tombol danger (merah, untuk aksi destruktif).
]]
function Buttons.Danger(parent, text, onClick, options)
    options = options or {}
    options.Variant = "danger"
    options.Text    = text
    options.OnClick = onClick
    return BuildButton(parent, options)
end

--[[
    Buttons.Ghost(parent, text, onClick, options) → TextButton
    Shortcut: tombol ghost (transparan dengan border accent).
]]
function Buttons.Ghost(parent, text, onClick, options)
    options = options or {}
    options.Variant = "ghost"
    options.Text    = text
    options.OnClick = onClick
    return BuildButton(parent, options)
end

--[[
    Buttons.Icon(parent, iconChar, onClick, options) → TextButton
    Tombol ikon persegi (tanpa teks).
]]
function Buttons.Icon(parent, iconChar, onClick, options)
    options = options or {}
    local size = options.Size or 32

    local btn = Functions.CreateButton({
        Name            = options.Name or "IconBtn",
        Parent          = parent,
        Size            = UDim2.new(0, size, 0, size),
        BackgroundColor = options.Color or Theme.Get("ButtonSecondary"),
        CornerRadius    = options.Round and UDim.new(1, 0) or Config.UI.ButtonRadius,
        ZIndex          = options.ZIndex or 3,
        LayoutOrder     = options.LayoutOrder or 0,
        Text            = "",
    })

    Functions.CreateLabel({
        Name      = "IconChar",
        Parent    = btn,
        Text      = iconChar,
        Size      = UDim2.new(1, 0, 1, 0),
        Font      = Enum.Font.GothamBold,
        TextSize  = options.IconSize or 14,
        TextColor = options.TextColor or Theme.Get("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = btn.ZIndex + 1,
    })

    Animations.ApplyHoverEffect(btn, Theme.Get("ButtonHover"), Theme.Get("ButtonSecondary"))

    btn.MouseButton1Click:Connect(function()
        if onClick then pcall(onClick) end
    end)

    return btn
end

--[[
    Buttons.Row(parent, buttonDefs, options) → Frame
    Buat satu baris tombol sekaligus.

    @param buttonDefs  { { Variant, Text, OnClick }, ... }
    @param options {
        Gap:    number   -- jarak antar tombol
        Align:  "left" | "center" | "right"
    }
]]
function Buttons.Row(parent, buttonDefs, options)
    options = options or {}

    local row = Functions.CreateFrame({
        Name                   = "ButtonRow",
        Parent                 = parent,
        Size                   = UDim2.new(1, 0, 0, Config.UI.ComponentHeight),
        BackgroundTransparency = 1,
        LayoutOrder            = options.LayoutOrder or 0,
    })

    local halign = Enum.HorizontalAlignment.Left
    if options.Align == "center" then
        halign = Enum.HorizontalAlignment.Center
    elseif options.Align == "right" then
        halign = Enum.HorizontalAlignment.Right
    end

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = halign
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Padding             = UDim.new(0, options.Gap or 8)
    layout.Parent              = row

    for i, def in ipairs(buttonDefs) do
        def.LayoutOrder = i
        BuildButton(row, def)
    end

    return row
end

return Buttons
