-- // Cards.lua
-- // BorcaScriptHub - Card Component
-- // Card adalah panel konten untuk menampung informasi, preview, status, atau blok fitur.
-- // Mendukung: title, description, badge, icon, footer, image, aksi klik, dan variant style.

local Cards = {}
local Functions, Theme, Config

function Cards.Init(deps)
    Functions = deps.Functions
    Theme     = deps.Theme
    Config    = deps.Config
end

-- ========================
-- // VARIANT STYLES
-- // "Default"  = panel biasa (SecondaryBG)
-- // "Accent"   = border accent aktif
-- // "Success"  = border hijau
-- // "Warning"  = border kuning
-- // "Error"    = border merah
-- // "Premium"  = border + glow ungu (Midnight accent)
-- // "Flat"     = tanpa border, background tipis
-- ========================
local VARIANTS = {
    Default = function(t) return t.Get("SecondaryBG"),  t.Get("Border"),    1 end,
    Accent  = function(t) return t.Get("TertiaryBG"),   t.Get("Accent"),    1 end,
    Success = function(t) return t.Get("TertiaryBG"),   t.Get("Success"),   1 end,
    Warning = function(t) return t.Get("TertiaryBG"),   t.Get("Warning"),   1 end,
    Error   = function(t) return t.Get("TertiaryBG"),   t.Get("Error"),     1 end,
    Premium = function(t) return t.Get("SecondaryBG"),  t.Get("Accent"),    0.4 end,
    Flat    = function(t) return t.Get("ElementBG"),    t.Get("Border"),    0.85 end,
}

-- ========================
-- // INTERNAL: Accent strip kiri (seperti Paragraph)
-- ========================
local function makeAccentStrip(parent, color)
    local strip = Functions.Create("Frame", {
        Size             = UDim2.fromOffset(3, 0),
        Position         = UDim2.fromOffset(0, 0),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        ZIndex           = 2,
    }, parent)
    Functions.Create("UICorner", {CornerRadius = UDim.new(1, 0)}, strip)
    return strip
end

