--[[
    BorcaUIHub — Components/Labels.lua
    Teks statis: judul, nama fitur, keterangan singkat, penanda status.
    Mendukung icon prefix, badge, warna kustom, dan alignment.
]]

local Labels = {}

local Theme     = require(script.Parent.Parent.UI.Theme)
local Config    = require(script.Parent.Parent.UI.Config)
local Functions = require(script.Parent.Parent.UI.Functions)

-- ============================================================
-- PUBLIC API
-- ============================================================

--[[
    Labels.Create(parent, options) → labelObject
    Buat label teks statis.

    @param options {
        Text:         string
        Style:        "title" | "subtitle" | "body" | "hint" | "accent" | "error" | "success" | "warning"
        Icon:         string   -- opsional karakter di kiri teks
        Align:        "left" | "center" | "right"
        Color:        Color3   -- override warna
        RichText:     boolean
        Wrap:         boolean  -- word wrap
        LayoutOrder:  number
    }
    @return labelObject {
        Frame:      Frame (atau TextLabel)
        SetText:    function(string)
        SetColor:   function(Color3)
        SetVisible: function(boolean)
    }
]]
function Labels.Create(parent, options)
    options = options or {}

    local text        = options.Text        or ""
    local style       = options.Style       or "body"
    local icon        = options.Icon        or ""
    local align       = options.Align       or "left"
    local customColor = options.Color
    local richText    = options.RichText    or false
    local wordWrap    = options.Wrap        or false
    local layoutOrder = options.LayoutOrder or 0

    -- Tentukan font & warna berdasarkan style
    local font, textSize, textColor
    if style == "title" then
        font      = Enum.Font.GothamBold
        textSize  = Config.Font.Size.Title
        textColor = Theme.Get("TextPrimary")
    elseif style == "subtitle" then
        font      = Enum.Font.GothamBold
        textSize  = Config.Font.Size.ComponentLabel
        textColor = Theme.Get("TextSecondary")
    elseif style == "hint" then
        font      = Config.Font.Small
        textSize  = Config.Font.Size.ComponentHint
        textColor = Theme.Get("TextSecondary")
    elseif style == "accent" then
        font      = Enum.Font.GothamBold
        textSize  = Config.Font.Size.ComponentLabel
        textColor = Theme.Get("Accent")
    elseif style == "error" then
        font      = Config.Font.Body
        textSize  = Config.Font.Size.ComponentLabel
        textColor = Theme.Get("Error")
    elseif style == "success" then
        font      = Config.Font.Body
        textSize  = Config.Font.Size.ComponentLabel
        textColor = Theme.Get("Success")
    elseif style == "warning" then
        font      = Config.Font.Body
        textSize  = Config.Font.Size.ComponentLabel
        textColor = Theme.Get("Warning")
    else  -- body (default)
        font      = Config.Font.Body
        textSize  = Config.Font.Size.ComponentLabel
        textColor = Theme.Get("TextPrimary")
    end

    if customColor then textColor = customColor end

    local xAlign = Enum.TextXAlignment.Left
    if align == "center" then xAlign = Enum.TextXAlignment.Center
    elseif align == "right" then xAlign = Enum.TextXAlignment.Right end

    -- Jika ada ikon, bungkus dalam frame horizontal
    if icon ~= "" then
        local frame = Functions.CreateFrame({
            Name                   = "LabelRow",
            Parent                 = parent,
            Size                   = UDim2.new(1, 0, 0, textSize + 6),
            AutomaticSize          = wordWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            LayoutOrder            = layoutOrder,
        })

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection      = Enum.FillDirection.Horizontal
        rowLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
        rowLayout.SortOrder          = Enum.SortOrder.LayoutOrder
        rowLayout.Padding            = UDim.new(0, 6)
        rowLayout.Parent             = frame

        -- Ikon
        Functions.CreateLabel({
            Name         = "LabelIcon",
            Parent       = frame,
            Text         = icon,
            Size         = UDim2.new(0, textSize, 0, textSize),
            Font         = Enum.Font.GothamBold,
            TextSize     = textSize - 2,
            TextColor    = textColor,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex       = 3,
            LayoutOrder  = 0,
        })

        local lbl = Functions.CreateLabel({
            Name         = "LabelText",
            Parent       = frame,
            Text         = text,
            Size         = UDim2.new(1, -(textSize + 10), 0, textSize + 6),
            Font         = font,
            TextSize     = textSize,
            TextColor    = textColor,
            TextXAlignment = xAlign,
            RichText     = richText,
            ZIndex       = 3,
            LayoutOrder  = 1,
        })
        if wordWrap then lbl.TextWrapped = true end

        Theme.OnChanged(function()
            lbl.TextColor3 = customColor or Theme.Get(
                style == "hint" and "TextSecondary" or
                style == "accent" and "Accent" or
                style == "error" and "Error" or
                style == "success" and "Success" or
                style == "warning" and "Warning" or "TextPrimary"
            )
        end)

        return {
            Frame     = frame,
            SetText   = function(t) lbl.Text = t end,
            SetColor  = function(c) lbl.TextColor3 = c end,
            SetVisible = function(v) frame.Visible = v end,
        }
    end

    -- Tanpa ikon: langsung TextLabel
    local lbl = Functions.CreateLabel({
        Name         = "Label",
        Parent       = parent,
        Text         = text,
        Size         = UDim2.new(1, 0, 0, wordWrap and 0 or (textSize + 6)),
        AutomaticSize = wordWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        Font         = font,
        TextSize     = textSize,
        TextColor    = textColor,
        TextXAlignment = xAlign,
        RichText     = richText,
        ZIndex       = 3,
        LayoutOrder  = layoutOrder,
    })
    if wordWrap then lbl.TextWrapped = true end

    Theme.OnChanged(function()
        lbl.TextColor3 = customColor or Theme.Get(
            style == "hint" and "TextSecondary" or
            style == "accent" and "Accent" or
            style == "error" and "Error" or
            style == "success" and "Success" or
            style == "warning" and "Warning" or
            style == "subtitle" and "TextSecondary" or "TextPrimary"
        )
    end)

    return {
        Frame     = lbl,
        SetText   = function(t) lbl.Text = t end,
        SetColor  = function(c) lbl.TextColor3 = c end,
        SetVisible = function(v) lbl.Visible = v end,
    }