-- ========================
-- // CREATE CARD
-- ========================
--[[
options = {
    -- Wajib
    Name        = "Card Name",        -- string

    -- Konten
    Title       = "Judul Card",       -- string (opsional; kalau kosong pakai Name)
    Description = "Deskripsi...",     -- string
    Icon        = "⭐",               -- emoji/char (opsional)
    Badge       = "NEW",              -- teks badge (opsional)
    BadgeType   = "Accent",           -- "Accent"|"Success"|"Warning"|"Error"
    Footer      = "Updated: v1.2",    -- teks kecil di bawah (opsional)

    -- Style
    Variant     = "Default",          -- lihat VARIANTS di atas
    AccentStrip = false,              -- apakah tampilkan garis kiri accent?
    Clickable   = false,              -- apakah card bisa diklik?
    Callback    = function() end,     -- dipanggil saat klik (jika Clickable=true)

    -- Layout
    Order       = nil,                -- LayoutOrder
}
]]
function Cards.CreateCard(section, options)
    options = options or {}

    local name        = options.Name        or "Card"
    local title       = options.Title       or name
    local description = options.Description or ""
    local icon        = options.Icon        or ""
    local badge       = options.Badge       or ""
    local badgeType   = options.BadgeType   or "Accent"
    local footer      = options.Footer      or ""
    local variant     = options.Variant     or "Default"
    local accentStrip = options.AccentStrip == true
    local clickable   = options.Clickable   == true
    local callback    = options.Callback    or function() end
    local order       = options.Order       or #section.Elements + 1

    -- Ambil warna dari variant
    local varFn = VARIANTS[variant] or VARIANTS.Default
    local bgColor, borderColor, borderTransp = varFn(Theme)

    -- ========================
    -- // CARD FRAME
    -- ========================
    local cardFrame = Functions.Create(clickable and "TextButton" or "Frame", {
        Name             = "Card_" .. name,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = bgColor,
        BorderSizePixel  = 0,
        LayoutOrder      = order,
        ClipsDescendants = false,
        -- TextButton specific
        Text             = "",
        AutoButtonColor  = false,
    }, section.ContentHolder)

    Functions.Create("UICorner", {
        CornerRadius = UDim.new(0, Config.UI.ElementCorner + 1)
    }, cardFrame)

    local stroke = Functions.Create("UIStroke", {
        Color           = borderColor,
        Thickness       = variant == "Premium" and 1.5 or 1,
        Transparency    = borderTransp < 1 and (1 - borderTransp) or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, cardFrame)

    -- ========================
    -- // INNER PADDING
    -- ========================
    local paddingLeft = accentStrip and 16 or 10
    Functions.Create("UIPadding", {
        PaddingTop    = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft   = UDim.new(0, paddingLeft),
        PaddingRight  = UDim.new(0, 10),
    }, cardFrame)

    Functions.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 3),
    }, cardFrame)

    -- ========================
    -- // ACCENT STRIP (opsional)
    -- ========================
    if accentStrip then
        makeAccentStrip(cardFrame, borderColor)
    end

    -- ========================
    -- // HEADER ROW (icon + title + badge)
    -- ========================
    local headerRow = Functions.Create("Frame", {
        Name             = "HeaderRow",
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        LayoutOrder      = 1,
    }, cardFrame)

    Functions.Create("UIListLayout", {
        FillDirection    = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Padding          = UDim.new(0, 5),
    }, headerRow)

    -- Icon
    local iconLabel = nil
    if icon ~= "" then
        iconLabel = Functions.Create("TextLabel", {
            Name                   = "Icon",
            Size                   = UDim2.fromOffset(20, 20),
            BackgroundColor3       = Theme.Get("ElementBG"),
            BackgroundTransparency = 0,
            Text                   = icon,
            TextSize               = 13,
            Font                   = Enum.Font.GothamMedium,
            BorderSizePixel        = 0,
            LayoutOrder            = 1,
        }, headerRow)
        Functions.Create("UICorner", {CornerRadius = UDim.new(0, 4)}, iconLabel)
    end

    -- Title
    local titleLabel = Functions.Create("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(0, 0, 0, 18),
        AutomaticSize          = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = Theme.Get("TextPrimary"),
        TextSize               = Config.UI.FontSize,
        Font                   = Config.UI.TitleFont,
        TextXAlignment         = Enum.TextXAlignment.Left,
        LayoutOrder            = 2,
    }, headerRow)

    -- Badge
    local badgeLabel = nil
    if badge ~= "" then
        local badgeColorKey = ({
            Accent  = "Accent",
            Success = "Success",
            Warning = "Warning",
            Error   = "Error",
        })[badgeType] or "Accent"
        local badgeColor = Theme.Get(badgeColorKey)

        badgeLabel = Functions.Create("TextLabel", {
            Name                   = "Badge",
            Size                   = UDim2.new(0, 0, 0, 16),
            AutomaticSize          = Enum.AutomaticSize.X,
            BackgroundColor3       = badgeColor,
            BackgroundTransparency = 0.72,
            Text                   = " " .. badge .. " ",
            TextColor3             = badgeColor,
            TextSize               = 8,
            Font                   = Enum.Font.GothamBold,
            BorderSizePixel        = 0,
            LayoutOrder            = 3,
        }, headerRow)
        Functions.Create("UICorner", {CornerRadius = UDim.new(0, 3)}, badgeLabel)
    end

    -- ========================
    -- // DESCRIPTION
    -- ========================
    local descLabel = nil
    if description ~= "" then
        descLabel = Functions.Create("TextLabel", {
            Name                   = "Description",
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text                   = description,
            TextColor3             = Theme.Get("TextSecondary"),
            TextSize               = Config.UI.FontSize - 1,
            Font                   = Config.UI.SmallFont,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            RichText               = true,
            LayoutOrder            = 2,
        }, cardFrame)
    end

    -- ========================
    -- // FOOTER
    -- ========================
    local footerLabel = nil
    if footer ~= "" then
        -- Divider tipis sebelum footer
        Functions.Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Get("Divider"),
            BorderSizePixel  = 0,
            LayoutOrder      = 3,
        }, cardFrame)

        footerLabel = Functions.Create("TextLabel", {
            Name                   = "Footer",
            Size                   = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text                   = footer,
            TextColor3             = Theme.Get("TextMuted"),
            TextSize               = 9,
            Font                   = Config.UI.SmallFont,
            TextXAlignment         = Enum.TextXAlignment.Left,
            LayoutOrder            = 4,
        }, cardFrame)
    end

    -- ========================
    -- // HOVER & CLICK (jika Clickable)
    -- ========================
    if clickable then
        cardFrame.MouseEnter:Connect(function()
            Functions.Tween(cardFrame, {BackgroundColor3 = Theme.Get("HoverBG")}, 0.1)
            Functions.Tween(stroke, {Color = Theme.Get("AccentHover")}, 0.1)
        end)
        cardFrame.MouseLeave:Connect(function()
            Functions.Tween(cardFrame, {BackgroundColor3 = bgColor}, 0.1)
            Functions.Tween(stroke, {Color = borderColor}, 0.1)
        end)
        cardFrame.MouseButton1Down:Connect(function()
            Functions.Tween(cardFrame, {BackgroundColor3 = Theme.Get("AccentDark")}, 0.08)
        end)
        cardFrame.MouseButton1Up:Connect(function()
            Functions.Tween(cardFrame, {BackgroundColor3 = Theme.Get("HoverBG")}, 0.12)
        end)
        cardFrame.MouseButton1Click:Connect(function()
            Functions.SafeCall(callback)
        end)
    end

    -- ========================
    -- // CARD OBJECT
    -- ========================
    local Card = {
        Name       = name,
        Frame      = cardFrame,
        Variant    = variant,
    }

    function Card:SetTitle(t)
        titleLabel.Text = tostring(t or "")
    end

    function Card:SetDescription(d)
        if descLabel then
            descLabel.Text = tostring(d or "")
        end
    end

    function Card:SetBadge(text, bType)
        if badgeLabel then
            badgeLabel.Text = " " .. tostring(text or "") .. " "
            if bType then
                local c = Theme.Get(bType)
                badgeLabel.TextColor3             = c
                badgeLabel.BackgroundColor3       = c
            end
        end
    end

    function Card:SetFooter(f)
        if footerLabel then
            footerLabel.Text = tostring(f or "")
        end
    end

    function Card:SetIcon(i)
        if iconLabel then
            iconLabel.Text = tostring(i or "")
        end
    end

    function Card:SetVisible(v)
        cardFrame.Visible = v
    end

    function Card:SetCallback(fn)
        callback = fn
    end

    function Card:Destroy()
        cardFrame:Destroy()
        Functions.TableRemove(section.Elements, self)
    end

    table.insert(section.Elements, Card)
    return Card
end

return Cards