end

--[[
    Labels.Title(parent, text, options) → labelObject
    Shortcut: label judul.
]]
function Labels.Title(parent, text, options)
    options = options or {}
    options.Text  = text
    options.Style = "title"
    return Labels.Create(parent, options)
end

--[[
    Labels.Hint(parent, text, options) → labelObject
    Shortcut: label hint kecil.
]]
function Labels.Hint(parent, text, options)
    options = options or {}
    options.Text  = text
    options.Style = "hint"
    return Labels.Create(parent, options)
end

--[[
    Labels.Badge(parent, text, options) → Frame
    Buat badge kecil dengan background (contoh: "NEW", "FREE", status).
]]
function Labels.Badge(parent, text, colorKey, options)
    options = options or {}
    local color    = Theme.Get(colorKey or "Accent")
    local layoutOrder = options.LayoutOrder or 0

    local badge = Functions.CreateFrame({
        Name            = "Badge_" .. text,
        Parent          = parent,
        Size            = UDim2.new(0, 0, 0, 18),
        AutomaticSize   = Enum.AutomaticSize.X,
        BackgroundColor = color,
        CornerRadius    = 4,
        ZIndex          = options.ZIndex or 4,
        LayoutOrder     = layoutOrder,
    })

    Functions.ApplyPadding(badge, { Left = 7, Right = 7 })

    local lbl = Functions.CreateLabel({
        Name      = "BadgeText",
        Parent    = badge,
        Text      = text,
        Size      = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font      = Enum.Font.GothamBold,
        TextSize  = Config.Font.Size.BadgeText,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = badge.ZIndex + 1,
    })

    return badge
end

return Labels
